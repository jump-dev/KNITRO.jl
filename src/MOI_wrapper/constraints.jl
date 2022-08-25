# Copyright (c) 2016: Ng Yee Sian, Miles Lubin, other contributors
#
# Use of this source code is governed by an MIT-style license that can be found
# in the LICENSE.md file or at https://opensource.org/licenses/MIT.

function MOI.supports_constraint(
    ::Optimizer,
    ::Type{MOI.VariableIndex},
    ::Type{
        <:Union{
            MOI.EqualTo{Float64},
            MOI.GreaterThan{Float64},
            MOI.LessThan{Float64},
            MOI.Interval{Float64},
            MOI.ZeroOne,
            MOI.Integer,
        },
    },
)
    return true
end

function MOI.supports_constraint(
    ::Optimizer,
    ::Type{<:Union{MOI.ScalarAffineFunction{Float64},MOI.ScalarQuadraticFunction{Float64}}},
    ::Type{
        <:Union{
            MOI.LessThan{Float64},
            MOI.GreaterThan{Float64},
            MOI.EqualTo{Float64},
            MOI.Interval{Float64},
        },
    },
)
    return true
end

function MOI.supports_constraint(
    ::Optimizer,
    ::Type{MOI.VectorAffineFunction{Float64}},
    ::Type{MOI.SecondOrderCone},
)
    return true
end

function MOI.supports_constraint(
    ::Optimizer,
    ::Type{MOI.VectorOfVariables},
    ::Type{MOI.SecondOrderCone},
)
    return true
end

##################################################
# TODO: clean getters
## Getters
MOI.get(model::Optimizer, ::MOI.NumberOfConstraints) = KN_get_number_cons(model.inner)

function MOI.get(model::Optimizer, ::MOI.NumberOfConstraints{MOI.VariableIndex,MOI.ZeroOne})
    return model.number_zeroone_constraints
end
function MOI.get(model::Optimizer, ::MOI.NumberOfConstraints{MOI.VariableIndex,MOI.Integer})
    return model.number_integer_constraints
end
function MOI.get(
    model::Optimizer,
    ::MOI.NumberOfConstraints{MOI.VariableIndex,S},
) where {
    S<:Union{
        MOI.EqualTo{Float64},
        MOI.GreaterThan{Float64},
        MOI.LessThan{Float64},
        MOI.Interval{Float64},
    },
}
    return sum(
        typeof.(collect(keys(model.constraint_mapping))) .==
        MOI.ConstraintIndex{MOI.VariableIndex,S},
    )
end

function MOI.get(
    model::Optimizer,
    ::MOI.NumberOfConstraints{MOI.VectorAffineFunction{Float64},MOI.SecondOrderCone},
)
    return sum(
        typeof.(collect(keys(model.constraint_mapping))) .==
        MOI.ConstraintIndex{MOI.VectorAffineFunction{Float64},MOI.SecondOrderCone},
    )
end

function MOI.get(
    model::Optimizer,
    ::MOI.NumberOfConstraints{MOI.ScalarAffineFunction{Float64},S},
) where {S<:Union{MOI.EqualTo{Float64},MOI.GreaterThan{Float64},MOI.LessThan{Float64}}}
    return sum(
        typeof.(collect(keys(model.constraint_mapping))) .==
        MOI.ConstraintIndex{MOI.ScalarAffineFunction{Float64},S},
    )
end
function MOI.get(
    model::Optimizer,
    ::MOI.NumberOfConstraints{MOI.ScalarQuadraticFunction{Float64},S},
) where {S<:Union{MOI.EqualTo{Float64},MOI.GreaterThan{Float64},MOI.LessThan{Float64}}}
    return sum(
        typeof.(collect(keys(model.constraint_mapping))) .==
        MOI.ConstraintIndex{MOI.ScalarQuadraticFunction{Float64},S},
    )
end

###
### MOI.VariableIndex -in- LessThan
###

function MOI.is_valid(
    model::Optimizer,
    ci::MOI.ConstraintIndex{MOI.VariableIndex,MOI.LessThan{Float64}},
)
    return model.variable_info[ci.value].has_upper_bound
end

function MOI.add_constraint(
    model::Optimizer,
    vi::MOI.VariableIndex,
    lt::MOI.LessThan{Float64},
)
    if model.number_solved >= 1
        throw(
            MOI.AddConstraintNotAllowed{typeof(vi),typeof(lt)}(
                "Constraints cannot be added after a call to optimize!.",
            ),
        )
    end
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
    model.variable_info[vi.value].has_upper_bound = true
    # By construction, MOI's indexing is the same as KNITRO's indexing.
    KN_set_var_upbnd(model.inner, vi.value - 1, ub)
    ci = MOI.ConstraintIndex{MOI.VariableIndex,MOI.LessThan{Float64}}(vi.value)
    model.constraint_mapping[ci] = convert(Cint, vi.value)
    return ci
