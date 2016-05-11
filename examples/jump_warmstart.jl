using KNITRO, JuMP, Base.Test

m = Model(solver=KnitroSolver())
@variable(m, x)
setValue(x, 5)
@NLobjective(m, Min, -log(x)+x^2)
solve(m)
@test_approx_eq_eps getobjectivevalue(m) 0.84657 1e-5
@test_approx_eq_eps getvalue(x) 0.707107 1e-5

ktrmod = internalmodel(m)
MathProgBase.freemodel!(ktrmod)
