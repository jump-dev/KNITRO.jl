# Test KNITRO with MathProgBase unit-tests
#
using MathProgBase, KNITRO

include(joinpath(dirname(pathof(MathProgBase)),"..", "test", "nlp.jl"))
convexnlptest(KnitroSolver())
rosenbrocktest(KnitroSolver(opttol=1e-7))
nlptest(KnitroSolver())
nlptest_nohessian(KnitroSolver())
