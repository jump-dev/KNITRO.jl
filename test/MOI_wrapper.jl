using KNITRO, Test
using MathOptInterface
const MOI = MathOptInterface
const MOIT = MOI.Test
const MOIU = MOI.Utilities
const MOIB = MOI.Bridges


MOIU.@model(KnitroModelData,
            (),
            (MOI.EqualTo, MOI.GreaterThan, MOI.LessThan, MOI.Interval),
            (MOI.Zeros, MOI.Nonnegatives, MOI.Nonpositives, MOI.ZeroOne, MOI.SecondOrderCone),
            (),
            (MOI.SingleVariable,),
            (MOI.ScalarAffineFunction, MOI.ScalarQuadraticFunction),
            (MOI.VectorOfVariables,),
            (MOI.VectorAffineFunction, ))

const config = MOIT.TestConfig(atol=1e-4, rtol=1e-4,
                               optimal_status=MOI.LOCALLY_SOLVED)

@testset "MOI Linear tests" begin
    # to check unbounded problem, change the default algorithm used
    # by KNITRO
    optimizer = KNITRO.Optimizer(outlev=0, algorithm=3)

    exclude = ["linear8a", # Behavior in infeasible case doesn't match test.
               "linear12", # Same as above.
               "linear14", # variable deletion not supported
               ]
    linear_optimizer = MOI.Bridges.SplitInterval{Float64}(
                        MOIU.CachingOptimizer(KnitroModelData{Float64}(), optimizer)
                                                         )
    MOIT.contlineartest(linear_optimizer, config, exclude)
end


@testset "MOI QP/QCQP tests" begin
    optimizer = KNITRO.Optimizer(outlev=0)
    qp_optimizer = MOIU.CachingOptimizer(KnitroModelData{Float64}(), optimizer)
    MOIT.contquadratictest(qp_optimizer, config)
end


@testset "MOI NLP tests" begin
    optimizer = KNITRO.Optimizer(outlev=0)
    MOIT.nlptest(optimizer, config)
end


# Currently SOCP test returns segfault ...
#= @testset "MOI SOCP tests" begin =#
#=     socp_optimizer = MOIU.CachingOptimizer(KnitroModelData{Float64}(), optimizer) =#
#=     MOI.supports_constraint(::KNITRO.Optimizer, ::Type{MOI.VectorOfVariables}, ::Type{MOI.SecondOrderCone}) = true =#
#=     MOIT._soc1test(socp_optimizer, config, false) =#
#= end =#

@testset "MOI MILP test" begin
    optimizer = KNITRO.Optimizer(outlev=0)
    MOIT.knapsacktest(optimizer, config)
end
