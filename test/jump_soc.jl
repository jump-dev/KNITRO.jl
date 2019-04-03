# Adaptation of some examples in MosekTools
# Refer to:
# https://github.com/JuliaOpt/MosekTools.jl/blob/master/test/jump_soc.jl
#
# MIT License
# Copyright (c) 2017, Ulf Worsøe, Mosek Aps

using JuMP

@testset "Second-order Cone Programming" begin
    solver = KNITRO.Optimizer

    @testset "SOC1" begin
        m = Model(with_optimizer(solver, outlev=0))
        @variable(m, x)
        @variable(m, y)
        @variable(m, t >= 0)
        @objective(m, Min, t)
        @constraint(m, x + y >= 1)
        @constraint(m, [t,x,y] in MOI.SecondOrderCone(3))

        JuMP.optimize!(m)

        @test JuMP.has_values(m)
        @test JuMP.termination_status(m) == MOI.LOCALLY_SOLVED
        @test JuMP.primal_status(m) == MOI.FEASIBLE_POINT

        @test JuMP.objective_value(m) ≈ sqrt(1/2) atol=1e-6

        @test JuMP.value.([x,y,t]) ≈ [0.5,0.5,sqrt(1/2)] atol=1e-3

    end

    @testset "RotatedSOC1" begin
        m = Model(with_optimizer(solver, outlev=0))

        @variable(m, x[1:5] >= 0)
        @variable(m, 0 <= u <= 5)
        @variable(m, v)
        @variable(m, t1 == 1)
        @variable(m, t2 == 1)

        @objective(m, Max, v)

        @constraint(m, [t1/sqrt(2),t2/sqrt(2),x...] in MOI.RotatedSecondOrderCone(7))
        @constraint(m, [x[1]/sqrt(2), u/sqrt(2), v] in MOI.RotatedSecondOrderCone(3))

        JuMP.optimize!(m)

        @test JuMP.has_values(m)
        @test JuMP.termination_status(m) == MOI.LOCALLY_SOLVED
        @test JuMP.primal_status(m) == MOI.FEASIBLE_POINT

        @test JuMP.value.(x) ≈ [1,0,0,0,0] atol=1e-2
        @test JuMP.value(u) ≈ 5 atol=1e-4
        @test JuMP.value(v) ≈ sqrt(5) atol=1e-4
    end
end
