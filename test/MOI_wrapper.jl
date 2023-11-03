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
    model = MOI.instantiate(
        KNITRO.Optimizer;
        with_bridge_type=Float64,
        with_cache_type=Float64,
    )
    MOI.set(model, MOI.Silent(), true)
    MOI.Test.runtests(
        model,
        MOI.Test.Config(
            atol=1e-3,
            rtol=1e-3,
            optimal_status=MOI.LOCALLY_SOLVED,
            infeasible_status=MOI.LOCALLY_INFEASIBLE,
            exclude=Any[
                MOI.ConstraintBasisStatus,
                MOI.VariableBasisStatus,
                MOI.DualObjectiveValue,
            ],
        );
        exclude=String[
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
        ],
    )
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

end

TestMOIWrapper.runtests()
