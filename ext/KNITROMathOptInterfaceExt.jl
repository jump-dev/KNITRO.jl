# Copyright (c) 2016: Ng Yee Sian, Miles Lubin, other contributors
#
# Use of this source code is governed by an MIT-style license that can be found
# in the LICENSE.md file or at https://opensource.org/licenses/MIT.

module KNITROMathOptInterfaceExt

import KNITRO
import MathOptInterface as MOI

function __init__()
    setglobal!(KNITRO, :Optimizer, Optimizer)
    return
end

"""
    _c_column(x::MOI.VariableIndex) --> Cint

Return the 0-indexed `Cint` corressponding to the column of `x`.
"""
_c_column(x::MOI.VariableIndex) = Cint(x.value - 1)

const _SETS = Union{
    MOI.LessThan{Float64},
    MOI.GreaterThan{Float64},
    MOI.EqualTo{Float64},
    MOI.Interval{Float64},
}

function _canonical_quadratic_reduction(f::MOI.ScalarQuadraticFunction)
    if !MOI.Utilities.is_canonical(f)
        f = MOI.Utilities.canonicalize!(copy(f))
    end
    I = Cint[_c_column(term.variable_1) for term in f.quadratic_terms]
    J = Cint[_c_column(term.variable_2) for term in f.quadratic_terms]
    V = Cdouble[term.coefficient for term in f.quadratic_terms]
    for i in eachindex(V)
        if I[i] == J[i]
            V[i] /= 2
        elseif I[i] > J[i]
            I[i], J[i] = J[i], I[i]
        end
    end
    return length(I), I, J, V
end

function _canonical_linear_reduction(terms::Vector{<:MOI.ScalarAffineTerm})
    columns = Cint[_c_column(term.variable) for term in terms]
    coefficients = Cdouble[term.coefficient for term in terms]
    return length(terms), columns, coefficients
end

function _canonical_linear_reduction(f::MOI.ScalarQuadraticFunction)
    return _canonical_linear_reduction(f.affine_terms)
end

function _canonical_linear_reduction(f::MOI.ScalarAffineFunction)
    return _canonical_linear_reduction(f.terms)
end

function _canonical_vector_affine_reduction(f::MOI.VectorAffineFunction)
    I, J, V = Cint[], Cint[], Cdouble[]
    for t in f.terms
        push!(I, t.output_index - 1)
        push!(J, _c_column(t.scalar_term.variable))
        push!(V, t.scalar_term.coefficient)
    end
    return I, J, V
end

_clamp_inf(x::Float64) = clamp(x, -KNITRO.KN_INFINITY, KNITRO.KN_INFINITY)

mutable struct _VariableInfo
    has_lower_bound::Bool
    has_upper_bound::Bool
    is_fixed::Bool
    name::String
    _VariableInfo() = new(false, false, false, "")
end

mutable struct _ComplementarityCache
    n::Int
    index_comps_1::Vector{Cint}
    index_comps_2::Vector{Cint}
    cc_types::Vector{Cint}
    _ComplementarityCache() = new(0, Cint[], Cint[], Cint[])
end

_has_complementarity(cache::_ComplementarityCache) = cache.n >= 1

function _add_complementarity_constraint!(
    cache::_ComplementarityCache,
    index_vars_1::Vector{Cint},
    index_vars_2::Vector{Cint},
    cc_types::Vector{Int},
)
    @assert length(index_vars_1) == length(index_vars_2) == length(cc_types)
    cache.n += 1
    append!(cache.index_comps_1, index_vars_1)
    append!(cache.index_comps_2, index_vars_2)
    append!(cache.cc_types, cc_types)
    return
end

mutable struct Optimizer <: MOI.AbstractOptimizer
    inner::KNITRO.Model
    # We only keep in memory some information about variables
    # as we cannot delete variables, we do not have to store an index.
    variable_info::Vector{_VariableInfo}
    # Get number of solve for restart.
    number_solved::Int
    # Specify if NLP is loaded inside KNITRO to avoid double definition.
    nlp_loaded::Bool
    nlp_data::Union{Nothing,MOI.NLPBlockData}
    nlp_model::MOI.Nonlinear.Model
    # Store index of nlp constraints.
    nlp_index_cons::Vector{Cint}
    # Store optimization sense.
    sense::MOI.OptimizationSense
    # Store the structure of the objective.
    objective::Union{
        MOI.VariableIndex,
        MOI.ScalarAffineFunction{Float64},
        MOI.ScalarQuadraticFunction{Float64},
        MOI.ScalarNonlinearFunction,
        Nothing,
    }
    # Complementarity cache
    complementarity_cache::_ComplementarityCache
    # Constraint mappings.
    constraint_mapping::Dict{MOI.ConstraintIndex,Union{Cint,Vector{Cint}}}
    license_manager::Union{KNITRO.LMcontext,Nothing}
    options::Dict{String,Any}
    # Cache for the solution
    x::Vector{Float64}
    lambda::Vector{Float64}
    time_limit_sec::Union{Nothing,Float64}
end

function Optimizer(; license_manager::Union{KNITRO.LMcontext,Nothing}=nothing, kwargs...)
    if !isempty(kwargs)
        error("Unsupported keyword arguments passed to `Optimizer`. Set attributes instead")
    end
    kc = if isa(license_manager, KNITRO.LMcontext)
        KNITRO.KN_new_lm(license_manager)
    else
        KNITRO.KN_new()
    end
    return Optimizer(
        kc,
        _VariableInfo[],
        0,
        false,
        nothing,
        MOI.Nonlinear.Model(),
        Cint[],
        MOI.FEASIBILITY_SENSE,
        nothing,
        _ComplementarityCache(),
        Dict{MOI.ConstraintIndex,Union{Cint,Vector{Cint}}}(),
        license_manager,
        Dict{String,Any}(),
        Float64[],
        Float64[],
        nothing,
    )
end

function Base.show(io::IO, model::Optimizer)
    println(io, "A MathOptInterface model with backend:")
    println(io, model.inner)
    return
end

MOI.supports_incremental_interface(model::Optimizer) = true

function MOI.copy_to(model::Optimizer, src::MOI.ModelLike)
    return MOI.Utilities.default_copy_to(model, src)
end

function MOI.empty!(model::Optimizer)
    KNITRO.@_checked KNITRO.KN_free(model.inner)
    model.inner = if isa(model.license_manager, KNITRO.LMcontext)
        KNITRO.KN_new_lm(model.license_manager)
    else
        KNITRO.KN_new()
    end
    empty!(model.variable_info)
    model.number_solved = 0
    model.nlp_data = nothing
    model.nlp_loaded = false
    model.nlp_index_cons = Cint[]
    MOI.empty!(model.nlp_model)
    model.sense = MOI.FEASIBILITY_SENSE
    model.objective = nothing
    model.complementarity_cache = _ComplementarityCache()
    model.constraint_mapping = Dict()
    model.license_manager = model.license_manager
    for (name, value) in model.options
        MOI.set(model, MOI.RawOptimizerAttribute(name), value)
    end
    empty!(model.x)
    empty!(model.lambda)
    MOI.set(model, MOI.TimeLimitSec(), model.time_limit_sec)
    return
end

function MOI.is_empty(model::Optimizer)
    return isempty(model.variable_info) &&
           model.nlp_data === nothing &&
           MOI.is_empty(model.nlp_model) &&
           model.sense == MOI.FEASIBILITY_SENSE &&
           model.number_solved == 0 &&
           isa(model.objective, Nothing) &&
           !_has_complementarity(model.complementarity_cache) &&
           !model.nlp_loaded
end

function _throw_if_solved(model::Optimizer, attr::MOI.AbstractModelAttribute)
    if model.number_solved >= 1
        msg = "Problem cannot be modified after a call to optimize!"
        throw(MOI.SetAttributeNotAllowed(attr, msg))
    end
    return
end

function _throw_if_solved(model::Optimizer, f::MOI.AbstractFunction, s::MOI.AbstractSet)
    if model.number_solved >= 1
        msg = "Constraints cannot be added after a call to optimize!"
        throw(MOI.AddConstraintNotAllowed{typeof(f),typeof(s)}(msg))
    end
    return
end

function _throw_if_solved(model::Optimizer, ::Type{MOI.VariableIndex})
    if model.number_solved >= 1
        msg = "Variables cannot be added after a call to optimize!"
        throw(MOI.AddVariableNotAllowed(msg))
    end
    return
end

# MOI.SolverName

MOI.get(model::Optimizer, ::MOI.SolverName) = "Knitro"

# MOI.SolverVersion

MOI.get(::Optimizer, ::MOI.SolverVersion) = string(KNITRO.knitro_version())

# MOI.Silent

MOI.supports(model::Optimizer, ::MOI.Silent) = true

function MOI.get(model::Optimizer, ::MOI.Silent)
    p = Ref{Cint}(-1)
    KNITRO.@_checked KNITRO.KN_get_int_param_by_name(model.inner, "outlev", p)
    return p[] == 0
