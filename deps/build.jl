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
        show(f, joinpath(knpath, "knitroampl", "knitroampl"))
        println(f)
    end
end

paths_to_try = String[]

libname = string(Sys.iswindows() ? "" : "lib", "knitro", ".", Libdl.dlext)

# try to load absolute path before
if haskey(ENV, "KNITRODIR")
    push!(paths_to_try, ENV["KNITRODIR"])
end

push!(paths_to_try, libname)

global found_knitro = false
for path in paths_to_try
    l = joinpath(path, "lib", libname)
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
