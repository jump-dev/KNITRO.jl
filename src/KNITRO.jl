# Copyright (c) 2016: Ng Yee Sian, Miles Lubin, other contributors
#
# Use of this source code is governed by an MIT-style license that can be found
# in the LICENSE.md file or at https://opensource.org/licenses/MIT.

module KNITRO

import KNITRO_jll
import Libdl

const _DEPS_FILE = joinpath(dirname(@__FILE__), "..", "deps", "deps.jl")
if isfile(_DEPS_FILE)
    include(_DEPS_FILE)
else
    error("KNITRO.jl not properly installed. Please run `] build KNITRO`")
end

has_knitro() = endswith(libknitro, Libdl.dlext)

if isdefined(@__MODULE__, :libknitro)
    # deps.jl must define a local installation.
elseif KNITRO_jll.is_available()
    import KNITRO_jll: libknitro
else
    error(
        "Unsupported platform: Use a manual installation by setting " *
        "`KNITRODIR`. See the README for details.",
    )
end

function __init__()
    if KNITRO_jll.is_available()
        return
    end
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
    length = 15
    release = zeros(Cchar, length)
    KN_get_release(length, release)
    version_string = GC.@preserve(release, unsafe_string(pointer(release)))
    return VersionNumber(split(version_string, " ")[2])
end

include("libknitro.jl")
include("C_wrapper.jl")

# KNITRO exports all `KN_XXX` symbols. If you don't want all of these symbols in
# your environment, then use `import KNITRO` instead of `using KNITRO`.

for name in filter(s -> startswith("$s", "KN_"), names(@__MODULE__; all=true))
    @eval export $name
end

# For the MOI extension
global Optimizer

end