end

function MOI.set(model::Optimizer, ::MOI.Silent, value)
    # Default outlev is KNITRO.KN_OUTLEV_ITER_10.
    outlev = value ? KNITRO.KN_OUTLEV_NONE : KNITRO.KN_OUTLEV_ITER_10
    model.options["outlev"] = outlev
    KNITRO.@_checked KNITRO.KN_set_int_param(model.inner, KNITRO.KN_PARAM_OUTLEV, outlev)
    return
end

# MOI.TimeLimitSec

MOI.supports(model::Optimizer, ::MOI.TimeLimitSec) = true

MOI.get(model::Optimizer, ::MOI.TimeLimitSec) = model.time_limit_sec

function MOI.set(model::Optimizer, ::MOI.TimeLimitSec, value)
    model.time_limit_sec = value
    # By default, maxtime is set to 1e8 in Knitro.
    limit = something(value, 1e8)
    # KNITRO does not have a single option to control the global time limit, so
    # we set various options.
    # MAXTIME_REAL is the base option, which applies if the problem is a NLP.
    KNITRO.@_checked KNITRO.KN_set_double_param(
        model.inner,
        KNITRO.KN_PARAM_MAXTIMEREAL,
        limit,
    )
    # MIP_MAXTIME_REAL applies if the problem is a MINLP
    KNITRO.@_checked KNITRO.KN_set_double_param(
        model.inner,
        KNITRO.KN_PARAM_MIP_MAXTIMEREAL,
        limit,
    )
    return
end

# MOI.RawOptimizerAttribute

function MOI.supports(model::Optimizer, attr::MOI.RawOptimizerAttribute)
    if attr.name in ("option_file", "tuner_file", "free")
        return true
    end
    p = Ref{Cint}(0)
    ret = KNITRO.KN_get_param_id(model.inner, attr.name, p)
    return ret != KNITRO.KN_RC_BAD_PARAMINPUT && p[] > 0
end

function MOI.get(model::Optimizer, attr::MOI.RawOptimizerAttribute)
    if !MOI.supports(model, attr)
        throw(MOI.UnsupportedAttribute(attr))
    elseif !haskey(model.options, attr.name)
        throw(MOI.GetAttributeNotAllowed(attr))
    end
    return model.options[attr.name]
end

function MOI.set(model::Optimizer, attr::MOI.RawOptimizerAttribute, value)
    if attr.name == "option_file"
        KNITRO.@_checked KNITRO.KN_load_param_file(model.inner, value)
        return
    elseif attr.name == "tuner_file"
        KNITRO.@_checked KNITRO.KN_load_tuner_file(model.inner, value)
        return
    elseif attr.name == "free"
        KNITRO.@_checked KNITRO.KN_free(model.inner)
        return
    end
    pId = Ref{Cint}(0)
    ret = KNITRO.KN_get_param_id(model.inner, attr.name, pId)
    if ret == KNITRO.KN_RC_BAD_PARAMINPUT || pId[] <= 0
        throw(MOI.UnsupportedAttribute(attr))
    end
    pType = Ref{Cint}()
    KNITRO.@_checked KNITRO.KN_get_param_type(model.inner, pId[], pType)
    if pType[] == KNITRO.KN_PARAMTYPE_INTEGER
        KNITRO.@_checked KNITRO.KN_set_int_param(model.inner, pId[], value)
    elseif pType[] == KNITRO.KN_PARAMTYPE_FLOAT
        KNITRO.@_checked KNITRO.KN_set_double_param(model.inner, pId[], value)
    else
        @assert pType[] == KNITRO.KN_PARAMTYPE_STRING
        KNITRO.@_checked KNITRO.KN_set_char_param(model.inner, pId[], value)
    end
    model.options[attr.name] = value
    return
end

# MOI.UserDefinedFunction

MOI.supports(model::Optimizer, ::MOI.UserDefinedFunction) = true

function MOI.set(model::Optimizer, attr::MOI.UserDefinedFunction, args)
    MOI.Nonlinear.register_operator(model.nlp_model, attr.name, attr.arity, args...)
    return
end

# Variables

MOI.get(model::Optimizer, ::MOI.NumberOfVariables) = length(model.variable_info)

function MOI.get(model::Optimizer, ::MOI.ListOfVariableIndices)
    return [MOI.VariableIndex(i) for i in 1:length(model.variable_info)]
end

function MOI.add_variable(model::Optimizer)
    _throw_if_solved(model, MOI.VariableIndex)
    push!(model.variable_info, _VariableInfo())
    pindex = Ref{Cint}(0)
    KNITRO.@_checked KNITRO.KN_add_var(model.inner, pindex)
    return MOI.VariableIndex(length(model.variable_info))
end

function MOI.is_valid(model::Optimizer, x::MOI.VariableIndex)
    return 1 <= x.value <= length(model.variable_info)
end

function _throw_if_not_valid(model::Optimizer, x::MOI.VariableIndex)
    return MOI.throw_if_not_valid(model, x)
end

function _throw_if_not_valid(model::Optimizer, aff::MOI.ScalarAffineFunction)
    for term in aff.terms
        _throw_if_not_valid(model, term.variable)
    end
    return
end

function _throw_if_not_valid(model::Optimizer, quad::MOI.ScalarQuadraticFunction)
    for term in quad.affine_terms
        _throw_if_not_valid(model, term.variable)
    end
    for term in quad.quadratic_terms
        _throw_if_not_valid(model, term.variable_1)
        _throw_if_not_valid(model, term.variable_2)
    end
    return
end

function _has_upper_bound(model::Optimizer, x::MOI.VariableIndex)
    return model.variable_info[x.value].has_upper_bound
end

function _has_lower_bound(model::Optimizer, x::MOI.VariableIndex)
    return model.variable_info[x.value].has_lower_bound
end

function _is_fixed(model::Optimizer, x::MOI.VariableIndex)
    return model.variable_info[x.value].is_fixed
end

function _is_binary(model::Optimizer, x::MOI.VariableIndex)
    p = Ref{Cint}(0)
    KNITRO.@_checked KNITRO.KN_get_var_type(model.inner, _c_column(x), p)
    return p[] == KNITRO.KN_VARTYPE_BINARY
end

# MOI.VariablePrimalStart

MOI.supports(::Optimizer, ::MOI.VariablePrimalStart, ::Type{MOI.VariableIndex}) = true

function MOI.set(
    model::Optimizer,
    ::MOI.VariablePrimalStart,
    x::MOI.VariableIndex,
    value::Union{Real,Nothing},
)
    MOI.throw_if_not_valid(model, x)
    start = something(value, 0.0)
    KNITRO.@_checked KNITRO.KN_set_var_primal_init_value(
        model.inner,
        _c_column(x),
        Cdouble(start),
    )
    return
end

# MOI.VariableName

MOI.supports(::Optimizer, ::MOI.VariableName, ::Type{MOI.VariableIndex}) = true

function MOI.set(model::Optimizer, ::MOI.VariableName, x::MOI.VariableIndex, name::String)
    model.variable_info[x.value].name = name
    return
end

function MOI.get(model::Optimizer, ::MOI.VariableName, x::MOI.VariableIndex)
    return model.variable_info[x.value].name
end

# Constraints

function MOI.supports_constraint(
    ::Optimizer,
    ::Type{MOI.VariableIndex},
    ::Type{<:Union{_SETS,MOI.ZeroOne,MOI.Integer}},
)
    return true
end

function MOI.supports_constraint(
    ::Optimizer,
    ::Type{<:Union{MOI.ScalarAffineFunction{Float64},MOI.ScalarQuadraticFunction{Float64}}},
    ::Type{<:_SETS},
)
    return true
end

# MOI.NumberOfConstraints

_get_F_S(::MOI.ConstraintIndex{F,S}) where {F,S} = (F, S)

function MOI.get(model::Optimizer, ::MOI.ListOfConstraintTypesPresent)
    ret = Tuple{Type,Type}[]
    for k in keys(model.constraint_mapping)
        F, S = _get_F_S(k)
        if !((F, S) in ret)
            push!(ret, (F, S))
        end
    end
    return ret
end

function MOI.get(model::Optimizer, ::MOI.ListOfConstraintIndices{F,S}) where {F,S}
    ret = MOI.ConstraintIndex{F,S}[]
    for k in keys(model.constraint_mapping)
        if k isa MOI.ConstraintIndex{F,S}
            push!(ret, k)
        end
    end
    sort!(ret; by=x -> x.value)
    return ret
end

function MOI.get(model::Optimizer, ::MOI.NumberOfConstraints{F,S}) where {F,S}
    f = Base.Fix2(isa, MOI.ConstraintIndex{F,S})
    return count(f, keys(model.constraint_mapping); init=0)
end

function MOI.is_valid(model::Optimizer, ci::MOI.ConstraintIndex)
    return haskey(model.constraint_mapping, ci)
