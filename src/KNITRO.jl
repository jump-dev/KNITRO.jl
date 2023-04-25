# Copyright (c) 2016: Ng Yee Sian, Miles Lubin, other contributors
#
# Use of this source code is governed by an MIT-style license that can be found
# in the LICENSE.md file or at https://opensource.org/licenses/MIT.

module KNITRO

import Libdl
import SparseArrays

const _DEPS_FILE = joinpath(dirname(@__FILE__), "..", "deps", "deps.jl")
if isfile(_DEPS_FILE)
    include(_DEPS_FILE)
else
    error("KNITRO.jl not properly installed. Please run `] build KNITRO`")
end

const IS_KNITRO_LOADED = endswith(libknitro, Libdl.dlext)
KNITRO_VERSION = VersionNumber(0, 0, 0) # Fake a version for AutoMerge

function __init__()
    if haskey(ENV, "SECRET_KNITRO_LIBIOMP5")
        Libdl.dlopen(replace(libknitro, "libknitro" => "libiomp5"))
    end
    if IS_KNITRO_LOADED
        len = 15
        out = zeros(Cchar, len)
        ccall((:KTR_get_release, libknitro), Any, (Cint, Ptr{Cchar}), len, out)
        res = String(strip(String(convert(Vector{UInt8}, out)), '\0'))
        global KNITRO_VERSION = VersionNumber(split(res, " ")[2])
    end
    if KNITRO_VERSION != v"0.0.0" && KNITRO_VERSION < v"11.0"
        error(
            "You have installed version $KNITRO_VERSION of Artelys " *
            "Knitro, which is not supported by KNITRO.jl. We require a " *
            "Knitro version greater than 11.0.",
        )
    end
    return
end

has_knitro() = IS_KNITRO_LOADED
knitro_version() = KNITRO_VERSION

include("libknitro.jl")
include("C_wrapper.jl")
include("callbacks.jl")
include("MOI_wrapper.jl")

end
