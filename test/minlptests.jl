# Test Knitro with MINLPTests
#
using MINLPTests, JuMP, Test

using KNITRO

const SOLVER = JuMP.with_optimizer(KNITRO.Optimizer, outlev=0, opttol=1e-8)

const NLP_SOLVERS = [SOLVER]
const MINLP_SOLVERS = [SOLVER]
const POLY_SOLVERS = []
const MIPOLY_SOLVERS = []

@testset "JuMP Model Tests" begin
    @testset "$(solver.constructor): nlp" for solver in NLP_SOLVERS
        MINLPTests.test_nlp(solver, exclude = [
            "005_010",
            "005_011",  # Uses the function `\`
        ])
        # For 005_010, Knitro founds a different solution, close
        # to those of MINLPTests.
        MINLPTests.nlp_005_010(solver, 1e-5, 1e-5, 1e-5)
        MINLPTests.test_nlp_cvx(solver)
    end
    @testset "$(solver.constructor): nlp_mi" for solver in MINLP_SOLVERS
        MINLPTests.test_nlp_mi(solver, exclude = [
            "005_010",
            "005_011",  # Uses the function `\`
            "006_010"   # Bug in Juniper - handling of user-defined functions.
        ])
        MINLPTests.test_nlp_mi_cvx(solver)
    end
end
