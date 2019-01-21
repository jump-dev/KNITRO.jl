#--------------------------------------------------
# import KNITRO's MOIWrapper
# This file is largely inspired from:
# https://github.com/JuliaOpt/Ipopt.jl/blob/master/src/MOIWrapper.jl
# The authors are indebted to the developpers of Ipopt.jl for
# the current MOI wrapper.
#
#--------------------------------------------------
# Specifications
#--------------------------------------------------
# The MOI wrapper works only for KNITRO version >= 11.0
#
# - linear coefs are handled directly by KNITRO, via
#  `KN_add_con_linear_struct , KN_add_obj_linear_struct
#
# - quadratic coefs are also handled directly by KNITRO, via
#  `KN_add_con_quad_struct , KN_add_obj_quad_struct
#
# - NLP data are handled via KNITRO's callbacks
#
# NB: if `model.nlp_data`is empty, KNITRO would not use any
#     callbacks during the resolving.
#
#--------------------------------------------------

import MathOptInterface
const MOI  = MathOptInterface
const MOIU = MathOptInterface.Utilities

const SF = Union{MOI.ScalarAffineFunction{Float64},
                 MOI.ScalarQuadraticFunction{Float64}}

const SS = Union{MOI.EqualTo{Float64},
                 MOI.GreaterThan{Float64},
                 MOI.LessThan{Float64},
                 MOI.Interval{Float64},
                 MOI.Zeros,
                 MOI.Nonnegatives,
                 MOI.Nonpositives}

const VS = Union{MOI.EqualTo{Float64},
                 MOI.GreaterThan{Float64},
                 MOI.LessThan{Float64}}


##################################################
# Define custom error for MOI wrapper
struct UpdateObjectiveError <: MOI.NotAllowedError end
struct AddVariableError <: MOI.NotAllowedError end
struct AddConstraintError <: MOI.NotAllowedError end

##################################################
# import legacy from LinQuadOptInterface to ease the integration
# of KNITRO quadratic and linear facilities
"""
    canonical_quadratic_reduction(func::ScalarQuadraticFunction)

Reduce a ScalarQuadraticFunction into three arrays, returned in the following
order:
 1. a vector of quadratic row indices
 2. a vector of quadratic column indices
 3. a vector of quadratic coefficients

Warning: we assume in this function that all variables are correctly
ordered, that is no deletion or swap has occured.
"""
function canonical_quadratic_reduction(func::MOI.ScalarQuadraticFunction)
    quad_columns_1, quad_columns_2, quad_coefficients = (
        Int32[term.variable_index_1.value for term in func.quadratic_terms],
        Int32[term.variable_index_2.value for term in func.quadratic_terms],
        [term.coefficient for term in func.quadratic_terms]
    )
    # take care of difference between MOI standards and KNITRO ones
    for i in 1:length(quad_coefficients)
        if quad_columns_1[i] == quad_columns_2[i]
            quad_coefficients[i] *= .5
        end
    end
    # take care that Julia is 1-indexed
    quad_columns_1 .-= 1
    quad_columns_2 .-= 1
    return quad_columns_1, quad_columns_2, quad_coefficients
end

"""
    canonical_linear_reduction(func::Quad)

Reduce a ScalarQuadraticFunction into two arrays, returned in the following
order:
 1. a vector of linear column indices
 2. a vector of linear coefficients

Warning: we assume in this function that all variables are correctly
ordered, that is no deletion or swap has occured.
"""
function canonical_linear_reduction(func::MOI.ScalarQuadraticFunction)
    affine_columns = Int32[term.variable_index.value for term in func.affine_terms]
    affine_coefficients = [term.coefficient for term in func.affine_terms]
    affine_columns .-= 1
    return affine_columns, affine_coefficients
end
function canonical_linear_reduction(func::MOI.ScalarAffineFunction)
    affine_columns = Int32[term.variable_index.value for term in func.terms]
    affine_coefficients = [term.coefficient for term in func.terms]
    affine_columns .-= 1
    return affine_columns, affine_coefficients
end

function canonical_vector_affine_reduction(func::MOI.VectorAffineFunction)
    index_cols = Int32[]
    index_vars = Int32[]
    coefs = Float64[]

    for t in func.terms
        push!(index_cols, t.output_index)
        push!(index_vars, t.scalar_term.variable_index.value)
        push!(coefs, t.scalar_term.coefficient)
    end
    index_cols .-= 1
    index_vars .-= 1
    return index_cols, index_vars, coefs
end

##################################################

mutable struct VariableInfo
    lower_bound::Float64  # May be -Inf even if has_lower_bound == true
    has_lower_bound::Bool # Implies lower_bound == Inf
    upper_bound::Float64  # May be Inf even if has_upper_bound == true
    has_upper_bound::Bool # Implies upper_bound == Inf
    is_fixed::Bool        # Implies lower_bound == upper_bound and !has_lower_bound and !has_upper_bound.
    start::Float64
    name::String
end
# The default start value is zero.
VariableInfo() = VariableInfo(-Inf, false, Inf, false, false, 0.0, "")

mutable struct Optimizer <: MOI.AbstractOptimizer
    inner::Union{Model, Nothing}
    # we only keep in memory some information about variables
    # as we cannot delete variables, we do not have to store an index
    variable_info::Vector{VariableInfo}
    # get number of solve for restart
    number_solved::Int
    # specify if NLP is loaded inside KNITRO to avoid double definition
    nlp_loaded::Bool
    nlp_data::MOI.NLPBlockData
    sense::MOI.OptimizationSense
    # constraint counters
    number_zeroone_constraints::Int
    number_integer_constraints::Int
    # constraint mappings
    constraint_mapping::Dict{MOI.ConstraintIndex, Union{Cint, Vector{Cint}}}
    options::Dict
end

