# MathOptInterface constraints

##################################################
## Support constraints
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

##################################################
## Getters
MOI.get(model::Optimizer, ::MOI.NumberOfConstraints{MOI.SingleVariable, MOI.ZeroOne}) =
    model.number_zeroone_constraints
# TODO: a bit hacky, but that should work for MOI Test.
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
    model.variable_info[vi.value].upper_bound = ub
    model.variable_info[vi.value].has_upper_bound = true
    # By construction, MOI's indexing is the same as KNITRO's indexing.
    KN_set_var_upbnds(model.inner, vi.value - 1, ub)
    return MOI.ConstraintIndex{MOI.SingleVariable, MOI.LessThan{Float64}}(vi.value)
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
    model.variable_info[vi.value].lower_bound = lb
    model.variable_info[vi.value].has_lower_bound = true
    # We assume that MOI's indexing is the same as KNITRO's indexing.
    KN_set_var_lobnds(model.inner, vi.value - 1, lb)
    return MOI.ConstraintIndex{MOI.SingleVariable, MOI.GreaterThan{Float64}}(vi.value)
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
    model.variable_info[vi.value].lower_bound = eqv
    model.variable_info[vi.value].upper_bound = eqv
    model.variable_info[vi.value].is_fixed = true
    # We assume that MOI's indexing is the same as KNITRO's indexing.
    KN_set_var_fxbnds(model.inner, vi.value - 1, eqv)
    return MOI.ConstraintIndex{MOI.SingleVariable, MOI.EqualTo{Float64}}(vi.value)
end

function MOI.add_constraint(model::Optimizer,
                            func::MOI.ScalarAffineFunction{Float64}, set::VS)
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
    ci = KN_add_con(model.inner)
    # Add upper bound.
    lb = check_value(set.lower)
    ub = check_value(set.upper)
    KN_set_con_lobnd(model.inner, ci, lb - func.constant)
    KN_set_con_upbnd(model.inner, ci, ub - func.constant)
    # Parse structure of constraint.
    indexvars, coefs = canonical_linear_reduction(func)
    KN_add_con_linear_struct(model.inner, ci, indexvars, coefs)
    # Add constraints to index.
    consi = MOI.ConstraintIndex{typeof(func), typeof(set)}(ci)
    model.constraint_mapping[consi] = ci
    return consi
end

function MOI.add_constraint(model::Optimizer,
                            func::MOI.ScalarQuadraticFunction{Float64}, set::VS)
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
    end
    # Parse linear structure of constraint.
    indexvars, coefs = canonical_linear_reduction(func)
    KN_add_con_linear_struct(model.inner, num_cons, indexvars, coefs)
    # Parse quadratic term.
    qvar1, qvar2, qcoefs = canonical_quadratic_reduction(func)
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
        # TODO
        error("Invalid set $set for VectorAffineFunction constraint")
    end
    # Add constraints to index.
    ci = MOI.ConstraintIndex{typeof(func), typeof(set)}(index_cons[1])
    model.constraint_mapping[ci] = index_cons
    return ci
end

function MOI.add_constraint(model::Optimizer,
                            func::MOI.VectorAffineFunction, set::MOI.SecondOrderCone)
    @warn("Support of MOI.SecondOrderCone is still experimental")
    (model.number_solved >= 1) && throw(AddConstraintError())
    # TODO: add check inbounds for VectorAffineFunction.
    previous_col_number = number_constraints(model)
    ncoords = length(func.constants)
    # Add constraints inside KNITRO.
    index_con = KN_add_con(model.inner)

    # Parse vector affine expression.
    indexcoords, indexvars, coefs = canonical_vector_affine_reduction(func)
    constants = func.constants
    # Load Second Order Conic constraint.
    KN_add_con_L2norm(model.inner, index_con, ncoords, length(indexcoords),
                  indexcoords, indexvars, coefs, constants)
    # Add constraints to index.
    ci = MOI.ConstraintIndex{typeof(func), typeof(set)}(index_con)
    model.constraint_mapping[ci] = index_con
    return ci
end

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
    if model.variable_info[indv + 1].has_lower_bound
        # Knitro automatically set the lowerbound to 0., except
        # if it is equal to 1.
        lobnd = model.variable_info[indv +1 ].lower_bound
    end
    upbnd = 1.
    if model.variable_info[indv + 1].has_upper_bound
        # Knitro automatically set the upperbound to 1., except
        # if it is equal to 0.
        upbnd = model.variable_info[indv +1 ].upper_bound
    end
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
function MOI.supports(::Optimizer, ::MOI.ConstraintDualStart,
                      ::Type{MOI.ConstraintIndex})
    return true
end
function MOI.set(model::Optimizer, ::MOI.ConstraintDualStart,
                 ci::MOI.ConstraintIndex, value::Union{Real, Nothing})
    check_inbounds(model, ci)
    if isa(value, Real)
        KN_set_con_dual_init_values(model.inner, vi.value - 1, Cdouble(value))
    else
        # By default, initial value is set to 0.
        KN_set_con_dual_init_values(model.inner, vi.value - 1, Cdouble(0.))
    end
    return
end

##################################################
## Constraint naming
# TODO: dry supports with macros.
MOI.supports(::Optimizer, ::MOI.ConstraintName, ::Type{MOI.ConstraintIndex}) = true