end

###
### MOI.VariableIndex -in- LessThan
###

function MOI.is_valid(
    model::Optimizer,
    ci::MOI.ConstraintIndex{MOI.VariableIndex,MOI.LessThan{Float64}},
)
    info = get(model.variable_info, ci.value, nothing)
    if info === nothing
        return false
    end
    return info.has_upper_bound
end

function MOI.add_constraint(
    model::Optimizer,
    x::MOI.VariableIndex,
    set::MOI.LessThan{Float64},
)
    _throw_if_solved(model, x, set)
    MOI.throw_if_not_valid(model, x)
    if !_is_binary(model, x)
        if _has_upper_bound(model, x)
            error("Upper bound on variable $x already exists.")
        end
        if _is_fixed(model, x)
            error("Variable $x is fixed. Cannot also set upper bound.")
        end
        ub = _clamp_inf(set.upper)
        model.variable_info[x.value].has_upper_bound = true
        KNITRO.@_checked KNITRO.KN_set_var_upbnd(model.inner, _c_column(x), ub)
        ci = MOI.ConstraintIndex{MOI.VariableIndex,MOI.LessThan{Float64}}(x.value)
        model.constraint_mapping[ci] = convert(Cint, x.value)
    else
        ub = _clamp_inf(set.upper)
        p = Ref{Cint}(0)
        KNITRO.@_checked KNITRO.KN_add_con(model.inner, p)
        num_cons = p[]
        KNITRO.@_checked KNITRO.KN_add_con_linear_struct_one(
            model.inner,
            1,
            num_cons,
            [_c_column(x)],
            [1.0],
        )
        KNITRO.@_checked KNITRO.KN_set_con_upbnd(model.inner, num_cons, ub)
        ci = MOI.ConstraintIndex{MOI.VariableIndex,MOI.LessThan{Float64}}(num_cons)
        model.constraint_mapping[ci] = num_cons
    end
    return ci
end

###
### MOI.VariableIndex -in- GreaterThan
###

function MOI.is_valid(
    model::Optimizer,
    ci::MOI.ConstraintIndex{MOI.VariableIndex,MOI.GreaterThan{Float64}},
)
    info = get(model.variable_info, ci.value, nothing)
    if info === nothing
        return false
    end
    return info.has_lower_bound
end

function MOI.add_constraint(
    model::Optimizer,
    x::MOI.VariableIndex,
    set::MOI.GreaterThan{Float64},
)
    _throw_if_solved(model, x, set)
    MOI.throw_if_not_valid(model, x)
    if !_is_binary(model, x)
        if _has_lower_bound(model, x)
            error("Lower bound on variable $x already exists.")
        end
        if _is_fixed(model, x)
            error("Variable $x is fixed. Cannot also set lower bound.")
        end
        lb = _clamp_inf(set.lower)
        model.variable_info[x.value].has_lower_bound = true
        KNITRO.@_checked KNITRO.KN_set_var_lobnd(model.inner, _c_column(x), lb)
        ci = MOI.ConstraintIndex{MOI.VariableIndex,MOI.GreaterThan{Float64}}(x.value)
        model.constraint_mapping[ci] = convert(Cint, x.value)
    else
        lb = _clamp_inf(set.lower)
        p = Ref{Cint}(0)
        KNITRO.@_checked KNITRO.KN_add_con(model.inner, p)
        num_cons = p[]
        KNITRO.@_checked KNITRO.KN_add_con_linear_struct_one(
            model.inner,
            1,
            num_cons,
            [_c_column(x)],
            [1.0],
        )
        KNITRO.@_checked KNITRO.KN_set_con_lobnd(model.inner, num_cons, lb)
        ci = MOI.ConstraintIndex{MOI.VariableIndex,MOI.GreaterThan{Float64}}(num_cons)
        model.constraint_mapping[ci] = num_cons
    end
    return ci
end

###
### MOI.VariableIndex -in- Interval
###

function MOI.is_valid(
    model::Optimizer,
    ci::MOI.ConstraintIndex{MOI.VariableIndex,MOI.Interval{Float64}},
)
    info = get(model.variable_info, ci.value, nothing)
    if info === nothing
        return false
    end
    return info.has_lower_bound && info.has_upper_bound
end

function MOI.add_constraint(
    model::Optimizer,
    x::MOI.VariableIndex,
    set::MOI.Interval{Float64},
)
    _throw_if_solved(model, x, set)
    MOI.throw_if_not_valid(model, x)
    if !_is_binary(model, x)
        if _has_lower_bound(model, x) || _has_upper_bound(model, x)
            error("Bounds on variable $x already exists.")
        end
        if _is_fixed(model, x)
            error("Variable $x is fixed. Cannot also set lower bound.")
        end
        lb = _clamp_inf(set.lower)
        ub = _clamp_inf(set.upper)
        model.variable_info[x.value].has_lower_bound = true
        model.variable_info[x.value].has_upper_bound = true
        KNITRO.@_checked KNITRO.KN_set_var_lobnd(model.inner, _c_column(x), lb)
        KNITRO.@_checked KNITRO.KN_set_var_upbnd(model.inner, _c_column(x), ub)
        ci = MOI.ConstraintIndex{MOI.VariableIndex,MOI.Interval{Float64}}(x.value)
        model.constraint_mapping[ci] = convert(Cint, x.value)
    else
        lb = _clamp_inf(set.lower)
        ub = _clamp_inf(set.upper)
        p = Ref{Cint}(0)
        KNITRO.@_checked KNITRO.KN_add_con(model.inner, p)
        num_cons = p[]
        KNITRO.@_checked KNITRO.KN_add_con_linear_struct_one(
            model.inner,
            1,
            num_cons,
            [_c_column(x)],
            [1.0],
        )
        KNITRO.@_checked KNITRO.KN_set_con_lobnd(model.inner, num_cons, lb)
        KNITRO.@_checked KNITRO.KN_set_con_upbnd(model.inner, num_cons, ub)
        ci = MOI.ConstraintIndex{MOI.VariableIndex,MOI.Interval{Float64}}(num_cons)
        model.constraint_mapping[ci] = num_cons
    end
    return ci
end

###
### MOI.VariableIndex -in- EqualTo
###

function MOI.is_valid(
    model::Optimizer,
    ci::MOI.ConstraintIndex{MOI.VariableIndex,MOI.EqualTo{Float64}},
)
    info = get(model.variable_info, ci.value, nothing)
    if info === nothing
        return false
    end
    return info.is_fixed
end

function MOI.add_constraint(
    model::Optimizer,
    x::MOI.VariableIndex,
    set::MOI.EqualTo{Float64},
)
    _throw_if_solved(model, x, set)
    MOI.throw_if_not_valid(model, x)
    if _has_lower_bound(model, x)
        error("Variable $x has a lower bound. Cannot be fixed.")
    end
    if _has_upper_bound(model, x)
        error("Variable $x has an upper bound. Cannot be fixed.")
    end
    if _is_fixed(model, x)
        error("Variable $x is already fixed.")
    end
    eqv = _clamp_inf(set.value)
    model.variable_info[x.value].is_fixed = true
    KNITRO.@_checked KNITRO.KN_set_var_fxbnd(model.inner, _c_column(x), eqv)
    ci = MOI.ConstraintIndex{MOI.VariableIndex,MOI.EqualTo{Float64}}(x.value)
    model.constraint_mapping[ci] = convert(Cint, x.value)
    return ci
end

###
### ConstraintDualStart :: VariableIndex -in- {LessThan,GreaterThan,EqualTo,Interval}
###

function MOI.supports(
    ::Optimizer,
    ::MOI.ConstraintDualStart,
    ::Type{MOI.ConstraintIndex{MOI.VariableIndex,S}},
) where {S<:Union{MOI.EqualTo{Float64},MOI.GreaterThan{Float64},MOI.LessThan{Float64}}}
    return true
end

function MOI.set(
    model::Optimizer,
    ::MOI.ConstraintDualStart,
    ci::MOI.ConstraintIndex{
        MOI.VariableIndex,
        <:Union{MOI.EqualTo{Float64},MOI.GreaterThan{Float64},MOI.LessThan{Float64}},
    },
    value::Union{Real,Nothing},
)
    start = convert(Cdouble, something(value, 0.0))
    indexVars = [_c_column(MOI.VariableIndex(ci.value))]
    KNITRO.@_checked KNITRO.KN_set_var_dual_init_values(model.inner, 1, indexVars, [start])
    return
end

###
### MOI.VariableIndex -in- ZeroOne
###

