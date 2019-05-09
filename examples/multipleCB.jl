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
# This is the same as exampleNLP2.c, but it demonstrates using
# multiple callbacks for the nonlinear evaluations and computing
# some gradients using finite-differencs, while others are provided
# in callback routines.
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


using KNITRO, Test

#*------------------------------------------------------------------*
#*     FUNCTION EVALUATION CALLBACKS                                *
#*------------------------------------------------------------------*

# The signature of this function matches KNITRO.KN_eval_callback in knitro.h.
# Only "obj" is set in the KNITRO.KN_eval_result structure.
function callbackEvalObj(kc, cb, evalRequest, evalResult, userParams)
    xind = userParams[:data]

    if evalRequest.evalRequestCode != KNITRO.KN_RC_EVALFC
        println("*** callbackEvalObj incorrectly called with eval type ", evalRequest.evalRequestCode)
        return -1
    end
    x = evalRequest.x

    # Evaluate nonlinear term in objective
    evalResult.obj[1] = x[xind[1]] * x[xind[2]] * x[xind[3]] * x[xind[4]]

    return 0
end

# The signature of this function matches KNITRO.KN_eval_callback in knitro.h.
# Only "c0" is set in the KNITRO.KN_eval_result structure.
function callbackEvalC0(kc, cb, evalRequest, evalResult, userParams)
    xind = userParams[:data]

    if evalRequest.evalRequestCode != KNITRO.KN_RC_EVALFC
        println("*** callbackEvalC0 incorrectly called with eval type ", evalRequest.evalRequestCode)
        return -1
    end
    x = evalRequest.x

    # Evaluate nonlinear terms in constraint, c0
    evalResult.c[1] = x[xind[1]] * x[xind[1]] * x[xind[1]]

    return 0
end

# The signature of this function matches KNITRO.KN_eval_callback in knitro.h.
# Only "c1" is set in the KNITRO.KN_eval_result structure.
function callbackEvalC1(kc, cb, evalRequest, evalResult, userParams)
    xind = userParams[:data]

    if evalRequest.evalRequestCode != KNITRO.KN_RC_EVALFC
        println("*** callbackEvalC1 incorrectly called with eval type %d" % evalRequest.evalRequestCode)
        return -1
    end
    x = evalRequest.x

    # Evaluate nonlinear terms in constraint, c1
    evalResult.c[1] = x[xind[1]] * x[xind[1]] * x[xind[4]]

    return 0
end

#*------------------------------------------------------------------*
#*     GRADIENT EVALUATION CALLBACKS                                *
#*------------------------------------------------------------------*

# The signature of this function matches KNITRO.KN_eval_callback in knitro.h.
# Only "objGrad" is set in the KNITRO.KN_eval_result structure.
function callbackEvalObjGrad(kc, cb, evalRequest, evalResult, userParams)
    xind = userParams[:data]

    if evalRequest.evalRequestCode != KNITRO.KN_RC_EVALGA
        println("*** callbackEvalObjGrad incorrectly called with eval type %d" % evalRequest.evalRequestCode)
        return -1
    end
    x = evalRequest.x

    # Evaluate nonlinear terms in objective gradient
    evalResult.objGrad[xind[1]] = x[xind[2]] * x[xind[3]] * x[xind[4]]
    evalResult.objGrad[xind[2]] = x[xind[1]] * x[xind[3]] * x[xind[4]]
    evalResult.objGrad[xind[3]] = x[xind[1]] * x[xind[2]] * x[xind[4]]
    evalResult.objGrad[xind[4]] = x[xind[1]] * x[xind[2]] * x[xind[3]]

    return 0
end