end

###
### MOI.VariableIndex -in- GreaterThan
###

function MOI.is_valid(
    model::Optimizer,
    ci::MOI.ConstraintIndex{MOI.VariableIndex,MOI.GreaterThan{Float64}},
)
    return model.variable_info[ci.value].has_lower_bound
end

function MOI.add_constraint(
    model::Optimizer,
    vi::MOI.VariableIndex,
    gt::MOI.GreaterThan{Float64},
)
    if model.number_solved >= 1
        throw(
            MOI.AddConstraintNotAllowed{typeof(vi),typeof(gt)}(
                "Constraints cannot be added after a call to optimize!.",
            ),
        )
    end
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
    model.variable_info[vi.value].has_lower_bound = true
    # We assume that MOI's indexing is the same as KNITRO's indexing.
    KN_set_var_lobnd(model.inner, vi.value - 1, lb)
    ci = MOI.ConstraintIndex{MOI.VariableIndex,MOI.GreaterThan{Float64}}(vi.value)
    model.constraint_mapping[ci] = convert(Cint, vi.value)
    return ci
end

###
### MOI.VariableIndex -in- Interval
###

function MOI.is_valid(
    model::Optimizer,
    ci::MOI.ConstraintIndex{MOI.VariableIndex,MOI.Interval{Float64}},
)
    return model.variable_info[ci.value].has_lower_bound &&
           model.variable_info[ci.value].has_upper_bound
end

function MOI.add_constraint(
    model::Optimizer,
    vi::MOI.VariableIndex,
    set::MOI.Interval{Float64},
)
    if model.number_solved >= 1
        throw(
            MOI.AddConstraintNotAllowed{typeof(vi),typeof(set)}(
                "Constraints cannot be added after a call to optimize!.",
            ),
        )
    end
    check_inbounds(model, vi)
    if isnan(set.lower) || isnan(set.upper)
        error("Invalid lower bound value $(set.lower).")
    end
    if has_lower_bound(model, vi) || has_upper_bound(model, vi)
        error("Bounds on variable $vi already exists.")
    end
    if is_fixed(model, vi)
        error("Variable $vi is fixed. Cannot also set lower bound.")
    end
    lb = check_value(set.lower)
    ub = check_value(set.upper)
    model.variable_info[vi.value].has_lower_bound = true
    model.variable_info[vi.value].has_upper_bound = true
    # We assume that MOI's indexing is the same as KNITRO's indexing.
    KN_set_var_lobnd(model.inner, vi.value - 1, lb)
    KN_set_var_upbnd(model.inner, vi.value - 1, ub)
    ci = MOI.ConstraintIndex{MOI.VariableIndex,MOI.Interval{Float64}}(vi.value)
    model.constraint_mapping[ci] = convert(Cint, vi.value)
    return ci
end

###
### MOI.VariableIndex -in- EqualTo
###

function MOI.is_valid(
    model::Optimizer,
    ci::MOI.ConstraintIndex{MOI.VariableIndex,MOI.EqualTo{Float64}},
)
    return model.variable_info[ci.value].is_fixed
end

function MOI.add_constraint(
    model::Optimizer,
    vi::MOI.VariableIndex,
    eq::MOI.EqualTo{Float64},
)
    if model.number_solved >= 1
        throw(
            MOI.AddConstraintNotAllowed{typeof(vi),typeof(eq)}(
                "Constraints cannot be added after a call to optimize!.",
            ),
        )
    end
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
    model.variable_info[vi.value].is_fixed = true
    # We assume that MOI's indexing is the same as KNITRO's indexing.
    KN_set_var_fxbnd(model.inner, vi.value - 1, eqv)
    ci = MOI.ConstraintIndex{MOI.VariableIndex,MOI.EqualTo{Float64}}(vi.value)
    model.constraint_mapping[ci] = convert(Cint, vi.value)
    return ci
end

###
### ConstraintDualStart :: VariableIndex -in- {LessThan,GreaterThan,EqualTo,Interval}
###

function MOI.supports(
    ::Optimizer,
    ::MOI.ConstraintDualStart,
    ::MOI.ConstraintIndex{
        MOI.VariableIndex,
        <:Union{MOI.EqualTo{Float64},MOI.GreaterThan{Float64},MOI.LessThan{Float64}},
    },
)
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
    start = something(value, 0.0)
    KN_set_var_dual_init_values(model.inner, ci.value, Cdouble(start))
    return