function MOI.add_constraint(model::Optimizer, x::MOI.VariableIndex, ::MOI.ZeroOne)
    MOI.throw_if_not_valid(model, x)
    lb, ub = nothing, nothing
    p = Ref{Cdouble}(NaN)
    if model.variable_info[x.value].has_lower_bound
        KNITRO.@_checked KNITRO.KN_get_var_lobnd(model.inner, _c_column(x), p)
        lb = max(0.0, p[])
    end
    if model.variable_info[x.value].has_upper_bound
        KNITRO.@_checked KNITRO.KN_get_var_upbnd(model.inner, _c_column(x), p)
        ub = min(1.0, p[])
    end
    KNITRO.@_checked KNITRO.KN_set_var_type(
        model.inner,
        _c_column(x),
        KNITRO.KN_VARTYPE_BINARY,
    )
    if lb !== nothing || ub !== nothing
        q = Ref{Cint}(0)
        KNITRO.@_checked KNITRO.KN_add_con(model.inner, q)
        num_cons = q[]
        KNITRO.@_checked KNITRO.KN_add_con_linear_struct_one(
            model.inner,
            1,
            num_cons,
            [_c_column(x)],
            [1.0],
        )
        if lb !== nothing
            KNITRO.@_checked KNITRO.KN_set_con_lobnd(model.inner, num_cons, lb)
        end
        if ub !== nothing
            KNITRO.@_checked KNITRO.KN_set_con_upbnd(model.inner, num_cons, ub)
        end
    end
    ci = MOI.ConstraintIndex{MOI.VariableIndex,MOI.ZeroOne}(x.value)
    model.constraint_mapping[ci] = convert(Cint, x.value)
    return ci
end

###
### MOI.VariableIndex -in- Integer
###

function MOI.add_constraint(model::Optimizer, x::MOI.VariableIndex, set::MOI.Integer)
    _throw_if_solved(model, x, set)
    MOI.throw_if_not_valid(model, x)
    KNITRO.@_checked KNITRO.KN_set_var_type(
        model.inner,
        _c_column(x),
        KNITRO.KN_VARTYPE_INTEGER,
    )
    ci = MOI.ConstraintIndex{MOI.VariableIndex,MOI.Integer}(x.value)
    model.constraint_mapping[ci] = convert(Cint, x.value)
    return ci
end

###
### MOI.ScalarAffineFunction -in- {LessThan,GreaterThan,EqualTo,Interval}
###

function MOI.add_constraint(
    model::Optimizer,
    func::MOI.ScalarAffineFunction{Float64},
    set::Union{
        MOI.EqualTo{Float64},
        MOI.GreaterThan{Float64},
        MOI.LessThan{Float64},
        MOI.Interval{Float64},
    },
)
    _throw_if_solved(model, func, set)
    _throw_if_not_valid(model, func)
    # Add a single constraint in KNITRO.
    p = Ref{Cint}(0)
    KNITRO.@_checked KNITRO.KN_add_con(model.inner, p)
    num_cons = p[]
    # Add bound to constraint.
    if isa(set, MOI.LessThan{Float64})
        val = _clamp_inf(set.upper)
        KNITRO.@_checked KNITRO.KN_set_con_upbnd(model.inner, num_cons, val - func.constant)
    elseif isa(set, MOI.GreaterThan{Float64})
        val = _clamp_inf(set.lower)
        KNITRO.@_checked KNITRO.KN_set_con_lobnd(model.inner, num_cons, val - func.constant)
    elseif isa(set, MOI.EqualTo{Float64})
        val = _clamp_inf(set.value)
        KNITRO.@_checked KNITRO.KN_set_con_eqbnd(model.inner, num_cons, val - func.constant)
    else
        @assert set isa MOI.Interval{Float64}
        # Add upper bound.
        lb, ub = _clamp_inf(set.lower), _clamp_inf(set.upper)
        KNITRO.@_checked KNITRO.KN_set_con_lobnd(model.inner, num_cons, lb - func.constant)
        KNITRO.@_checked KNITRO.KN_set_con_upbnd(model.inner, num_cons, ub - func.constant)
    end
    nnz, columns, coefficients = _canonical_linear_reduction(func)
    KNITRO.@_checked(
        KNITRO.KN_add_con_linear_struct_one(
            model.inner,
            nnz,
            num_cons,
            columns,
            coefficients,
        ),
    )
    ci = MOI.ConstraintIndex{typeof(func),typeof(set)}(num_cons)
    model.constraint_mapping[ci] = num_cons
    return ci
end

function MOI.supports(
    ::Optimizer,
    ::MOI.ConstraintDualStart,
    ::Type{MOI.ConstraintIndex{MOI.ScalarAffineFunction{Float64},S}},
) where {
    S<:Union{
        MOI.EqualTo{Float64},
        MOI.GreaterThan{Float64},
        MOI.LessThan{Float64},
        MOI.Interval{Float64},
    },
}
    return true
end

function MOI.set(
    model::Optimizer,
    ::MOI.ConstraintDualStart,
    ci::MOI.ConstraintIndex{
        MOI.ScalarAffineFunction{Float64},
        <:Union{
            MOI.EqualTo{Float64},
            MOI.GreaterThan{Float64},
            MOI.LessThan{Float64},
            MOI.Interval{Float64},
        },
    },
    value::Union{Real,Nothing},
)
    start = convert(Cdouble, something(value, 0.0))
    indexCons = KNITRO.KNINT[ci.value]
    KNITRO.@_checked KNITRO.KN_set_con_dual_init_values(model.inner, 1, indexCons, [start])
    return
end

###
### MOI.ScalarQuadraticFunction -in- {LessThan,GreaterThan,EqualTo,Interval}
###

function MOI.add_constraint(
    model::Optimizer,
    func::MOI.ScalarQuadraticFunction{Float64},
    set::Union{
        MOI.EqualTo{Float64},
        MOI.GreaterThan{Float64},
        MOI.LessThan{Float64},
        MOI.Interval{Float64},
    },
)
    _throw_if_solved(model, func, set)
    _throw_if_not_valid(model, func)
    # We add a constraint in KNITRO.
    p = Ref{Cint}(0)
    KNITRO.@_checked KNITRO.KN_add_con(model.inner, p)
    num_cons = p[]
    # Add upper bound.
    if isa(set, MOI.LessThan{Float64})
        val = _clamp_inf(set.upper)
        KNITRO.@_checked KNITRO.KN_set_con_upbnd(model.inner, num_cons, val - func.constant)
    elseif isa(set, MOI.GreaterThan{Float64})
        val = _clamp_inf(set.lower)
        KNITRO.@_checked KNITRO.KN_set_con_lobnd(model.inner, num_cons, val - func.constant)
    elseif isa(set, MOI.EqualTo{Float64})
        val = _clamp_inf(set.value)
        KNITRO.@_checked KNITRO.KN_set_con_eqbnd(model.inner, num_cons, val - func.constant)
    elseif isa(set, MOI.Interval{Float64})
        lb = _clamp_inf(set.lower)
        ub = _clamp_inf(set.upper)
        KNITRO.@_checked KNITRO.KN_set_con_lobnd(model.inner, num_cons, lb - func.constant)
        KNITRO.@_checked KNITRO.KN_set_con_upbnd(model.inner, num_cons, ub - func.constant)
    end
    nnz, columns, coefficients = _canonical_linear_reduction(func)
    KNITRO.@_checked(
        KNITRO.KN_add_con_linear_struct_one(
            model.inner,
            nnz,
            num_cons,
            columns,
            coefficients,
        ),
    )
    nnz, I, J, V = _canonical_quadratic_reduction(func)
    KNITRO.@_checked KNITRO.KN_add_con_quadratic_struct_one(
        model.inner,
        nnz,
        num_cons,
        I,
        J,
        V,
    )
    ci = MOI.ConstraintIndex{typeof(func),typeof(set)}(num_cons)
    model.constraint_mapping[ci] = num_cons
    return ci
end

function MOI.supports(
    ::Optimizer,
    ::MOI.ConstraintDualStart,
    ::Type{MOI.ConstraintIndex{MOI.ScalarQuadraticFunction{Float64},S}},
) where {
    S<:Union{
        MOI.EqualTo{Float64},
        MOI.GreaterThan{Float64},
        MOI.LessThan{Float64},
        MOI.Interval{Float64},
    },
}
    return true
end

function MOI.set(
    model::Optimizer,
    ::MOI.ConstraintDualStart,
    ci::MOI.ConstraintIndex{
        MOI.ScalarQuadraticFunction{Float64},
        <:Union{
            MOI.EqualTo{Float64},
            MOI.GreaterThan{Float64},
            MOI.LessThan{Float64},
            MOI.Interval{Float64},
        },
    },
    value::Union{Real,Nothing},
)
    start = convert(Cdouble, something(value, 0.0))
    indexCons = KNITRO.KNINT[ci.value]
    KNITRO.@_checked KNITRO.KN_set_con_dual_init_values(model.inner, 1, indexCons, [start])
    return
end

###
### MOI.VectorAffineFunction -in- SecondOrderCone
###

function MOI.supports_constraint(
    ::Optimizer,
    ::Type{MOI.VectorAffineFunction{Float64}},
    ::Type{MOI.SecondOrderCone},
)
    return true
end

