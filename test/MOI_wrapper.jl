using Test
using MathOptInterface
const MOI = MathOptInterface
const MOIT = MOI.Test
const MOIU = MOI.Utilities
const MOIB = MOI.Bridges

import KNITRO

#= const optimizer = KNITRO.Optimizer(outlev=0) =#

MOIU.@model(KnitroModelData,
            (),
            (MOI.EqualTo, MOI.GreaterThan, MOI.LessThan, MOI.Interval),
            (MOI.Zeros, MOI.Nonnegatives, MOI.Nonpositives, MOI.ZeroOne, MOI.SecondOrderCone),
            (),
            (),
            (MOI.ScalarAffineFunction, MOI.ScalarQuadraticFunction),
            (MOI.VectorOfVariables,),
            (MOI.VectorAffineFunction, ))


const config = MOIT.TestConfig(atol=1e-4, rtol=1e-4,
                               optimal_status=MOI.LOCALLY_SOLVED,
                               query=false, modify_lhs=false)

const BRIDGED = MOIB.full_bridge_optimizer(KNITRO.Optimizer(outlev=0), Float64)

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
@testset "Silent" begin
    optimizer = KNITRO.Optimizer()

    # "loud" by default
    @test MOI.get(optimizer, MOI.Silent()) == false

    # make it silent
    MOI.set(optimizer, MOI.Silent(), true)
    @test MOI.get(optimizer, MOI.Silent()) == true
end

#= @testset "Modification" begin =#
#=     MOIT.modificationtest(bridged, config) =#
#= end =#

@testset "MOI Linear tests" begin
    # To check unbounded problem, change the default algorithm used by KNITRO.
    optimizer = KNITRO.Optimizer(outlev=0, algorithm=3)

    exclude = ["linear8a", # Behavior in infeasible case doesn't match test.
               "linear1",
               "linear5",
               "linear12", # Same as above.
               "linear14", # TODO
               "linear8c", # Problem catching infeasibility ray
               ]
    model_for_knitro = MOIU.UniversalFallback(KnitroModelData{Float64}())
    linear_optimizer = MOIU.CachingOptimizer(model_for_knitro, optimizer)
    MOIT.linear2test(BRIDGED, config)
    MOIT.linear3test(BRIDGED, config)
    MOIT.linear9test(BRIDGED, config)
    MOIT.linear13test(BRIDGED, config)
    MOIT.linear15test(BRIDGED, config)
    MOIT.linear10btest(BRIDGED, config)
end

@testset "MOI QP/QCQP tests" begin
    optimizer = KNITRO.Optimizer(outlev=0)
    # Exclude QP tests as Knitro does not support update in objective
    # function after a solve.
    exclude = String["qp1", "qp2", "qp3"]
    MOIT.contquadratictest(BRIDGED, config, exclude)
end

#= @testset "MOI SOCP tests" begin =#
#=     # TODO: DualObjectivevalue not supported =#
#=     # Presolve must be switch off to get proper dual variables. =#
#=     config2 = MOIT.TestConfig(atol=1e-4, rtol=1e-4, =#
#=                               optimal_status=MOI.LOCALLY_SOLVED, query=false) =#
#=     optimizer = KNITRO.Optimizer(outlev=0, presolve=0) =#
#=     socp_optimizer = MOIU.CachingOptimizer(KnitroModelData{Float64}(), optimizer) =#
#=     # Behavior in infeasible case doesn't match test. =#
#=     exclude = ["lin3", "lin4"] =#
#=     MOIT.lintest(socp_optimizer, config2, exclude) =#
#= end =#

@testset "MOI NLP tests" begin
    optimizer = KNITRO.Optimizer(outlev=0)
    MOIT.nlptest(optimizer, config)
end

@testset "MOI MILP test" begin
    optimizer = KNITRO.Optimizer(outlev=0)
    MOIT.knapsacktest(optimizer, config)
end
