#*******************************************************/
#* Copyright(c) 2018 by Artelys                        */
#* This source code is subject to the terms of the     */
#* MIT Expat License (see LICENSE.md)                  */
#*******************************************************/

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# This example demonstrates how to use Knitro to solve the following
# simple mathematical program with equilibrium/complementarity
# constraints(MPEC/MPCC).
#
#  min  (x0 - 5)^2 +(2 x1 + 1)^2
#  s.t.  -1.5 x0 + 2 x1 + x2 - 0.5 x3 + x4 = 2
#        x2 complements(3 x0 - x1 - 3)
#        x3 complements(-x0 + 0.5 x1 + 4)
#        x4 complements(-x0 - x1 + 7)
#        x0, x1, x2, x3, x4 >= 0
#
# The complementarity constraints must be converted so that one
# nonnegative variable complements another nonnegative variable.
#
#  min  (x0 - 5)^2 +(2 x1 + 1)^2
#  s.t.  -1.5 x0 + 2 x1 + x2 - 0.5 x3 + x4 = 2  (c0)
#        3 x0 - x1 - 3 - x5 = 0                 (c1)
#        -x0 + 0.5 x1 + 4 - x6 = 0              (c2)
#        -x0 - x1 + 7 - x7 = 0                  (c3)
#        x2 complements x5
#        x3 complements x6
#        x4 complements x7
#        x0, x1, x2, x3, x4, x5, x6, x7 >= 0
#
# The solution is(1, 0, 3.5, 0, 0, 0, 3, 6), with objective value 17.
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


using KNITRO, Test

#*------------------------------------------------------------------*
#*     main                                                         *
#*------------------------------------------------------------------*

# Create a new Knitro solver instance.
kc = KNITRO.KN_new()

# Illustrate how to override default options by reading from
# the knitro.opt file.
options = joinpath(dirname(@__FILE__), "..", "examples", "knitro.opt")
KNITRO.KN_load_param_file(kc, options)

# Initialize Knitro with the problem definition.

# Add the variables and set their bounds and initial values.
# Note: unset bounds assumed to be infinite.
KNITRO.KN_add_vars(kc, 8)
KNITRO.KN_set_var_lobnds(kc, zeros(Float64, 8))
KNITRO.KN_set_var_primal_init_values(kc, zeros(Float64, 8))

# Add the constraints and set their bounds.
KNITRO.KN_add_cons(kc, 4)
KNITRO.KN_set_con_eqbnds(kc, Float64[2, 3, -4, -7])

# Add coefficients for all linear constraints at once.

# c0
lconIndexCons = Int32[0, 0, 0, 0, 0]
lconIndexVars = Int32[0, 1, 2, 3, 4]
lconCoefs = [-1.5, 2.0, 1.0, -0.5, 1.0]

# c1
lconIndexCons = [lconIndexCons; Int32[1, 1, 1]]
lconIndexVars = [lconIndexVars; Int32[0, 1, 5]]
lconCoefs = [lconCoefs; [3.0, -1.0, -1.0]]

# c2
lconIndexCons = [lconIndexCons; Int32[2, 2, 2]]
lconIndexVars = [lconIndexVars; Int32[0, 1, 6]]
lconCoefs = [lconCoefs; [-1.0, 0.5, -1.0]]

# c3
lconIndexCons = [lconIndexCons; Int32[3, 3, 3]]
lconIndexVars = [lconIndexVars; Int32[0, 1, 7]]
lconCoefs = [lconCoefs; [-1.0, -1.0, -1.0]]

KNITRO.KN_add_con_linear_struct(kc, lconIndexCons, lconIndexVars, lconCoefs)

# Note that the objective(x0 - 5)^2 +(2 x1 + 1)^2 when
# expanded becomes:
#    x0^2 + 4 x1^2 - 10 x0 + 4 x1 + 26

# Add quadratic coefficients for the objective
qobjIndexVars1 = Int32[0, 1]
qobjIndexVars2 = Int32[0, 1]
qobjCoefs = [1.0, 4.0]
KNITRO.KN_add_obj_quadratic_struct(kc, qobjIndexVars1, qobjIndexVars2, qobjCoefs)

# Add linear coefficients for the objective
lobjIndexVars = Int32[0, 1]
lobjCoefs = [-10.0, 4.0]
KNITRO.KN_add_obj_linear_struct(kc, lobjIndexVars, lobjCoefs)

# Add constant to the objective
KNITRO.KN_add_obj_constant(kc, 26.0)

# Set minimize or maximize(if not set, assumed minimize)
KNITRO.KN_set_obj_goal(kc, KNITRO.KN_OBJGOAL_MINIMIZE)

# Now add the complementarity constraints
ccTypes = [KNITRO.KN_CCTYPE_VARVAR, KNITRO.KN_CCTYPE_VARVAR, KNITRO.KN_CCTYPE_VARVAR]
indexComps1 = Int32[2, 3, 4]
indexComps2 = Int32[5, 6, 7]
KNITRO.KN_set_compcons(kc, ccTypes, indexComps1, indexComps2)

# Solve the problem.
#
# Return status codes are defined in "knitro.h" and described
# in the Knitro manual.
nStatus = KNITRO.KN_solve(kc)
println("Knitro converged with final status = ", nStatus)

# An example of obtaining solution information.
nStatus, objSol, x, lambda_ = KNITRO.KN_get_solution(kc)
println("  optimal objective value  = ", objSol)
println("  optimal primal values x0=", x[1])
println("                        x1=", x[2])
println("                        x2=", (x[3], x[6]))
println("                        x3=", (x[4], x[7]))
println("                        x4=", (x[5], x[8]))
println("  feasibility violation    = ", KNITRO.KN_get_abs_feas_error(kc))
println("  KKT optimality violation = ", KNITRO.KN_get_abs_opt_error(kc))

# Delete the Knitro solver instance.
KNITRO.KN_free(kc)

@testset "Example MPEC 1" begin
    @test nStatus == 0
    @test objSol ≈ 17.
    @test x ≈ [1., 0., 3.5, 0., 0., 0., 3., 6.]
end