struct EmptyNLPEvaluator <: MOI.AbstractNLPEvaluator end
MOI.features_available(::EmptyNLPEvaluator) = [:Grad, :Jac, :Hess]
MOI.initialize(::EmptyNLPEvaluator, features) = nothing
MOI.eval_objective(::EmptyNLPEvaluator, x) = NaN
function MOI.eval_constraint(::EmptyNLPEvaluator, g, x)
    return
end
MOI.eval_objective_gradient(::EmptyNLPEvaluator, g, x) = nothing
MOI.jacobian_structure(::EmptyNLPEvaluator) = Tuple{Int64,Int64}[]
MOI.hessian_lagrangian_structure(::EmptyNLPEvaluator) = Tuple{Int64,Int64}[]
function MOI.eval_constraint_jacobian(::EmptyNLPEvaluator, J, x)
    return
end
function MOI.eval_hessian_lagrangian(::EmptyNLPEvaluator, H, x, σ, μ)
    return
end


empty_nlp_data() = MOI.NLPBlockData([], EmptyNLPEvaluator(), false)

function set_options(model::Optimizer)
    # set KNITRO option
    for (name,value) in model.options
        sname = string(name)
        if sname == "option_file"
            KN_load_param_file(model.inner, value)
        elseif sname == "tuner_file"
            KN_load_tuner_file(model.inner, value)
        else
            if haskey(KN_paramName2Indx, sname) # KN_PARAM_*
                KN_set_param(model.inner, paramName2Indx[sname], value)
            else # string name
                KN_set_param(model.inner, sname, value)
            end
        end
    end
end

function Optimizer(;license_manager=nothing, options...)
    # create KNITRO context
    if isa(license_manager, LMcontext)
        println("Load KNITRO with license manager.")
        kc = KN_new_lm(license_manager)
    else
        kc = KN_new()
    end
    model = Optimizer(kc, [], 0, false, empty_nlp_data(), MOI.FEASIBILITY_SENSE,
                      0, 0,
                      Dict{MOI.ConstraintIndex, Int}(), options)

    set_options(model)
    return model
end

# TODO: dry supports with macros
MOI.supports(::Optimizer, ::MOI.NLPBlock) = true
MOI.supports(::Optimizer, ::MOI.ObjectiveFunction{MOI.SingleVariable}) = true
MOI.supports(::Optimizer, ::MOI.ObjectiveFunction{MOI.ScalarAffineFunction{Float64}}) = true
MOI.supports(::Optimizer, ::MOI.ObjectiveFunction{MOI.ScalarQuadraticFunction{Float64}}) = true
MOI.supports(::Optimizer, ::MOI.ObjectiveSense) = true
MOI.supports(::Optimizer, ::MOI.VariableName, ::Type{MOI.VariableIndex}) = true
MOI.supports(::Optimizer, ::MOI.ConstraintName, ::Type{MOI.ConstraintIndex}) = true

MOI.supports_constraint(::Optimizer, ::Type{MOI.SingleVariable}, ::Type{MOI.LessThan{Float64}}) = true
MOI.supports_constraint(::Optimizer, ::Type{MOI.SingleVariable}, ::Type{MOI.GreaterThan{Float64}}) = true
MOI.supports_constraint(::Optimizer, ::Type{MOI.SingleVariable}, ::Type{MOI.EqualTo{Float64}}) = true
MOI.supports_constraint(::Optimizer, ::Type{MOI.SingleVariable}, ::Type{MOI.ZeroOne}) = true
MOI.supports_constraint(::Optimizer, ::Type{MOI.SingleVariable}, ::Type{MOI.Integer}) = true

MOI.supports_constraint(::Optimizer, ::Type{MOI.ScalarAffineFunction{Float64}}, ::Type{MOI.LessThan{Float64}}) = true
MOI.supports_constraint(::Optimizer, ::Type{MOI.ScalarAffineFunction{Float64}}, ::Type{MOI.GreaterThan{Float64}}) = true
MOI.supports_constraint(::Optimizer, ::Type{MOI.ScalarAffineFunction{Float64}}, ::Type{MOI.EqualTo{Float64}}) = true
MOI.supports_constraint(::Optimizer, ::Type{MOI.ScalarAffineFunction{Float64}}, ::Type{MOI.Interval{Float64}}) = true
MOI.supports_constraint(::Optimizer, ::Type{MOI.ScalarQuadraticFunction{Float64}}, ::Type{MOI.LessThan{Float64}}) = true
MOI.supports_constraint(::Optimizer, ::Type{MOI.ScalarQuadraticFunction{Float64}}, ::Type{MOI.GreaterThan{Float64}}) = true
MOI.supports_constraint(::Optimizer, ::Type{MOI.ScalarQuadraticFunction{Float64}}, ::Type{MOI.EqualTo{Float64}}) = true
MOI.supports_constraint(::Optimizer, ::Type{<:SF}, ::Type{<:SS}) = true
MOI.supports_constraint(::Optimizer, ::Type{MOI.SingleVariable}, ::Type{<:VS}) = true
MOI.supports_constraint(::Optimizer, ::Type{MOI.VectorAffineFunction{Float64}}, ::Type{MOI.Nonnegatives}) = true
MOI.supports_constraint(::Optimizer, ::Type{MOI.VectorAffineFunction{Float64}}, ::Type{MOI.Zeros}) = true
MOI.supports_constraint(::Optimizer, ::Type{MOI.VectorAffineFunction{Float64}}, ::Type{MOI.Nonpositives}) = true
MOI.supports_constraint(::Optimizer, ::Type{MOI.VectorAffineFunction{Float64}}, ::Type{MOI.SecondOrderCone}) = true

function MOI.copy_to(model::Optimizer, src::MOI.ModelLike; kws...)
    return MOI.Utilities.automatic_copy_to(model, src; kws...)
