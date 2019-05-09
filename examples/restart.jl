#*******************************************************/
#* Copyright(c) 2018 by Artelys                        */
#* This source code is subject to the terms of the     */
#* MIT Expat License (see LICENSE.md)                  */
#*******************************************************/

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# This example demonstrates how to use Knitro to solve the following
# simple nonlinear optimization problem, while varying user
# options and bounds on variables or constraints.
# This model is test problem HS15 from the Hock & Schittkowski
# collection.
#
# min   100(x1 - x0^2)^2 +(1 - x0)^2
# s.t.  x0 x1 >= c0lb(initially 1)
#       x0 + x1^2 >= 0
#       x0 <= x0ub   (initially 0.5)
#
# We first solve the model with c0lb=1 and x0ub=0.5, and then
# re-solve for different values of the "bar_murule" user option.
# We then re-solve the model, while changing the value of the
# variable bound "x0ub".  Finally, we re-solve while changing the
# value of the constraint bound "c0lb".
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


using KNITRO
using Printf

#*------------------------------------------------------------------*
#*     FUNCTION callbackEvalF                                       *
#*------------------------------------------------------------------*
# The signature of this function matches KNITRO.KN_eval_callback in knitro.jl.
# Only "obj" is set in the KNITRO.KN_eval_result structure.
function callbackEvalF(kc, cb, evalRequest, evalResult, userParams)
    x = evalRequest.x

    # Evaluate nonlinear objective
    dTmp = x[2] - x[1] * x[1]
    evalResult.obj[1] = 100.0 * (dTmp * dTmp) + ((1.0 - x[1]) * (1.0 - x[1]))

    return 0
end

#*------------------------------------------------------------------*
#*     FUNCTION callbackEvalG                                       *
#*------------------------------------------------------------------*
# The signature of this function matches KNITRO.KN_eval_callback in knitro.h.
# Only "objGrad" is set in the KNITRO.KN_eval_result structure.
function callbackEvalG!(kc, cb, evalRequest, evalResult, userParams)
    x = evalRequest.x

    # Evaluate gradient of nonlinear objective
    dTmp = x[2] - x[1] * x[1]
    evalResult.objGrad[1] = (-400.0 * dTmp * x[1]) - (2.0 * (1.0 - x[1]))
    evalResult.objGrad[2] = 200.0 * dTmp

    return 0
end

#*------------------------------------------------------------------*
#*     FUNCTION callbackEvalH                                       *
#*------------------------------------------------------------------*
# The signature of this function matches KNITRO.KN_eval_callback in knitro.h.
# Only "hess" and "hessVec" are set in the KNITRO.KN_eval_result structure.
function callbackEvalH!(kc, cb, evalRequest, evalResult, userParams)
    x = evalRequest.x
    # Scale objective component of hessian by sigma
    sigma = evalRequest.sigma

    # Evaluate the hessian of the nonlinear objective.
    # Note: Since the Hessian is symmetric, we only provide the
    #       nonzero elements in the upper triangle(plus diagonal).
    #       These are provided in row major ordering as specified
    #       by the setting KNITRO.KN_DENSE_ROWMAJOR in "KNITRO.KN_set_cb_hess()".
    # Note: The Hessian terms for the quadratic constraints
    #       will be added internally by Knitro to form
    #       the full Hessian of the Lagrangian.
    evalResult.hess[1] = sigma * ((-400.0 * x[2]) + (1200.0 * x[1] * x[1]) + 2.0) #(0,0)
    evalResult.hess[2] = sigma * (-400.0 * x[1]) #(0,1)
    evalResult.hess[3] = sigma * 200.0           #(1,1)

    return 0
end


#*------------------------------------------------------------------*
#*     main                                                         *
#*------------------------------------------------------------------*

# Create a new Knitro solver instance.
kc = KNITRO.KN_new()

# Illustrate how to override default options by reading from
# the knitro.opt file.
options = joinpath(dirname(@__FILE__), "..", "examples", "knitro.opt")
KNITRO.KN_load_param_file(kc, options)

# Initialize knitro with the problem definition.

# Add the 4 variables and set their bounds.
# Note: any unset lower bounds are assumed to be
# unbounded below and any unset upper bounds are
# assumed to be unbounded above.
KNITRO.KN_add_vars(kc, 2)
KNITRO.KN_set_var_lobnds(kc, [-KNITRO.KN_INFINITY, -KNITRO.KN_INFINITY]) # not necessary since infinite
KNITRO.KN_set_var_upbnds(kc, [0.5, KNITRO.KN_INFINITY])

# Add the constraints and set their lower bounds
KNITRO.KN_add_cons(kc, 2)
KNITRO.KN_set_con_lobnds(kc, [1.0, 0.0])

# Both constraints are quadratic so we can directly load all the
# structure for these constraints.

# First load quadratic structure x0*x1 for the first constraint
KNITRO.KN_add_con_quadratic_struct(kc, 0, 0, 1, 1.0)

# Load structure for the second constraint.  below we add the linear
# structure and the quadratic structure separately, though it
# is possible to add both together in one call to
# "KNITRO.KN_add_con_quadratic_struct()" since this api function also
# supports adding linear terms.

# Add linear term x0 in the second constraint
KNITRO.KN_add_con_linear_struct(kc, 1, 0, 1.0)

# Add quadratic term x1^2 in the second constraint
KNITRO.KN_add_con_quadratic_struct(kc, 1, 1, 1, 1.0)

