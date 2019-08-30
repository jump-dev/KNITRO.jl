# Extend MathOptInterface Test for Knitro.
#
# This file is largely adapted from :
# MathOptInterface/src/Tests/contconic.jl
# https://github.com/JuliaOpt/MathOptInterface.jl/blob/master/src/Test/contconic.jl
#
# LICENSE:
# MIT "expat" license
# Copyright (c) 2017: Miles Lubin and contributors Copyright (c) 2017: Google Inc.

using MathOptInterface

const MOI = MathOptInterface

const CONIC_OPTIMIZER = KNITRO.Optimizer(outlev=0, presolve=0, opttol=1e-8)
const CONIC_BRIDGED = MOIB.full_bridge_optimizer(CONIC_OPTIMIZER, Float64)

@testset "MOI SOCP 1" begin
    # Derived from MOI's problem SOC1
    model = CONIC_BRIDGED
    atol = 1e-4
    rtol = 1e-4

    # Problem SOC1
    # max 0x + 1y + 1z
    #  st  x            == 1
    #      x >= ||(y,z)||

    @test MOIU.supports_default_copy_to(model, #=copy_names=# false)
    @test MOI.supports(model, MOI.ObjectiveFunction{MOI.ScalarAffineFunction{Float64}}())
    @test MOI.supports(model, MOI.ObjectiveSense())
    @test MOI.supports_constraint(model, MOI.VectorAffineFunction{Float64}, MOI.Zeros)
    @test MOI.supports_constraint(model, MOI.VectorOfVariables,MOI.SecondOrderCone)

    MOI.empty!(model)
    @test MOI.is_empty(model)

    x,y,z = MOI.add_variables(model, 3)

    MOI.set(model, MOI.ObjectiveFunction{MOI.ScalarAffineFunction{Float64}}(),
            MOI.ScalarAffineFunction(MOI.ScalarAffineTerm.([1.0,1.0], [y,z]), 0.0))
    MOI.set(model, MOI.ObjectiveSense(), MOI.MAX_SENSE)

    ceq = MOI.add_constraint(model,
                             MOI.VectorAffineFunction([MOI.VectorAffineTerm(1, MOI.ScalarAffineTerm(1.0, x))], [-1.0]), MOI.Zeros(1))
    vov = MOI.VectorOfVariables([x,y,z])
    csoc = MOI.add_constraint(model,
                              MOI.VectorAffineFunction{Float64}(vov), MOI.SecondOrderCone(3))

    @test MOI.get(model, MOI.NumberOfConstraints{MOI.VectorAffineFunction{Float64},MOI.Zeros}()) == 1
    @test MOI.get(model, MOI.NumberOfConstraints{MOI.VectorAffineFunction{Float64},MOI.SecondOrderCone}()) == 1
    #= loc = MOI.get(model, MOI.ListOfConstraints()) =#
    #= @test length(loc) == 2 =#
    #= @test (MOI.VectorAffineFunction{Float64},MOI.Zeros) in loc =#
    #= @test (MOI.VectorAffineFunction{Float64},MOI.SecondOrderCone) in loc =#

    @test MOI.get(model, MOI.TerminationStatus()) == MOI.OPTIMIZE_NOT_CALLED

    MOI.optimize!(model)

    @test MOI.get(model, MOI.TerminationStatus()) == MOI.LOCALLY_SOLVED

    @test MOI.get(model, MOI.PrimalStatus()) == MOI.FEASIBLE_POINT
    @test MOI.get(model, MOI.DualStatus()) == MOI.FEASIBLE_POINT

    @test MOI.get(model, MOI.ObjectiveValue()) ≈ √2 atol=atol rtol=rtol

    @test MOI.get(model, MOI.VariablePrimal(), x) ≈ 1 atol=atol rtol=rtol
    @test MOI.get(model, MOI.VariablePrimal(), y) ≈ 1/√2 atol=atol rtol=rtol
    @test MOI.get(model, MOI.VariablePrimal(), z) ≈ 1/√2 atol=atol rtol=rtol

    @test MOI.get(model, MOI.ConstraintPrimal(), ceq) ≈ [0.] atol=atol rtol=rtol
    @test MOI.get(model, MOI.ConstraintPrimal(), csoc) ≈ [1., 1/√2, 1/√2] atol=atol rtol=rtol

    @test MOI.get(model, MOI.ConstraintDual(), ceq) ≈ [-√2] atol=atol rtol=rtol
    @test MOI.get(model, MOI.ConstraintDual(), csoc) ≈ [√2, -1.0, -1.0] atol=atol rtol=rtol
end

MOI.empty!(CONIC_BRIDGED)

@testset "MOI SOCP 2" begin
    model = CONIC_BRIDGED
    atol = 1e-4
    rtol = 1e-4
    # Problem SOC2
    # min  x
    # s.t. y ≥ 1/√2
    #      x² + y² ≤ 1
    # in conic form:
    # min  x
    # s.t.  -1/√2 + y ∈ R₊
    #        1 - t ∈ {0}
    #      (t,x,y) ∈ SOC₃

    @test MOIU.supports_default_copy_to(model, #=copy_names=# false)
    @test MOI.supports(model, MOI.ObjectiveFunction{MOI.ScalarAffineFunction{Float64}}())
    @test MOI.supports(model, MOI.ObjectiveSense())
    @test MOI.supports_constraint(model, MOI.VectorAffineFunction{Float64}, MOI.Zeros)
    @test MOI.supports_constraint(model, MOI.VectorAffineFunction{Float64}, MOI.Nonpositives)
    @test MOI.supports_constraint(model, MOI.VectorAffineFunction{Float64},MOI.SecondOrderCone)

    MOI.empty!(model)
    @test MOI.is_empty(model)

    x,y,t = MOI.add_variables(model, 3)

    MOI.set(model, MOI.ObjectiveFunction{MOI.ScalarAffineFunction{Float64}}(), MOI.ScalarAffineFunction([MOI.ScalarAffineTerm(1.0, x)], 0.0))
    MOI.set(model, MOI.ObjectiveSense(), MOI.MIN_SENSE)

    cnon = MOI.add_constraint(model, MOI.VectorAffineFunction([MOI.VectorAffineTerm(1, MOI.ScalarAffineTerm(-1.0, y))], [1/√2]), MOI.Nonpositives(1))
    ceq = MOI.add_constraint(model, MOI.VectorAffineFunction([MOI.VectorAffineTerm(1, MOI.ScalarAffineTerm(-1.0, t))], [1.0]), MOI.Zeros(1))
    csoc = MOI.add_constraint(model, MOI.VectorAffineFunction(MOI.VectorAffineTerm.([1,2,3], MOI.ScalarAffineTerm.(1.0, [t,x,y])), zeros(3)), MOI.SecondOrderCone(3))

    @test MOI.get(model, MOI.NumberOfConstraints{MOI.VectorAffineFunction{Float64}, MOI.Nonpositives}()) == 1
    @test MOI.get(model, MOI.NumberOfConstraints{MOI.VectorAffineFunction{Float64},MOI.Zeros}()) == 1
    @test MOI.get(model, MOI.NumberOfConstraints{MOI.VectorAffineFunction{Float64},MOI.SecondOrderCone}()) == 1

    @test MOI.get(model, MOI.TerminationStatus()) == MOI.OPTIMIZE_NOT_CALLED

    MOI.optimize!(model)

    @test MOI.get(model, MOI.TerminationStatus()) == MOI.LOCALLY_SOLVED

    @test MOI.get(model, MOI.PrimalStatus()) == MOI.FEASIBLE_POINT
    @test MOI.get(model, MOI.DualStatus()) == MOI.FEASIBLE_POINT

    @test MOI.get(model, MOI.ObjectiveValue()) ≈ -1/√2 atol=atol rtol=rtol

    @test MOI.get(model, MOI.VariablePrimal(), x) ≈ -1/√2 atol=atol rtol=rtol
    @test MOI.get(model, MOI.VariablePrimal(), y) ≈ 1/√2 atol=atol rtol=rtol
    @test MOI.get(model, MOI.VariablePrimal(), t) ≈ 1 atol=atol rtol=rtol

    # Getter of Nonnegatives constraints is currently broken!!
    @test_broken MOI.get(model, MOI.ConstraintPrimal(), cnon) ≈ [0.0] atol=atol rtol=rtol
    @test MOI.get(model, MOI.ConstraintPrimal(), ceq) ≈ [0.0] atol=atol rtol=rtol
    @test MOI.get(model, MOI.ConstraintPrimal(), csoc) ≈ [1., -1/√2, 1/√2] atol=atol rtol=rtol

    @test MOI.get(model, MOI.ConstraintDual(), cnon) ≈ [-1.0] atol=atol rtol=rtol
    @test MOI.get(model, MOI.ConstraintDual(), ceq) ≈ [√2] atol=atol rtol=rtol
    @test MOI.get(model, MOI.ConstraintDual(), csoc) ≈ [√2, 1.0, -1.0] atol=atol rtol=rtol
end