end
MOIU.supports_default_copy_to(model::Optimizer, copy_names::Bool) = true

MOI.get(model::Optimizer, ::MOI.NumberOfVariables) = length(model.variable_info)
MOI.get(model::Optimizer, ::MOI.NumberOfConstraints{MOI.SingleVariable, MOI.ZeroOne}) =
    model.number_zeroone_constraints
# TODO: a bit hacky, but that should work for MOI Test
MOI.get(model::Optimizer, ::MOI.NumberOfConstraints{MOI.VectorAffineFunction{Float64}, MOI.Nonnegatives}) =
sum(typeof.(collect(keys(model.constraint_mapping))) .== MOI.ConstraintIndex{MOI.VectorAffineFunction{Float64}, MOI.Nonnegatives})
MOI.get(model::Optimizer, ::MOI.NumberOfConstraints{MOI.VectorAffineFunction{Float64}, MOI.Nonpositives}) =
sum(typeof.(collect(keys(model.constraint_mapping))) .== MOI.ConstraintIndex{MOI.VectorAffineFunction{Float64}, MOI.Nonpositives})
MOI.get(model::Optimizer, ::MOI.NumberOfConstraints{MOI.VectorAffineFunction{Float64}, MOI.Zeros}) =
sum(typeof.(collect(keys(model.constraint_mapping))) .== MOI.ConstraintIndex{MOI.VectorAffineFunction{Float64}, MOI.Zeros})
MOI.get(model::Optimizer, ::MOI.NumberOfConstraints{MOI.VectorAffineFunction{Float64}, MOI.SecondOrderCone}) =
sum(typeof.(collect(keys(model.constraint_mapping))) .== MOI.ConstraintIndex{MOI.VectorAffineFunction{Float64}, MOI.SecondOrderCone})

MOI.get(model::Optimizer, ::MOI.NumberOfConstraints{MOI.ScalarAffineFunction{Float64}, S}) where S <: VS  =
sum(typeof.(collect(keys(model.constraint_mapping))) .== MOI.ConstraintIndex{MOI.ScalarAffineFunction{Float64}, S})

MOI.get(model::Optimizer, ::MOI.NumberOfConstraints{MOI.ScalarQuadraticFunction{Float64}, S}) where S <: VS  =
sum(typeof.(collect(keys(model.constraint_mapping))) .== MOI.ConstraintIndex{MOI.ScalarQuadraticFunction{Float64}, S})

function MOI.get(model::Optimizer, ::MOI.ListOfVariableIndices)
    return [MOI.VariableIndex(i) for i in 1:length(model.variable_info)]
end

function MOI.set(model::Optimizer, ::MOI.ObjectiveSense,
                 sense::MOI.OptimizationSense)
    # if the model was already solved, we cannot change the objective
    (model.number_solved >= 1) && throw(UpdateObjectiveError())

    model.sense = sense
    if model.sense == MOI.MAX_SENSE
        KN_set_obj_goal(model.inner, KN_OBJGOAL_MAXIMIZE)
    elseif model.sense == MOI.MIN_SENSE
        KN_set_obj_goal(model.inner, KN_OBJGOAL_MINIMIZE)
    end
    return
end

function MOI.empty!(model::Optimizer)
    # free KNITRO model properly
    if model.inner != nothing
        KN_free(model.inner)
    end
    model.inner = KN_new()
    empty!(model.variable_info)
    model.number_solved = 0
    model.nlp_data = empty_nlp_data()
    model.nlp_loaded = false
    model.sense = MOI.FEASIBILITY_SENSE
    model.number_zeroone_constraints = 0
    model.number_integer_constraints = 0
    model.constraint_mapping = Dict()
    set_options(model)
end

function MOI.is_empty(model::Optimizer)
    return isempty(model.variable_info) &&
           model.nlp_data.evaluator isa EmptyNLPEvaluator &&
           model.sense == MOI.FEASIBILITY_SENSE
end

function MOI.add_variable(model::Optimizer)
    # if model has been optimized, KNITRO does not support adding
    # variable anymore
    (model.number_solved >= 1) && throw(AddVariableError())
    push!(model.variable_info, VariableInfo())
    KN_add_var(model.inner)
    return MOI.VariableIndex(length(model.variable_info))
end
# TODO: maybe we can rewrite this function to go faster
function MOI.add_variables(model::Optimizer, n::Int)
    return [MOI.add_variable(model) for i in 1:n]
end

# convert Julia'Inf to KNITRO's Inf
check_value(val::Float64) = isinf(val) ? KN_INFINITY : val

function check_inbounds(model::Optimizer, vi::MOI.VariableIndex)
    num_variables = length(model.variable_info)
    if !(1 <= vi.value <= num_variables)
        error("Invalid variable index $vi. ($num_variables variables in the model.)")
    end
end

function check_inbounds(model::Optimizer, var::MOI.SingleVariable)
    return check_inbounds(model, var.variable)
end

function check_inbounds(model::Optimizer, aff::MOI.ScalarAffineFunction)
    for term in aff.terms
        check_inbounds(model, term.variable_index)
    end
end

function check_inbounds(model::Optimizer, quad::MOI.ScalarQuadraticFunction)
    for term in quad.affine_terms
        check_inbounds(model, term.variable_index)
    end
    for term in quad.quadratic_terms
        check_inbounds(model, term.variable_index_1)
        check_inbounds(model, term.variable_index_2)
    end
end

function has_upper_bound(model::Optimizer, vi::MOI.VariableIndex)
    return model.variable_info[vi.value].has_upper_bound
end

function has_lower_bound(model::Optimizer, vi::MOI.VariableIndex)
    return model.variable_info[vi.value].has_lower_bound
end

function is_fixed(model::Optimizer, vi::MOI.VariableIndex)
    return model.variable_info[vi.value].is_fixed
