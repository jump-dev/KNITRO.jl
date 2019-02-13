#*******************************************************/
#* Copyright(c) 2018 by Artelys                        */
#* This source code is subject to the terms of the     */
#* MIT Expat License (see LICENSE.md)                  */
#*******************************************************/

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# This example demonstrates how to use Knitro to solve the following
# mixed-integer nonlinear optimization problem(MINLP).  This model
# is test problem 1(Synthesis of processing system) in
# M. Duran & I.E. Grossmann,  "An outer approximation algorithm for
# a class of mixed integer nonlinear programs", Mathematical
# Programming 36, pp. 307-339, 1986.  The problem also appears as
# problem synthes1 in the MacMINLP test set.
#
# min   5 x3 + 6 x4 + 8 x5 + 10 x0 - 7 x2 -18 log(x1 + 1)
#      - 19.2 log(x0 - x1 + 1) + 10
# s.t.  0.8 log(x1 + 1) + 0.96 log(x0 - x1 + 1) - 0.8 x2 >= 0
#       log(x1 + 1) + 1.2 log(x0 - x1 + 1) - x2 - 2 x5 >= -2
#       x1 - x0 <= 0
#       x1 - 2 x3 <= 0
#       x0 - x1 - 2 x4 <= 0
#       x3 + x4 <= 1
#       0 <= x0 <= 2
#       0 <= x1 <= 2
#       0 <= x2 <= 1
#       x0, x1, x2 continuous
#       x3, x4, x5 binary
#
# The solution is(1.30098, 0, 1, 0, 1, 0).
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


using KNITRO

#*------------------------------------------------------------------*
#*     FUNCTION callbackEvalFC                                      *
#*------------------------------------------------------------------*
# The signature of this function matches KNITRO.KN_eval_callback in knitro.h.
# Only "obj" and "c" are set in the KNITRO.KN_eval_result structure.
function callbackEvalFC(kc, cb, evalRequest, evalResult, userParams)
    x = evalRequest.x

    # Evaluate nonlinear objective structure
    dTmp1 = x[1] - x[2] + 1.0
    dTmp2 = x[2] + 1.0
    evalResult.obj[1] = -18.0 * log(dTmp2) - 19.2 * log(dTmp1)

    # Evaluate nonlinear constraint structure
    evalResult.c[1] = 0.8 * log(dTmp2) + 0.96 * log(dTmp1)
    evalResult.c[2] = log(dTmp2) + 1.2 * log(dTmp1)

    return 0
end

#*------------------------------------------------------------------*
#*     FUNCTION callbackEvalGA                                      *
#*------------------------------------------------------------------*
# The signature of this function matches KNITRO.KN_eval_callback in knitro.h.
# Only "objGrad" and "jac" are set in the KNITRO.KN_eval_result structure.
function callbackEvalGA(kc, cb, evalRequest, evalResult, userParams)
    x = evalRequest.x

    # Evaluate gradient of nonlinear objective structure
    dTmp1 = x[1] - x[2] + 1.0
    dTmp2 = x[2] + 1.0
    evalResult.objGrad[1] = -(19.2 / dTmp1)
    evalResult.objGrad[2] = (-18.0 / dTmp2) + (19.2 / dTmp1)

    # Gradient of nonlinear structure in constraint 0.
    evalResult.jac[1] = 0.96 / dTmp1                      # wrt x0
    evalResult.jac[2] = (-0.96 / dTmp1) + (0.8 / dTmp2)   # wrt x1
    # Gradient of nonlinear structure in constraint 1.
    evalResult.jac[3] = 1.2 / dTmp1                       # wrt x0
    evalResult.jac[4] = (-1.2 / dTmp1) + (1.0 / dTmp2)    # wrt x1

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

    # Evaluate the non-zero components in the Hessian of the Lagrangian.
    # Note: Since the Hessian is symmetric, we only provide the
    #       nonzero elements in the upper triangle(plus diagonal).
    dTmp1 = x[1] - x[2] + 1.0
    dTmp2 = x[2] + 1.0
    evalResult.hess[1] = sigma * (19.2 /(dTmp1 * dTmp1)) +
                            lambda_[1] * (-0.96 / (dTmp1 * dTmp1)) + lambda_[2] * (-1.2 / (dTmp1 * dTmp1))
    evalResult.hess[2] = sigma * (-19.2 /(dTmp1 * dTmp1)) +
                            lambda_[1] * (0.96 / (dTmp1 * dTmp1)) + lambda_[2] * (1.2 / (dTmp1 * dTmp1))
    evalResult.hess[3] = sigma * ((19.2 / (dTmp1 * dTmp1)) +(18.0 / (dTmp2 * dTmp2))) +
                            lambda_[1] * ((-0.96 / (dTmp1 * dTmp1)) -(0.8 / (dTmp2 * dTmp2))) +
                            lambda_[2] * ((-1.2 / (dTmp1 * dTmp1)) -(1.0 / (dTmp2 * dTmp2)))

    return 0
