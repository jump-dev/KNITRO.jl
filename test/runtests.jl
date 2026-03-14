# Copyright (c) 2016: Ng Yee Sian, Miles Lubin, other contributors
#
# Use of this source code is governed by an MIT-style license that can be found
# in the LICENSE.md file or at https://opensource.org/licenses/MIT.

import KNITRO
import ParallelTestRunner
import Test

@info "Running tests with $(KNITRO.libknitro)"
# Before proceeding, check that KNITRO is installed correctly.
@test KNITRO.has_knitro()

is_test_file(f) = startswith(f, "test_") && endswith(f, ".jl")
testsuite = Dict{String,Expr}(
    file => :(include($file))
    for (root, dirs, files) in walkdir(@__DIR__)
    for file in joinpath.(root, filter(is_test_file, files))
)
ParallelTestRunner.runtests(KNITRO, ARGS; testsuite)
