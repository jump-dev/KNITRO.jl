# MathOptInterface constraints

##################################################
## Support constraints
MOI.supports_constraint(::Optimizer, ::Type{MOI.SingleVariable}, ::Type{MOI.ZeroOne}) = true
MOI.supports_constraint(::Optimizer, ::Type{MOI.SingleVariable}, ::Type{MOI.Integer}) = true
MOI.supports_constraint(::Optimizer, ::Type{MOI.SingleVariable}, ::Type{<:SS}) = true

MOI.supports_constraint(::Optimizer, ::Type{MOI.ScalarAffineFunction{Float64}}, ::Type{MOI.LessThan{Float64}}) = true
MOI.supports_constraint(::Optimizer, ::Type{MOI.ScalarAffineFunction{Float64}}, ::Type{MOI.GreaterThan{Float64}}) = true
MOI.supports_constraint(::Optimizer, ::Type{MOI.ScalarAffineFunction{Float64}}, ::Type{MOI.EqualTo{Float64}}) = true
MOI.supports_constraint(::Optimizer, ::Type{MOI.ScalarAffineFunction{Float64}}, ::Type{MOI.Interval{Float64}}) = true
MOI.supports_constraint(::Optimizer, ::Type{MOI.ScalarQuadraticFunction{Float64}}, ::Type{MOI.LessThan{Float64}}) = true
MOI.supports_constraint(::Optimizer, ::Type{MOI.ScalarQuadraticFunction{Float64}}, ::Type{MOI.GreaterThan{Float64}}) = true
MOI.supports_constraint(::Optimizer, ::Type{MOI.ScalarQuadraticFunction{Float64}}, ::Type{MOI.EqualTo{Float64}}) = true
MOI.supports_constraint(::Optimizer, ::Type{MOI.ScalarQuadraticFunction{Float64}}, ::Type{MOI.Interval{Float64}}) = true
MOI.supports_constraint(::Optimizer, ::Type{<:SF}, ::Type{<:SS}) = true
MOI.supports_constraint(::Optimizer, ::Type{VAF}, ::Type{<:VLS}) = true
MOI.supports_constraint(::Optimizer, ::Type{VOV}, ::Type{<:VLS}) = true
MOI.supports_constraint(::Optimizer, ::Type{VAF}, ::Type{MOI.SecondOrderCone}) = true
MOI.supports_constraint(::Optimizer, ::Type{VOV}, ::Type{MOI.SecondOrderCone}) = true
MOI.supports_constraint(::Optimizer, ::Type{VOV}, ::Type{MOI.Complements}) = true
MOI.supports_constraint(::Optimizer, ::Type{VAF}, ::Type{MOI.Complements}) = true

##################################################
## Getters
MOI.get(model::Optimizer, ::MOI.NumberOfConstraints) =
    KN_get_number_cons(model.inner)
MOI.get(model::Optimizer, ::MOI.NumberOfConstraints{MOI.SingleVariable, MOI.ZeroOne}) =
    model.number_zeroone_constraints
MOI.get(model::Optimizer, ::MOI.NumberOfConstraints{MOI.SingleVariable, MOI.Integer}) =
    model.number_integer_constraints
MOI.get(model::Optimizer, ::MOI.NumberOfConstraints{MOI.SingleVariable, S}) where S <: LS =
    sum(typeof.(collect(keys(model.constraint_mapping))) .== MOI.ConstraintIndex{MOI.SingleVariable, S})
# TODO: a bit hacky, but that should work for MOI Test.
MOI.get(model::Optimizer, ::MOI.NumberOfConstraints{VAF, MOI.Nonnegatives}) =
    sum(typeof.(collect(keys(model.constraint_mapping))) .== MOI.ConstraintIndex{VAF, MOI.Nonnegatives})
MOI.get(model::Optimizer, ::MOI.NumberOfConstraints{VAF, MOI.Nonpositives}) =
    sum(typeof.(collect(keys(model.constraint_mapping))) .== MOI.ConstraintIndex{VAF, MOI.Nonpositives})
MOI.get(model::Optimizer, ::MOI.NumberOfConstraints{VAF, MOI.Zeros}) =
    sum(typeof.(collect(keys(model.constraint_mapping))) .== MOI.ConstraintIndex{VAF, MOI.Zeros})
MOI.get(model::Optimizer, ::MOI.NumberOfConstraints{VAF, MOI.SecondOrderCone}) =
    sum(typeof.(collect(keys(model.constraint_mapping))) .== MOI.ConstraintIndex{VAF, MOI.SecondOrderCone})
