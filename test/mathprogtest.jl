include(joinpath(Pkg.dir("MathProgBase"),"test","nlp.jl"))
convexnlptest(KnitroSolver())
rosenbrocktest(KnitroSolver())
nlptest(KnitroSolver())