end

##################################################
# Generic constraint definition
##################################################
#--------------------------------------------------
# Bound constraint on variables
function MOI.add_constraint(model::Optimizer, v::MOI.SingleVariable, lt::MOI.LessThan{Float64})
    (model.number_solved >= 1) && throw(AddConstraintError())
    vi = v.variable
    check_inbounds(model, vi)
    if isnan(lt.upper)
        error("Invalid upper bound value $(lt.upper).")
    end
    if has_upper_bound(model, vi)
        error("Upper bound on variable $vi already exists.")
    end
    if is_fixed(model, vi)
        error("Variable $vi is fixed. Cannot also set upper bound.")
    end
    ub = check_value(lt.upper)
    model.variable_info[vi.value].upper_bound = ub
    model.variable_info[vi.value].has_upper_bound = true
    # we assume that MOI's indexing is the same as KNITRO's indexing
    KN_set_var_upbnds(model.inner, vi.value-1, ub)
    return MOI.ConstraintIndex{MOI.SingleVariable, MOI.LessThan{Float64}}(vi.value)
end

function MOI.add_constraint(model::Optimizer, v::MOI.SingleVariable, gt::MOI.GreaterThan{Float64})
    (model.number_solved >= 1) && throw(AddConstraintError())
    vi = v.variable
    check_inbounds(model, vi)
    if isnan(gt.lower)
        error("Invalid lower bound value $(gt.lower).")
    end
    if has_lower_bound(model, vi)
        error("Lower bound on variable $vi already exists.")
    end
    if is_fixed(model, vi)
        error("Variable $vi is fixed. Cannot also set lower bound.")
    end
    lb = check_value(gt.lower)
    model.variable_info[vi.value].lower_bound = lb
    model.variable_info[vi.value].has_lower_bound = true
    # we assume that MOI's indexing is the same as KNITRO's indexing
    KN_set_var_lobnds(model.inner, vi.value-1, lb)
    return MOI.ConstraintIndex{MOI.SingleVariable, MOI.GreaterThan{Float64}}(vi.value)
end

function MOI.add_constraint(model::Optimizer, v::MOI.SingleVariable, eq::MOI.EqualTo{Float64})
    (model.number_solved >= 1) && throw(AddConstraintError())
    vi = v.variable
    check_inbounds(model, vi)
    if isnan(eq.value)
        error("Invalid fixed value $(eq.value).")
    end
    if has_lower_bound(model, vi)
        error("Variable $vi has a lower bound. Cannot be fixed.")
    end
    if has_upper_bound(model, vi)
        error("Variable $vi has an upper bound. Cannot be fixed.")
    end
    if is_fixed(model, vi)
        error("Variable $vi is already fixed.")
    end
    eqv = check_value(eq.value)
    model.variable_info[vi.value].lower_bound = eqv
    model.variable_info[vi.value].upper_bound = eqv
    model.variable_info[vi.value].is_fixed = true
    # we assume that MOI's indexing is the same as KNITRO's indexing
    KN_set_var_fxbnds(model.inner, vi.value-1, eqv)
    return MOI.ConstraintIndex{MOI.SingleVariable, MOI.EqualTo{Float64}}(vi.value)
end

function MOI.add_constraint(model::Optimizer, func::MOI.ScalarAffineFunction{Float64},
                            set::VS)
    (model.number_solved >= 1) && throw(AddConstraintError())
    check_inbounds(model, func)
    # we add a constraint in KNITRO
    num_cons = KN_add_con(model.inner)
    # add bound
    if isa(set, MOI.LessThan{Float64})
        val = check_value(set.upper)
        KN_set_con_upbnd(model.inner, num_cons, val - func.constant)
    elseif isa(set, MOI.GreaterThan{Float64})
        val = check_value(set.lower)
        KN_set_con_lobnd(model.inner, num_cons, val - func.constant)
    elseif isa(set, MOI.EqualTo{Float64})
        val = check_value(set.value)
        KN_set_con_eqbnd(model.inner, num_cons, val - func.constant)
    end
    # parse structure of constraint
    indexvars, coefs = canonical_linear_reduction(func)
    KN_add_con_linear_struct(model.inner, num_cons, indexvars, coefs)
    # add constraints to index
    ci = MOI.ConstraintIndex{typeof(func), typeof(set)}(num_cons)
    model.constraint_mapping[ci] = num_cons
    return ci
end

function MOI.add_constraint(model::Optimizer, func::MOI.ScalarAffineFunction{Float64},
                            set::MOI.Interval{Float64})
    (model.number_solved >= 1) && throw(AddConstraintError())
    check_inbounds(model, func)
    # we add a constraint in KNITRO
    ci = KN_add_con(model.inner)
    # add upper bound
    lb = check_value(set.lower)
    ub = check_value(set.upper)
    KN_set_con_lobnd(model.inner, ci, lb - func.constant)
    KN_set_con_upbnd(model.inner, ci, ub - func.constant)
    # parse structure of constraint
    indexvars, coefs = canonical_linear_reduction(func)
    KN_add_con_linear_struct(model.inner, ci, indexvars, coefs)
    # add constraints to index
    consi = MOI.ConstraintIndex{typeof(func), typeof(set)}(ci)
    model.constraint_mapping[consi] = ci
    return consi
end

