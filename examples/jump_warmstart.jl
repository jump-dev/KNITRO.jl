using KNITRO, JuMP, Base.Test

m = Model(solver=KnitroSolver())
@defVar(m, x)
setValue(x, 5)
@setNLObjective(m, Min, -log(x)+x^2)
solve(m)
@test_approx_eq_eps getObjectiveValue(m) 0.84657 1e-5
@test_approx_eq_eps getValue(x) 0.707107 1e-5

ktrmod = getInternalModel(m)
MathProgBase.freemodel!(ktrmod)
