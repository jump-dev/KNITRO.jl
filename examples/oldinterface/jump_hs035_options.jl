
using MathProgBase, KNITRO, JuMP


function testmodel(m)
    @variable(m, x[1:3]>=0)
    @NLobjective(m, Min, 9.0 - 8.0*x[1] - 6.0*x[2] - 4.0*x[3]
                            + 2.0*x[1]^2 + 2.0*x[2]^2 + x[3]^2
                            + 2.0*x[1]*x[2] + 2.0*x[1]*x[3])
    @constraint(m, x[1] + x[2] + 2.0*x[3] <= 3)
    solve(m)
    @test isapprox(getvalue(x[1]), 1.3333333, atol=1.0e-5)
    @test isapprox(getvalue(x[2]), 0.7777777, atol=1.0e-5)
    @test isapprox(getvalue(x[3]), 0.4444444, atol=1.0e-5)
    @test isapprox(getobjectivevalue(m), 0.1111111, atol=1.0e-5)
end

m = Model(solver=KnitroSolver())
testmodel(m)
ktrmod = internalmodel(m)
MathProgBase.freemodel!(ktrmod)

m = Model(solver=KnitroSolver(KTR_PARAM_ALG=5))
testmodel(m)
ktrmod = internalmodel(m)
MathProgBase.freemodel!(ktrmod)

m = Model(solver=KnitroSolver(hessopt=1))
testmodel(m)
ktrmod = internalmodel(m)
MathProgBase.freemodel!(ktrmod)

m = Model(solver=KnitroSolver(options_file=joinpath(dirname(@__FILE__) * "/tuner-fixed.opt")))
testmodel(m)
ktrmod = internalmodel(m)
MathProgBase.freemodel!(ktrmod)

m = Model(solver=KnitroSolver(tuner_file=joinpath(dirname(@__FILE__) * "/tuner-explore.opt")))
testmodel(m)
ktrmod = internalmodel(m)
MathProgBase.freemodel!(ktrmod)
