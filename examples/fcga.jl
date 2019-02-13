#*******************************************************/
#* Copyright(c) 2018 by Artelys                        */
#* This source code is subject to the terms of the     */
#* MIT Expat License (see LICENSE.md)                  */
#*******************************************************/

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#  Knitro example defining a single callback function for function
#  and gradient(i.e. EVALFCGA) requests, and a second callback for
#  Hessian(i.e. EVALH / EVALHV) requests.  This model is test
#  problem HS40 from the Hock & Schittkowski collection.
#
#  max   x0*x1*x2*x3        (obj)
#  s.t.  x0^3 + x1^2 = 1    (c0)
#        x0^2*x3 - x2 = 0   (c1)
#        x3^2 - x1 = 0      (c2)
#
#  See exampleNLP2.c to see how this is solved in the standard
#  way with separate callbacks for functions and gradients.
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


using KNITRO

#*------------------------------------------------------------------*/
#*     FUNCTION callbackEvalFCGA                                    */
#*------------------------------------------------------------------*/
# The signature of this function matches KNITRO.KN_eval_callback in knitro.h.
# To compute the functions and gradient together, set "obj", "c",
# "objGrad" and "jac" in the KNITRO.KN_eval_result structure when there
# is a function+gradient evaluation request(i.e. EVALFCGA).
#
# NOTE: It is generally more efficient and recommended to have
# separate callback routines for functions and gradients since a
# gradient evaluation is not always needed for every function
# evaluation.  However, in some cases, it may be more convenient
# to compute them together if most of the work for computing the
# gradients is already done for the function evaluation.
function callbackEvalFCGA(kc, cb, evalRequest, evalResult, userParams)
    x = evalRequest.x

    # Evaluate nonlinear term in objective
    evalResult.obj[1] = x[1]*x[2]*x[3]*x[4]

    # Evaluate nonlinear terms in constraints
    evalResult.c[1] = x[1]*x[1]*x[1]
    evalResult.c[2] = x[1]*x[1]*x[4]

    # Evaluate nonlinear term in objective gradient
    evalResult.objGrad[1] = x[2]*x[3]*x[4]
    evalResult.objGrad[2] = x[1]*x[3]*x[4]
    evalResult.objGrad[3] = x[1]*x[2]*x[4]
    evalResult.objGrad[4] = x[1]*x[2]*x[3]

    # Evaluate nonlinear terms in constraint gradients(Jacobian)
    evalResult.jac[1] = 3.0*x[1]*x[1] # derivative of x0^3 term  wrt x0
    evalResult.jac[2] = 2.0*x[1]*x[4] # derivative of x0^2*x3 term  wrt x0
    evalResult.jac[3] = x[1]*x[1]     # derivative of x0^2*x3 terms wrt x3

    return 0
end


#*------------------------------------------------------------------*/
#*     FUNCTION callbackEvalH                                       */
#*------------------------------------------------------------------*/
# The signature of this function matches KNITRO.KN_eval_callback in knitro.h.
# Only "hess" and "hessVec" are set in the KNITRO.KN_eval_result structure.
function callbackEvalH(kc, cb, evalRequest, evalResult, userParams)

    x = evalRequest.x
    lambda_ = evalRequest.lambda
    # Scale objective component of Hessian by sigma
    sigma = evalRequest.sigma

    # Evaluate nonlinear terms in the Hessian of the Lagrangian.
    # Note: If sigma=0, some computations can be avoided.
    if sigma > 0.0  # Evaluate the full Hessian of the Lagrangian
        evalResult.hess[1] = lambda_[1]*6.0*x[1] + lambda_[2]*2.0*x[4]
        evalResult.hess[2] = sigma*x[3]*x[4]
        evalResult.hess[3] = sigma*x[2]*x[4]
        evalResult.hess[4] = sigma*x[2]*x[3] + lambda_[2]*2.0*x[1]
        evalResult.hess[5] = sigma*x[1]*x[4]
        evalResult.hess[6] = sigma*x[1]*x[3]
        evalResult.hess[7] = sigma*x[1]*x[2]
    else            # sigma=0, do not include objective component
        evalResult.hess[1] = lambda_[1]*6.0*x[1] + lambda_[2]*2.0*x[4]
        evalResult.hess[2] = 0.0
        evalResult.hess[3] = 0.0
        evalResult.hess[4] = lambda_[2]*2.0*x[1]
        evalResult.hess[5] = 0.0
        evalResult.hess[6] = 0.0
        evalResult.hess[7] = 0.0
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
vars = KNITRO.KN_add_vars(kc, 4)
for x in vars
    KNITRO.KN_set_var_primal_init_values(kc, x, 0.8)
