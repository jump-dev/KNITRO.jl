using KNITRO, JuMP, Base.Test

function testmodel(m)
    @variable(m, x[1:3]>=0)
    @NLobjective(m, Min, 9.0 - 8.0*x[1] - 6.0*x[2] - 4.0*x[3]
                            + 2.0*x[1]^2 + 2.0*x[2]^2 + x[3]^2
                            + 2.0*x[1]*x[2] + 2.0*x[1]*x[3])
    @constraint(m, x[1] + x[2] + 2.0*x[3] <= 3)
    solve(m)
    @test_approx_eq_eps getvalue(x[1]) 1.3333333 1e-5
    @test_approx_eq_eps getvalue(x[2]) 0.7777777 1e-5
    @test_approx_eq_eps getvalue(x[3]) 0.4444444 1e-5
    @test_approx_eq_eps getobjectivevalue(m) 0.1111111 1e-5
end

m = Model(solver=KnitroSolver())
testmodel(m)
ktrmod = internalmodel(m)
MathProgBase.freemodel!(ktrmod)

Model(solver=KnitroSolver(KTR_PARAM_ALG=5))
testmodel(m)
ktrmod = internalmodel(m)
MathProgBase.freemodel!(ktrmod)

Model(solver=KnitroSolver(hessopt=1))
testmodel(m)
ktrmod = internalmodel(m)
MathProgBase.freemodel!(ktrmod)

Model(solver=KnitroSolver(options_file=joinpath(dirname(@__FILE__)"tuner-fixed.opt")))
testmodel(m)
ktrmod = internalmodel(m)
MathProgBase.freemodel!(ktrmod)

Model(solver=KnitroSolver(tuner_file=joinpath(dirname(@__FILE__)"tuner-explore.opt")))
testmodel(m)
ktrmod = internalmodel(m)
MathProgBase.freemodel!(ktrmod)