function MOI.add_constraint(model::Optimizer, func::MOI.ScalarQuadraticFunction{Float64},
                            set::VS)
    (model.number_solved >= 1) && throw(AddConstraintError())
    check_inbounds(model, func)
    # we add a constraint in KNITRO
    num_cons = KN_add_con(model.inner)
    # add upper bound
    if isa(set, MOI.LessThan{Float64})
        val = check_value(set.upper)
        KN_set_con_upbnd(model.inner, num_cons, val - func.constant)
    elseif isa(set, MOI.GreaterThan{Float64})
        val = check_value(set.lower)
        KN_set_con_lobnd(model.inner, num_cons, val - func.constant)
    elseif isa(set, MOI.EqualTo{Float64})
        val = check_value(set.value)
        KN_set_con_eqbnd(model.inner, num_cons, val - func.constant)
    end
    # parse linear structure of constraint
    indexvars, coefs = canonical_linear_reduction(func)
    KN_add_con_linear_struct(model.inner, num_cons, indexvars, coefs)
    # parse quadratic term
    qvar1, qvar2, qcoefs = canonical_quadratic_reduction(func)
    KN_add_con_quadratic_struct(model.inner, num_cons, qvar1, qvar2, qcoefs)
    # add constraints to index
    ci = MOI.ConstraintIndex{typeof(func), typeof(set)}(num_cons)
    model.constraint_mapping[ci] = num_cons
    return ci
end

function MOI.add_constraint(model::Optimizer, func::MOI.VectorAffineFunction, set::MOI.AbstractVectorSet)
    (model.number_solved >= 1) && throw(AddConstraintError())
    # TODO: add check inbounds for VectorAffineFunction
    previous_col_number = number_constraints(model)
    num_cols = length(func.constants)
    # add constraints inside KNITRO
    index_cons = KN_add_cons(model.inner, num_cols)

    # parse vector affine expression
    indexcols, indexvars, coefs = canonical_vector_affine_reduction(func)
    # reformate indexcols with current numbering
    indexcols .+= previous_col_number

    # load inside KNITRO
    KN_add_con_linear_struct(model.inner, indexcols, indexvars, coefs)
    if isa(set, MOI.Nonnegatives)
        KN_set_con_lobnds(model.inner, index_cons, - func.constants)
    elseif isa(set, MOI.Nonpositives)
        KN_set_con_upbnds(model.inner, index_cons, - func.constants)
    elseif isa(set, MOI.Zeros)
        KN_set_con_eqbnds(model.inner, index_cons, - func.constants)
    else
        error("Unvalid set $set for VectorAffineFunction constraint")
    end
    # add constraints to index
    ci = MOI.ConstraintIndex{typeof(func), typeof(set)}(index_cons[1])
    model.constraint_mapping[ci] = index_cons
    return ci
end

function MOI.add_constraint(model::Optimizer, func::MOI.VectorAffineFunction, set::MOI.SecondOrderCone)
    @warn("Support of MOI.SecondOrderCone is still experimental")
    (model.number_solved >= 1) && throw(AddConstraintError())
    # TODO: add check inbounds for VectorAffineFunction
    previous_col_number = number_constraints(model)
    ncoords = length(func.constants)
    # add constraints inside KNITRO
    index_con = KN_add_con(model.inner)

    # parse vector affine expression
    indexcoords, indexvars, coefs = canonical_vector_affine_reduction(func)
    constants = func.constants
    # load Second Order Conic constraint
    KN_add_con_L2norm(model.inner, index_con, ncoords, length(indexcoords),
                  indexcoords, indexvars, coefs, constants)
    # add constraints to index
    ci = MOI.ConstraintIndex{typeof(func), typeof(set)}(index_con)
    model.constraint_mapping[ci] = index_con
    return ci
end

# define integer and boolean constraints
function MOI.add_constraint(model::Optimizer, v::MOI.SingleVariable, ::MOI.ZeroOne)
    vi = v.variable
    check_inbounds(model, vi)
    model.number_zeroone_constraints += 1
    # we have to made the bounds explicit for KNITRO
    KN_set_var_lobnds(model.inner, vi.value-1, 0.)
    KN_set_var_upbnds(model.inner, vi.value-1, 1.)
    KN_set_var_type(model.inner, vi.value-1, KN_VARTYPE_BINARY)
end

function MOI.add_constraint(model::Optimizer, v::MOI.SingleVariable, ::MOI.Integer)
    (model.number_solved >= 1) && throw(AddConstraintError())
    vi = v.variable
    check_inbounds(model, vi)
    model.number_integer_constraints += 1
    KN_set_var_type(model.inner, vi.value-1, KN_VARTYPE_INTEGER)
end

##################################################
# Primal and dual warmstart
##################################################
function MOI.supports(::Optimizer, ::MOI.VariablePrimalStart,
                      ::Type{MOI.VariableIndex})
    return true
end
function MOI.set(model::Optimizer, ::MOI.VariablePrimalStart,
                 vi::MOI.VariableIndex, value::Real)
    check_inbounds(model, vi)
    model.variable_info[vi.value].start = value
    KN_set_var_primal_init_values(model.inner, vi.value-1, Cdouble(value))
    return
end

function MOI.supports(::Optimizer, ::MOI.ConstraintDualStart,
                      ::Type{MOI.ConstraintIndex})
    return true
end
function MOI.set(model::Optimizer, ::MOI.ConstraintDualStart,
                 ci::MOI.ConstraintIndex, value::Real)
    check_inbounds(model, ci)
    KN_set_con_dual_init_values(model.inner, ci.value-1, value)
    return
end

