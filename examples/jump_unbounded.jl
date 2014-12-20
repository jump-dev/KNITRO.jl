using JuMP, KNITRO
m = Model(solver=KnitroSolver())
@defVar(m, x >= 0)
@setNLObjective(m, Max, x)
@addNLConstraint(m, x >= 5)
solve(m)