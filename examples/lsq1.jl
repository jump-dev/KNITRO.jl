#*******************************************************/
#* Copyright(c) 2018 by Artelys                        */
#* This source code is subject to the terms of the     */
#* MIT Expat License (see LICENSE.md)                  */
#*******************************************************/

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# This example demonstrates how to use Knitro to solve a simple
# linear least squares data fitting problem.  This model is
# Example 3.2 from "Scientific Computing An Introductory Survey",
# by Michael T. Heath.  In this example we want to fit a quadratic
# polynomial
#
#  y = f(t, x) = x0 + x1*t + x2*t^2
#
# to the five data points given by:
#
#  t = [-1, -0.5 0, 0.5, 1], y = [1, 0.5, 0, 0.5, 2]
#
# The residual functions are given by
#     y - f(t,x)
# for the five data points, i.e.,
#
# r0:   1 - x0 +     x1 -      x2
# r1: 0.5 - x0 + 0.5*x1 - 0.25*x2
# r2:     - x0
# r3: 0.5 - x0 - 0.5*x1 - 0.25*x2
# r4:   2 - x0 -     x1 -      x2
#
# The unknown variables we are solving for are the parameters,
# x = [x0, x1, x2].  The solution is x*=[0.086, 0.4, 1.4].
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


using KNITRO, Test

#*------------------------------------------------------------------*
#*     main                                                         *
#*------------------------------------------------------------------*

# Create a new Knitro solver instance.
kc = KNITRO.KN_new()

# Add the variables/parameters.
# Note: Any unset lower bounds are assumed to be
# unbounded below and any unset upper bounds are
# assumed to be unbounded above.
n = 3 # # of variables/parameters
KNITRO.KN_add_vars(kc, n)

# Add the residuals.
m = 5 # # of residuals
KNITRO.KN_add_rsds(kc, m)

# Set the array of constants, y, in the residuals
KNITRO.KN_add_rsd_constants(kc, [1.0, 0.5, 0.0, 0.5, 2.0])

# Set the linear coefficients for all the residuals.

# coefficients for r0
indexRsds = Int32[0, 0, 0]
indexVars = Int32[0, 1, 2]
coefs = [-1.0, 1.0, -1.0]

# coefficients for r1
indexRsds = [indexRsds; Int32[1, 1, 1]]
indexVars = [indexVars; Int32[0, 1, 2]]
coefs = [coefs; [-1.0, 0.5, -0.25]]

# coefficient for r2
indexRsds = [indexRsds; Int32[2]]
indexVars = [indexVars; Int32[0]]
coefs = [coefs; [-1.0]]

# coefficients for r3
indexRsds = [indexRsds; Int32[3, 3, 3]]
indexVars = [indexVars; Int32[0, 1, 2]]
coefs = [coefs; [-1.0, -0.5, -0.25]]

# coefficients for r4
indexRsds = [indexRsds; Int32[4, 4, 4]]
indexVars = [indexVars; Int32[0, 1, 2]]
coefs = [coefs; [-1.0, -1.0, -1.0]]

# Pass in the linear coefficients
KNITRO.KN_add_rsd_linear_struct(kc, indexRsds, indexVars, coefs)

# Solve the problem.
#
# Return status codes are defined in "knitro.h" and described
# in the Knitro manual.

nRC = KNITRO.KN_solve(kc)

if nRC != 0
    println("Knitro failed to solve the problem, status = ",  nRC)
else
    # An example of obtaining solution information.
    # Return status codes are defined in "knitro.h" and described
    # in the Knitro manual.
    nStatus, obj, x, lambda_ = KNITRO.KN_get_solution(kc)
    println("Knitro successful. The optimal solution is:")
    for i in 1:n
        println("x[$i]=", x[i])
    end
end

# Delete the knitro solver instance.
KNITRO.KN_free(kc)

@testset "Example LSQ1" begin
    @test nStatus == 0
    # we found only a loose approximation
    @test x ≈ [0.086, 0.4, 1.4] atol=1e-1
end
