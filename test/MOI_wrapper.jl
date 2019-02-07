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
    # To check unbounded problem, change the default algorithm used by KNITRO.
    optimizer = KNITRO.Optimizer(outlev=0, algorithm=3)

    exclude = ["linear8a", # Behavior in infeasible case doesn't match test.
               "linear12", # Same as above.
               ]
    model_for_knitro = MOIU.UniversalFallback(KnitroModelData{Float64}())
    linear_optimizer = MOI.Bridges.SplitInterval{Float64}(
                        MOIU.CachingOptimizer(model_for_knitro, optimizer))
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


@testset "MOI SOCP tests" begin
    # Warning: set presolve to 0 to avoid bug in Knitro.
    optimizer = KNITRO.Optimizer(outlev=0, opttol=1e-8, presolve=0)
    socp_optimizer = MOIU.CachingOptimizer(KnitroModelData{Float64}(), optimizer)
    # Behavior in infeasible case doesn't match test.
    exclude = ["lin3", "lin4"]
    MOIT.lintest(socp_optimizer, config, exclude)

    # Support of SOC's duals is not enabled.
    configcone = MOIT.TestConfig(atol=1e-4, rtol=1e-4, duals=false,
                                 optimal_status=MOI.LOCALLY_SOLVED)
    # Behavior in infeasible case doesn't match test.
    exclude = ["soc3", "soc4"]
    MOIT.soctest(socp_optimizer, configcone, exclude)
end


@testset "MOI MILP test" begin
    optimizer = KNITRO.Optimizer(outlev=0)
    MOIT.knapsacktest(optimizer, config)
end
