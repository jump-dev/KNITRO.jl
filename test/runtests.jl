using KNITRO
using Test

const KN_VERBOSE = false

# @testset "Test C API" begin
#     include("C_wrapper.jl")
# end

# @testset "Test examples" begin
#     examples_dir = joinpath(dirname(@__FILE__), "..", "examples")
#     for file in filter(f -> endswith(f, ".jl"), readdir(examples_dir))
#         if !occursin("mps_reader", file)
#             include(joinpath(examples_dir, file))
#         end
#     end
# end

@testset "Test MathOptInterface" begin
    include("MOI_wrapper.jl")
end

# try
#     @testset "Test C API License" begin
#         include("knitroapi_licman.jl")
#     end
# catch e
#     @warn(
#         "License tests failed, but this might be due to License Manager" *
#         " not being supported by your license."
#     )
#     println("The error catched was:\n")
#     println("$e\n")
#     println("See table above for more details.")
# end