function MOI.add_constraint(
    model::Optimizer,
    func::MOI.VectorAffineFunction,
    set::MOI.SecondOrderCone,
)
    _throw_if_solved(model, func, set)
    p = Ref{Cint}(0)
    KNITRO.@_checked KNITRO.KN_add_con(model.inner, p)
    index_con = p[]
    rows, columns, coefficients = _canonical_vector_affine_reduction(func)
    index_vars = zeros(Cint, set.dimension)
    KNITRO.@_checked KNITRO.KN_add_vars(model.inner, set.dimension, index_vars)
    index_cons = zeros(Cint, set.dimension)
    KNITRO.@_checked KNITRO.KN_add_cons(model.inner, set.dimension, index_cons)
    for i in 1:set.dimension
        KNITRO.@_checked KNITRO.KN_add_con_linear_struct_one(
            model.inner,
            1,
            index_cons[i],
            [index_vars[i]],
            [1.0],
        )
        row = rows .== (i - 1)
        KNITRO.@_checked KNITRO.KN_add_con_linear_struct_one(
            model.inner,
            sum(row),
            index_cons[i],
            columns[row],
            -coefficients[row],
        )
        KNITRO.@_checked KNITRO.KN_set_con_eqbnd(
            model.inner,
            index_cons[i],
            func.constants[i],
        )
    end
    q = Ref{Cint}(0)
    KNITRO.@_checked KNITRO.KN_add_con(model.inner, q)
    index_con_nonneg = q[]
    KNITRO.@_checked KNITRO.KN_set_con_upbnd(model.inner, index_con_nonneg, 0.0)
    KNITRO.@_checked KNITRO.KN_add_con_linear_struct_one(
        model.inner,
        1,
        index_con_nonneg,
        [index_vars[1]],
        [-1.0],
    )
    KNITRO.@_checked KNITRO.KN_set_con_upbnd(model.inner, index_con, 0.0)
    KNITRO.@_checked KNITRO.KN_add_con_quadratic_struct_one(
        model.inner,
        length(index_vars) - 1,
        index_con,
        index_vars[2:end],
        index_vars[2:end],
        ones(Float64, length(index_vars) - 1),
    )
    KNITRO.@_checked KNITRO.KN_add_con_quadratic_struct_one(
        model.inner,
        1,
        index_con,
        [index_vars[1]],
        [index_vars[1]],
        [-1.0],
    )
    # # Distinct two parts of secondordercone.
    # # First row corresponds to linear part of SOC.
    # linear_row_indices = rows .== 0
    # cone_indices = .!(linear_row_indices)
    # ## i) linear part
    # KNITRO.@_checked KNITRO.KN_set_con_upbnd(model.inner, index_con, func.constants[1])
    # KNITRO.@_checked KNITRO.KN_add_con_linear_struct_one(
    #     model.inner,
    #     sum(linear_row_indices),
    #     index_con,
    #     columns[linear_row_indices],
    #     -coefficients[linear_row_indices],
    # )
    # ## ii) soc part
    # index_var_cone = columns[cone_indices]
    # nnz = length(index_var_cone)
    # KNITRO.@_checked KNITRO.KN_add_con_L2norm(
    #     model.inner,
    #     index_con,
    #     set.dimension - 1,
    #     nnz,
    #     # The rows are 0-indexed. But we additionally need to drop the first
    #     # (linear) row from the matrix.
    #     rows[cone_indices] .- Cint(1),
    #     index_var_cone,
    #     coefficients[cone_indices],
    #     func.constants[2:end],
    # )
    ci = MOI.ConstraintIndex{typeof(func),typeof(set)}(index_con)
    model.constraint_mapping[ci] = columns
    return ci
end

###
### MOI.VectorOfVariables -in- SecondOrderCone
###

function MOI.supports_constraint(
    ::Optimizer,
    ::Type{MOI.VectorOfVariables},
    ::Type{MOI.SecondOrderCone},
)
    return true
end

function MOI.add_constraint(
    model::Optimizer,
    func::MOI.VectorOfVariables,
    set::MOI.SecondOrderCone,
)
    _throw_if_solved(model, func, set)
    # Add constraints inside KNITRO.
    p = Ref{Cint}(0)
    KNITRO.@_checked KNITRO.KN_add_con(model.inner, p)
    index_con = p[]
    indv = _c_column.(func.variables)
    q = Ref{Cint}(0)
    KNITRO.@_checked KNITRO.KN_add_con(model.inner, q)
    index_con_nonneg = q[]
    KNITRO.@_checked KNITRO.KN_set_con_upbnd(model.inner, index_con_nonneg, 0.0)
    KNITRO.@_checked KNITRO.KN_add_con_linear_struct_one(
        model.inner,
        1,
        index_con_nonneg,
        [indv[1]],
        [-1.0],
    )
    KNITRO.@_checked KNITRO.KN_set_con_upbnd(model.inner, index_con, 0.0)
    KNITRO.@_checked KNITRO.KN_add_con_quadratic_struct_one(
        model.inner,
        length(indv) - 1,
        index_con,
        indv[2:end],
        indv[2:end],
        ones(Float64, length(indv) - 1),
    )
    KNITRO.@_checked KNITRO.KN_add_con_quadratic_struct_one(
        model.inner,
        1,
        index_con,
        [indv[1]],
        [indv[1]],
        [-1.0],
    )
    # KNITRO.@_checked KNITRO.KN_add_con_linear_struct_one(
    #     model.inner,
    #     1,
    #     index_con,
    #     [indv[1]],
    #     [-1.0],
    # )
    # indexVars = indv[2:end]
    # nnz = length(indexVars)
    # indexCoords = Cint[i for i in 0:(nnz-1)]
    # coefs = ones(Float64, nnz)
    # constants = zeros(Float64, nnz)
    # KNITRO.@_checked KNITRO.KN_add_con_L2norm(
    #     model.inner,
    #     index_con,
    #     nnz,
    #     nnz,
    #     indexCoords,
    #     indexVars,
    #     coefs,
    #     constants,
    # )
    ci = MOI.ConstraintIndex{typeof(func),typeof(set)}(index_con)
    model.constraint_mapping[ci] = indv
    return ci
end

# MOI.ScalarNonlinearFunction

function MOI.supports_constraint(
    ::Optimizer,
    ::Type{MOI.ScalarNonlinearFunction},
    ::Type{<:_SETS},
)
    return true
end

function MOI.is_valid(
    model::Optimizer,
    ci::MOI.ConstraintIndex{MOI.ScalarNonlinearFunction,<:_SETS},
)
    index = MOI.Nonlinear.ConstraintIndex(ci.value)
    return MOI.is_valid(model.nlp_model, index)
end

function MOI.add_constraint(model::Optimizer, f::MOI.ScalarNonlinearFunction, s::_SETS)
    index = MOI.Nonlinear.add_constraint(model.nlp_model, f, s)
    ci = MOI.ConstraintIndex{typeof(f),typeof(s)}(index.value)
    model.constraint_mapping[ci] = convert(Cint, index.value)
    return ci
end

# MOI.VectorOfVariables-in-MOI.Complements

function MOI.supports_constraint(
    ::Optimizer,
    ::Type{MOI.VectorOfVariables},
    ::Type{MOI.Complements},
)
    return true
end

# Complementarity constraints (x_1 complements x_2), with x_1 and x_2
# being two variables of the problem.
function MOI.add_constraint(
    model::Optimizer,
    func::MOI.VectorOfVariables,
    set::MOI.Complements,
)
    _throw_if_solved(model, func, set)
    indv = _c_column.(func.variables)
    # Number of complementarity in Knitro is half the dimension of the MOI set
    n_comp = div(set.dimension, 2)
    # Currently, only complementarity constraints between two variables
    # are supported.
    comp_type = fill(KNITRO.KN_CCTYPE_VARVAR, n_comp)
    # Number of complementarity constraint previously added
    n_comp_cons = model.complementarity_cache.n
    _add_complementarity_constraint!(
        model.complementarity_cache,
        indv[1:n_comp],
        indv[(n_comp+1):end],
        comp_type,
    )
    ci = MOI.ConstraintIndex{typeof(func),typeof(set)}(n_comp_cons)
    model.constraint_mapping[ci] = convert(Cint, n_comp_cons)
    return ci
end

# MOI.NLPBlock

MOI.supports(::Optimizer, ::MOI.NLPBlock) = true

MOI.get(model::Optimizer, ::MOI.NLPBlock) = model.nlp_data

function MOI.set(model::Optimizer, attr::MOI.NLPBlock, nlp_data::MOI.NLPBlockData)
    _throw_if_solved(model, attr)
    model.nlp_data = nlp_data
    return
end

# MOI.NLPBlockDualStart

MOI.supports(::Optimizer, ::MOI.NLPBlockDualStart) = true

function MOI.set(model::Optimizer, ::MOI.NLPBlockDualStart, values)
    KNITRO.@_checked KNITRO.KN_set_con_dual_init_values(
        model.inner,
        length(model.nlp_index_cons),
        model.nlp_index_cons,
        values,
    )
    return
