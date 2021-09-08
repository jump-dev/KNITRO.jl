using KNITRO
using Test

const KN_VERBOSE = false

@testset "Test C API" begin
    include("knitroapi.jl")
end

@testset "Test examples" begin
    for file in filter(f -> endswith(f, ".jl"), readdir(joinpath(dirname(@__FILE__), "..", "examples")))
        if occursin("mps_reader", file)
            continue
        end
        @testset "Test example $file" begin
            include(joinpath(dirname(@__FILE__), "..", "examples", file))
        end
    end
end

@testset "Test MathOptInterface" begin
    include("MOI_wrapper.jl")
    include("MOI_additional.jl")
end

try
    @testset "Test C API License" begin
        include("knitroapi_licman.jl")
    end
catch e
    @warn("License tests failed, but this might be due to License Manager" *
    " not being supported by your license.")
    println("The error catched was:\n")
    println("$e\n")
    println("See table above for more details.")
end
