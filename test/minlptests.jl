# Test Knitro with MINLPTests
#
using MINLPTests, JuMP, Test

using KNITRO

const SOLVER = JuMP.with_optimizer(KNITRO.Optimizer, outlev=0)

const NLP_SOLVERS = [SOLVER]
const MINLP_SOLVERS = [SOLVER]
const POLY_SOLVERS = []
const MIPOLY_SOLVERS = []

@testset "JuMP Model Tests" begin
    @testset "$(solver.constructor): nlp" for solver in NLP_SOLVERS
        MINLPTests.test_nlp(solver, exclude = [
            "005_011",  # Uses the function `\`
            "008_011"   # Requires quadratic duals
        ])
        MINLPTests.test_nlp_cvx(solver)
    end
    @testset "$(solver.constructor): nlp_mi" for solver in MINLP_SOLVERS
        MINLPTests.test_nlp_mi(solver, exclude = [
            "005_011",  # Uses the function `\`
            "003_014",  # Bug in Knitro
            "003_015",  # Bug in Knitro
            "006_010"   # Bug in Juniper - handling of user-defined functions.
        ])
        MINLPTests.test_nlp_mi_cvx(solver)
    end
end