end

# MOI.ObjectiveSense

MOI.supports(::Optimizer, ::MOI.ObjectiveSense) = true

MOI.get(model::Optimizer, ::MOI.ObjectiveSense) = model.sense

function MOI.set(model::Optimizer, attr::MOI.ObjectiveSense, sense::MOI.OptimizationSense)
    _throw_if_solved(model, attr)
    model.sense = sense
    if model.sense == MOI.MAX_SENSE
        KNITRO.@_checked KNITRO.KN_set_obj_goal(model.inner, KNITRO.KN_OBJGOAL_MAXIMIZE)
    elseif model.sense == MOI.MIN_SENSE
        KNITRO.@_checked KNITRO.KN_set_obj_goal(model.inner, KNITRO.KN_OBJGOAL_MINIMIZE)
    end
    return
end

# MOI.ObjectiveFunction

function MOI.supports(
    ::Optimizer,
    ::MOI.ObjectiveFunction{
        <:Union{
            MOI.VariableIndex,
            MOI.ScalarAffineFunction{Float64},
            MOI.ScalarQuadraticFunction{Float64},
            MOI.ScalarNonlinearFunction,
        },
    },
)
    return true
end

function _add_objective(model::Optimizer, f::MOI.ScalarQuadraticFunction)
    nnz, I, J, V = _canonical_quadratic_reduction(f)
    KNITRO.@_checked KNITRO.KN_add_obj_quadratic_struct(model.inner, nnz, I, J, V)
    nnz, columns, coefficients = _canonical_linear_reduction(f)
    KNITRO.@_checked KNITRO.KN_add_obj_linear_struct(
        model.inner,
        nnz,
        columns,
        coefficients,
    )
    KNITRO.@_checked KNITRO.KN_add_obj_constant(model.inner, f.constant)
    model.objective = nothing
    return
end

function _add_objective(model::Optimizer, f::MOI.ScalarAffineFunction)
    nnz, columns, coefficients = _canonical_linear_reduction(f)
    KNITRO.@_checked KNITRO.KN_add_obj_linear_struct(
        model.inner,
        nnz,
        columns,
        coefficients,
    )
    KNITRO.@_checked KNITRO.KN_add_obj_constant(model.inner, f.constant)
    model.objective = nothing
    return
end

function _add_objective(model::Optimizer, f::MOI.VariableIndex)
    KNITRO.@_checked KNITRO.KN_add_obj_linear_struct(model.inner, 1, [_c_column(f)], [1.0])
    model.objective = nothing
    return
end

function MOI.set(
    model::Optimizer,
    attr::MOI.ObjectiveFunction{F},
    func::F,
) where {F<:Union{MOI.VariableIndex,MOI.ScalarAffineFunction,MOI.ScalarQuadraticFunction}}
    _throw_if_solved(model, attr)
    _throw_if_not_valid(model, func)
    model.objective = func
    return
end

function MOI.set(
    model::Optimizer,
    attr::MOI.ObjectiveFunction{MOI.ScalarNonlinearFunction},
    f::MOI.ScalarNonlinearFunction,
)
    _throw_if_solved(model, attr)
    MOI.Nonlinear.set_objective(model.nlp_model, f)
    model.objective = f
    return
end

function MOI.get(
    model::Optimizer,
    ::MOI.ObjectiveFunction{F},
) where {
    F<:Union{
        MOI.VariableIndex,
        MOI.ScalarAffineFunction,
        MOI.ScalarQuadraticFunction,
        MOI.ScalarNonlinearFunction,
    },
}
    return convert(F, model.objective)
end

# MOI.optimize!

function MOI.optimize!(model::Optimizer)
    KNITRO.@_checked KNITRO.KN_set_int_param_by_name(model.inner, "datacheck", 0)
    KNITRO.@_checked KNITRO.KN_set_int_param_by_name(model.inner, "hessian_no_f", 1)
    if _has_complementarity(model.complementarity_cache)
        KNITRO.@_checked KNITRO.KN_set_compcons(
            model.inner,
            length(model.complementarity_cache.cc_types),
            model.complementarity_cache.cc_types,
            model.complementarity_cache.index_comps_1,
            model.complementarity_cache.index_comps_2,
        )
    end
    if !MOI.is_empty(model.nlp_model) && !model.nlp_loaded
        vars = MOI.get(model, MOI.ListOfVariableIndices())
        backend = MOI.Nonlinear.SparseReverseMode()
        evaluator = MOI.Nonlinear.Evaluator(model.nlp_model, backend, vars)
        model.nlp_data = MOI.NLPBlockData(evaluator)
    end
    if model.nlp_data !== nothing && !model.nlp_loaded
        features = MOI.features_available(model.nlp_data.evaluator)::Vector{Symbol}
        has_hessian = (:Hess in features)
        has_hessvec = (:HessVec in features)
        has_nlp_objective = model.nlp_data.has_objective
        num_nlp_constraints = length(model.nlp_data.constraint_bounds)
        has_nlp_constraints = (num_nlp_constraints > 0)
        init_feat = Symbol[]
        has_nlp_objective && push!(init_feat, :Grad)
        # Knitro could not mix Hessian callback with Hessian-vector callback.
        if has_hessian
            push!(init_feat, :Hess)
        elseif has_hessvec
            push!(init_feat, :HessVec)
        end
        if has_nlp_constraints
            push!(init_feat, :Jac)
        end
        MOI.initialize(model.nlp_data.evaluator, init_feat)
        # Load NLP structure inside Knitro.
        p = Ref{Cint}(0)
        KNITRO.@_checked KNITRO.KN_get_number_cons(model.inner, p)
        offset = p[]
        num_nlp_constraints = length(model.nlp_data.constraint_bounds)
        if num_nlp_constraints > 0
            nlp_rows = model.nlp_index_cons = zeros(Cint, num_nlp_constraints)
            KNITRO.@_checked KNITRO.KN_add_cons(model.inner, num_nlp_constraints, nlp_rows)
            for (row, pair) in zip(nlp_rows, model.nlp_data.constraint_bounds)
                KNITRO.@_checked KNITRO.KN_set_con_upbnd(
                    model.inner,
                    row,
                    _clamp_inf(pair.upper),
                )
                KNITRO.@_checked KNITRO.KN_set_con_lobnd(
                    model.inner,
                    row,
                    _clamp_inf(pair.lower),
                )
            end
        end
        KNITRO.@_checked KNITRO.KN_get_number_cons(model.inner, p)
        num_cons = p[]
        # 1/ Definition of the callbacks
        # Objective callback (used both for objective and constraint evaluation).
        function eval_f_cb(kc, cb, evalRequest, evalResult, userParams)
            # Evaluate objective if specified in nlp_data.
            if has_nlp_objective
                evalResult.obj[1] =
                    MOI.eval_objective(model.nlp_data.evaluator, evalRequest.x)
            end
            # Evaluate nonlinear term in constraint.
            if has_nlp_constraints
                MOI.eval_constraint(model.nlp_data.evaluator, evalResult.c, evalRequest.x)
            end
            return 0
        end
        # Gradient and Jacobian callback.
        function eval_grad_cb(kc, cb, evalRequest, evalResult, userParams)
            # Evaluate non-linear term in objective gradient.
            if has_nlp_objective
                MOI.eval_objective_gradient(
                    model.nlp_data.evaluator,
                    evalResult.objGrad,
                    evalRequest.x,
                )
            end
            # Evaluate non linear part of jacobian.
            if has_nlp_constraints
                MOI.eval_constraint_jacobian(
                    model.nlp_data.evaluator,
                    evalResult.jac,
                    evalRequest.x,
                )
            end
            return 0
        end
        # 2/ Passing the callbacks to Knitro
        # 2.1/ Objective & constraints
        # Objective defined in NLP structure has precedence over model.objective.
        # If we have a NLP structure, we have three possible choices
        #   1. We have both a NLP objective and NLP constraints
        #   2. We have NLP constraints, with a linear or quadratic objective
        #   3. We have a NLP objective, without NLP constraints
        if has_nlp_constraints
            # Add only a callback for objective if no NLP constraint
            cb = KNITRO.KN_add_eval_callback(
                model.inner,
                has_nlp_objective,
                model.nlp_index_cons,
                eval_f_cb,
            )
        elseif has_nlp_objective
            cb = KNITRO.KN_add_objective_callback(model.inner, eval_f_cb)
        end
        # If a objective is specified in model.objective, load it.
        if !has_nlp_objective && !isnothing(model.objective)
            _add_objective(model, model.objective)
        end
        # 2.2/ Gradient & Jacobian
        nV = has_nlp_objective ? KNITRO.KN_DENSE : Cint(0)
        if !has_nlp_constraints
            KNITRO.@_checked KNITRO.KN_set_cb_grad(model.inner, cb, eval_grad_cb; nV=nV)
        else
            # Get jacobian structure.
            jacob_structure =
                MOI.jacobian_structure(model.nlp_data.evaluator)::Vector{Tuple{Int,Int}}
            # Take care to convert 1-indexing to 0-indexing!
            # KNITRO supports only Cint array for integer.
            jacIndexVars = Cint[j - 1 for (_, j) in jacob_structure]
            # NLP constraints are set after all other constraints
            # inside Knitro.
            jacIndexCons = Cint[i - 1 + offset for (i, _) in jacob_structure]
            KNITRO.@_checked KNITRO.KN_set_cb_grad(
                model.inner,
                cb,
                eval_grad_cb;
                nV=nV,
                jacIndexCons=jacIndexCons,
                jacIndexVars=jacIndexVars,
            )
        end
        # 2.3/ Hessian
        # By default, Hessian callback takes precedence over Hessvec callback.
        if has_hessian
            # Hessian callback.
            function eval_h_cb(kc, cb, evalRequest, evalResult, userParams)
                MOI.eval_hessian_lagrangian(
                    model.nlp_data.evaluator,
                    evalResult.hess,
                    evalRequest.x,
                    evalRequest.sigma,
                    view(evalRequest.lambda, (offset+1):num_cons),
                )
                return 0
            end
            # Get hessian structure.
            hessian_structure = MOI.hessian_lagrangian_structure(
                model.nlp_data.evaluator,
            )::Vector{Tuple{Int,Int}}
            nnzH = length(hessian_structure)
            # Take care to convert 1-indexing to 0-indexing!
            # Knitro supports only Cint array for integer.
            hessIndexVars1 = Cint[i - 1 for (i, _) in hessian_structure]
            hessIndexVars2 = Cint[j - 1 for (_, j) in hessian_structure]
            KNITRO.@_checked KNITRO.KN_set_cb_hess(
                model.inner,
                cb,
                nnzH,
                eval_h_cb,
                hessIndexVars1=hessIndexVars1,
                hessIndexVars2=hessIndexVars2,
            )
        elseif has_hessvec
            function eval_hv_cb(kc, cb, evalRequest, evalResult, userParams)
                MOI.eval_hessian_lagrangian_product(
                    model.nlp_data.evaluator,
                    evalResult.hessVec,
                    evalRequest.x,
                    evalRequest.vec,
                    evalRequest.sigma,
                    view(evalRequest.lambda, (offset+1):num_cons),
                )
                return 0
            end
            # Set callback
            # (no need to specify sparsity pattern for Hessian-vector product).
            KNITRO.@_checked KNITRO.KN_set_cb_hess(model.inner, cb, 0, eval_hv_cb)
            # Specify to Knitro that we are using Hessian-vector product.
            KNITRO.@_checked KNITRO.KN_set_int_param(
                model.inner,
                KNITRO.KN_PARAM_HESSOPT,
                KNITRO.KN_HESSOPT_PRODUCT,
            )
        end
        model.nlp_loaded = true
    elseif !isa(model.objective, Nothing) &&
           !isa(model.objective, MOI.ScalarNonlinearFunction)
        _add_objective(model, model.objective)
    end
    KNITRO.KN_solve(model.inner)
    model.number_solved += 1
    return
