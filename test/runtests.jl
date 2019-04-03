using KNITRO, Compat
using Compat.Test
(VERSION >= v"1.0") && using Pkg

@testset "Test old API" begin
    include("oldexamples.jl")
    include("mathprogtest.jl")
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
