for test_file in readdir(joinpath(dirname(@__FILE__), "..", "examples/oldinterface"))
    # Do not test JuMP examples to avoid conflict between JuMP 0.18 and 0.19.
    if test_file[end-2:end] == ".jl" && !startswith(test_file, "jump")
        include(joinpath(dirname(@__FILE__), "..", "examples/oldinterface", test_file))
    end
end