end

#*------------------------------------------------------------------*
#*     FUNCTION callbackProcessNode                                 *
#*------------------------------------------------------------------*
# The signature of this function matches KNITRO.KN_user_callback in knitro.h.
# Argument "kcSub" is the context pointer for the last node
# subproblem solved inside Knitro.  The application level context
# pointer is passed in through "userParams".
function callbackProcessNode(kcSub, x, lambda_, userParams)
    # The Knitro context pointer was passed in through "userParams".
    kc = userParams

    # Print info about the status of the MIP solution.
    numNodes = KNITRO.KN_get_mip_number_nodes(kc)
    relaxBound = KNITRO.KN_get_mip_relaxation_bnd(kc)
    # Note: To retrieve solution information about the node subproblem
    # we need to pass in "kcSub" here.
    nodeObj = KNITRO.KN_get_obj_value(kc)
    println("callbackProcessNode:")
    println("    Node number    = ", numNodes)
    println("    Node objective = ", nodeObj)
    println("    Current relaxation bound = ", relaxBound)
    try
        println("    Current incumbent bound  = ", KNITRO.KN_get_mip_incumbent_obj(kc))
        println("    Absolute integrality gap = ", KNITRO.KN_get_mip_abs_gap(kc))
        println("    Relative integrality gap = ", KNITRO.KN_get_mip_rel_gap(kc))
    catch
        println("    No integer feasible point found yet.")
    end

    # User defined termination example.
    # Uncomment below to force termination after 3 nodes.
    #if(numNodes == 3)
    #    return KNITRO.KN_RC_USER_TERMINATION

    return 0
end

#*------------------------------------------------------------------*
#*     main                                                         *
#*------------------------------------------------------------------*

# Create a new Knitro solver instance.
kc = KNITRO.KN_new()

# Illustrate how to override default options.
KNITRO.KN_set_param(kc, "mip_method", KNITRO.KN_MIP_METHOD_BB)
KNITRO.KN_set_param(kc, "algorithm", KNITRO.KN_ALG_ACT_CG)
KNITRO.KN_set_param(kc, "outmode", KNITRO.KN_OUTMODE_SCREEN)
KNITRO.KN_set_param(kc, KNITRO.KN_PARAM_OUTLEV, KNITRO.KN_OUTLEV_ALL)
KNITRO.KN_set_param(kc, KNITRO.KN_PARAM_MIP_OUTINTERVAL, 1)
KNITRO.KN_set_param(kc, KNITRO.KN_PARAM_MIP_MAXNODES, 10000)

# Initialize Knitro with the problem definition.

# Add the variables and set their bounds and types.
# Note: any unset lower bounds are assumed to be
# unbounded below and any unset upper bounds are
# assumed to be unbounded above.
n = 6
KNITRO.KN_add_vars(kc, n)
KNITRO.KN_set_var_lobnds(kc, zeros(Float64, n))
KNITRO.KN_set_var_upbnds(kc, [2., 2., 1., 1., 1., 1.])
KNITRO.KN_set_var_types(kc, [KNITRO.KN_VARTYPE_CONTINUOUS,
                             KNITRO.KN_VARTYPE_CONTINUOUS,
                             KNITRO.KN_VARTYPE_CONTINUOUS,
                             KNITRO.KN_VARTYPE_BINARY,
                             KNITRO.KN_VARTYPE_BINARY,
                             KNITRO.KN_VARTYPE_BINARY])

# Note that variables x2..x5 only appear linearly in the
# problem.  We mark them as linear variables, which may
# help Knitro do more extensive presolving resulting in
# faster solves.
for i in 2:(n-1)
    KNITRO.KN_set_var_property(kc, i, KNITRO.KN_VAR_LINEAR)
end

# Add the constraints and set their bounds
KNITRO.KN_add_cons(kc, 6)
KNITRO.KN_set_con_lobnds(kc,  [0, -2,
                               -KNITRO.KN_INFINITY,
                               -KNITRO.KN_INFINITY,
                               -KNITRO.KN_INFINITY,
                               -KNITRO.KN_INFINITY])