end

function MOI.get(model::Optimizer, ::MOI.RawStatusString)
    statusP, obj = Ref{Cint}(0), Ref{Cdouble}(0.0)
    KNITRO.@_checked KNITRO.KN_get_solution(model.inner, statusP, obj, C_NULL, C_NULL)
    return string(statusP[])
end

# Refer to KNITRO manual for solver status:
# https://www.artelys.com/tools/knitro_doc/3_referenceManual/returnCodes.html#returncodes
const _KN_TO_MOI_RETURN_STATUS = Dict{Int,MOI.TerminationStatusCode}(
    KNITRO.KN_RC_OPTIMAL_OR_SATISFACTORY => MOI.LOCALLY_SOLVED,
    KNITRO.KN_RC_NEAR_OPT => MOI.ALMOST_OPTIMAL,
    # slow progress
    KNITRO.KN_RC_FEAS_XTOL => MOI.SLOW_PROGRESS,
    KNITRO.KN_RC_FEAS_NO_IMPROVE => MOI.SLOW_PROGRESS,
    KNITRO.KN_RC_FEAS_FTOL => MOI.SLOW_PROGRESS,
    # infeasible
    KNITRO.KN_RC_INFEASIBLE => MOI.LOCALLY_INFEASIBLE,
    KNITRO.KN_RC_INFEAS_XTOL => MOI.LOCALLY_INFEASIBLE,
    KNITRO.KN_RC_INFEAS_NO_IMPROVE => MOI.LOCALLY_INFEASIBLE,
    KNITRO.KN_RC_INFEAS_MULTISTART => MOI.LOCALLY_INFEASIBLE,
    KNITRO.KN_RC_INFEAS_CON_BOUNDS => MOI.LOCALLY_INFEASIBLE,
    KNITRO.KN_RC_INFEAS_VAR_BOUNDS => MOI.LOCALLY_INFEASIBLE,
    # unbounded
    KNITRO.KN_RC_UNBOUNDED => MOI.DUAL_INFEASIBLE,
    KNITRO.KN_RC_UNBOUNDED_OR_INFEAS => MOI.DUAL_INFEASIBLE,
    # feasible limits
    KNITRO.KN_RC_ITER_LIMIT_FEAS => MOI.ITERATION_LIMIT,
    KNITRO.KN_RC_TIME_LIMIT_FEAS => MOI.TIME_LIMIT,
    KNITRO.KN_RC_FEVAL_LIMIT_FEAS => MOI.OTHER_LIMIT,
    KNITRO.KN_RC_MIP_EXH_FEAS => MOI.LOCALLY_SOLVED,
    KNITRO.KN_RC_MIP_TERM_FEAS => MOI.SOLUTION_LIMIT,
    KNITRO.KN_RC_MIP_SOLVE_LIMIT_FEAS => MOI.OTHER_LIMIT,
    KNITRO.KN_RC_MIP_NODE_LIMIT_FEAS => MOI.NODE_LIMIT,
    # infeasible limits
    KNITRO.KN_RC_ITER_LIMIT_INFEAS => MOI.ITERATION_LIMIT,
    KNITRO.KN_RC_TIME_LIMIT_INFEAS => MOI.TIME_LIMIT,
    KNITRO.KN_RC_FEVAL_LIMIT_INFEAS => MOI.OTHER_LIMIT,
    KNITRO.KN_RC_MIP_EXH_INFEAS => MOI.OTHER_LIMIT,
    KNITRO.KN_RC_MIP_SOLVE_LIMIT_INFEAS => MOI.OTHER_LIMIT,
    KNITRO.KN_RC_MIP_NODE_LIMIT_INFEAS => MOI.OTHER_LIMIT,
    # errors
    KNITRO.KN_RC_CALLBACK_ERR => MOI.INVALID_MODEL,
    KNITRO.KN_RC_LP_SOLVER_ERR => MOI.NUMERICAL_ERROR,
    KNITRO.KN_RC_EVAL_ERR => MOI.INVALID_MODEL,
    KNITRO.KN_RC_OUT_OF_MEMORY => MOI.MEMORY_LIMIT,
    KNITRO.KN_RC_USER_TERMINATION => MOI.INTERRUPTED,
)

function MOI.get(model::Optimizer, ::MOI.TerminationStatus)
    if model.number_solved == 0
        return MOI.OPTIMIZE_NOT_CALLED
    end
    statusP, obj = Ref{Cint}(0), Ref{Cdouble}(0.0)
    KNITRO.@_checked KNITRO.KN_get_solution(model.inner, statusP, obj, C_NULL, C_NULL)
    return get(_KN_TO_MOI_RETURN_STATUS, statusP[], MOI.OTHER_ERROR)
end

function MOI.get(model::Optimizer, ::MOI.ResultCount)
    return model.number_solved >= 1 ? 1 : 0
end

function _status_to_primal_status_code(status)
    if status == 0
        return MOI.FEASIBLE_POINT
    elseif -199 <= status <= -100
        return MOI.FEASIBLE_POINT
    elseif -299 <= status <= -200
        return MOI.INFEASIBLE_POINT
    elseif -399 <= status <= -300
        return MOI.UNKNOWN_RESULT_STATUS
    elseif -409 <= status <= -400
        return MOI.FEASIBLE_POINT
    elseif -499 <= status <= -410
        return MOI.UNKNOWN_RESULT_STATUS
    end
    @assert -599 <= status <= -500
    return MOI.UNKNOWN_RESULT_STATUS
end

function MOI.get(model::Optimizer, attr::MOI.PrimalStatus)
    if model.number_solved == 0 || attr.result_index != 1
        return MOI.NO_SOLUTION
    end
    statusP, obj = Ref{Cint}(0), Ref{Cdouble}(0.0)
    KNITRO.@_checked KNITRO.KN_get_solution(model.inner, statusP, obj, C_NULL, C_NULL)
    return _status_to_primal_status_code(statusP[])
