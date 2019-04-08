# KNITRO environment & context

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

    Env(ptr::Ptr{Cvoid}) = new(ptr)
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
