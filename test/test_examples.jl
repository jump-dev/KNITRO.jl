# Copyright (c) 2016: Ng Yee Sian, Miles Lubin, other contributors
#
# Use of this source code is governed by an MIT-style license that can be found
# in the LICENSE.md file or at https://opensource.org/licenses/MIT.

using KNITRO
using Test

const KN_VERBOSE = false

examples_dir = joinpath(dirname(dirname(@__FILE__)), "examples")
files = readdir(examples_dir; join = true)
filter!(f -> endswith(f, ".jl") && !occursin("mps_reader", f), files)
Test.@testset "$file" for file in files
    include(file)
end