end

function _status_to_dual_status_code(status)
    if status == 0
        return MOI.FEASIBLE_POINT
    elseif -199 <= status <= -100
        return MOI.FEASIBLE_POINT
    elseif -299 <= status <= -200
        return MOI.UNKNOWN_RESULT_STATUS
    elseif -399 <= status <= -300
        return MOI.UNKNOWN_RESULT_STATUS
    elseif -499 <= status <= -400
        return MOI.UNKNOWN_RESULT_STATUS
    end
    @assert -599 <= status <= -500
    return MOI.UNKNOWN_RESULT_STATUS
end

function MOI.get(model::Optimizer, attr::MOI.DualStatus)
    if model.number_solved == 0 || attr.result_index != 1
        return MOI.NO_SOLUTION
    end
    statusP, obj = Ref{Cint}(0), Ref{Cdouble}(0.0)
    KNITRO.@_checked KNITRO.KN_get_solution(model.inner, statusP, obj, C_NULL, C_NULL)
    return _status_to_dual_status_code(statusP[])
end

function MOI.get(model::Optimizer, attr::MOI.ObjectiveValue)
    MOI.check_result_index_bounds(model, attr)
    status, obj = Ref{Cint}(0), Ref{Cdouble}(0.0)
    KNITRO.@_checked KNITRO.KN_get_solution(model.inner, status, obj, C_NULL, C_NULL)
    return obj[]
end

function _get_solution(model::Optimizer, index::Integer)
    if isempty(model.x)
        p = Ref{Cint}(0)
        KNITRO.@_checked KNITRO.KN_get_number_vars(model.inner, p)
        model.x = zeros(Cdouble, p[])
        status, obj = Ref{Cint}(0), Ref{Cdouble}(0.0)
        KNITRO.@_checked KNITRO.KN_get_solution(model.inner, status, obj, model.x, C_NULL)
    end
    return model.x[index]
end

function _get_dual(model::Optimizer, index::Integer)
    if isempty(model.lambda)
        nx, nc = Ref{Cint}(0), Ref{Cint}(0)
        KNITRO.@_checked KNITRO.KN_get_number_vars(model.inner, nx)
        KNITRO.@_checked KNITRO.KN_get_number_cons(model.inner, nc)
        model.lambda = zeros(Cdouble, nx[] + nc[])
        status, obj = Ref{Cint}(0), Ref{Cdouble}(0.0)
        KNITRO.@_checked KNITRO.KN_get_solution(
            model.inner,
            status,
            obj,
            C_NULL,
            model.lambda,
        )
    end
    return model.lambda[index]
end

function MOI.get(model::Optimizer, attr::MOI.VariablePrimal, x::MOI.VariableIndex)
    MOI.check_result_index_bounds(model, attr)
    MOI.throw_if_not_valid(model, x)
    return _get_solution(model, x.value)
end

function MOI.get(
    model::Optimizer,
    attr::MOI.ConstraintPrimal,
    ci::MOI.ConstraintIndex{S,T},
) where {
    S<:Union{MOI.ScalarAffineFunction{Float64},MOI.ScalarQuadraticFunction{Float64}},
    T<:Union{
        MOI.EqualTo{Float64},
        MOI.GreaterThan{Float64},
        MOI.LessThan{Float64},
        MOI.Interval{Float64},
    },
}
    MOI.check_result_index_bounds(model, attr)
    MOI.throw_if_not_valid(model, ci)
    indexCon = model.constraint_mapping[ci]
    p = Ref{Cdouble}(NaN)
    KNITRO.@_checked KNITRO.KN_get_con_value(model.inner, indexCon, p)
    return p[]
end

# function MOI.get(
#     model::Optimizer,
#     cp::MOI.ConstraintPrimal,
#     ci::MOI.ConstraintIndex{S,MOI.SecondOrderCone},
# ) where {S<:Union{MOI.VectorAffineFunction{Float64},MOI.VectorOfVariables}}
#     return # Not supported
# end

function MOI.get(
    model::Optimizer,
    attr::MOI.ConstraintPrimal,
    ci::MOI.ConstraintIndex{
        MOI.VariableIndex,
        <:Union{MOI.EqualTo{Float64},MOI.GreaterThan{Float64},MOI.LessThan{Float64}},
    },
)
    MOI.check_result_index_bounds(model, attr)
    x = MOI.VariableIndex(ci.value)
    MOI.throw_if_not_valid(model, x)
    return _get_solution(model, x.value)
end

# KNITRO's dual sign depends on optimization sense.
_sense_dual(model::Optimizer) = model.sense == MOI.MAX_SENSE ? 1.0 : -1.0

function MOI.get(
    model::Optimizer,
    attr::MOI.ConstraintDual,
    ci::MOI.ConstraintIndex{S,T},
) where {
    S<:Union{MOI.ScalarAffineFunction{Float64},MOI.ScalarQuadraticFunction{Float64}},
    T<:Union{
        MOI.EqualTo{Float64},
        MOI.GreaterThan{Float64},
        MOI.LessThan{Float64},
        MOI.Interval{Float64},
    },
}
    MOI.check_result_index_bounds(model, attr)
    MOI.throw_if_not_valid(model, ci)
    index = model.constraint_mapping[ci] + 1
    return _sense_dual(model) * _get_dual(model, index)
end

function MOI.get(
    model::Optimizer,
    ::MOI.ConstraintDual,
    ci::MOI.ConstraintIndex{MOI.ScalarNonlinearFunction},
)
    return _sense_dual(model) * _get_dual(model, ci.value)
end

# function MOI.get(
#     model::Optimizer,
#     cd::MOI.ConstraintDual,
#     ci::MOI.ConstraintIndex{S,MOI.SecondOrderCone},
# ) where {S<:Union{MOI.VectorAffineFunction{Float64},MOI.VectorOfVariables}}
#     return  # Not supported.
# end

function _reduced_cost(
    model,
    attr::MOI.ConstraintDual,
    ci::MOI.ConstraintIndex{MOI.VariableIndex,S},
) where {S}
    MOI.check_result_index_bounds(model, attr)
    x = MOI.VariableIndex(ci.value)
    MOI.throw_if_not_valid(model, x)
    p = Ref{Cint}()
    KNITRO.@_checked KNITRO.KN_get_number_cons(model.inner, p)
    return _sense_dual(model) * _get_dual(model, x.value + p[])
end

function MOI.get(
    model::Optimizer,
    attr::MOI.ConstraintDual,
    ci::MOI.ConstraintIndex{MOI.VariableIndex,MOI.LessThan{Float64}},
)
    return min(0.0, _reduced_cost(model, attr, ci))
end

function MOI.get(
    model::Optimizer,
    attr::MOI.ConstraintDual,
    ci::MOI.ConstraintIndex{MOI.VariableIndex,MOI.GreaterThan{Float64}},
)
    return max(0.0, _reduced_cost(model, attr, ci))
end

function MOI.get(
    model::Optimizer,
    attr::MOI.ConstraintDual,
    ci::MOI.ConstraintIndex{MOI.VariableIndex,S},
) where {S<:Union{MOI.EqualTo{Float64},MOI.Interval{Float64}}}
    return _reduced_cost(model, attr, ci)
end

function MOI.get(model::Optimizer, attr::MOI.NLPBlockDual)
    if model.number_solved == 0
        throw(MOI.ResultIndexBoundsError(attr, 0))
    end
    return [_sense_dual(model) * _get_dual(model, i + 1) for i in model.nlp_index_cons]
end

function MOI.get(model::Optimizer, ::MOI.SolveTimeSec)
    p = Ref{Cdouble}(NaN)
    if KNITRO.knitro_version() >= v"12.0"
        KNITRO.@_checked KNITRO.KN_get_solve_time_cpu(model.inner, p)
    end
    return p[]
end

function MOI.get(model::Optimizer, ::MOI.NodeCount)::Int64
    p = Ref{Cint}(0)
    KNITRO.@_checked KNITRO.KN_get_mip_number_nodes(model.inner, p)
    return p[]
end

function MOI.get(model::Optimizer, ::MOI.BarrierIterations)::Int64
    p = Ref{Cint}(0)
    KNITRO.@_checked KNITRO.KN_get_number_iters(model.inner, p)
    return p[]
end

function MOI.get(model::Optimizer, ::MOI.RelativeGap)
    p = Ref{Cdouble}(NaN)
    KNITRO.@_checked KNITRO.KN_get_mip_rel_gap(model.inner, p)
    return p[]
end

function MOI.get(model::Optimizer, ::MOI.ObjectiveBound)
    p = Ref{Cdouble}(NaN)
    KNITRO.@_checked KNITRO.KN_get_mip_relaxation_bnd(model.inner, p)
    return p[]
end

end  # module KNITROMathOptInterfaceExt
