# KNITRO environment & context

mutable struct Env
    ptr_env::Ref{Ptr{Nothing}}

    function Env()
        new(Ref{Ptr{Nothing}}())
    end
end

function is_valid(env::Env)
    env.ptr_env.x != C_NULL
end

function free_env(env::Env)
    env.ptr_env.x == C_NULL && return
    @kn_ccall(free, Cint, (Ptr{Nothing},), env.ptr_env)
    env.ptr_env.x = C_NULL
end