function MOI.set(model::Optimizer, ::MOI.NLPBlock, nlp_data::MOI.NLPBlockData)
    model.nlp_data = nlp_data

    evaluator = model.nlp_data.evaluator
    features = MOI.features_available(evaluator)
    has_hessian = (:Hess in features)
    init_feat = [:Grad]
    has_hessian && push!(init_feat, :Hess)
    num_nlp_constraints = length(nlp_data.constraint_bounds)
    num_nlp_constraints > 0 && push!(init_feat, :Jac)

    #= MOI.initialize(evaluator, init_feat) =#
    # we need to load the NLP constraints inside KNITRO
    if num_nlp_constraints > 0
        num_cons = KN_add_cons(model.inner, num_nlp_constraints)

        for (ib, pair) in enumerate(nlp_data.constraint_bounds)
            if pair.upper == pair.lower
                KN_set_con_eqbnd(model.inner, num_cons[ib], pair.upper)
            else
                KN_set_con_upbnd(model.inner, num_cons[ib], pair.upper)
                KN_set_con_lobnd(model.inner, num_cons[ib], pair.lower)
            end
        end
        # add constraint to index
        ci = MOI.ConstraintIndex{MOI.NLPBlockData, MOI.Interval}(num_cons[1])
        # take care that julia is 1-indexing!
        model.constraint_mapping[ci] = num_cons
    end
    return
end

##################################################
# Objective definition
##################################################
MOI.get(model::Optimizer, ::MOI.ObjectiveSense) = model.sense
function add_objective!(model::Optimizer, objective::MOI.ScalarQuadraticFunction)
    # we parse the expression passed in arguments:
    qobjindex1, qobjindex2, qcoefs = canonical_quadratic_reduction(objective)
    lobjindex, lcoefs = canonical_linear_reduction(objective)
    # we load the objective inside KNITRO
    KN_add_obj_quadratic_struct(model.inner, qobjindex1, qobjindex2, qcoefs)
    KN_add_obj_linear_struct(model.inner, lobjindex, lcoefs)
    KN_add_obj_constant(model.inner, objective.constant)
end

function add_objective!(model::Optimizer, objective::MOI.ScalarAffineFunction)
    # we parse the expression passed in arguments:
    lobjindex, lcoefs = canonical_linear_reduction(objective)
    # we load the objective inside KNITRO
    KN_add_obj_linear_struct(model.inner, lobjindex, lcoefs)
    KN_add_obj_constant(model.inner, objective.constant)
end

function add_objective!(model::Optimizer, var::MOI.SingleVariable)
    # we load the objective inside KNITRO
    KN_add_obj_linear_struct(model.inner, var.variable.value-1, 1.)
end

function MOI.set(model::Optimizer, ::MOI.ObjectiveFunction,
                 func::Union{MOI.SingleVariable, MOI.ScalarAffineFunction,
                             MOI.ScalarQuadraticFunction})
    # 1/ if the model was already solved, we cannot change the objective
    (model.number_solved >= 1) && throw(UpdateObjectiveError())
    # 2/ if the model has valid non-linear objective, discard adding func
    if ~isa(model.nlp_data.evaluator, EmptyNLPEvaluator) && model.nlp_data.has_objective
        @warn("Objective of `model` is already specified in NLPBlockData.")
        return
    end
    check_inbounds(model, func)
    # we can fetch directly the objective as an expression.
    add_objective!(model, func)
    return
end


number_variables(model::Optimizer) = length(model.variable_info)
number_constraints(model::Optimizer) = KN_get_number_cons(model.inner)


function MOI.optimize!(model::Optimizer)

    # add NLP structure if specified
    # FIXME: ideally, the following code should be moved
    # inside set(::Optimizer, ::NLPBlockData) function.
    # However, we encounter an error if we do so, because currently
    # the definition of eval_*_cb functions should be in the same
    # scope as KN_solve (may be due to a closure limitation)
    if ~isa(model.nlp_data.evaluator, EmptyNLPEvaluator) && ~model.nlp_loaded
        # instantiate NLPEvaluator once and for all
        features = MOI.features_available(model.nlp_data.evaluator)
        has_hessian = (:Hess in features)
        # build initial features for solver
        init_feat = [:Grad]
        has_hessian && push!(init_feat, :Hess)
        num_nlp_constraints = length(model.nlp_data.constraint_bounds)
        num_nlp_constraints > 0 && push!(init_feat, :Jac)
        # initialize!
        MOI.initialize(model.nlp_data.evaluator, init_feat)

        # the callbacks must match the signature of the callbacks
        # defined in knitro.h.
        # Objective callback (set both objective and constraint evaluation
        function eval_f_cb(kc, cb, evalRequest, evalResult, userParams)
            # evaluate objective if specified in nlp_data
            if model.nlp_data.has_objective
                evalResult.obj[1] = MOI.eval_objective(model.nlp_data.evaluator, evalRequest.x)
            end
            # evaluate nonlinear term in constraint
            MOI.eval_constraint(model.nlp_data.evaluator, evalResult.c, evalRequest.x)
            return 0
        end

        # Objective gradient callback
        function eval_grad_cb(kc, cb, evalRequest, evalResult, userParams)
            # evaluate non-linear term in objective gradient
            if model.nlp_data.has_objective
                MOI.eval_objective_gradient(model.nlp_data.evaluator, evalResult.objGrad, evalRequest.x)
            end
            # evaluate non linear part of jacobian
            MOI.eval_constraint_jacobian(model.nlp_data.evaluator, evalResult.jac, evalRequest.x)
        end

        if has_hessian
            # Hessian callback
            function eval_h_cb(kc, cb, evalRequest, evalResult, userParams)
                MOI.eval_hessian_lagrangian(model.nlp_data.evaluator,
                                            evalResult.hess,
                                            evalRequest.x,
                                            evalRequest.sigma,
                                            evalRequest.lambda)
            end
        else
            eval_h_cb = nothing
        end

        # be careful that sometimes objective is not evaluated here
        if model.nlp_data.has_objective
            # here, we assume that the full objective is evaluated in eval_f
            cb = KN_add_eval_callback(model.inner, eval_f_cb)
        else
            indexcons = collect(Int32, 0:length(model.nlp_data.constraint_bounds)-1)
            cb = KN_add_eval_callback(model.inner, false, indexcons, eval_f_cb)
        end

        # get jacobian structure
        jacob_structure = MOI.jacobian_structure(model.nlp_data.evaluator)
        nnzJ = length(jacob_structure)
        if nnzJ == 0
            KN_set_cb_grad(model.inner, cb, eval_grad_cb)
        else
            # take care to convert 1-indexing to 0-indexing!
            # KNITRO supports only Int32 array for integer
            jacIndexCons = Int32[i-1 for (i, _) in jacob_structure]
            jacIndexVars = Int32[j-1 for (_, j) in jacob_structure]
            KN_set_cb_grad(model.inner, cb, eval_grad_cb,
                        jacIndexCons=jacIndexCons, jacIndexVars=jacIndexVars)
        end

        if has_hessian
            # get hessian structure
            hessian_structure = MOI.hessian_lagrangian_structure(model.nlp_data.evaluator)
            nnzH = length(hessian_structure)
            # take care to convert 1-indexing to 0-indexing!
            # KNITRO supports only Int32 array for integer
            hessIndexVars1 = Int32[i-1 for (i, _) in hessian_structure]
            hessIndexVars2 = Int32[j-1 for (_, j) in hessian_structure]

            KN_set_cb_hess(model.inner, cb, nnzH, eval_h_cb,
                        hessIndexVars1=hessIndexVars1,
                        hessIndexVars2=hessIndexVars2)
        end

        model.nlp_loaded = true
    end

    KN_solve(model.inner)
    model.number_solved += 1
