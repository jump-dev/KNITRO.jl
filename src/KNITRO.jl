# Copyright (c) 2016: Ng Yee Sian, Miles Lubin, other contributors
#
# Use of this source code is governed by an MIT-style license that can be found
# in the LICENSE.md file or at https://opensource.org/licenses/MIT.

module KNITRO

import Libdl

# deps.jl file is always built via `Pkg.build`, even if we didn't find a local
# install and we want to use the artifact instead. This is so KNITRO.jl will be
# recompiled if we update the file. See issue Gurobi#438 for more details.
const _DEPS_FILE = joinpath(dirname(@__FILE__), "..", "deps", "deps.jl")

if isfile(_DEPS_FILE)
    include(_DEPS_FILE)
else
    error("""
          KNITRO.jl is not installed correctly. Please run the following code and
          then restart Julia:
          ```
          import Pkg
          Pkg.build("KNITRO")
          ```
          """)
end

@static if isdefined(@__MODULE__, :libknitro)
    # deps.jl must define a local installation.
    let version = has_knitro() ? knitro_version() : v"15.0.0"
        if !(v"13" <= version < v"16")
            error(
                "You have installed version $version of Artelys Knitro, " *
                "which is not supported by KNITRO.jl. We require a version " *
                "in [13, 16)",
            )
        end
    end
else
    import KNITRO_jll
    if KNITRO_jll.is_available()
        using KNITRO_jll: libknitro, knitroampl
        const amplexe = knitroampl
    else
        error(
            "Unsupported platform: Use a manual installation by setting " *
            "`KNITRO_JL_USE_KNITRO_JLL` to false. See the README for details.",
        )
    end
end

function __init__()
    libiomp5 = replace(libknitro, "libknitro" => "libiomp5")
    if isfile(libiomp5)
        Libdl.dlopen(libiomp5)
    end
    return
end

has_knitro() = endswith(libknitro, Libdl.dlext)

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