# Add a callback function "callbackEvalF" to evaluate the nonlinear
#(non-quadratic) objective.  Note that the linear and
# quadratic terms in the objective could be loaded separately
# via "KNITRO.KN_add_obj_linear_struct()" / "KNITRO.KN_add_obj_quadratic_struct()".
# However, for simplicity, we evaluate the whole objective
# function through the callback.
cb = KNITRO.KN_add_objective_callback(kc, callbackEvalF)

# Also add a callback function "callbackEvalG" to evaluate the
# objective gradient.  If not provided, Knitro will approximate
# the gradient using finite-differencing.  However, we recommend
# providing callbacks to evaluate the exact gradients whenever
# possible as this can drastically improve the performance of Knitro.
# We specify the objective gradient in "dense" form for simplicity.
# However for models with many constraints, it is important to specify
# the non-zero sparsity structure of the constraint gradients
#(i.e. Jacobian matrix) for efficiency(this is true even when using
# finite-difference gradients).
KNITRO.KN_set_cb_grad(kc, cb, callbackEvalG!)

# Add a callback function "callbackEvalH" to evaluate the Hessian
#(i.e. second derivative matrix) of the objective.  If not specified,
# Knitro will approximate the Hessian. However, providing a callback
# for the exact Hessian(as well as the non-zero sparsity structure)
# can greatly improve Knitro performance and is recommended if possible.
# Since the Hessian is symmetric, only the upper triangle is provided.
# Again for simplicity, we specify it in dense(row major) form.
KNITRO.KN_set_cb_hess(kc, cb, KNITRO.KN_DENSE_ROWMAJOR, callbackEvalH!)

# specify that the user is able to provide evaluations
# of the hessian matrix without the objective component.
# turned off by default but should be enabled if possible.
KNITRO.KN_set_param(kc, KNITRO.KN_PARAM_HESSIAN_NO_F, KNITRO.KN_HESSIAN_NO_F_ALLOW)

# Set minimize or maximize(if not set, assumed minimize)
KNITRO.KN_set_obj_goal(kc, KNITRO.KN_OBJGOAL_MINIMIZE)

# Turn output off and use Interior/Direct algorithm
KNITRO.KN_set_param(kc, "outlev", KNITRO.KN_OUTLEV_NONE)
KNITRO.KN_set_param(kc, "algorithm", KNITRO.KN_ALG_BAR_DIRECT)

# Solve the problem.
#
# Return status codes are defined in "knitro.h" and described
# in the Knitro manual.

# First solve for the 6 different values of user option "bar_murule".
# This option handles how the barrier parameter is updated each
# iteration in the barrier/interior-point solver.
println("Changing a user option and re-solving...")
for i in 1:6
    KNITRO.KN_set_param(kc, "bar_murule", i)
    # Reset original initial point
    KNITRO.KN_set_var_primal_init_values(kc, [-2.0, 1.0])
    nStatus = KNITRO.KN_solve(kc)
    if nStatus != 0
        println("  bar_murule=$i - Knitro failed to solve, status = $nStatus")
    else
        @printf("\n  bar_murule=%d - solved in %2d iters, %2d function evaluations, objective=%e",
               i, KNITRO.KN_get_number_iters(kc), KNITRO.KN_get_number_FC_evals(kc), KNITRO.KN_get_obj_value(kc))
    end
end

# Now solve for different values of the x0 upper bound.
# Continually relax the upper bound until it is no longer
# "active"(i.e. no longer restricting x0), at which point
# there is no more significant change in the optimal solution.
# Change to the active-set algorithm and do not reset the
# initial point, so the re-solves are "warm-started".
println("\nChanging a variable bound and re-solving...")
KNITRO.KN_set_param(kc, "algorithm", KNITRO.KN_ALG_ACT_CG)
tmpbound = 0.5
i = 0

for i = 1:20
    # Modify bound for next solve.
    tmpbound = 0.1*i
    KNITRO.KN_set_var_upbnds(kc, 0, tmpbound)

    nStatus = KNITRO.KN_solve(kc)
    if nStatus != 0
        @printf("\n  x0 upper bound=%e - Knitro failed to solve, status = %d", tmpbound, nStatus)
    else
        nStatus, objSol, x, lambda_ = KNITRO.KN_get_solution(kc)
        @printf("\n  x0 upper bound=%e - solved in %2d iters, x0=%e, objective=%e",
                tmpbound, KNITRO.KN_get_number_iters(kc), x[1], objSol)
    end

    if nStatus != 0 || x[1] < tmpbound - 1e-4
        break
    end
end
# Restore original value
KNITRO.KN_set_var_upbnds(kc, 0, 0.5)

# Now solve for different values of the c0 lower bound.
# Continually relax the lower bound until it is no longer
# "active"(i.e. no longer restricting c0), at which point
# there is no more significant change in the optimal solution.
println("\nChanging a constraint bound and re-solving...")
tmpbound = 1.0
i = 0
for i = 1:20
    tmpbound = 1. - 0.1*i
    KNITRO.KN_set_con_lobnds(kc, 0, tmpbound)
    nStatus = KNITRO.KN_solve(kc)
    if nStatus != 0
        @printf("\n  c0 lower bound=%e - Knitro failed to solve, status = %d", tmpbound, nStatus)
    else
        c0 = KNITRO.KN_get_con_values(kc, 0)
        @printf("\n  c0 lower bound=%e - solved in %2d iters, c0=%e, objective=%e",
               tmpbound, KNITRO.KN_get_number_iters(kc), c0, KNITRO.KN_get_obj_value(kc))
    end
    if nStatus != 0 || c0 > tmpbound + 1e-4
        break
    end
end

# Delete the Knitro solver instance.
KNITRO.KN_free(kc)