end

# refer to KNITRO manual:
# https://www.artelys.com/tools/knitro_doc/3_referenceManual/returnCodes.html#returncodes
function MOI.get(model::Optimizer, ::MOI.TerminationStatus)
    if model.number_solved == 0
        return MOI.OPTIMIZE_NOT_CALLED
    end
    status = get_status(model.inner)
    if status == 0
        return MOI.LOCALLY_SOLVED
    elseif status == -100
        return MOI.ALMOST_OPTIMAL
    elseif -109 <= status <= -101
        return MOI.ALMOST_OPTIMAL
    elseif -209 <= status <= -200
        return MOI.LOCALLY_INFEASIBLE
    elseif status == -300
        return MOI.DUAL_INFEASIBLE
    elseif (status == -400) || (status == -410)
        return MOI.ITERATION_LIMIT
    elseif (status == -401) || (status == -411)
        return MOI.TIME_LIMIT
    elseif (-405 <= status <= -402) || (-415 <= status <= -412)
        # TODO
        return MOI.OTHER_LIMIT
    elseif (status == -406) || (status == -416)
        return MOI.NODE_LIMIT
    elseif -599 <= status <= -500
        return MOI.OTHER_ERROR
    elseif status == -503
        return MOI.MEMORY_LIMIT
    elseif status == -504
        return MOI.INTERRUPTED
    elseif (status == -505 ) || (status == -521)
        return MOI.INVALID_OPTION
    elseif (-514 <= status <= -506 ) || (-532 <= status <= -522)
        return MOI.INVALID_MODEL
    elseif (-525 <= status <= -522 )
        return MOI.NUMERICAL_ERROR
    elseif (status == -600) || (-520 <= status <= -515)
        return MOI.OTHER_ERROR
    else
        error("Unrecognized KNITRO status $status")
    end
end

# TODO
function MOI.get(model::Optimizer, ::MOI.ResultCount)
    return (model.number_solved >= 1) ? 1 : 0
end

function MOI.get(model::Optimizer, ::MOI.PrimalStatus)
    if model.number_solved == 0
        return MOI.NO_SOLUTION
    end
    status = get_status(model.inner)
    if status == 0
        return MOI.FEASIBLE_POINT
    elseif -109 <= status <= -100
        return MOI.FEASIBLE_POINT
    elseif -209 <= status <= -200
        return MOI.INFEASIBLE_POINT
    elseif status == -300
        return MOI.INFEASIBILITY_CERTIFICATE
    elseif -409 <= status <= -400
        return MOI.FEASIBLE_POINT
    elseif -419 <= status <= -410
        return MOI.INFEASIBLE_POINT
    elseif -599 <= status <= -500
        return MOI.UNKNOWN_RESULT_STATUS
    else
        return MOI.UNKNOWN_RESULT_STATUS
    end
end

function MOI.get(model::Optimizer, ::MOI.DualStatus)
    if model.number_solved == 0
        return MOI.NO_SOLUTION
    end
    status = get_status(model.inner)
    if status == 0
        return MOI.FEASIBLE_POINT
    elseif -109 <= status <= -100
        return MOI.FEASIBLE_POINT
    elseif -209 <= status <= -200
        return MOI.INFEASIBILITY_CERTIFICATE
    elseif status == -300
        return MOI.NO_SOLUTION
    elseif -409 <= status <= -400
        return MOI.FEASIBLE_POINT
    elseif -419 <= status <= -410
        return MOI.INFEASIBLE_POINT
    elseif -599 <= status <= -500
        return MOI.UNKNOWN_RESULT_STATUS
    else
        return MOI.UNKNOWN_RESULT_STATUS
    end
end

function MOI.get(model::Optimizer, ::MOI.ObjectiveValue)
    if model.number_solved == 0
        error("ObjectiveValue not available.")
    end
    return get_objective(model.inner)
end

# TODO: This is a bit off, because the variable primal should be available
# only after a solve. If model.inner is initialized but we haven't solved, then
# the primal values we return do not have the intended meaning.
function MOI.get(model::Optimizer, ::MOI.VariablePrimal, vi::MOI.VariableIndex)
    if model.number_solved == 0
        error("VariablePrimal not available.")
    end
    check_inbounds(model, vi)
    return get_solution(model.inner)[vi.value]
end

