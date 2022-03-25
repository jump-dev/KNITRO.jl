#*******************************************************/
#* Copyright(c) 2021 by Artelys                        */
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
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

using KNITRO, Test

function example_nlp2noderivs(; verbose=true)
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

    # Set minimize or maximize(if not set, assumed minimize)
    KNITRO.KN_set_obj_goal(kc, KNITRO.KN_OBJGOAL_MAXIMIZE)

    # Set option to println output after every iteration.
    kn_outlev = verbose ? KNITRO.KN_OUTLEV_ITER : KNITRO.KN_OUTLEV_NONE
    KNITRO.KN_set_param(kc, KNITRO.KN_PARAM_OUTLEV, kn_outlev)

    # Solve the problem.
    #
    # Return status codes are defined in "knitro.h" and described
    # in the Knitro manual.
    nStatus = KNITRO.KN_solve(kc)
    nStatus, objSol, x, lambda_ = KNITRO.KN_get_solution(kc)
    varbndInfeas, varintInfeas, varviols = KNITRO.KN_get_var_viols(kc, Cint[0, 1, 2, 3])
    coninfeas, conviols = KNITRO.KN_get_con_viols(kc, Cint[0, 1, 2])
    err = KNITRO.KN_get_presolve_error(kc)

    if verbose
        println()
        println("Knitro converged with final status = ", nStatus)
        # An example of obtaining solution information.
        println("  optimal objective value  = ", objSol)
        println("  optimal primal values x  = ", x)
        println("  feasibility violation    = ", KNITRO.KN_get_abs_feas_error(kc))
        println("  KKT optimality violation = ", KNITRO.KN_get_abs_opt_error(kc))
        println("Variables bound violations = ", varbndInfeas)
        println("Variables integrality violations = ", varintInfeas)
        println("Variables violation values = ", varviols)
        println("Constraints bound violations = ", coninfeas)
        println("Constraints violation values = ", conviols)
    end

    @testset "Example HS40 nlp1noderivs" begin
        @test varbndInfeas == [0, 0, 0, 0]
        @test varintInfeas == [0, 0, 0, 0]
        @test varviols ≈ [0.0, 0.0, 0.0, 0.0] atol = 1e-6
        @test coninfeas == [0, 0, 0]
        @test conviols ≈ [0.0, 0.0, 0.0] atol = 1e-6
        @test KNITRO.KN_get_abs_feas_error(kc) == max(conviols...)
    end

    # Delete the Knitro solver instance.
    return KNITRO.KN_free(kc)
end

if KNITRO.KNITRO_VERSION >= v"12.4"
    example_nlp2noderivs(; verbose=isdefined(Main, :KN_VERBOSE) ? KN_VERBOSE : true)
else
    println("Example `nlp2noderivs.jl` is only available with Knitro >= 12.4")
end
