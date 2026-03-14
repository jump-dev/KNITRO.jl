# Copyright (c) 2016: Ng Yee Sian, Miles Lubin, other contributors
#
# Use of this source code is governed by an MIT-style license that can be found
# in the LICENSE.md file or at https://opensource.org/licenses/MIT.

module TestMOIWrapperRunTestsCached

using Test

import KNITRO
import MathOptInterface as MOI

const LICENSE_MANAGER = KNITRO.LMcontext()

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
    second_order_exclude = [
        r"^test_conic_GeometricMeanCone_VectorAffineFunction$",
        r"^test_conic_GeometricMeanCone_VectorAffineFunction_2$",
        r"^test_conic_GeometricMeanCone_VectorOfVariables$",
        r"^test_conic_GeometricMeanCone_VectorOfVariables_2$",
        r"^test_conic_RotatedSecondOrderCone_INFEASIBLE_2$",
        r"^test_conic_RotatedSecondOrderCone_VectorAffineFunction$",
        r"^test_conic_RotatedSecondOrderCone_VectorOfVariables$",
        r"^test_conic_RotatedSecondOrderCone_out_of_order$",
        r"^test_conic_SecondOrderCone_Nonpositives$",
        r"^test_conic_SecondOrderCone_Nonnegatives$",
        r"^test_conic_SecondOrderCone_VectorAffineFunction$",
        r"^test_conic_SecondOrderCone_VectorOfVariables$",
        r"^test_conic_SecondOrderCone_out_of_order$",
        r"^test_constraint_PrimalStart_DualStart_SecondOrderCone$",
    ]
    model = MOI.instantiate(
        () -> KNITRO.Optimizer(; license_manager=LICENSE_MANAGER);
        with_bridge_type=Float64,
        with_cache_type=Float64,
    )
    MOI.set(model, MOI.Silent(), true)
    config = MOI.Test.Config(
        atol=2e-3,
        rtol=1e-3,
        optimal_status=MOI.LOCALLY_SOLVED,
        infeasible_status=MOI.LOCALLY_INFEASIBLE,
        exclude=Any[MOI.VariableBasisStatus, MOI.ConstraintBasisStatus],
    )
    MOI.Test.runtests(
        model,
        config;
        exclude=Union{String,Regex}[
            # This is an upstream issue in MOI with bridges and support
            # comparing VectorNonlinear and VectorQuadratic
            r"^test_basic_VectorNonlinearFunction_GeometricMeanCone$",
            # Returns OTHER_ERROR, which is also reasonable.
            r"^test_conic_empty_matrix$",
            # Returns ITERATION_LIMIT instead of DUAL_INFEASIBLE, which is okay.
            r"^test_conic_RotatedSecondOrderCone_INFEASIBLE$",
            # Incorrect ObjectiveBound with an LP, but that's understandable.
            r"^test_solve_ObjectiveBound_MAX_SENSE_LP$",
            # Cannot get ConstraintDualStart
            r"^test_model_ModelFilter_AbstractConstraintAttribute$",
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

end

TestMOIWrapperRunTestsCached.runtests()
