using Test
using MathOptInterface
const MOI = MathOptInterface
const MOIT = MOI.DeprecatedTest
const MOIU = MOI.Utilities
const MOIB = MOI.Bridges

import KNITRO

# Default configuration.
const config = MOIT.Config(atol=1e-5, rtol=1e-8,
                           optimal_status=MOI.LOCALLY_SOLVED,
                           query=false,
                           infeas_certificates=false, # Do not ask for infeasibility certificates.
                           modify_lhs=false)

const config_noduals = MOIT.Config(atol=1e-5, rtol=1e-8,
                                   optimal_status=MOI.LOCALLY_SOLVED,
                                   query=false,
                                   duals=false,
                                   infeas_certificates=false,
                                   modify_lhs=false)

@testset "MOI utils" begin
    @testset "SolverName" begin
        optimizer = KNITRO.Optimizer()
        @test MOI.get(optimizer, MOI.SolverName()) == "Knitro"
        KNITRO.free(optimizer)
    end
    @testset "supports_default_copy_to" begin
        optimizer = KNITRO.Optimizer()
        @test MOIU.supports_default_copy_to(optimizer, false)
        # Use `@test !...` if names are not supported
        @test MOIU.supports_default_copy_to(optimizer, true)
        KNITRO.free(optimizer)
    end
    @testset "MOI.Silent" begin
        optimizer = KNITRO.Optimizer()
        @test MOI.supports(optimizer, MOI.Silent())
        @test MOI.get(optimizer, MOI.Silent()) == false
        MOI.set(optimizer, MOI.Silent(), true)
        @test MOI.get(optimizer, MOI.Silent()) == true
        KNITRO.free(optimizer)
    end
    @testset "MOI.TimeLimitSec" begin
        optimizer = KNITRO.Optimizer()
        @test MOI.supports(optimizer, MOI.TimeLimitSec())
        # TimeLimitSec is set to 1e8 by default in Knitro.
        @test MOI.get(optimizer, MOI.TimeLimitSec()) == 1e8
        my_time_limit = 10.
        MOI.set(optimizer, MOI.TimeLimitSec(), my_time_limit)
        @test MOI.get(optimizer, MOI.TimeLimitSec()) == my_time_limit
        KNITRO.free(optimizer)
    end
    @testset "MOI.RawAttribute" begin
        # Test special RawAttributes
        optimizer = KNITRO.Optimizer()
        option_file = joinpath(dirname(pathof(KNITRO)),"..", "examples", "knitro.opt")
        MOI.set(optimizer, MOI.RawOptimizerAttribute("option_file"), option_file)
        tuner_file = joinpath(dirname(pathof(KNITRO)),"..", "examples", "tuner-fixed.opt")
        MOI.set(optimizer, MOI.RawOptimizerAttribute("tuner_file"), tuner_file)
        KNITRO.free(optimizer)
    end
end

const OPTIMIZER = KNITRO.Optimizer()
MOI.set(OPTIMIZER, MOI.RawOptimizerAttribute("outlev"), 0)
MOI.empty!(OPTIMIZER)

# Build bridge optimizer.
const BRIDGED = MOIB.full_bridge_optimizer(OPTIMIZER, Float64)


@testset "MOI Linear tests" begin
    exclude = ["linear1",
               "linear2", # DualObjectivevalue not supported
               "linear4", # ConstraintSet not supported
               "linear5",
               "linear6", # ConstraintSet not supported
               "linear7", # Delete not allowed
               "linear8a", # Behavior in infeasible case doesn't match test.
               "linear8b", # Investigate
               "linear8c", # Problem catching infeasibility ray
               "linear10", # Delete not allowed
               "linear11", # problem accessing constraint function
               "linear12", # Same as above.
               "linear14", # Delete not allowed
               "linear15", # DualObjectivevalue not supported
               ]
    MOIT.contlineartest(BRIDGED, config, exclude)
    # Test linear2 and linear15 without querying the dual solution.
    MOIT.linear15test(BRIDGED, config_noduals)
    MOIT.linear2test(BRIDGED, config_noduals)
end

@testset "MOI QP/QCQP tests" begin
    # Exclude QP tests as Knitro does not support update in objective
    # function after a solve.
    exclude = String["qp2", "qp3"]
    MOIT.contquadratictest(BRIDGED, config, exclude)
end

@testset "MOI complementarity tests" begin
    MOIT.test_qp_complementarity_constraint(BRIDGED, config)
    MOIT.test_linear_mixed_complementarity(BRIDGED, config)
end

#= @testset "MOI SOCP tests" begin =#
#=     # TODO: DualObjectivevalue not supported =#
#=     # Presolve must be switch off to get proper dual variables. =#
#=     config2 = MOIT.TestConfig(atol=1e-4, rtol=1e-4, infeas_certificates=false, =#
#=                               optimal_status=MOI.LOCALLY_SOLVED, query=false) =#
#=     # Behavior in infeasible case doesn't match test. =#
#=     exclude = ["lin4"] =#
#=     BRIDGED2 = MOIB.full_bridge_optimizer(KNITRO.Optimizer(outlev=0, presolve=0), Float64) =#
#=     MOIT.lintest(BRIDGED2, config2) =#
#= end =#

@testset "MOI NLP tests" begin
    MOIT.nlptest(OPTIMIZER, config)
end

@testset "MOI MILP test" begin
    MOIT.knapsacktest(OPTIMIZER, config)
end

KNITRO.free(OPTIMIZER)
