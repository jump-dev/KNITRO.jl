using Compat.Test


@testset "Test C API" begin
    include("knitroapi.jl")
end

@testset "Test examples" begin
    include("testexamples.jl")
end
