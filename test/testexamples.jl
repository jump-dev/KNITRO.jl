for test_file in readdir("../examples/")
    if test_file[end-2:end] == ".jl"
        include("../examples/$(test_file)")
    end
end