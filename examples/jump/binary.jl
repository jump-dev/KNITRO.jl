# Test JuMP in AUTOMATIC mode.

using KNITRO, JuMP
using Test
using MathOptInterface
const MOI = MathOptInterface

# Binary Variable
# max x
# st  x ∈ {0,1}

# Create JuMP Model in automatic mode.
model = Model(KNITRO.Optimizer)

@variable(model, x, Bin)
@objective(model, Max, x)
JuMP.optimize!(model)

@test JuMP.termination_status(model) == MOI.OPTIMAL
@test JuMP.primal_status(model) == MOI.FEASIBLE_POINT
@test JuMP.value(x) ≈ 1.0
