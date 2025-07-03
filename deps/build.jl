# Copyright (c) 2016: Ng Yee Sian, Miles Lubin, other contributors
#
# Use of this source code is governed by an MIT-style license that can be found
# in the LICENSE.md file or at https://opensource.org/licenses/MIT.

import Libdl

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

const WHEELS = Dict(
    "linux" => "https://files.pythonhosted.org/packages/76/6e/ffe880b013ad244f0fd91940454e4f2bf16fa01e74c469e1b0fb75eda12a/knitro-15.0.0-py3-none-manylinux1_x86_64.whl",
    "windows" => "https://files.pythonhosted.org/packages/13/3f/54953373ee3b631640b33b5d4bdb0217bdb1f8514b9374b08348e098ea2a/knitro-15.0.0-py3-none-win_amd64.whl",
)

function try_wheel_installation()
    ext, url = if Sys.islinux()
        ".so", WHEELS["linux"]
    elseif Sys.iswindows()
        ".dll", WHEELS["windows"]
    end
    if !isdir(joinpath(@__DIR__, "knitro"))
        run(`curl --output knitro.whl $url`)
        run(`unzip knitro.whl`)
    end
    filename = joinpath(@__DIR__, "knitro", "lib", "libknitro$(ext)")
    write_depsfile("", filename)
    return
end

function try_secret_installation()
    local_filename = joinpath(@__DIR__, "libknitro.so")
    download(ENV["SECRET_KNITRO_URL"], local_filename)
    download(ENV["SECRET_KNITRO_LIBIOMP5"], joinpath(@__DIR__, "libiomp5.so"))
    write_depsfile("", local_filename)
    return
end

if get(ENV, "KNITRO_JL_WHL", "false") == "true"
    try_wheel_installation()
elseif get(ENV, "SECRET_KNITRO_URL", "") != ""
    try_secret_installation()
else
    try_local_installation()
end
