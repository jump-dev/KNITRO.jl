Applications may define functions for evaluating problem elements given a
current solution. This section of the documentation details the function
signatures expected for the callbacks.

### eval_f
Returns the value of the objective function at the current solution `x`

```
function eval_f(x::Vector{Float64})   # (length n) Current Solution
    # ...
    return obj_value
end
```

### eval_g
Sets the value of the constraint functions `g` at the current solution `x`

```julia
function eval_g(x::Vector{Float64},     # (length n) Current Solution
                cons::Vector{Float64})  # (length m) Constraint values g(x)
    # ...
    # cons[1] = ...
    # ...
    # cons[prob.m] = ...
end
```

Note that the values of `cons` must be set "in-place", i.e. the statement
`cons = zeros(prob.m)` musn't be done. If you do want to create a new vector
and allocate it to `cons` use `cons[:]`, e.g. `cons[:] = zeros(prob.m)`.

### eval_grad_f
Sets the value of the gradient of the objective function at the current
solution `x`

```julia
function eval_grad_f(x::Vector{Float64},     # (length n) Current Solution
                     grad::Vector{Float64})  # (length n) Objective gradient
    # ...
    # grad[1] = ...
    # ...
    # grad[prob.n] = ...
end
```

As with `eval_g`, you must set the values "in-place" for `eval_grad_f`.

### eval_jac_g
This function returns the values of the Jacobian, evaluated at the non-negative
indices, based on the sparsity structure passed to Artelys Knitro through
`initializeProblem`. Julia is 1-based, in the sense that indexing always starts
at 1 (unlike C, which starts at 0).

```julia
function eval_jac_g(x::Vector{Float64},    # (length n) Current Solution
                    jac::Vector{Float64})  # (length nnzJ) The Jacobian values
    # ...
    # jac[1] = ...
    # ...
    # jac[nnzJ] = ... # where nnzJ = length(jac)
end
```

As for the previous two callbacks, all values must be set "in-place".

### eval_h

Similar to the Jacobian, except for the Hessian of the Lagrangian. See
the documentation for full details of the meaning of everything.

```julia
function eval_h(x::Vector{Float64},        # (length n) Current solution
                lambda::Vector{Float64},   # (length n+m) Multipliers for each constraint
                sigma::Float64,            # Lagrangian multiplier for objective
                hess::Vector{Float64})     # (length nnzH) The values of the Hessian
    # ...
    # hess[1] = ...
    # ...
    # hess[nnzH] = ... # where nnzH = length(hess)
end
```

### eval_hv
Computes the Hessian-of-the-Lagrangian-vector product, storing the result in
the vector `hv`.

```julia
function eval_hv(x::Vector{Float64},      # (length n) Current solution
                 lambda::Vector{Float64}, # (length n+m) Multipliers for each constraint
                 sigma::Float64,          # Lagrangian multiplier for objective
                 hv::Vector{Float64})     # (length n) Hessian-of-the-Lagrangian-vector product
    # ...
    # hv[1] = ...
    # ...
    # hv[end] = ...
end
```
