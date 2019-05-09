using KNITRO, JuMP

m = Model(solver=KnitroSolver())
@variable(m, x)
setvalue(x, 5)
@NLobjective(m, Min, -log(x)+x^2)
solve(m)
@test isapprox(getobjectivevalue(m), 0.84657, atol=1.0e-5)
@test isapprox(getvalue(x), 0.707107, atol=1.0e-5)

ktrmod = internalmodel(m)
MathProgBase.freemodel!(ktrmod)