KNITRO.KN_set_con_upbnds(kc, [KNITRO.KN_INFINITY, KNITRO.KN_INFINITY, 0, 0, 0, 1])

# Add the linear structure in the objective function.
objGradIndexVars = Int32[3, 4, 5, 0, 2]
objGradCoefs = [5.0, 6.0, 8.0, 10.0, -7.0]
KNITRO.KN_add_obj_linear_struct(kc, objGradIndexVars, objGradCoefs)

# Add the constant in the objective function.
KNITRO.KN_add_obj_constant(kc, 10.0)

# Load the linear structure for all constraints at once.
jacIndexCons = Int32[0, 1, 1, 2, 2, 3, 3, 4, 4, 4, 5, 5]
jacIndexVars = Int32[2, 2, 5, 1, 0, 1, 3, 0, 1, 4, 3, 4]
jacCoefs = [-0.8, -1.0, -2.0, 1.0, -1.0, 1.0, -2.0, 1.0, -1.0, -2.0, 1.0, 1.0]
KNITRO.KN_add_con_linear_struct(kc, jacIndexCons, jacIndexVars, jacCoefs)

# Add a callback function "callbackEvalFC" to evaluate the nonlinear
# structure in the objective and first two constraints.  Note that
# the linear terms in the objective and first two constraints were
# added above in "KNITRO.KN_add_obj_linear_struct()" and
# "KNITRO.KN_add_con_linear_struct()" and will not be specified in the
# callback.
cIndices = Int32[0, 1] # Constraint indices for callback
cb = KNITRO.KN_add_eval_callback(kc, true, cIndices, callbackEvalFC)

# Also add a callback function "callbackEvalGA" to evaluate the
# gradients of all nonlinear terms specified in the callback.  If
# not provided, Knitro will approximate the gradients using finite-
# differencing.  However, we recommend providing callbacks to
# evaluate the exact gradients whenever possible as this can
# drastically improve the performance of Knitro.
# Objective gradient non-zero structure for callback
objGradIndexVarsCB = Int32[0, 1]
# Constraint Jacobian non-zero structure for callback
jacIndexConsCB = Int32[0, 0, 1, 1]
jacIndexVarsCB = Int32[0, 1, 0, 1]
KNITRO.KN_set_cb_grad(kc, cb, callbackEvalGA,
                      nV=length(objGradIndexVarsCB),
                      objGradIndexVars=objGradIndexVarsCB,
                      jacIndexCons=jacIndexConsCB,
                      jacIndexVars=jacIndexVarsCB)

hessIndexVars1CB = Int32[0, 0, 1]
hessIndexVars2CB = Int32[0, 1, 1]
# Add a callback function "callbackEvalH" to evaluate the Hessian
#(i.e. second derivative matrix) of the objective.  If not specified,
# Knitro will approximate the Hessian. However, providing a callback
# for the exact Hessian(as well as the non-zero sparsity structure)
# can greatly improve Knitro performance and is recommended if possible.
# Since the Hessian is symmetric, only the upper triangle is provided.
KNITRO.KN_set_cb_hess(kc, cb, length(hessIndexVars1CB), callbackEvalH,
                      hessIndexVars1=hessIndexVars1CB,
                      hessIndexVars2=hessIndexVars2CB)

 # Specify that the user is able to provide evaluations
#  of the Hessian matrix without the objective component.
#  turned off by default but should be enabled if possible.
KNITRO.KN_set_param(kc, KNITRO.KN_PARAM_HESSIAN_NO_F, KNITRO.KN_HESSIAN_NO_F_ALLOW)

# Set minimize or maximize(if not set, assumed minimize)
KNITRO.KN_set_obj_goal(kc, KNITRO.KN_OBJGOAL_MINIMIZE)

# Set a callback function that performs some user-defined task
# after completion of each node in the branch-and-bound tree.
KNITRO.KN_set_mip_node_callback(kc, callbackProcessNode)

# Solve the problem.
#
# Return status codes are defined in "knitro.h" and described
# in the Knitro manual.

nStatus = KNITRO.KN_solve(kc)
# An example of obtaining solution information.
nSTatus, objSol, x, lambda_ = KNITRO.KN_get_solution(kc)
println("Optimal objective value  = ", objSol)
println("Optimal x")
for i in 1:n
    println("  x[$i] = ", x[i])
end

# Delete the Knitro solver instance.
KNITRO.KN_free(kc)

@testset "Exemple minlp1" begin
    @test nStatus == 0
    @test objSol ≈ 6.0097589
    @test x ≈ [1.30097589, 0., 1., 0., 1., 0.] atol=1e-5
end
