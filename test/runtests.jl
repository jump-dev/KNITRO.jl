# Copyright (c) 2016: Ng Yee Sian, Miles Lubin, other contributors
#
# Use of this source code is governed by an MIT-style license that can be found
# in the LICENSE.md file or at https://opensource.org/licenses/MIT.

using KNITRO
using Test

const KN_VERBOSE = false

# Before proceeding, check that KNITRO is installed correctly.
@test KNITRO.has_knitro()

@testset "Test C API" begin
    include("C_wrapper.jl")
end

@testset "Test examples" begin
    examples_dir = joinpath(dirname(@__FILE__), "..", "examples")
    for file in filter(f -> endswith(f, ".jl"), readdir(examples_dir))
        if !occursin("mps_reader", file)
            @info "Executing $file"
            include(joinpath(examples_dir, file))
        end
    end
end

@testset "Test MathOptInterface" begin
    include("MOI_wrapper.jl")
end

@testset "Test C API License" begin
    include("knitroapi_licman.jl")
end
