# Copyright (c) 2016: Ng Yee Sian, Miles Lubin, other contributors
#
# Use of this source code is governed by an MIT-style license that can be found
# in the LICENSE.md file or at https://opensource.org/licenses/MIT.

module TestMOIWrapper

using Test
using KNITRO

const MOI = KNITRO.MOI

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
    model = MOI.Utilities.CachingOptimizer(
        MOI.Utilities.UniversalFallback(MOI.Utilities.Model{Float64}()),
        MOI.instantiate(KNITRO.Optimizer; with_bridge_type=Float64),
    )
    MOI.set(model, MOI.Silent(), true)
    MOI.Test.runtests(
        model,
        MOI.Test.Config(
            atol=1e-4,
            rtol=1e-4,
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

end

TestMOIWrapper.runtests()
