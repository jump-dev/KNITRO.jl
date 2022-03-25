#*******************************************************/
#* Copyright(c) 2018 by Artelys                        */
#* This source code is subject to the terms of the     */
#* MIT Expat License (see LICENSE.md)                  */
#*******************************************************/

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#  This example is like nlp2.jl, but shows how to re-solve
#  a model after modifying linear structures.
#
#  We first show how to use Knitro to solve the following
#  simple nonlinear optimization problem.  This model is test problem
#  HS40 from the Hock & Schittkowski collection.
#
#  max   x0*x1*x2*x3            (obj)
#  s.t.  x0^3 + x1^2 = 1        (c0)
#        x0^2*x3 - x2 = 0       (c1)
#        x3^2 - x1 = 0          (c2)
#
#  Then we add a new linear term 0.5x3 to (c2), so it becomes
#        x3^2 - x1 + 0.5x3 = 0  (c2)
#  and also add a new linear inequality constraint
#        x1 + 2x2 + x3 <= 2.5   (c3)
#  to the model.  Then it is re-solved using the same kc structure.
#
#  Finally we remove the linear term 0.5x3 from (c2), and change
#  the linear term x1 in c(3) to be 3.5x1 so the model becomes
#  max   x0*x1*x2*x3             (obj)
#  s.t.  x0^3 + x1^2 = 1         (c0)
#        x0^2*x3 - x2 = 0        (c1)
#        x3^2 - x1 = 0           (c2)
#        3.5x1 + 2x2 + x3 <= 2.5 (c3)
#
# and then re-solve again.
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

using KNITRO, Test

function example_nlp2resolve(; verbose=true)
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
        KNITRO.KN_set_var_primal_init_value(kc, x, 0.8)
    end

    # Add the constraints and set the rhs and coefficients
    KNITRO.KN_add_cons(kc, 3)
    KNITRO.KN_set_con_eqbnds_all(kc, [1.0, 0.0, 0.0])

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

    KNITRO.KN_add_con_quadratic_struct(
        kc,
        qconIndexCons,
        qconIndexVars1,
        qconIndexVars2,
        qconCoefs,
    )

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
    KNITRO.KN_set_cb_grad(
        kc,
        cb,
        callbackEvalGA,
        jacIndexCons=cbjacIndexCons,
        jacIndexVars=cbjacIndexVars,
    )

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
    KNITRO.KN_set_cb_hess(
        kc,
        cb,
        length(cbhessIndexVars1),
        callbackEvalH,
        hessIndexVars1=cbhessIndexVars1,
        hessIndexVars2=cbhessIndexVars2,
    )

    # Set minimize or maximize(if not set, assumed minimize)
    KNITRO.KN_set_obj_goal(kc, KNITRO.KN_OBJGOAL_MAXIMIZE)

    # Set option to println output after every iteration.
    kn_outlev = verbose ? KNITRO.KN_OUTLEV_ITER : KNITRO.KN_OUTLEV_NONE
    KNITRO.KN_set_param(kc, KNITRO.KN_PARAM_OUTLEV, kn_outlev)

    # Solve the initial problem.
    #
    # Return status codes are defined in "knitro.h" and described
    # in the Knitro manual.
    nStatus = KNITRO.KN_solve(kc)

    if verbose
        println()
        println("Knitro converged with final status = ", nStatus)
        # An example of obtaining solution information.
        nStatus, objSol, x, lambda_ = KNITRO.KN_get_solution(kc)
        println("  optimal objective value  = ", objSol)
        println("  optimal primal values x  = ", x)
        println("  feasibility violation    = ", KNITRO.KN_get_abs_feas_error(kc))
        println("  KKT optimality violation = ", KNITRO.KN_get_abs_opt_error(kc))
    end

    # =============== MODIFY PROBLEM AND RE-SOLVE ===========
    # Add 0.5x3 linear term to c2
    KNITRO.KN_add_con_linear_struct(kc, 2, 3, 0.5)
    # Now add a new linear constraint x1 + 2x2 + x3 <= 2.5 (c3) and re-solve
    cIndNew = KNITRO.KN_add_con(kc)
    KNITRO.KN_set_con_upbnd(kc, cIndNew, 2.5)
    KNITRO.KN_add_con_linear_struct(kc, cIndNew, Int32[1, 2, 3], [1.0, 2.0, 1.0])

    # Tell Knitro to try a "warm-start" since it is starting from the solution
    # of the previous solve, which may be a good initial point for the solution
    # of the slightly modified problem.
    KNITRO.KN_set_param(
        kc,
        KNITRO.KN_PARAM_STRAT_WARM_START,
        KNITRO.KN_STRAT_WARM_START_YES,
    )

    if verbose
        println(
            "****Re-solve after adding new linear term to c[2] and adding new constraint c[",
            cIndNew,
            "]****",
        )
    end

    nStatus = KNITRO.KN_solve(kc)

    if verbose
        println()
        println("Knitro converged with final status = ", nStatus)
        nStatus, objSol, x, lambda_ = KNITRO.KN_get_solution(kc)
        println("  optimal objective value  = ", objSol)
        println("  optimal primal values x  = ", x)
        println("  feasibility violation    = ", KNITRO.KN_get_abs_feas_error(kc))
        println("  KKT optimality violation = ", KNITRO.KN_get_abs_opt_error(kc))
    end

    # =============== MODIFY PROBLEM AND RE-SOLVE AGAIN ===========
    # Delete 0.5x3 linear term from c2
    KNITRO.KN_del_con_linear_term(kc, 2, 3)
    # Change x1 linear term in c3 to 3.5*x1
    KNITRO.KN_chg_con_linear_term(kc, 3, 1, 3.5)

    verbose && println(
        "****Re-solve after adding new linear term to c[2] and adding new constraint c[",
        cIndNew,
        "]****",
    )
    nStatus = KNITRO.KN_solve(kc)

    nStatus, objSol, x, lambda_ = KNITRO.KN_get_solution(kc)
    if verbose
        println()
        println("Knitro converged with final status = ", nStatus)
        println("  optimal objective value  = ", objSol)
        println("  optimal primal values x  = ", x)
        println("  feasibility violation    = ", KNITRO.KN_get_abs_feas_error(kc))
        println("  KKT optimality violation = ", KNITRO.KN_get_abs_opt_error(kc))
    end

    @testset "Example HS40 nlp2resolve" begin
        @test nStatus == 0
        @test objSol ≈ 0.07133 atol = 1e-4
        @test x ≈ [0.973535, 0.278048, 0.499762, 0.527303] atol = 1e-4
    end

    # Delete the Knitro solver instance.
    return KNITRO.KN_free(kc)
end

if KNITRO.KNITRO_VERSION >= v"12.4"
    example_nlp2resolve(; verbose=isdefined(Main, :KN_VERBOSE) ? KN_VERBOSE : true)
else
    println("Example `nlp2resolve.jl` is only available with Knitro >= 12.4")
end
