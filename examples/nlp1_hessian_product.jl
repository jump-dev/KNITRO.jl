#*******************************************************/
#* Copyright(c) 2018 by Artelys                        */
#* This source code is subject to the terms of the     */
#* MIT Expat License (see LICENSE.md)                  */
#*******************************************************/

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# This example demonstrates how to use Knitro to solve the following
# simple nonlinear optimization problem by using Hessian vector product.
# This model is test problem HS15 from the Hock & Schittkowski collection.
#
# min   100(x1 - x0^2)^2 +(1 - x0)^2
# s.t.  x0 x1 >= 1
#       x0 + x1^2 >= 0
#       x0 <= 0.5
#
# The standard start point(-2, 1) usually converges to the standard
# minimum at(0.5, 2.0), with final objective = 306.5.
# Sometimes the solver converges to another local minimum
# at(-0.79212, -1.26243), with final objective = 360.4.
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


using KNITRO
using Test

function example_nlp1_hessian_product(; verbose=true)
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
    # The signature of this function matches KN_eval_callback in knitro.h.
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
    #*     FUNCTION callbackEvalHv                                      *
    #*------------------------------------------------------------------*
    # Some algorithms in Knitro (KN_ALG_BAR_CG and KN_ALG_ACT_CG)
    # allow the user to provide a callback routine to compute Hessian-vector
    # products instead of computing the Hessian itself.  This may be
    # useful on large problems where the Hessian is too expensive to
    # compute and store by itself, but where Hessian times vector products can
    # be directly computed and provided.  To enable this option, the user
    # must set the "hessopt" option to KN_HESSOPT_PRODUCT.
    # The signature of this function matches KN_eval_callback in knitro.h.
    # Only "hessVec" is set in the KN_eval_result structure.
    function callbackEvalHv!(kc, cb, evalRequest, evalResult, userParams)
        x = evalRequest.x
        vec = evalRequest.vec
        sigma = evalRequest.sigma
        hessVec = evalResult.hessVec
        # Evaluate the Hessian of the nonlinear objective times the vector "vec".
        # Note: The Hessian-vector terms for the quadratic constraints
        #       will be added internally by Knitro to form
        #       the full Hessian of the Lagrangian - vector product. */
        hessVec[1] = (sigma * ( (-400.0 * x[2]) + (1200.0 * x[1]*x[1]) + 2.0)) * vec[1] +
                    (sigma * (-400.0 * x[1])) * vec[2]
        hessVec[2] = (sigma * (-400.0 * x[1])) * vec[1] + (sigma * 200.0) * vec[2]
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
    kn_outlev = verbose ? KNITRO.KN_OUTLEV_ALL : KNITRO.KN_OUTLEV_NONE
    KNITRO.KN_set_param(kc, KNITRO.KN_PARAM_OUTLEV, kn_outlev)

    # Initialize Knitro with the problem definition.

    # Add the variables and set their bounds.
    # Note: any unset lower bounds are assumed to be
    # unbounded below and any unset upper bounds are
    # assumed to be unbounded above.
    n = 2
    KNITRO.KN_add_vars(kc, n)
    KNITRO.KN_set_var_lobnds_all(kc, [-KNITRO.KN_INFINITY, -KNITRO.KN_INFINITY]) # not necessary since infinite
    KNITRO.KN_set_var_upbnds_all(kc, [0.5, KNITRO.KN_INFINITY])
    # Define an initial point. If not set, Knitro will generate one.
    KNITRO.KN_set_var_primal_init_values_all(kc, [-2.0, 1.0])

    # Add the constraints and set their lower bounds
    m = 2
    KNITRO.KN_add_cons(kc, m)
    KNITRO.KN_set_con_lobnds_all(kc, [1.0, 0.0])

    # Both constraints are quadratic so we can directly load all the
    # structure for these constraints.

    # First load quadratic structure x0*x1 for the first constraint
    KNITRO.KN_add_con_quadratic_struct(kc, 0, 0, 1, 1.0)

    # Load structure for the second constraint.  below we add the linear
    # structure and the quadratic structure separately, though it
    # is possible to add both together in one call to
    # "KNITRO.KN_add_con_quadratic_struct()" since this API function also
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
    # (i.e. Jacobian matrix) for efficiency(this is true even when using
    # finite-difference gradients).
    KNITRO.KN_set_cb_grad(kc, cb, callbackEvalG!)

    # Add a callback function "callbackEvalH" to evaluate the Hessian
    # (i.e. second derivative matrix) of the objective. When using Hessian-vector
    # product, we should set nnzH equal to 0 to avoid unnecessary allocations
    # in Knitro.
    KNITRO.KN_set_cb_hess(kc, cb, 0, callbackEvalHv!)
    # We should specify to knitro to use Hessian vector product here.
    KNITRO.KN_set_param(kc, KNITRO.KN_PARAM_HESSOPT, KNITRO.KN_HESSOPT_PRODUCT)
    # Sometimes, you may want to add a preconditionner to reduce the
    # number of CG iterations in Knitro. Switch to 1 to activate.
    KNITRO.KN_set_param(kc, KNITRO.KN_PARAM_CG_PRECOND, 0)

    # Specify that the user is able to provide evaluations
    # of the hessian matrix without the objective component.
    # turned off by default but should be enabled if possible.
    KNITRO.KN_set_param(kc, KNITRO.KN_PARAM_HESSIAN_NO_F, KNITRO.KN_HESSIAN_NO_F_ALLOW)

    # Set minimize or maximize(if not set, assumed minimize)
    KNITRO.KN_set_obj_goal(kc, KNITRO.KN_OBJGOAL_MINIMIZE)

    # Perform a derivative check.
    KNITRO.KN_set_param(kc, KNITRO.KN_PARAM_DERIVCHECK, KNITRO.KN_DERIVCHECK_ALL)

    # Increase tolerance on optimality conditions
    KNITRO.KN_set_param(kc, KNITRO.KN_PARAM_OPTTOL, 1e-10)

    # Solve the problem.
    #
    # Return status codes are defined in "knitro.h" and described
    # in the Knitro manual.
    nStatus = KNITRO.KN_solve(kc)

    # An example of obtaining solution information.
    nStatus, objSol, x, lambda_ = KNITRO.KN_get_solution(kc)
    c = KNITRO.KN_get_con_values(kc)

    if verbose
        println("Optimal objective value  = ", objSol)
        println("Optimal x(with corresponding multiplier)")
        for i in 1:n
            println("  x[$i] = ", x[i], "(lambda = ",  lambda_[m+i], ")")
        end
        println("Optimal constraint values(with corresponding multiplier)")
        for j in 1:m
            println("  c[$j] = ", c[j], "(lambda = ",  lambda_[j], ")")
        end
        println("  feasibility violation    = ", KNITRO.KN_get_abs_feas_error(kc))
        println("  KKT optimality violation = ", KNITRO.KN_get_abs_opt_error(kc))
    end

    # Delete the Knitro solver instance.
    KNITRO.KN_free(kc)

    @testset "Example HS15 nlp1" begin
        @test nStatus == 0
        @test objSol  ≈ 306.5
        @test x ≈ [0.5, 2]
    end
end

example_nlp1_hessian_product(; verbose=isdefined(Main, :KN_VERBOSE) ? KN_VERBOSE : true)

