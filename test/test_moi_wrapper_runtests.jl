# Copyright (c) 2016: Ng Yee Sian, Miles Lubin, other contributors
#
# Use of this source code is governed by an MIT-style license that can be found
# in the LICENSE.md file or at https://opensource.org/licenses/MIT.

module TestMOIWrapperRunTests

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

function test_runtests()
    model = MOI.instantiate(() -> KNITRO.Optimizer(; license_manager=LICENSE_MANAGER))
    config = MOI.Test.Config(
        atol=1e-3,
        rtol=1e-3,
        optimal_status=MOI.LOCALLY_SOLVED,
        infeasible_status=MOI.LOCALLY_INFEASIBLE,
        exclude=Any[MOI.VariableBasisStatus, MOI.ConstraintBasisStatus, MOI.ConstraintName],
    )
    MOI.Test.runtests(model, config; include=["test_basic_"])
    return
end

end

TestMOIWrapperRunTests.runtests()
