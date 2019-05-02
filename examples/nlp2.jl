#*******************************************************/
#* Copyright(c) 2018 by Artelys                        */
#* This source code is subject to the terms of the     */
#* MIT Expat License (see LICENSE.md)                  */
#*******************************************************/

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# This example demonstrates how to use Knitro to solve the following
# simple nonlinear optimization problem.  This model is test problem
# HS40 from the Hock & Schittkowski collection.
#
# max   x0*x1*x2*x3        (obj)
# s.t.  x0^3 + x1^2 = 1    (c0)
#       x0^2*x3 - x2 = 0   (c1)
#       x3^2 - x1 = 0      (c2)
#
# This example also shows show to use the "newpt" callback, which
# can be used to perform some user-defined task every time Knitro
# iterates to a new solution estimate(e.g. it can be used to define
# a customized stopping condition).
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


using KNITRO, Test

#*------------------------------------------------------------------*
#*     FUNCTION callbackEvalFC                                      *
#*------------------------------------------------------------------*
# The signature of this function matches KNITRO.KN_eval_callback in knitro.h.
# Only "obj" and "c" are set in the KNITRO.KN_eval_result structure.
function callbackEvalFC(kc, cb, evalRequest, evalResult, userParams)
    x = evalRequest.x

    # Evaluate nonlinear term in objective
    evalResult.obj[1] = x[1] * x[2] * x[3] * x[4]

    # Evaluate nonlinear terms in constraints
    evalResult.c[1] = x[1] * x[1] * x[1]
    evalResult.c[2] = x[1] * x[1] * x[4]

    return 0
end

#*------------------------------------------------------------------*
#*     FUNCTION callbackEvalGA                                      *
#*------------------------------------------------------------------*
# The signature of this function matches KNITRO.KN_eval_callback in knitro.h.
# Only "objGrad" and "jac" are set in the KNITRO.KN_eval_result structure.
function callbackEvalGA(kc, cb, evalRequest, evalResult, userParams)
    x = evalRequest.x

    # Evaluate nonlinear term in objective gradient
    evalResult.objGrad[1] = x[2] * x[3] * x[4]
    evalResult.objGrad[2] = x[1] * x[3] * x[4]
    evalResult.objGrad[3] = x[1] * x[2] * x[4]
    evalResult.objGrad[4] = x[1] * x[2] * x[3]

    # Evaluate nonlinear terms in constraint gradients(Jacobian)
    evalResult.jac[1] = 3.0 * x[1] * x[1] # derivative of x0^3 term  wrt x0
    evalResult.jac[2] = 2.0 * x[1] * x[4] # derivative of x0^2 * x3 term  wrt x0
    evalResult.jac[3] = x[1] * x[1]       # derivative of x0^2 * x3 terms wrt x3

    return 0
end

#*------------------------------------------------------------------*
#*     FUNCTION callbackEvalH                                       *
#*------------------------------------------------------------------*
# The signature of this function matches KNITRO.KN_eval_callback in knitro.h.
# Only "hess" or "hessVec" are set in the KNITRO.KN_eval_result structure.
function callbackEvalH(kc, cb, evalRequest, evalResult, userParams)
    x = evalRequest.x
    lambda_ = evalRequest.lambda
    # Scale objective component of hessian by sigma
    sigma = evalRequest.sigma

    # Evaluate nonlinear term in the Hessian of the Lagrangian.
    # Note: If sigma=0, some computations can be avoided.
    if sigma > 0.0 # Evaluate the full Hessian of the Lagrangian
        evalResult.hess[1] = lambda_[1] * 6.0 * x[1] + lambda_[2] * 2.0 * x[4]
        evalResult.hess[2] = sigma * x[3] * x[4]
        evalResult.hess[3] = sigma * x[2] * x[4]
        evalResult.hess[4] = sigma * x[2] * x[3] + lambda_[2] * 2.0 * x[1]
        evalResult.hess[5] = sigma * x[1] * x[4]
        evalResult.hess[6] = sigma * x[1] * x[3]
        evalResult.hess[7] = sigma * x[1] * x[2]
    else # sigma=0, do not include objective component
        evalResult.hess[1] = lambda_[1] * 6.0 * x[1] + lambda_[2] * 2.0 * x[4]
        evalResult.hess[2] = 0.0
        evalResult.hess[3] = 0.0
        evalResult.hess[4] = lambda_[2] * 2.0 * x[1]
        evalResult.hess[5] = 0.0
        evalResult.hess[6] = 0.0
        evalResult.hess[7] = 0.0
    end

    return 0
end

#*------------------------------------------------------------------*
#*     FUNCTION callbackNewPoint                                    *
#*------------------------------------------------------------------*
# The signature of this function matches KNITRO.KN_user_callback in
# knitro.h.  Nothing should be modified.  This example printlns out
# that Knitro has iterated to a new point(x, lambda) that it
# considers an improvement over the previous iterate, and printlns
# out the current feasibility error and number of evaluations.
# To exercise it, edit "knitro.opt" and set the the "newpoint"
# option to "user".  The demonstration looks best if the "outlev"
# option is set to 5 or 6.
function callbackNewPoint(kc, x, lambda_, userParams)

    # Get the number of variables in the model
    n = KNITRO.KN_get_number_vars(userParams)

    println(">> New point computed by Knitro:(", x, ")")

    # Query information about the current problem.
    dFeasError = KNITRO.KN_get_abs_feas_error(userParams)
    println("Number FC evals= ", KNITRO.KN_get_number_FC_evals(userParams))
    println("Current feasError= " , dFeasError)

    # Demonstrate user-defined termination
    #(Uncomment to activate)
    if KNITRO.KN_get_obj_value(userParams) > 0.2 && dFeasError <= 1.0e-4
        return KNITRO.KN_RC_USER_TERMINATION
    end

    return 0