MOI.get(model::Optimizer, ::MOI.NumberOfConstraints{VOV, T}) where T <: VLS =
    sum(typeof.(collect(keys(model.constraint_mapping))) .== MOI.ConstraintIndex{VOV, T})
MOI.get(model::Optimizer, ::MOI.NumberOfConstraints{MOI.ScalarAffineFunction{Float64}, S}) where S <: LS  =
    sum(typeof.(collect(keys(model.constraint_mapping))) .== MOI.ConstraintIndex{MOI.ScalarAffineFunction{Float64}, S})
MOI.get(model::Optimizer, ::MOI.NumberOfConstraints{MOI.ScalarQuadraticFunction{Float64}, S}) where S <: LS  =
    sum(typeof.(collect(keys(model.constraint_mapping))) .== MOI.ConstraintIndex{MOI.ScalarQuadraticFunction{Float64}, S})

##################################################
# Generic constraint definition
#--------------------------------------------------
# Bound constraint on variables.
function MOI.add_constraint(model::Optimizer,
                            v::MOI.SingleVariable, lt::MOI.LessThan{Float64})
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
    model.variable_info[vi.value].has_upper_bound = true
    # By construction, MOI's indexing is the same as KNITRO's indexing.
    KN_set_var_upbnds(model.inner, vi.value - 1, ub)
    ci = MOI.ConstraintIndex{MOI.SingleVariable, MOI.LessThan{Float64}}(vi.value)
    model.constraint_mapping[ci] = convert(Cint, vi.value)
    return ci
end

function MOI.add_constraint(model::Optimizer,
                            v::MOI.SingleVariable, gt::MOI.GreaterThan{Float64})
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
    model.variable_info[vi.value].has_lower_bound = true
    # We assume that MOI's indexing is the same as KNITRO's indexing.
    KN_set_var_lobnds(model.inner, vi.value - 1, lb)
    ci = MOI.ConstraintIndex{MOI.SingleVariable, MOI.GreaterThan{Float64}}(vi.value)
    model.constraint_mapping[ci] = convert(Cint, vi.value)
    return ci
end

function MOI.add_constraint(model::Optimizer,
                            v::MOI.SingleVariable, set::MOI.Interval{Float64})
    (model.number_solved >= 1) && throw(AddConstraintError())
    vi = v.variable
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
    KN_set_var_lobnds(model.inner, vi.value - 1, lb)
    KN_set_var_upbnds(model.inner, vi.value - 1, ub)
    ci = MOI.ConstraintIndex{MOI.SingleVariable, MOI.Interval{Float64}}(vi.value)
    model.constraint_mapping[ci] = convert(Cint, vi.value)
    return ci
end

function MOI.add_constraint(model::Optimizer,
                            v::MOI.SingleVariable, eq::MOI.EqualTo{Float64})
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
    model.variable_info[vi.value].is_fixed = true
    # We assume that MOI's indexing is the same as KNITRO's indexing.
    KN_set_var_fxbnds(model.inner, vi.value - 1, eqv)
    ci = MOI.ConstraintIndex{MOI.SingleVariable, MOI.EqualTo{Float64}}(vi.value)
    model.constraint_mapping[ci] = convert(Cint, vi.value)
    return ci
end

function MOI.add_constraint(model::Optimizer,
                            func::MOI.ScalarAffineFunction{Float64}, set::LS)
    (model.number_solved >= 1) && throw(AddConstraintError())
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
    end
    # Parse structure of constraint.
    indexvars, coefs = canonical_linear_reduction(func)
    KN_add_con_linear_struct(model.inner, num_cons, indexvars, coefs)
    # Add constraint to index.
    ci = MOI.ConstraintIndex{typeof(func), typeof(set)}(num_cons)
    model.constraint_mapping[ci] = num_cons
    return ci
end

function MOI.add_constraint(model::Optimizer,
                            func::MOI.ScalarAffineFunction{Float64}, set::MOI.Interval{Float64})
    (model.number_solved >= 1) && throw(AddConstraintError())
    check_inbounds(model, func)
    # Add a single constraint in KNITRO.
    num_cons = KN_add_con(model.inner)
    # Add upper bound.
    lb = check_value(set.lower)
    ub = check_value(set.upper)
    KN_set_con_lobnd(model.inner, num_cons, lb - func.constant)
    KN_set_con_upbnd(model.inner, num_cons, ub - func.constant)
    # Parse structure of constraint.
    indexvars, coefs = canonical_linear_reduction(func)
    KN_add_con_linear_struct(model.inner, num_cons, indexvars, coefs)
    # Add constraints to index.
    consi = MOI.ConstraintIndex{typeof(func), typeof(set)}(num_cons)
    model.constraint_mapping[consi] = num_cons
    return consi
