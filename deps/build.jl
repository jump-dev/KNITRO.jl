using Libdl, Base.Sys

depsfile = joinpath(dirname(@__FILE__), "deps.jl")

if isfile(depsfile)
    rm(depsfile)
end

function write_depsfile(knpath, libpath)
    open(depsfile,"w") do f
        print(f,"const libknitro = ")
        show(f, libpath)
        println(f)
        print(f,"const amplexe = ")
        show(f, joinpath(knpath, "..", "knitroampl", "knitroampl"))
        println(f)
    end
end

libname = string(Sys.iswindows() ? "" : "lib", "knitro", ".", Libdl.dlext)

if haskey(ENV, "LD_LIBRARY_PATH")
    paths_to_try = split(ENV["LD_LIBRARY_PATH"], ':')
else
    paths_to_try = String[]
end

if haskey(ENV, "KNITRODIR")
    push!(paths_to_try, joinpath(ENV["KNITRODIR"], "lib"))
end

global found_knitro = false
# test KNITRODIR first
for path in reverse(paths_to_try)
    l = joinpath(path, libname)
    d = Libdl.dlopen_e(l)
    if d != C_NULL
        global found_knitro = true
        write_depsfile(path, l)
        break
    end
end

if !found_knitro
    error("Unable to locate KNITRO installation, " *
          "please check your enviroment variable KNITRODIR.")
end
