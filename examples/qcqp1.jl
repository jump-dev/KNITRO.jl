#*******************************************************/
#* Copyright(c) 2018 by Artelys                        */
#* This source code is subject to the terms of the     */
#* MIT Expat License (see LICENSE.md)                  */
#*******************************************************/

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#  This example demonstrates how to use Knitro to solve the following
#  simple quadratically constrained quadratic programming problem(QCQP).
#
#  min   1000 - x0^2 - 2 x1^2 - x2^2 - x0 x1 - x0 x2 #  s.t.  8 x0 + 14 x1 + 7 x2 = 56
#        x0^2 + x1^2 + x2^2 >= 25
#        x0 >= 0, x1 >= 0, x2 >= 0
#
#  The start point(2, 2, 2) converges to the minimum at(0, 0, 8),
#  with final objective = 936.0.  From a different start point,
#  Knitro may converge to an alternate local solution at(7, 0, 0),
#  with objective = 951.0.
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


using KNITRO
using Test

function example_qcqp1(; verbose=true)
    # Create a new Knitro solver instance.
    kc = KNITRO.KN_new()

    # Illustrate how to override default options by reading from
    # the knitro.opt file.
    options = joinpath(dirname(@__FILE__), "..", "examples", "knitro.opt")
    KNITRO.KN_load_param_file(kc, options)
    kn_outlev = verbose ? KNITRO.KN_OUTLEV_ITER : KNITRO.KN_OUTLEV_NONE
    KNITRO.KN_set_param(kc, KNITRO.KN_PARAM_OUTLEV, kn_outlev)

    # Initialize Knitro with the problem definition.

    # Add the variables and set their bounds and initial values.
    # Note: unset bounds assumed to be infinite.
    KNITRO.KN_add_vars(kc, 3)
    KNITRO.KN_set_var_lobnds_all(kc, [0., 0., 0.])
    KNITRO.KN_set_var_primal_init_values_all(kc,  [2.0, 2.0, 2.0])

    # Add the constraints and set their bounds.
    KNITRO.KN_add_cons(kc, 2)
    KNITRO.KN_set_con_eqbnd(kc, 0, 56.0)
    KNITRO.KN_set_con_lobnd(kc, 1, 25.0)

    # Add coefficients for linear constraint.
    lconIndexVars = Int32[0, 1, 2]
    lconCoefs     = [8.0, 14.0, 7.0]
    KNITRO.KN_add_con_linear_struct_one(kc, 3, 0, lconIndexVars, lconCoefs)

    # Add coefficients for quadratic constraint
    qconIndexVars1 = Int32[0, 1, 2]
    qconIndexVars2 = Int32[0, 1, 2]
    qconCoefs      = [1.0, 1.0, 1.0]
    KNITRO.KN_add_con_quadratic_struct_one(kc, 3, 1, qconIndexVars1, qconIndexVars2, qconCoefs)

    # Set minimize or maximize(if not set, assumed minimize)
    KNITRO.KN_set_obj_goal(kc, KNITRO.KN_OBJGOAL_MINIMIZE)

    # Add constant value to the objective.
    KNITRO.KN_add_obj_constant(kc, 1000.0)

    # Set quadratic objective structure.
    qobjIndexVars1 = Int32[0, 1, 2, 0, 0]
    qobjIndexVars2 = Int32[0, 1, 2, 1, 2]
    qobjCoefs      = [-1.0, -2.0, -1.0, -1.0, -1.0]

    KNITRO.KN_add_obj_quadratic_struct(kc, 5, qobjIndexVars1, qobjIndexVars2, qobjCoefs)

    # Solve the problem.
    #
    # Return status codes are defined in "knitro.h" and described
    # in the Knitro manual.
    nStatus = KNITRO.KN_solve(kc)
    nStatus, objSol, x, lambda_ =  KNITRO.KN_get_solution(kc)

    # An example of obtaining solution information.
    if verbose
        println("Knitro converged with final status = ", nStatus)
        println("  optimal objective value  = ", objSol)
        println("  optimal primal values x  = ", x)
        println("  feasibility violation    = ", KNITRO.KN_get_abs_feas_error(kc))
        println("  KKT optimality violation = ", KNITRO.KN_get_abs_opt_error(kc))
    end

    # Delete the Knitro solver instance.
    KNITRO.KN_free(kc)

    @testset "Example QCQP1" begin
        @test nStatus == 0
        @test objSol ≈ 936.
        @test x ≈ [0., 0., 8.]
    end
end

example_qcqp1(; verbose=isdefined(Main, :KN_VERBOSE) ? KN_VERBOSE : true)

