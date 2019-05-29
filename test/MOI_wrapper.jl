using Test
using MathOptInterface
const MOI = MathOptInterface
const MOIT = MOI.Test
const MOIU = MOI.Utilities
const MOIB = MOI.Bridges

import KNITRO


const config = MOIT.TestConfig(atol=1e-4, rtol=1e-4,
                               optimal_status=MOI.LOCALLY_SOLVED,
                               query=false,
                               infeas_certificates=false,
                               modify_lhs=false)

const OPTIMIZER = KNITRO.Optimizer(outlev=0)
const BRIDGED = MOIB.full_bridge_optimizer(OPTIMIZER, Float64)

@testset "SolverName" begin
    optimizer = KNITRO.Optimizer()
    @test MOI.get(optimizer, MOI.SolverName()) == "Knitro"
end

@testset "supports_default_copy_to" begin
    optimizer = KNITRO.Optimizer(outlev=0, algorithm=3)
    @test MOIU.supports_default_copy_to(optimizer, false)
    # Use `@test !...` if names are not supported
    @test MOIU.supports_default_copy_to(optimizer, true)
end

@testset "MOI Linear tests" begin
    exclude = ["linear1",
               "linear4", # ConstraintSet not supported
               "linear5",
               "linear6", # ConstraintSet not supported
               "linear7", # Delete not allowed
               "linear8a", # Behavior in infeasible case doesn't match test.
               "linear8b", # Investigate
               "linear8c", # Investigate
               "linear10", # Delete not allowed
               "linear11", # problem accessing constraint function
               "linear12", # Same as above.
               "linear14", # Delete not allowed
               "linear8c", # Problem catching infeasibility ray
               ]
    MOIT.contlineartest(BRIDGED, config, exclude)
end

@testset "MOI QP/QCQP tests" begin
    # Exclude QP tests as Knitro does not support update in objective
    # function after a solve.
    exclude = String["qp2", "qp3"]
    MOIT.contquadratictest(BRIDGED, config, exclude)
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
