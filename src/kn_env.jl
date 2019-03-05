# KNITRO environment & context

#--------------------------------------------------
# LM license manager
#--------------------------------------------------
"""
Type declaration for the Artelys License Manager context object.
Applications must not modify any part of the context.
"""
mutable struct LMcontext
    ptr_lmcontext::Ptr{Cvoid}

    function LMcontext()
        ptrref = Ref{Ptr{Cvoid}}()
        res = @kn_ccall(checkout_license, Cint, (Ptr{Cvoid},), ptrref)
        if res != 0
            error("KNITRO: Error checkout license")
        end
        lm = new(ptrref[])
        finalizer(KN_release_license, lm)
        return lm
    end
end

function KN_release_license(lm::LMcontext)
    if lm.ptr_lmcontext != C_NULL
        refptr = Ref{Ptr{Cvoid}}(lm.ptr_lmcontext)
        @kn_ccall(release_license, Cint, (Ptr{Cvoid},), refptr)
        lm.ptr_lmcontext = C_NULL
    end
end


#--------------------------------------------------
# KN_context
#--------------------------------------------------
"Wrapper for KNITRO KN_context."
mutable struct Env
    ptr_env::Ptr{Cvoid}

    function Env()
        ptrptr_env = Ref{Ptr{Cvoid}}()
        res = @kn_ccall(new, Cint, (Ptr{Cvoid},), ptrptr_env)
        if res != 0
            error("Fail to retrieve a valid KNITRO KN_context. Error $res")
        end
        new(ptrptr_env[])
    end
    function Env(lm::LMcontext)
        ptrptr_env = Ref{Ptr{Cvoid}}()
        res = @kn_ccall(new_lm, Cint, (Ptr{Cvoid},Ptr{Cvoid}), lm.ptr_lmcontext, ptrptr_env)
        if res != 0
            error("Fail to retrieve a valid KNITRO KN_context. Error $res")
        end
        new(ptrptr_env[])
    end
end

Base.unsafe_convert(ptr::Type{Ptr{Cvoid}}, env::Env) = env.ptr_env::Ptr{Cvoid}

is_valid(env::Env)= env.ptr_env != C_NULL

"""
Free all memory and release any Knitro license acquired by calling KN_new.
"""
function free_env(env::Env)
    if env.ptr_env != C_NULL
        ptrptr_env = Ref{Ptr{Cvoid}}(env.ptr_env)
        @kn_ccall(free, Cint, (Ptr{Cvoid},), ptrptr_env)
        env.ptr_env = C_NULL
    end
    return
end
