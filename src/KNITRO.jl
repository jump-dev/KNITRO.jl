module KNITRO

const _DEPS_FILE = joinpath(dirname(@__FILE__), "..", "deps", "deps.jl")
if isfile(_DEPS_FILE)
    include(_DEPS_FILE)
else
    error("KNITRO.jl not properly installed. Please run `] build KNITRO`")
end

using Libdl, SparseArrays
import Base: show

const IS_KNITRO_LOADED = endswith(libknitro, Libdl.dlext)

const KNITRO_VERSION = if IS_KNITRO_LOADED
    len = 15
    out = zeros(Cchar, len)
    ccall((:KTR_get_release, libknitro), Any, (Cint, Ptr{Cchar}), len, out)
    res = String(strip(String(convert(Vector{UInt8}, out)), '\0'))
    VersionNumber(split(res, " ")[2])
else
    VersionNumber(0, 0, 0) # Fake a version for AutoMerge
end

if KNITRO_VERSION != v"0.0.0" && KNITRO_VERSION < v"11.0"
    error(
        "You have installed version $KNITRO_VERSION of Artelys Knitro, which is not supported
  by KNITRO.jl. We require a Knitro version greater than 11.0.
  ",
    )
end

has_knitro() = IS_KNITRO_LOADED
knitro_version() = KNITRO_VERSION

include("libknitro.jl")
include("C_wrapper.jl")
include("callbacks.jl")
include("MOI_wrapper.jl")

end
