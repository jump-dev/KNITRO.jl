module KNITRO

const _DEPS_FILE = joinpath(dirname(@__FILE__), "..", "deps", "deps.jl")
if isfile(_DEPS_FILE)
    include(_DEPS_FILE)
else
    error("KNITRO.jl not properly installed. Please run `] build KNITRO`")
end

using Libdl, SparseArrays
import Base: show

const KNITRO_VERSION = if libknitro == "julia_registryci_automerge"
    VersionNumber(11, 0, 0) # Fake a valid version for AutoMerge
else
    len = 15
    out = zeros(Cchar,len)
    ccall((:KTR_get_release, libknitro), Any, (Cint, Ptr{Cchar}), len, out)
    res = String(strip(String(convert(Vector{UInt8},out)), '\0'))
    VersionNumber(split(res, " ")[2])
end

if KNITRO_VERSION < v"11.0"
    error("You have installed version $KNITRO_VERSION of Artelys Knitro, which is not supported
    by KNITRO.jl. We require a Knitro version greater than 11.0.
    ")
end

include("libknitro.jl")
include("C_wrapper.jl")
include("callbacks.jl")

# the MathOptInterface wrapper works only with the new API
include("MOI_wrapper.jl")

end
