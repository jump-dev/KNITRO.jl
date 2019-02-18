#*******************************************************/
#* Copyright(c) 2018 by Artelys                        */
#* This source code is subject to the terms of the     */
#* MIT Expat License (see LICENSE.md)                  */
#*******************************************************/
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# This file contains routines to implement problemDef.h for
# a simple nonlinear least-squares problem.
#
# min  ( x0*1.309^x1 - 2.138 )^2 +( x0*1.471^x1 - 3.421 )^2 +( x0*1.49^x1 - 3.597 )^2
#        +( x0*1.565^x1 - 4.34 )^2 +( x0*1.611^x1 - 4.882 )^2 +( x0*1.68^x1-5.66 )^2
#
# The standard start point(1.0, 5.0) usually converges to the standard
# minimum at(0.76886, 3.86041), with final objective = 0.00216.
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


using KNITRO


#*------------------------------------------------------------------*
#*     FUNCTION callbackEvalR                                       *
#*------------------------------------------------------------------*
# The signature of this function matches KNITRO.KN_eval_callback in knitro.h.
# Only "rsd" is set in the KNITRO.KN_eval_result structure.
function callbackEvalR(kc, cb, evalRequest, evalResult, userParams)
    if evalRequest.evalRequestCode != KNITRO.KN_RC_EVALR
        println("*** callbackEvalR incorrectly called with eval type ", evalRequest.evalRequestCode)
        return -1
    end
    x = evalRequest.x

    # Clamp x1 to 1000 so as to avoid overflow
    if x[2] > 1000.0
        x[2] = 1000.0
    end

    # Evaluate nonlinear residual components
    evalResult.rsd[1] = x[1] * 1.309^x[2]
    evalResult.rsd[2] = x[1] * 1.471^x[2]
    evalResult.rsd[3] = x[1] * 1.49^x[2]
    evalResult.rsd[4] = x[1] * 1.565^x[2]
    evalResult.rsd[5] = x[1] * 1.611^x[2]
    evalResult.rsd[6] = x[1] * 1.68^x[2]

    return 0
end

#*------------------------------------------------------------------*
#*     FUNCTION callbackEvalRJ                                      *
#*------------------------------------------------------------------*
# The signature of this function matches KNITRO.KN_eval_callback in knitro.h.
# Only "rsdJac" is set in the KNITRO.KN_eval_result structure.
function callbackEvalRJ(kc, cb, evalRequest, evalResult, userParams)
    if evalRequest.evalRequestCode != KNITRO.KN_RC_EVALRJ
        println("*** callbackEvalRJ incorrectly called with eval type %d" % evalRequest.evalRequestCode)
        return -1
    end
    x = evalRequest.x

    # Clamp x1 to 1000 so as to avoid overflow
    if x[2] > 1000.0
        x[2] = 1000.0
    end

    # Evaluate non-zero residual Jacobian elements(row major order).
    evalResult.rsdJac[1]  = 1.309^x[2]
    evalResult.rsdJac[2]  = x[1] * log(1.309) * 1.309^x[2]
    evalResult.rsdJac[3]  = 1.471^x[2]
    evalResult.rsdJac[4]  = x[1] * log(1.471) * 1.471^x[2]
    evalResult.rsdJac[5]  = 1.49^x[2]
    evalResult.rsdJac[6]  = x[1] * log(1.49) * 1.49^x[2]
    evalResult.rsdJac[7]  = 1.565^x[2]
    evalResult.rsdJac[8]  = x[1] * log(1.565) * 1.565^x[2]
    evalResult.rsdJac[9]  = 1.611^x[2]
    evalResult.rsdJac[10] = x[1] * log(1.611) * 1.611^x[2]
    evalResult.rsdJac[11] = 1.68^x[2]
    evalResult.rsdJac[12] = x[1] * log(1.68) * 1.68^x[2]

    return 0
end

#*------------------------------------------------------------------*
#*     main                                                         *
#*------------------------------------------------------------------*

# Create a new Knitro solver instance.
kc = KNITRO.KN_new()

# Add the variables/parameters.
# Note: Any unset lower bounds are assumed to be
# unbounded below and any unset upper bounds are
# assumed to be unbounded above.
n = 2 # # of variables/parameters
KNITRO.KN_add_vars(kc, n)

# In order to prevent the possiblity of numerical
# overflow from very large numbers, we set a
# reasonable upper bound on variable x[1] and set the
# "honorbnds" option for this variable to enforce
# that all trial x[1] values satisfy this bound.
KNITRO.KN_set_var_upbnds(kc, 1, 100.0)
KNITRO.KN_set_var_honorbnds(kc, 1, KNITRO.KN_HONORBNDS_ALWAYS)

# Add the residuals.
m = 6 # # of residuals
KNITRO.KN_add_rsds(kc, m)

# Set the array of constants in the residuals
KNITRO.KN_add_rsd_constants(kc, [-2.138, -3.421, -3.597, -4.34, -4.882, -5.66])

# Add a callback function "callbackEvalR" to evaluate the nonlinear
# residual components.  Note that the constant terms are added
# separately above, and will not be included in the callback.
cb = KNITRO.KN_add_lsq_eval_callback(kc, callbackEvalR)

# Also add a callback function "callbackEvalRJ" to evaluate the
# Jacobian of the residuals.  If not provided, Knitro will approximate
# the residual Jacobian using finite-differencing.  However, we recommend
# providing callbacks to evaluate the exact Jacobian whenever
# possible as this can drastically improve the performance of Knitro.
# We specify the residual Jacobian in "dense" row major form for simplicity.
# However for models with many sparse residuals, it is important to specify
# the non-zero sparsity structure of the residual Jacobian for efficiency
#(this is true even when using finite-difference gradients).
KNITRO.KN_set_cb_rsd_jac(kc, cb, KNITRO.KN_DENSE_ROWMAJOR, callbackEvalRJ)

# Solve the problem.
#
# Return status codes are defined in "knitro.h" and described
# in the Knitro manual.

nRC = KNITRO.KN_solve(kc)

# An example of obtaining solution information.
# Return status codes are defined in "knitro.h" and described
# in the Knitro manual.
nStatus, obj, x, lambda_ = KNITRO.KN_get_solution(kc)
if nStatus != 0
    println("Knitro successful. The optimal solution is:")
    for i in 1:n
        println("x[$i]= ", x[i])
    end
end

# Delete the knitro solver instance.
KNITRO.KN_free(kc)

@testset "Example LSQ2" begin
    @test nStatus == 0
    @test obj ≈ 0.00216 atol=1e-4
    @test x ≈ [0.76886, 3.86041] atol=1e-4
 end
