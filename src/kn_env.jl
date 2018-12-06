# KNITRO environment & context

mutable struct Env
    ptr_env::Ref{Ptr{Nothing}}

    function Env()
        new(Ref{Ptr{Nothing}}())
    end
end

Base.unsafe_convert(ptr::Type{Ptr{Cvoid}}, env::Env) = env.ptr_env.x::Ptr{Cvoid}

function is_valid(env::Env)
    env.ptr_env.x != C_NULL
end

function free_env(env::Env)
    env.ptr_env.x == C_NULL && return
    @kn_ccall(free, Cint, (Ptr{Nothing},), env.ptr_env)
    env.ptr_env.x = C_NULL
end

#--------------------------------------------------
# LM license manager
#--------------------------------------------------
mutable struct LMcontext
    ptr_lmcontext::Ref{Ptr{Nothing}}

    function LMcontext()
        ptr = Ref{Ptr{Nothing}}()
        res = @kn_ccall(checkout_license, Cint, (Ptr{Nothing},), ptr)
        if res != 0
            error("KNITRO: Error checkout license")
        end

        return new(ptr)
    end
end

function KN_release_license(lm::LMcontext)
    lm.ptr_lmcontext.x == C_NULL && return
    @kn_ccall(release_license, Cint, (Ptr{Nothing},), lm.ptr_lmcontext)
    lm.ptr_lmcontext = C_NULL
end