end

###
### MOI.VariableIndex -in- ZeroOne
###

function MOI.add_constraint(model::Optimizer, vi::MOI.VariableIndex, ::MOI.ZeroOne)
    indv = vi.value - 1
    check_inbounds(model, vi)
    model.number_zeroone_constraints += 1
    lb = KN_get_var_lobnd(model.inner, indv)
    ub = KN_get_var_upbnd(model.inner, indv)
    KN_set_var_type(model.inner, vi.value - 1, KN_VARTYPE_BINARY)
    KN_set_var_lobnd(model.inner, indv, max(lb, 0.0))
    KN_set_var_upbnd(model.inner, indv, min(ub, 1.0))
    return MOI.ConstraintIndex{MOI.VariableIndex,MOI.ZeroOne}(vi.value)
end

###
### MOI.VariableIndex -in- Integer
###

function MOI.add_constraint(model::Optimizer, vi::MOI.VariableIndex, set::MOI.Integer)
    if model.number_solved >= 1
        throw(
            MOI.AddConstraintNotAllowed{typeof(vi),typeof(set)}(
                "Constraints cannot be added after a call to optimize!.",
            ),
        )
    end
    check_inbounds(model, vi)
    model.number_integer_constraints += 1
    KN_set_var_type(model.inner, vi.value - 1, KN_VARTYPE_INTEGER)
    return MOI.ConstraintIndex{MOI.VariableIndex,MOI.Integer}(vi.value)
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
    if model.number_solved >= 1
        throw(
            MOI.AddConstraintNotAllowed{typeof(func),typeof(set)}(
                "Constraints cannot be added after a call to optimize!.",
            ),
        )
    end
    check_inbounds(model, func)
    # Add a single constraint in KNITRO.
    num_cons = KN_add_con(model.inner)
    # Add bound to constraint.
    if isa(set, MOI.LessThan{Float64})
        val = check_value(set.upper)
        KN_set_con_upbnd(model.inner, num_cons, val - func.constant)
    elseif isa(set, MOI.GreaterThan{Float64})
        val = check_value(set.lower)
        KN_set_con_lobnd(model.inner, num_cons, val - func.constant)
    elseif isa(set, MOI.EqualTo{Float64})
        val = check_value(set.value)
        KN_set_con_eqbnd(model.inner, num_cons, val - func.constant)
    else
        @assert set isa MOI.Interval{Float64}
        # Add upper bound.
        lb, ub = check_value(set.lower), check_value(set.upper)
        KN_set_con_lobnd(model.inner, num_cons, lb - func.constant)
        KN_set_con_upbnd(model.inner, num_cons, ub - func.constant)
    end
    # Parse structure of constraint.
    indexvars, coefs = canonical_linear_reduction(func)
    KN_add_con_linear_struct(model.inner, num_cons, indexvars, coefs)
    # Add constraint to index.
    ci = MOI.ConstraintIndex{typeof(func),typeof(set)}(num_cons)
    model.constraint_mapping[ci] = num_cons
    return ci
end

function MOI.supports(
    ::Optimizer,
    ::MOI.ConstraintDualStart,
    ::MOI.ConstraintIndex{
        MOI.ScalarAffineFunction{Float64},
        <:Union{
            MOI.EqualTo{Float64},
            MOI.GreaterThan{Float64},
            MOI.LessThan{Float64},
            MOI.Interval{Float64},
        },
    },
)
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
    start = something(value, 0.0)
    KN_set_con_dual_init_values(model.inner, ci.value, Cdouble(start))
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
    if model.number_solved >= 1
        throw(
            MOI.AddConstraintNotAllowed{typeof(func),typeof(set)}(
                "Constraints cannot be added after a call to optimize!.",
            ),
        )
    end
    check_inbounds(model, func)
    # We add a constraint in KNITRO.
    num_cons = KN_add_con(model.inner)
    # Add upper bound.
    if isa(set, MOI.LessThan{Float64})
        val = check_value(set.upper)
        KN_set_con_upbnd(model.inner, num_cons, val - func.constant)
    elseif isa(set, MOI.GreaterThan{Float64})
        val = check_value(set.lower)
        KN_set_con_lobnd(model.inner, num_cons, val - func.constant)
    elseif isa(set, MOI.EqualTo{Float64})
        val = check_value(set.value)
        KN_set_con_eqbnd(model.inner, num_cons, val - func.constant)
    elseif isa(set, MOI.Interval{Float64})
        lb = check_value(set.lower)
        ub = check_value(set.upper)
        KN_set_con_lobnd(model.inner, num_cons, lb - func.constant)
        KN_set_con_upbnd(model.inner, num_cons, ub - func.constant)
    end
    # Parse linear structure of constraint.
    indexvars, coefs = canonical_linear_reduction(func)
    KN_add_con_linear_struct(model.inner, num_cons, indexvars, coefs)
    # Parse quadratic term.
    qvar1, qvar2, qcoefs = canonical_quadratic_reduction(func)
    # Take care that Knitro is 0-indexed!
    qvar1 .= qvar1 .- 1
    qvar2 .= qvar2 .- 1
    KN_add_con_quadratic_struct(model.inner, num_cons, qvar1, qvar2, qcoefs)
    # Add constraints to index.
    ci = MOI.ConstraintIndex{typeof(func),typeof(set)}(num_cons)
    model.constraint_mapping[ci] = num_cons
    return ci