function MOI.get(model::Optimizer, ::MOI.ConstraintPrimal, ci::MOI.ConstraintIndex)
    if model.number_solved == 0
        error("ConstraintPrimal not available.")
    end
    if !(0 <= ci.value <= number_constraints(model) - 1)
        error("Invalid constraint index ", ci.value)
    end
    g = KN_get_con_values(model.inner)
    index = model.constraint_mapping[ci] .+ 1
    return g[index]
end

function MOI.get(model::Optimizer, ::MOI.ConstraintPrimal,
                 ci::MOI.ConstraintIndex{MOI.SingleVariable,
                                         MOI.LessThan{Float64}})
    if model.number_solved == 0
        error("ConstraintPrimal not available.")
    end
    vi = MOI.VariableIndex(ci.value)
    check_inbounds(model, vi)
    if !has_upper_bound(model, vi)
        error("Variable $vi has no upper bound -- ConstraintPrimal not defined.")
    end
    x = get_solution(model.inner)
    return x[vi.value]
end

function MOI.get(model::Optimizer, ::MOI.ConstraintPrimal,
                 ci::MOI.ConstraintIndex{MOI.SingleVariable,
                                         MOI.GreaterThan{Float64}})
    if model.number_solved == 0
        error("ConstraintPrimal not available.")
    end
    vi = MOI.VariableIndex(ci.value)
    check_inbounds(model, vi)
    if !has_lower_bound(model, vi)
        error("Variable $vi has no lower bound -- ConstraintPrimal not defined.")
    end
    x = get_solution(model.inner)
    return x[vi.value]
end

function MOI.get(model::Optimizer, ::MOI.ConstraintPrimal,
                 ci::MOI.ConstraintIndex{MOI.SingleVariable,
                                         MOI.EqualTo{Float64}})
    if model.number_solved == 0
        error("ConstraintPrimal not available.")
    end
    vi = MOI.VariableIndex(ci.value)
    check_inbounds(model, vi)
    if !is_fixed(model, vi)
        error("Variable $vi is not fixed -- ConstraintPrimal not defined.")
    end
    x = get_solution(model.inner)
    return x[vi.value]
end

# KNITRO's dual sign depends on optimization sense
sense_dual(model::Optimizer) = (model.sense == MOI.MAX_SENSE) ? 1. : -1.

function MOI.get(model::Optimizer, ::MOI.ConstraintDual,
                 ci::MOI.ConstraintIndex{MOI.ScalarAffineFunction{Float64}, S}) where S <: SS
    if model.number_solved == 0
        error("ConstraintDual not available.")
    end
    @assert 0 <= ci.value <= number_constraints(model) - 1

    index = model.constraint_mapping[ci] + 1
    lambda = get_dual(model.inner)
    return sense_dual(model) * lambda[index]
end

## reduced costs
function MOI.get(model::Optimizer, ::MOI.ConstraintDual,
                 ci::MOI.ConstraintIndex{MOI.SingleVariable, MOI.LessThan{Float64}})
    if model.number_solved == 0
        error("ConstraintDual not available.")
    end
    vi = MOI.VariableIndex(ci.value)
    check_inbounds(model, vi)
    if !model.variable_info[vi.value].has_upper_bound
        error("Variable $vi has no upper bound -- ConstraintDual not defined.")
    end

    xsol = get_solution(model.inner)
    # TODO: is fixing a tolerance the best solution?
    if isapprox(xsol[vi.value], model.variable_info[vi.value].upper_bound, atol=1e-4)
        # constraints' duals are before reduced costs in KNITRO
        offset = number_constraints(model)
        lambda = get_dual(model.inner)
        return sense_dual(model) * lambda[vi.value + offset]
    else
        return 0.
    end
end

function MOI.get(model::Optimizer, ::MOI.ConstraintDual,
                 ci::MOI.ConstraintIndex{MOI.SingleVariable, MOI.GreaterThan{Float64}})
    if model.number_solved == 0
        error("ConstraintDual not available.")
    end
    vi = MOI.VariableIndex(ci.value)
    check_inbounds(model, vi)
    if !model.variable_info[vi.value].has_lower_bound
        error("Variable $vi has no lower bound -- ConstraintDual not defined.")
    end

    xsol = get_solution(model.inner)
    # TODO: is fixing a tolerance the best solution?
    if isapprox(xsol[vi.value], model.variable_info[vi.value].lower_bound, atol=1e-4)
        # constraints' duals are before reduced costs in KNITRO
        offset = number_constraints(model)
        lambda = get_dual(model.inner)
        return sense_dual(model) * lambda[vi.value + offset]
    else
        return 0.
    end
end

function MOI.get(model::Optimizer, ::MOI.ConstraintDual,
                 ci::MOI.ConstraintIndex{MOI.SingleVariable, MOI.EqualTo{Float64}})
    if model.number_solved == 0
        error("ConstraintDual not available.")
    end
    vi = MOI.VariableIndex(ci.value)
    check_inbounds(model, vi)
    if !model.variable_info[vi.value].is_fixed
        error("Variable $vi is not fixed -- ConstraintDual not defined.")
    end

    # constraints' duals are before reduced costs in KNITRO
    offset = number_constraints(model)
    lambda = get_dual(model.inner)
    return sense_dual(model) * lambda[vi.value + offset]
end

function MOI.get(model::Optimizer, ::MOI.NLPBlockDual)

    if model.number_solved == 0
        error("NLPBlockDual not available.")
    end

    # TODO: broken
    #= index = model.constraint_mapping[ci] + 1 =#
    lambda = get_dual(model.inner)
    # FIXME: assume that lambda has same sense as for linear
    # and quadratic constraint, but this is not tested inside MOI
    return sense_dual(model) * lambda[index]
end

##################################################
# Naming
##################################################
# WIP
function MOI.set(model::Optimizer, ::MOI.VariableName, vi::MOI.VariableIndex, name::String)
    model.variable_info[vi.value].name = name
end
