# Adaptation of some examples in MosekTools
# Refer to:
# https://github.com/JuliaOpt/MosekTools.jl/blob/master/test/jump_soc.jl
#
# MIT License
# Copyright (c) 2017, Ulf Worsøe, Mosek Aps

using KNITRO
using JuMP
using Test
using MathOptInterface
const MOI = MathOptInterface

model = Model(with_optimizer(KNITRO.Optimizer, outlev=0))
@variable(model, x)
@variable(model, y)
@variable(model, t >= 0.0)
@objective(model, Min, t)
@constraint(model, x + y >= 1.0)
@constraint(model, [t, x, y] in MOI.SecondOrderCone(3))

JuMP.optimize!(model)

@test JuMP.has_values(model)
@test JuMP.termination_status(model) == MOI.LOCALLY_SOLVED
@test JuMP.primal_status(model) == MOI.FEASIBLE_POINT
@test JuMP.objective_value(model) ≈ sqrt(1/2) atol=1e-6
@test JuMP.value.([x,y,t]) ≈ [0.5, 0.5, sqrt(1/2)] atol=1e-3