end

# Add the constraints and set the rhs and coefficients
KNITRO.KN_add_cons(kc, 3)
KNITRO.KN_set_con_eqbnds(kc, [1.0, 0.0, 0.0]);

# Coefficients for 2 linear terms
lconIndexCons = Int32[1, 2]
lconIndexVars = Int32[2, 1]
lconCoefs = [-1.0, -1.0]
KNITRO.KN_add_con_linear_struct(kc, lconIndexCons, lconIndexVars, lconCoefs)

# Coefficients for 2 quadratic terms

qconIndexCons = Int32[0, 2]
qconIndexVars1 = Int32[1, 3]
qconIndexVars2 = Int32[1, 3]
qconCoefs = [1.0, 1.0]


KNITRO.KN_add_con_quadratic_struct(kc, qconIndexCons, qconIndexVars1, qconIndexVars2, qconCoefs)

# Add callback to evaluate nonlinear(non-quadratic) terms in the model:
#    x0*x1*x2*x3  in the objective
#    x0^3         in first constraint c0
#    x0^2*x3      in second constraint c1
cIndices = Int32[0, 1]
cb = KNITRO.KN_add_eval_callback(kc, true, cIndices, callbackEvalFCGA)

# Set obj. gradient and nonlinear jac provided through callbacks.
# Mark objective gradient as dense, and provide non-zero sparsity
# structure for constraint Jacobian terms. Set the gradient
# evaluations to use the same callback routine as used for
# function evaluations.
cbjacIndexCons = Int32[0, 1, 1]
cbjacIndexVars = Int32[0, 0, 3]
KNITRO.KN_set_cb_grad(kc, cb, nothing, jacIndexCons=cbjacIndexCons, jacIndexVars=cbjacIndexVars)

# Set nonlinear Hessian provided through callbacks. Since the
# Hessian is symmetric, only the upper triangle is provided.
# The upper triangular Hessian for nonlinear callback structure is:
#
#  lambda0*6*x0 + lambda1*2*x3     x2*x3    x1*x3    x1*x2 + lambda1*2*x0
#               0                    0      x0*x3         x0*x2
#                                             0           x0*x1
#                                                          0
# (7 nonzero elements)
cbhessIndexVars1 = Int32[0, 0, 0, 0, 1, 1, 2]
cbhessIndexVars2 = Int32[0, 1, 2, 3, 2, 3, 3]
KNITRO.KN_set_cb_hess(kc, cb, length(cbhessIndexVars1), callbackEvalH,
                      hessIndexVars1=cbhessIndexVars1,
                      hessIndexVars2=cbhessIndexVars2)

# Set minimize or maximize(if not set, assumed minimize)
KNITRO.KN_set_obj_goal(kc, KNITRO.KN_OBJGOAL_MAXIMIZE)

# Set option to print output after every iteration.
KNITRO.KN_set_param(kc, KNITRO.KN_PARAM_OUTLEV, KNITRO.KN_OUTLEV_ITER)

# Set option to tell Knitro that the gradients are being provided
# with the functions in one callback.
KNITRO.KN_set_param(kc, KNITRO.KN_PARAM_EVAL_FCGA, KNITRO.KN_EVAL_FCGA_YES)

# Solve the problem.
#
# Return status codes are defined in "knitro.h" and described
# in the Knitro manual.
nStatus = KNITRO.KN_solve(kc)

println("Knitro converged with final status = ", nStatus)

# An example of obtaining solution information.
nStatus, objSol, x, lambda_ =  KNITRO.KN_get_solution(kc)
println("  optimal objective value  = ", objSol)
println("  optimal primal values x  = ",   x)
println("  feasibility violation    = ", KNITRO.KN_get_abs_feas_error(kc))
println("  KKT optimality violation = ", KNITRO.KN_get_abs_opt_error(kc))


# Delete the Knitro solver instance.
KNITRO.KN_free(kc)

@testset "Exemple HS40 FCGA" begin
    @test nStatus == 0
    @test objSol ≈ 0.25
    @test x ≈ [0.793701, 0.707107, 0.529732, 0.840896] atol=1e-5
end
