using Compat
using Compat.Libdl

depsfile = joinpath(dirname(@__FILE__),"deps.jl")

if isfile(depsfile)
    rm(depsfile)
end

function write_depsfile(path)
    open(depsfile,"w") do f
        print(f,"const libknitro = ")
        show(f, path)
        println(f)
    end
end

paths_to_try = String[]

libname = string(Compat.Sys.iswindows() ? "" : "lib", "knitro", ".", Libdl.dlext)

# try to load absolute path before
if haskey(ENV, "KNITRODIR")
    push!(paths_to_try, joinpath(ENV["KNITRODIR"], "lib", libname))
end

push!(paths_to_try, libname)

global found_knitro = false
for l in paths_to_try
    d = Libdl.dlopen_e(l)
    if d != C_NULL
        global found_knitro = true
        write_depsfile(l)
        break
    end
end

if !found_knitro
    error("Unable to locate KNITRO installation, " *
          "please check your enviroment variable KNITRODIR.")
end
