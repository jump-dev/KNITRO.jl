# Copyright (c) 2016: Ng Yee Sian, Miles Lubin, other contributors
#
# Use of this source code is governed by an MIT-style license that can be found
# in the LICENSE.md file or at https://opensource.org/licenses/MIT.

import JuMP
import KNITRO
import MINLPTests
using Test

@testset "MINLPTests" begin
    solver =
        JuMP.optimizer_with_attributes(KNITRO.Optimizer, "outlev" => 0, "opttol" => 1e-8)
    # 005_010 : knitro finds a slightly different solution
    # 005_011 : uses the function `\`
    MINLPTests.test_nlp(solver; exclude=["005_010", "005_011"])
    MINLPTests.test_nlp_expr(solver; exclude=["005_010", "005_011", "008_010", "008_011"])
    # For 005_010, Knitro founds a different solution, close to those of MINLPTests.
    MINLPTests.nlp_005_010(solver, 1e-5, 1e-5, 1e-5)
    MINLPTests.nlp_expr_005_010(solver, 1e-5, 1e-5, 1e-5)
    MINLPTests.test_nlp_cvx(solver)
    MINLPTests.test_nlp_cvx_expr(solver)
    MINLPTests.test_nlp_mi(solver, exclude=["005_011"])
    MINLPTests.test_nlp_mi_expr(solver, exclude=["005_011"])
end