end

#*------------------------------------------------------------------*
#*     main                                                         *
#*------------------------------------------------------------------*

# Create a new Knitro solver instance.
kc = KNITRO.KN_new()

# Initialize Knitro with the problem definition.

# Add the variables and specify initial values for them.
# Note: any unset lower bounds are assumed to be
# unbounded below and any unset upper bounds are
# assumed to be unbounded above.
xIndices = KNITRO.KN_add_vars(kc, 4)
for x in xIndices
    KNITRO.KN_set_var_primal_init_values(kc, x, 0.8)
end

# Add the constraints and set the rhs and coefficients
KNITRO.KN_add_cons(kc, 3)
KNITRO.KN_set_con_eqbnds(kc, [1.0, 0.0, 0.0])

# Coefficients for 2 linear terms
lconIndexCons = Int32[1, 2]
lconIndexVars = Int32[2, 1]
lconCoefs = [-1.0, -1.0]
KNITRO.KN_add_con_linear_struct(kc, lconIndexCons, lconIndexVars, lconCoefs)

# Coefficients for 2 quadratic terms

# 1st term:  x1^2 term in c0
# 2nd term:  x3^2 term in c2
qconIndexCons = Int32[0, 2]
qconIndexVars1 = Int32[1, 3]
qconIndexVars2 = Int32[1, 3]
qconCoefs = [1.0, 1.0]


KNITRO.KN_add_con_quadratic_struct(kc, qconIndexCons, qconIndexVars1, qconIndexVars2, qconCoefs)

# Add callback to evaluate nonlinear(non-quadratic) terms in the model:
#    x0*x1*x2*x3  in the objective
#    x0^3         in first constraint c0
#    x0^2*x3      in second constraint c1
cb = KNITRO.KN_add_eval_callback(kc, true, Int32[0, 1], callbackEvalFC)

# Set obj. gradient and nonlinear jac provided through callbacks.
# Mark objective gradient as dense, and provide non-zero sparsity
# structure for constraint Jacobian terms.
cbjacIndexCons = Int32[0, 1, 1]
cbjacIndexVars = Int32[0, 0, 3]
KNITRO.KN_set_cb_grad(kc, cb, callbackEvalGA, jacIndexCons=cbjacIndexCons, jacIndexVars=cbjacIndexVars)

# Set nonlinear Hessian provided through callbacks. Since the
# Hessian is symmetric, only the upper triangle is provided.
# The upper triangular Hessian for nonlinear callback structure is:
#    # lambda0*6*x0 + lambda1*2*x3     x2*x3    x1*x3    x1*x2 + lambda1*2*x0
#              0                    0      x0*x3         x0*x2
#                                            0           x0*x1
#                                                         0
#(7 nonzero elements)
cbhessIndexVars1 = Int32[0, 0, 0, 0, 1, 1, 2]
cbhessIndexVars2 = Int32[0, 1, 2, 3, 2, 3, 3]
KNITRO.KN_set_cb_hess(kc, cb, length(cbhessIndexVars1), callbackEvalH,
                      hessIndexVars1=cbhessIndexVars1,  hessIndexVars2=cbhessIndexVars2)

# Set minimize or maximize(if not set, assumed minimize)
KNITRO.KN_set_obj_goal(kc, KNITRO.KN_OBJGOAL_MAXIMIZE)

# Demonstrate setting a "newpt" callback.  the callback function
# "callbackNewPoint" passed here is invoked after Knitro computes
# a new estimate of the solution.
KNITRO.KN_set_newpt_callback(kc, callbackNewPoint)

# Set option to println output after every iteration.
KNITRO.KN_set_param(kc, KNITRO.KN_PARAM_OUTLEV, KNITRO.KN_OUTLEV_ITER)

# Solve the problem.
#
# Return status codes are defined in "knitro.h" and described
# in the Knitro manual.
nStatus = KNITRO.KN_solve(kc)

println()
println("Knitro converged with final status = ", nStatus)

# An example of obtaining solution information.
nStatus, objSol, x, lambda_ =  KNITRO.KN_get_solution(kc)
println("  optimal objective value  = ", objSol)
println("  optimal primal values x  = ", x)
println("  feasibility violation    = ", KNITRO.KN_get_abs_feas_error(kc))
println("  KKT optimality violation = ", KNITRO.KN_get_abs_opt_error(kc))

# Delete the Knitro solver instance.
KNITRO.KN_free(kc)

@testset "Exemple HS40 nlp2" begin
    @test nStatus == KNITRO.KN_RC_USER_TERMINATION
    @test objSol ≈ 0.25 atol=1e-4
    @test x ≈ [0.793701, 0.707107, 0.529732, 0.840896] atol=1e-4
end
