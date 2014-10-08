include(joinpath(Pkg.dir("MathProgBase"),"test","nlp.jl"))
convexnlptest(KnitroSolver())
println("Convex NLP passed")
rosenbrocktest(KnitroSolver())
println("Rosenbrock test passed")
# nlptest(KnitroSolver()) # numerical differences...