end

function MOI.supports(
    ::Optimizer,
    ::MOI.ConstraintDualStart,
    ::MOI.ConstraintIndex{
        MOI.ScalarQuadraticFunction{Float64},
        <:Union{
            MOI.EqualTo{Float64},
            MOI.GreaterThan{Float64},
            MOI.LessThan{Float64},
            MOI.Interval{Float64},
        },
    },
)
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
    start = something(value, 0.0)
    KN_set_con_dual_init_values(model.inner, ci.value, Cdouble(start))
    return
end

###
### MOI.VectorAffineFunction -in- SecondOrderCone
###

function MOI.add_constraint(
    model::Optimizer,
    func::MOI.VectorAffineFunction,
    set::MOI.SecondOrderCone,
)
    if model.number_solved >= 1
        throw(
            MOI.AddConstraintNotAllowed{typeof(func),typeof(set)}(
                "Constraints cannot be added after a call to optimize!.",
            ),
        )
    end
    # Add constraints inside KNITRO.
    index_con = KN_add_con(model.inner)

    # Parse vector affine expression.
    indexcoords, indexvars, coefs = canonical_vector_affine_reduction(func)
    constants = func.constants
    # Distinct two parts of secondordercone.
    # First row corresponds to linear part of SOC.
    indlinear = indexcoords .== 0
    indcone = indexcoords .!= 0
    ncoords = length(constants) - 1
    @assert ncoords == set.dimension - 1

    # Load Second Order Conic constraint.
    ## i) linear part
    KN_set_con_upbnd(model.inner, index_con, constants[1])
    KN_add_con_linear_struct(
        model.inner,
        index_con,
        indexvars[indlinear],
        -coefs[indlinear],
    )

    ## ii) soc part
    index_var_cone = indexvars[indcone]
    nnz = length(index_var_cone)
    index_coord_cone = convert.(Cint, indexcoords[indcone] .- 1)
    coefs_cone = coefs[indcone]
    const_cone = constants[2:end]

    KN_add_con_L2norm(
        model.inner,
        index_con,
        ncoords,
        nnz,
        index_coord_cone,
        index_var_cone,
        coefs_cone,
        const_cone,
    )

    # Add constraints to index.
    ci = MOI.ConstraintIndex{typeof(func),typeof(set)}(index_con)
    model.constraint_mapping[ci] = indexvars
    return ci
end

###
### MOI.VectorOfVariables -in- SecondOrderCone
###

function MOI.add_constraint(
    model::Optimizer,
    func::MOI.VectorOfVariables,
    set::MOI.SecondOrderCone,
)
    if model.number_solved >= 1
        throw(
            MOI.AddConstraintNotAllowed{typeof(func),typeof(set)}(
                "Constraints cannot be added after a call to optimize!.",
            ),
        )
    end
    # Add constraints inside KNITRO.
    index_con = KN_add_con(model.inner)
    indv = [v.value - 1 for v in func.variables]
    KN_set_con_upbnd(model.inner, index_con, 0.0)
    KN_add_con_linear_struct(model.inner, index_con, indv[1], -1.0)
    indexVars = convert.(Cint, indv[2:end])
    nnz = length(indexVars)
    indexCoords = Cint[i for i in 0:(nnz-1)]
    coefs = ones(Float64, nnz)
    constants = zeros(Float64, nnz)
    KN_add_con_L2norm(
        model.inner,
        index_con,
        nnz,
        nnz,
        indexCoords,
        indexVars,
        coefs,
        constants,
    )
    # Add constraints to index.
    ci = MOI.ConstraintIndex{typeof(func),typeof(set)}(index_con)
    model.constraint_mapping[ci] = convert.(Cint, indv)
    return ci
end
