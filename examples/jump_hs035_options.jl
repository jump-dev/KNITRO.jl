using KNITRO, JuMP, Base.Test

for m in [Model(solver=KnitroSolver()),
          Model(solver=KnitroSolver(KTR_PARAM_ALG=5)),
          Model(solver=KnitroSolver(hessopt=1)),
          Model(solver=KnitroSolver(options_file=joinpath(dirname(@__FILE__),
                                                          "tuner-fixed.opt"))),
          Model(solver=KnitroSolver(tuner_file=joinpath(dirname(@__FILE__),
                                                        "tuner-explore.opt")))]
    @defVar(m, x[1:3]>=0)
    @setNLObjective(m, Min, 9.0 - 8.0*x[1] - 6.0*x[2] - 4.0*x[3]
                            + 2.0*x[1]^2 + 2.0*x[2]^2 + x[3]^2
                            + 2.0*x[1]*x[2] + 2.0*x[1]*x[3])
    @addConstraint(m, x[1] + x[2] + 2.0*x[3] <= 3)
    solve(m)
    @test_approx_eq_eps getValue(x[1]) 1.3333333 1e-5
    @test_approx_eq_eps getValue(x[2]) 0.7777777 1e-5
    @test_approx_eq_eps getValue(x[3]) 0.4444444 1e-5
    @test_approx_eq_eps getObjectiveValue(m) 0.1111111 1e-5
end