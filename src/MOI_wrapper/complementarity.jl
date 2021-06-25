# Complementarity constraints (M x + b  complements x)
# As Knitro supports only complementarity constraints between variables,
# we reformulate it by adding auxiliary variables:
#
# x_aux = Mx + b
# (x_aux complements x)
#
function MOI.add_constraint(model::Optimizer,
                            func::MOI.VectorAffineFunction, set::MOI.Complements)
    (model.number_solved >= 1) && throw(AddConstraintError())

    # Number of complementarity in Knitro is half the dimension of the MOI set
    n_comp = div(set.dimension, 2)

    # Add auxiliary variables `x_aux`.
    x_aux = KN_add_vars(model.inner, n_comp)

    # Add new constraints in Knitro to formulate x_aux = Mx + b
    n_cons = KN_add_cons(model.inner, n_comp)
    offset = n_cons[1]

    # Parse VectorAffineFunction defining the complementarity constraints
    indexcoords, indexvars, coefs = canonical_vector_affine_reduction(func)

    # Convert VectorAffineFunction in Knitro format
    x_comp = Cint[]
    jac_cons = Cint[]
    jac_vars = Cint[]
    jac_coefs = Cdouble[]
    for (c, v, f) in zip(indexcoords, indexvars, coefs)
        # By convention, if c is greater than the dimension of
        # the complementarity constraint set, then it specifies
        # the complementarity variable `x`.
        if c >= n_comp
            push!(x_comp, v)
        else
            # Otherwise, the index corresponds to one of the matrix `M`.
            # Add it to the Jacobian structure of the problem.
            push!(jac_cons, c + offset)
            push!(jac_vars, v)
            push!(jac_coefs, f)
        end
    end
    # Add the index corresponding to `x_aux` in the Jacobian.
    for (icons, ivar) in zip(n_cons, x_aux)
        push!(jac_cons, icons)
        push!(jac_vars, ivar)
        push!(jac_coefs, -1.0)
    end
    # Get constant structure
    q = func.constants[1:n_comp]

    # Add structure of new constaints to Knitro.
    KN_add_con_linear_struct(model.inner, jac_cons, jac_vars, jac_coefs)
    KN_set_con_eqbnds(model.inner, n_cons, -q)

    # Currently, only complementarity constraints between two variables
    # are supported.
    comp_type = fill(KN_CCTYPE_VARVAR, n_comp)

    # Number of complementarity constraint previously added
    n_comp_cons = model.complementarity_cache.n
    _add_complementarity_constraint!(
        model.complementarity_cache,
        x_comp,
        x_aux,
        comp_type,
    )

    return MOI.ConstraintIndex{typeof(func), typeof(set)}(n_comp_cons)
end

# Complementarity constraints (x_1 complements x_2), with x_1 and x_2
# being two variables of the problem.
function MOI.add_constraint(model::Optimizer,
                            func::MOI.VectorOfVariables, set::MOI.Complements)
    (model.number_solved >= 1) && throw(AddConstraintError())
    indv = Cint[v.value - 1 for v in func.variables]

    # Number of complementarity in Knitro is half the dimension of the MOI set
    n_comp = div(set.dimension, 2)
    # Currently, only complementarity constraints between two variables
    # are supported.
    comp_type = fill(KN_CCTYPE_VARVAR, n_comp)

    # Number of complementarity constraint previously added
    n_comp_cons = model.complementarity_cache.n

    _add_complementarity_constraint!(
        model.complementarity_cache,
        indv[1:n_comp],
        indv[n_comp+1:end],
        comp_type
    )

    return MOI.ConstraintIndex{typeof(func), typeof(set)}(n_comp_cons)
end
