# Copyright (c) 2016: Ng Yee Sian, Miles Lubin, other contributors
#
# Use of this source code is governed by an MIT-style license that can be found
# in the LICENSE.md file or at https://opensource.org/licenses/MIT.

module TestMOIWrapper

using Test

import KNITRO
import MathOptInterface as MOI

function runtests()
    for name in names(@__MODULE__; all=true)
        if startswith("$(name)", "test_")
            @testset "$(name)" begin
                getfield(@__MODULE__, name)()
            end
        end
    end
    return
end

function test_MOI_Test_cached()
    second_order_exclude = String[
        "test_conic_GeometricMeanCone_VectorAffineFunction",
        "test_conic_GeometricMeanCone_VectorAffineFunction_2",
        "test_conic_GeometricMeanCone_VectorOfVariables",
        "test_conic_GeometricMeanCone_VectorOfVariables_2",
        "test_conic_RotatedSecondOrderCone_INFEASIBLE_2",
        "test_conic_RotatedSecondOrderCone_VectorAffineFunction",
        "test_conic_RotatedSecondOrderCone_VectorOfVariables",
        "test_conic_RotatedSecondOrderCone_out_of_order",
        "test_conic_SecondOrderCone_Nonpositives",
        "test_conic_SecondOrderCone_Nonnegatives",
        "test_conic_SecondOrderCone_VectorAffineFunction",
        "test_conic_SecondOrderCone_VectorOfVariables",
        "test_conic_SecondOrderCone_out_of_order",
        "test_constraint_PrimalStart_DualStart_SecondOrderCone",
    ]
    model =
        MOI.instantiate(KNITRO.Optimizer; with_bridge_type=Float64, with_cache_type=Float64)
    MOI.set(model, MOI.Silent(), true)
    config = MOI.Test.Config(
        atol=1e-3,
        rtol=1e-3,
        optimal_status=MOI.LOCALLY_SOLVED,
        infeasible_status=MOI.LOCALLY_INFEASIBLE,
        exclude=Any[MOI.VariableBasisStatus, MOI.ConstraintBasisStatus],
    )
    MOI.Test.runtests(
        model,
        config;
        exclude=String[
            # TODO(odow): this test is flakey.
            "test_cpsat_ReifiedAllDifferent",
            # Returns OTHER_ERROR, which is also reasonable.
            "test_conic_empty_matrix",
            # Uses the ZerosBridge and ConstraintDual
            "test_conic_linear_VectorOfVariables_2",
            # Returns ITERATION_LIMIT instead of DUAL_INFEASIBLE, which is okay.
            "test_linear_DUAL_INFEASIBLE",
            # Incorrect ObjectiveBound with an LP, but that's understandable.
            "test_solve_ObjectiveBound_MAX_SENSE_LP",
            # KNITRO doesn't support INFEASIBILITY_CERTIFICATE results.
            "test_solve_DualStatus_INFEASIBILITY_CERTIFICATE_",
            # TODO(odow): bridge issues
            "test_basic_VectorNonlinearFunction_AllDifferent",
            "test_basic_VectorNonlinearFunction_BinPacking",
            "test_basic_VectorNonlinearFunction_Circuit",
            "test_basic_VectorNonlinearFunction_Complements",
            "test_basic_VectorNonlinearFunction_CountAtLeast",
            "test_basic_VectorNonlinearFunction_CountBelongs",
            "test_basic_VectorNonlinearFunction_CountDistinct",
            "test_basic_VectorNonlinearFunction_CountGreaterThan",
            "test_basic_VectorNonlinearFunction_GeometricMeanCone",
            "test_basic_VectorNonlinearFunction_HyperRectangle",
            "test_basic_VectorNonlinearFunction_Nonnegatives",
            "test_basic_VectorNonlinearFunction_Nonpositives",
            "test_basic_VectorNonlinearFunction_NormInfinityCone",
            "test_basic_VectorNonlinearFunction_NormOneCone",
            "test_basic_VectorNonlinearFunction_RotatedSecondOrderCone",
            "test_basic_VectorNonlinearFunction_SecondOrderCone",
            "test_basic_VectorNonlinearFunction_SOS1",
            "test_basic_VectorNonlinearFunction_SOS2",
            "test_basic_VectorNonlinearFunction_Table",
            "test_basic_VectorNonlinearFunction_Zeros",
            # ConstraintDual not supported for SecondOrderCone
            second_order_exclude...,
        ],
    )
    # Run the tests for second_order_exclude, this time excluding
    # `MOI.ConstraintDual` and `MOI.DualObjectiveValue`.
    push!(config.exclude, MOI.ConstraintDual)
    push!(config.exclude, MOI.DualObjectiveValue)
    MOI.Test.runtests(model, config; include=second_order_exclude)
    return
end

function test_zero_one_with_no_bounds()
    model = MOI.instantiate(KNITRO.Optimizer)
    MOI.set(model, MOI.Silent(), true)
    x = MOI.add_variable(model)
    MOI.add_constraint(model, x, MOI.ZeroOne())
    MOI.set(model, MOI.ObjectiveSense(), MOI.MAX_SENSE)
    MOI.set(model, MOI.ObjectiveFunction{typeof(x)}(), x)
    MOI.optimize!(model)
    @test isapprox(MOI.get(model, MOI.VariablePrimal(), x), 1.0; atol=1e-6)
    return
end

function test_RawOptimizerAttribute()
    model = MOI.instantiate(KNITRO.Optimizer)
    attr = MOI.RawOptimizerAttribute("bad_attr")
    @test !MOI.supports(model, attr)
    @test_throws MOI.UnsupportedAttribute{typeof(attr)} MOI.get(model, attr)
    @test_throws MOI.UnsupportedAttribute{typeof(attr)} MOI.set(model, attr, 0)
    attr = MOI.RawOptimizerAttribute("maxtime_real")
    @test MOI.supports(model, attr)
    @test_throws MOI.GetAttributeNotAllowed{typeof(attr)} MOI.get(model, attr)
    MOI.set(model, attr, 10.0)
    @test MOI.get(model, attr) == 10.0
    return
end

# Issue #289
function test_get_nlp_block()
    model = MOI.instantiate(KNITRO.Optimizer)
    MOI.set(model, MOI.Silent(), true)
    x = MOI.add_variable(model)
    f = MOI.ScalarNonlinearFunction(:^, Any[x, 4])
    MOI.add_constraint(model, f, MOI.LessThan(1.0))
    MOI.optimize!(model)
    block = MOI.get(model, MOI.NLPBlock())
    @test block.evaluator isa MOI.Nonlinear.Evaluator
    return
end

end

TestMOIWrapper.runtests()