end

function MOI.add_constraint(model::Optimizer,
                            func::MOI.ScalarQuadraticFunction{Float64}, set::SS)
    (model.number_solved >= 1) && throw(AddConstraintError())
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
    ci = MOI.ConstraintIndex{typeof(func), typeof(set)}(num_cons)
    model.constraint_mapping[ci] = num_cons
    return ci
end

function MOI.add_constraint(model::Optimizer,
                            func::MOI.VectorAffineFunction, set::MOI.AbstractVectorSet)
    (model.number_solved >= 1) && throw(AddConstraintError())
    # TODO: add check inbounds for VectorAffineFunction.
    previous_col_number = number_constraints(model)
    num_cols = length(func.constants)
    # Add constraints inside KNITRO.
    index_cons = KN_add_cons(model.inner, num_cols)

    # Parse vector affine expression.
    indexcols, indexvars, coefs = canonical_vector_affine_reduction(func)
    # Reformate indexcols with current numbering.
    indexcols .+= previous_col_number

    # Load inside KNITRO.
    KN_add_con_linear_struct(model.inner, indexcols, indexvars, coefs)
    if isa(set, MOI.Nonnegatives)
        KN_set_con_lobnds(model.inner, index_cons, - func.constants)
    elseif isa(set, MOI.Nonpositives)
        KN_set_con_upbnds(model.inner, index_cons, - func.constants)
    elseif isa(set, MOI.Zeros)
        KN_set_con_eqbnds(model.inner, index_cons, - func.constants)
    else
        error("Invalid set $set for VectorAffineFunction constraint")
    end
    # Add constraints to index.
    ci = MOI.ConstraintIndex{typeof(func), typeof(set)}(index_cons[1])
    model.constraint_mapping[ci] = index_cons
    return ci
end

# Add second order cone constraint.
function MOI.add_constraint(model::Optimizer,
                            func::MOI.VectorAffineFunction, set::MOI.SecondOrderCone)
    (model.number_solved >= 1) && throw(AddConstraintError())
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
    KN_add_con_linear_struct(model.inner, index_con,
                             indexvars[indlinear], -coefs[indlinear])

    ## ii) soc part
    index_var_cone = indexvars[indcone]
    nnz = length(index_var_cone)
    index_coord_cone = convert.(Cint, indexcoords[indcone] .- 1)
    coefs_cone = coefs[indcone]
    const_cone = constants[2:end]

    KN_add_con_L2norm(model.inner,
                      index_con, ncoords, nnz,
                      index_coord_cone,
                      index_var_cone,
                      coefs_cone,
                      const_cone)

    # set specific Knitro's params
    KN_set_param(model.inner, KN_PARAM_BAR_CONIC_ENABLE, KN_BAR_CONIC_ENABLE_SOC)
    KN_set_param(model.inner, KN_PARAM_ALGORITHM, KN_ALG_BAR_DIRECT)
    KN_set_param(model.inner, KN_PARAM_BAR_MURULE, KN_BAR_MURULE_FULLMPC)

    # Add constraints to index.
    ci = MOI.ConstraintIndex{typeof(func), typeof(set)}(index_con)
    model.constraint_mapping[ci] = indexvars
    return ci
end

function MOI.add_constraint(model::Optimizer, func::VOV, set::T) where T <: VLS
    (model.number_solved >= 1) && throw(AddConstraintError())
    indv = convert.(Cint, [v.value for v in func.variables] .- 1)
    bnd = zeros(Float64, length(indv))

    if isa(set, MOI.Zeros)
        KN_set_var_fxbnds(model.inner, indv, bnd)
    elseif isa(set, MOI.Nonnegatives)
        KN_set_var_lobnds(model.inner, indv, bnd)
    elseif isa(set, MOI.Nonpositives)
        KN_set_var_upbnds(model.inner, indv, bnd)
    end

    # TODO
    ncons = MOI.get(model, MOI.NumberOfConstraints{VOV, T}())
    ci = MOI.ConstraintIndex{VOV, T}(ncons)
    model.constraint_mapping[ci] = indv
    return ci
