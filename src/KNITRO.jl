__precompile__()

module KNITRO

    fn = joinpath(dirname(@__FILE__), "..", "deps", "deps.jl")
    if isfile(fn)
        include(fn)
    else
        error("KNITRO not properly installed. Please run `] build KNITRO`")
    end

    using Libdl, SparseArrays
    import Base: show

    "A macro to make calling KNITRO's C API a little cleaner"
    macro ktr_ccall(func, args...)
        f = Base.Meta.quot(Symbol("KTR_$(func)"))
        args = [esc(a) for a in args]
        quote
            ccall(($f,libknitro), $(args...))
        end
    end
    "Load KNITRO version number via KTR API."
    function unsafe_get_release()
        len = 15
        out = zeros(Cchar,len)
        @ktr_ccall(get_release, Any, (Cint, Ptr{Cchar}), len, out)
        res = String(strip(String(convert(Vector{UInt8},out)), '\0'))
        return VersionNumber(split(res, " ")[2])
    end

    const KNITRO_VERSION = unsafe_get_release()

    # Wrapper of old API (soon deprecated)
    include("ktr_model.jl")
    include("ktr_callbacks.jl")
    include("ktr_functions.jl")
    include("ktr_defines.jl")
    include("ktr_params.jl")
    # wrapper with MathProgBase (only work with old API)
    include("MPBWrapper.jl")

    # Wrapper of new API (KNITRO's version > 11.0)
    # We load the new API only if KNITRO has correct version
    if KNITRO_VERSION >= v"11.0"
        include("kn_common.jl")
        include("kn_env.jl")

        include("kn_model.jl")
        include("kn_defines.jl")
        include("kn_params.jl")
        include("kn_variables.jl")
        include("kn_attributes.jl")
        include("kn_constraints.jl")
        include("kn_residuals.jl")
        include("kn_solve.jl")
        include("kn_callbacks.jl")

        # the MathOptInterface wrapper works only with the new API
        include("MOI_wrapper.jl")
    end
end
