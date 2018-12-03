__precompile__()

module KNITRO
    using Compat
    using Compat.Libdl, Compat.SparseArrays
    import Compat: Sys



    function __init__()
        if Sys.islinux()
            # fixes missing symbols in libknitro.so
            Compat.Libdl.dlopen("libdl", RTLD_GLOBAL)
            Compat.Libdl.dlopen("libgomp", RTLD_GLOBAL)
        end
    end
    @static if Sys.islinux() const libknitro = "libknitro" end
    @static if Sys.iswindows() const libknitro = "knitro" end


    # Wrapper of old API (soon deprecated)
    include("ktr_model.jl")
    include("ktr_callbacks.jl")
    include("ktr_functions.jl")
    include("ktr_defines.jl")
    include("ktr_params.jl")

    # Wrapper of new API (KNITRO's version > 11.0)
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

    include("MOI_wrapper.jl")


    # wrapper with MathProgBase
    include("MPBWrapper.jl")
end