end

function MOI.add_constraint(model::Optimizer,
                            func::MOI.VectorOfVariables, set::MOI.SecondOrderCone)
    (model.number_solved >= 1) && throw(AddConstraintError())
    # Add constraints inside KNITRO.
    index_con = KN_add_con(model.inner)
    indv = [v.value - 1 for v in func.variables]

    KN_set_con_upbnd(model.inner, index_con, 0.)
    KN_add_con_linear_struct(model.inner, index_con, indv[1], -1.0)

    indexVars = convert.(Cint, indv[2:end])
    nnz = length(indexVars)
    indexCoords = Cint[i for i in 0:(nnz-1)]
    coefs = ones(Float64, nnz)
    constants = zeros(Float64, nnz)

    KN_add_con_L2norm(model.inner, index_con, nnz, nnz,
                      indexCoords, indexVars, coefs, constants)

    KN_set_param(model.inner, KN_PARAM_BAR_CONIC_ENABLE, KN_BAR_CONIC_ENABLE_SOC)
    KN_set_param(model.inner, KN_PARAM_ALGORITHM, KN_ALG_BAR_DIRECT)
    KN_set_param(model.inner, KN_PARAM_BAR_MURULE, KN_BAR_MURULE_FULLMPC)

    # Add constraints to index.
    ci = MOI.ConstraintIndex{typeof(func), typeof(set)}(index_con)
    model.constraint_mapping[ci] = convert.(Cint, indv)
    return ci
end


##################################################
## Binary & Integer constraints.

# Define integer and boolean constraints.
function MOI.add_constraint(model::Optimizer,
                            v::MOI.SingleVariable, ::MOI.ZeroOne)
    vi = v.variable
    indv = vi.value - 1
    check_inbounds(model, vi)
    model.number_zeroone_constraints += 1
    # Made the bounds explicit for KNITRO and take care of
    # preexisting MOI's bounds.
    lobnd = 0.
    upbnd = 1.
    KN_set_var_lobnds(model.inner, indv, lobnd)
    KN_set_var_upbnds(model.inner, indv, upbnd)
    KN_set_var_type(model.inner, vi.value - 1, KN_VARTYPE_BINARY)

    return MOI.ConstraintIndex{MOI.SingleVariable, MOI.ZeroOne}(model.number_zeroone_constraints)
end

function MOI.add_constraint(model::Optimizer,
                            v::MOI.SingleVariable, ::MOI.Integer)
    (model.number_solved >= 1) && throw(AddConstraintError())
    vi = v.variable
    check_inbounds(model, vi)
    model.number_integer_constraints += 1
    KN_set_var_type(model.inner, vi.value - 1, KN_VARTYPE_INTEGER)
    return MOI.ConstraintIndex{MOI.SingleVariable, MOI.Integer}(model.number_integer_constraints)
end


##################################################
## Constraint DualStart
function MOI.supports(::Optimizer,
                      ::MOI.ConstraintDualStart,
                      ::MOI.ConstraintIndex{<:SF, <:SS})
    return true
end
function MOI.set(model::Optimizer,
                 ::MOI.ConstraintDualStart,
                 ci::MOI.ConstraintIndex{<:SF,<:SS},
                 value::Union{Real, Nothing})
    if isa(value, Real)
        KN_set_con_dual_init_values(model.inner, ci.value, Cdouble(value))
    else
        # By default, initial value is set to 0.
        KN_set_con_dual_init_values(model.inner, ci.value, Cdouble(0.0))
    end
    return
end

function MOI.supports(::Optimizer,
                      ::MOI.ConstraintDualStart,
                      ::MOI.ConstraintIndex{MOI.SingleVariable, <:LS})
    return true
end
function MOI.set(model::Optimizer,
                 ::MOI.ConstraintDualStart,
                 ci::MOI.ConstraintIndex{MOI.SingleVariable, <:LS},
                 value::Union{Real, Nothing})
    if isa(value, Real)
        KN_set_var_dual_init_values(model.inner, ci.value, Cdouble(value))
    else
        # By default, initial value is set to 0.
        KN_set_var_dual_init_values(model.inner, ci.value, Cdouble(0.0))
    end
    return
end

##################################################
## Constraint naming
# TODO: dry supports with macros.
MOI.supports(::Optimizer, ::MOI.ConstraintName, ::Type{MOI.ConstraintIndex}) = true
