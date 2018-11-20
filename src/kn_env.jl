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