# The signature of this function matches KNITRO.KN_eval_callback in knitro.h.
# Only gradient of c0 is set in the KNITRO.KN_eval_result structure.
function callbackEvalC0Grad(kc, cb, evalRequest, evalResult, userParams)
    xind = userParams[:data]

    if evalRequest.evalRequestCode != KNITRO.KN_RC_EVALGA
        println("*** callbackEvalC0Grad incorrectly called with eval type ", evalRequest.evalRequestCode)
        return -1
    end
    x = evalRequest.x

    # Evaluate nonlinear terms in c0 constraint gradients
    evalResult.jac[1] = 3.0 * x[xind[1]] * x[xind[1]] # *  derivative of x0^3 term  wrt x0

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
cIndices = KNITRO.KN_add_cons(kc, 3)
KNITRO.KN_set_con_eqbnds(kc, cIndices[1], 1.0)
KNITRO.KN_set_con_eqbnds(kc, cIndices[2], 0.0)
KNITRO.KN_set_con_eqbnds(kc, cIndices[3], 0.0)

# Coefficients for 2 linear terms
lconIndexCons = Int32[1, 2]
lconIndexVars = Int32[2, 1]
lconCoefs = [-1.0, -1.0]
KNITRO.KN_add_con_linear_struct(kc, lconIndexCons, lconIndexVars, lconCoefs)

# Coefficients for 2 quadratic terms

#* x1^2 term in c0
#* x3^2 term in c2
qconIndexCons = Int32[0, 2]
qconIndexVars1 = Int32[1, 3]
qconIndexVars2 = Int32[1, 3]
qconCoefs = [1.0, 1.0]


KNITRO.KN_add_con_quadratic_struct(kc, qconIndexCons, qconIndexVars1, qconIndexVars2, qconCoefs)

# Add separate callbacks.

# Set callback data for nonlinear objective term.
cbObj = KNITRO.KN_add_objective_callback(kc, callbackEvalObj)
KNITRO.KN_set_cb_grad(kc, cbObj, callbackEvalObjGrad,
                      objGradIndexVars=xIndices, nV=length(xIndices))

# Set callback data for nonlinear constraint 0 term.
cbC0 = KNITRO.KN_add_eval_callback(kc, false, [cIndices[1]], callbackEvalC0)
indexCons = cIndices[1]  # constraint c0
indexVars = xIndices[1]  # variable x0
KNITRO.KN_set_cb_grad(kc, cbC0, callbackEvalC0Grad, jacIndexCons=[indexCons],
                      jacIndexVars=[indexVars])

# Set callback data for nonlinear constraint 1 term
cbC1 = KNITRO.KN_add_eval_callback(kc, false, [cIndices[2]], callbackEvalC1)
indexCons = [cIndices[2], cIndices[2]]  # constraint c1
indexVars = [xIndices[1], xIndices[1]]  # variables x0 and x3
KNITRO.KN_set_cb_grad(kc, cbC1, nothing, jacIndexCons=indexCons, jacIndexVars=indexVars)
# This one will be approximated via forward finite differences.
KNITRO.KN_set_cb_gradopt(kc, cbC1, KNITRO.KN_GRADOPT_FORWARD)

# Demonstrate passing a userParams structure to the evaluation
# callbacks.  Here we pass back the variable indices set from
# KNITRO.KN_add_vars() for use in the callbacks. Here we pass the same
# userParams structure to each callback but we could define different
# userParams for different callbacks.  This could be useful, for
# instance, if different callbacks operate on different sets of
# variables.
# We increment the indices as Julia is 1-indexed
userEval = xIndices .+ 1
KNITRO.KN_set_cb_user_params(kc, cbObj, userEval)
KNITRO.KN_set_cb_user_params(kc, cbC0, userEval)
KNITRO.KN_set_cb_user_params(kc, cbC1, userEval)

# Set minimize or maximize(if not set, assumed minimize)
KNITRO.KN_set_obj_goal(kc, KNITRO.KN_OBJGOAL_MAXIMIZE)

# Approximate hessian using BFGS
KNITRO.KN_set_param(kc, "hessopt", KNITRO.KN_HESSOPT_BFGS)

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

@testset "Exemple multipleCB" begin
    @test nStatus == 0
    @test_broken objSol ≈ 0.25
    @test_broken x ≈ [0.793701, 0.707107, 0.529732, 0.840896] atol=1e-5
end
