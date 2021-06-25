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

using JuMP, MathOptInterface
using KNITRO
using Test

const MOI = MathOptInterface
b = [-3.0, 4.0, 7.0]
M = [3.0   -1.0   0.0   0.0   0.0;
     -1.0   0.5   0.0   0.0   0.0;
     -1.0  -1.0   0.0   0.0   0.0]

model = JuMP.Model(KNITRO.Optimizer)

@variable(model, x[1:5] >= 0)
@constraint(model, -1.5 * x[1] + 2.0 * x[2] + x[3] - 0.5 * x[4] + x[5] == 2.0)

@constraint(model, [M*x + b; x[3:5]] in MOI.Complements(6))
@objective(model, Min, (x[1] - 5.0)^2 + (2.0 * x[2] + 1.0)^2)

JuMP.optimize!(model)

@test JuMP.has_values(model)
@test JuMP.termination_status(model) == MOI.LOCALLY_SOLVED
@test JuMP.primal_status(model) == MOI.FEASIBLE_POINT
@test JuMP.value.(x) ≈ [1.0, 0.0, 3.5, 0.0, 0.0] atol=1e-3
