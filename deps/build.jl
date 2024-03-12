using Libdl

const DEPS_FILE = joinpath(dirname(@__FILE__), "deps.jl")

if isfile(DEPS_FILE)
    rm(DEPS_FILE)
end

function write_depsfile(knpath, libpath)
    open(DEPS_FILE, "w") do io
        println(io, "const libknitro = \"$(escape_string(libpath))\"")
        knitroampl = joinpath(knpath, "..", "knitroampl", "knitroampl")
        println(io, "const amplexe = \"$(escape_string(knitroampl))\"")
        return
    end
    return
end

function try_local_installation()
    libname = string(Sys.iswindows() ? "" : "lib", "knitro", ".", Libdl.dlext)
    paths_to_try = String[]
    if haskey(ENV, "LD_LIBRARY_PATH")
        append!(paths_to_try, split(ENV["LD_LIBRARY_PATH"], ':'))
    end
    if haskey(ENV, "KNITRODIR")
        push!(paths_to_try, joinpath(ENV["KNITRODIR"], "lib"))
    end
    found_knitro = false
    for path in reverse(paths_to_try)
        l = joinpath(path, libname)
        d = Libdl.dlopen_e(l)
        if d != C_NULL
            found_knitro = true
            write_depsfile(path, l)
            break
        end
    end
    if !found_knitro
        write_depsfile("", "")
    end
    return
end

function try_ci_installation()
    local_filename = joinpath(@__DIR__, "knitro14.zip")
    download(ENV["SECRET_KNITRO_ZIP"], local_filename)
    run(`tar -xf knitro14.zip`)
    if Sys.islinux()
        write_depsfile("", joinpath(@__DIR__, "libknitro1400.so"))
    elseif Sys.isapple()
        write_depsfile("", joinpath(@__DIR__, "libknitro1400.dylib"))
    elseif Sys.iswindows()
        write_depsfile("", joinpath(@__DIR__, "knitro1400.dll"))
    end
    return
end

if get(ENV, "SECRET_KNITRO_ZIP", "") != ""
    try_ci_installation()
else
    try_local_installation()
end
