using JuMP, KNITRO, Base.Test
m = Model(solver=KnitroSolver(objrange=1e16))
@defVar(m, x >= 0)
@setNLObjective(m, Max, x)
@addNLConstraint(m, x >= 5)
status = solve(m)
@test status == :Unbounded