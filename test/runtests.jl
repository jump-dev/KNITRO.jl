# Copy code from Gurobi.jl, subject to
# The MIT License (MIT)
# Copyright (c) 2015 Dahua Lin, Miles Lubin, Joey Huchette, Iain Dunning, and contributors
# See https://github.com/JuliaOpt/Gurobi.jl/blob/master/LICENSE.md
if haskey(ENV, "GITHUB_ACTIONS")
    # We're being run as part of a Github action. The most likely case is that
    # this is the auto-merge action as part of the General registry.
    # For now, we're going to silently skip the tests.
    @info("Detected a Github action. Skipping tests.")
    exit(0)
end

using KNITRO
using Test

@testset "Test old API" begin
    include("oldexamples.jl")
end

if KNITRO.KNITRO_VERSION >= v"11.0"
    @testset "Test C API" begin
        include("knitroapi.jl")
    end

    @testset "Test examples" begin
        include("testexamples.jl")
    end

    @testset "Test MathOptInterface" begin
        include("MOI_wrapper.jl")
        include("MOI_additional.jl")
    end

    @testset "Test JuMP" begin
        include("jump_soc.jl")
    end
end
