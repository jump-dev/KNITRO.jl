# Copyright (c) 2016: Ng Yee Sian, Miles Lubin, other contributors
#
# Use of this source code is governed by an MIT-style license that can be found
# in the LICENSE.md file or at https://opensource.org/licenses/MIT.

module KNITRO

import Libdl
import MathOptInterface as MOI
import SparseArrays

const _DEPS_FILE = joinpath(dirname(@__FILE__), "..", "deps", "deps.jl")
if isfile(_DEPS_FILE)
    include(_DEPS_FILE)
else
    error("KNITRO.jl not properly installed. Please run `] build KNITRO`")
end

has_knitro() = endswith(libknitro, Libdl.dlext)

function __init__()
    libiomp5 = replace(libknitro, "libknitro" => "libiomp5")
    if isfile(libiomp5)
        Libdl.dlopen(libiomp5)
    end
    version = has_knitro() ? knitro_version() : v"0.0.0"
    if version != v"0.0.0" && version < v"11.0"
        error(
            "You have installed version $version of Artelys " *
            "Knitro, which is not supported by KNITRO.jl. We require a " *
            "Knitro version greater than 11.0.",
        )
    end
    return
end

function knitro_version()
    buffer = zeros(Cchar, 15)
    ccall((:KTR_get_release, libknitro), Cint, (Cint, Ptr{Cchar}), 15, buffer)
    version_string = GC.@preserve(buffer, unsafe_string(pointer(buffer)))
    return VersionNumber(split(version_string, " ")[2])
end

include("libknitro.jl")
include("C_wrapper.jl")
include("MOI_wrapper.jl")

end
