for test_file in readdir(joinpath(dirname(@__FILE__), "..", "examples"))
    if test_file[end-2:end] == ".jl" && !occursin("mps_reader", test_file)
        include(joinpath(dirname(@__FILE__), "..", "examples", test_file))
    end
end
