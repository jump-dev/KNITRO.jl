#*******************************************************/
#* Copyright(c) 2018 by Artelys                        */
#* This source code is subject to the terms of the     */
#* MIT Expat License (see LICENSE.md)                  */
#*******************************************************/

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#  This example demonstrates how to use Knitro to solve the following
#  simple quadratic programming problem (QP).
#
#     minimize     0.5*(x0^2+x1^2+x2^2) + 11*x0 + x2
#     subject to   -6*x2  <= 5
#                 0 <= x0
#                 0 <= x1
#                -3 <= x2 <= 2
#
#  The optimal solution is:
#     obj=-0.4861   x=[0,0,-5/6]
#
#  The purpose is to illustrate how to invoke Knitro using the C
#  language API.
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

using KNITRO
using Test

function example_qp1(; verbose=true)
    # Used to specify whether linear and quadratic objective
    # terms are loaded separately or together in this example.
    bSeparate = false

    # Create a new Knitro solver instance.
    kc = KNITRO.KN_new()

    # Illustrate how to override default options by reading from
    # the knitro.opt file.
    options = joinpath(dirname(@__FILE__), "..", "examples", "knitro.opt")
    KNITRO.KN_load_param_file(kc, options)
    kn_outlev = verbose ? KNITRO.KN_OUTLEV_ITER : KNITRO.KN_OUTLEV_NONE
    KNITRO.KN_set_int_param(kc, KNITRO.KN_PARAM_OUTLEV, kn_outlev)

    # Initialize Knitro with the problem definition.

    # Add the variables and set their bounds.
    # Note: unset bounds assumed to be infinite.
    KNITRO.KN_add_vars(kc, 3, C_NULL)
    KNITRO.KN_set_var_lobnds_all(kc, [0.0, 0.0, -3.0])
    KNITRO.KN_set_var_upbnd(kc, 2, 2.0)

    # Add the constraint and set the bound and coefficient.
    KNITRO.KN_add_cons(kc, 1, C_NULL)
    KNITRO.KN_set_con_upbnd(kc, 0, 5.0)
    KNITRO.KN_add_con_linear_struct(kc, 1, Cint[0], Cint[2], [-6.0])

    # Set the coefficients for the objective -
    # can either set linear and quadratic objective structure
    # separately or all at once.  We show both cases below.
    # Change the value of "bSeparate" to try both cases.

    if (bSeparate)
        # Set linear and quadratic objective structure separately.
        # First set linear objective structure.
        lobjIndexVars = Int32[0, 2]
        lobjCoefs = [11.0, 1.0]
        KNITRO.KN_add_obj_linear_struct(kc, 2, lobjIndexVars, lobjCoefs)
        # Now set quadratic objective structure.
        qobjIndexVars1 = Int32[0, 1, 2]
        qobjIndexVars2 = Int32[0, 1, 2]
        qobjCoefs = [0.5, 0.5, 0.5]
        KNITRO.KN_add_obj_quadratic_struct(kc, 3, qobjIndexVars1, qobjIndexVars2, qobjCoefs)
    else
        # Example of how to set linear and quadratic objective
        # structure at once. Setting the 2nd variable index in a
        # quadratic term to be negative, treats it as a linear term.
        indexVars1 = Int32[0, 1, 2, 0, 2]
        indexVars2 = Int32[0, 1, 2, -1, -1]  # -1 for linear coefficients
        objCoefs = [0.5, 0.5, 0.5, 11.0, 1.0]
        KNITRO.KN_add_obj_quadratic_struct(kc, 5, indexVars1, indexVars2, objCoefs)
    end

    # Set minimize or maximize (if not set, assumed minimize)
    KNITRO.KN_set_obj_goal(kc, KNITRO.KN_OBJGOAL_MINIMIZE)

    # Enable iteration output and crossover procedure to try to
    # get more solution precision
    KNITRO.KN_set_int_param(kc, KNITRO.KN_PARAM_BAR_MAXCROSSIT, 5)

    # Solve the problem.
    #
    # Return status codes are defined in "kn_defines.jl" and described
    # in the Knitro manual.
    nStatus = KNITRO.KN_solve(kc)
    nStatus, objSol, x, lambda_ = KNITRO.KN_get_solution(kc)

    # An example of obtaining solution information.
    if verbose
        feasError = Ref{Cdouble}()
        KNITRO.KN_get_abs_feas_error(kc, feasError)
        optError = Ref{Cdouble}()
        KNITRO.KN_get_abs_opt_error(kc, optError)
        println("Knitro converged with final status = ", nStatus)
        println("  optimal objective value  = ", objSol)
        println("  optimal primal values x  = ", x)
        println("  feasibility violation    = ", feasError[])
        println("  KKT optimality violation = ", optError[])
    end
    # Delete the Knitro solver instance.
    KNITRO.KN_free(kc)

    @testset "Example QP1" begin
        @test nStatus == 0
        @test objSol ≈ -0.4861 atol = 1e-4
        @test x ≈ [0.0, 0.0, -5 / 6] atol = 1e-5
    end
end

example_qp1(; verbose=isdefined(Main, :KN_VERBOSE) ? KN_VERBOSE : true)
