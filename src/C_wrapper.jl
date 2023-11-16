# Copyright (c) 2016: Ng Yee Sian, Miles Lubin, other contributors
#
# Use of this source code is governed by an MIT-style license that can be found
# in the LICENSE.md file or at https://opensource.org/licenses/MIT.

"A macro to make calling KNITRO's KN_* C API a little cleaner"
macro kn_ccall(func, args...)
    f = Base.Meta.quot(Symbol("KN_$(func)"))
    args = [esc(a) for a in args]
    quote
        ccall(($f, libknitro), $(args...))
    end
end

macro kn_get_attribute(function_name, type)
    fname = Symbol("KN_" * string(function_name))
    quote
        function $(esc(fname))(m::Model)
            val = zeros($type, 1)
            ret = $fname(m, val)
            return val[1]
        end
    end
end

"Return the current KNITRO version."
function get_release()
    len = 15
    out = zeros(Cchar, len)
    KN_get_release(len, out)
    return String(strip(String(convert(Vector{UInt8}, out)), '\0'))
end

"Wrapper for KNITRO KN_context."
mutable struct Env
    ptr_env::Ptr{Cvoid}

    function Env()
        ptrptr_env = Ref{Ptr{Cvoid}}()
        res = KN_new(ptrptr_env)
        if res != 0
            error("Fail to retrieve a valid KNITRO KN_context. Error $res")
        end
        return new(ptrptr_env[])
    end

    Env(ptr::Ptr{Cvoid}) = new(ptr)
end

Base.unsafe_convert(::Type{Ptr{Cvoid}}, env::Env) = env.ptr_env::Ptr{Cvoid}

is_valid(env::Env) = env.ptr_env != C_NULL

"""
Free all memory and release any Knitro license acquired by calling KN_new.
"""
function free_env(env::Env)
    if env.ptr_env != C_NULL
        ptrptr_env = Ref{Ptr{Cvoid}}(env.ptr_env)
        KN_free(ptrptr_env)
        env.ptr_env = C_NULL
    end
    return
end

"""
Structure specifying the callback context.

Each evaluation callbacks (for objective, gradient or hessian)
is attached to a unique callback context.
"""
mutable struct CallbackContext
    context::Ptr{Cvoid}
    n::Int
    m::Int
    # Add a dictionnary to store user params.
    userparams::Any

    # Oracle's callbacks are context dependent, so store
    # them inside dedicated CallbackContext.
    eval_f::Function
    eval_g::Function
    eval_h::Function
    eval_rsd::Function
    eval_jac_rsd::Function

    function CallbackContext(ptr_cb::Ptr{Cvoid})
        return new(ptr_cb, 0, 0, nothing)
    end
end

Base.unsafe_convert(::Type{Ptr{Cvoid}}, cb::CallbackContext) = cb.context::Ptr{Cvoid}

mutable struct Model
    # KNITRO context environment.
    env::Env
    # Keep reference to callbacks for garbage collector.
    callbacks::Vector{CallbackContext}
    # Some structures for userParams
    puts_user::Any
    multistart_user::Any
    mip_user::Any
    newpoint_user::Any

    # Solution values.
    # Optimization status. Equal to 1 if problem is unsolved.
    status::Cint
    obj_val::Cdouble
    x::Vector{Cdouble}
    mult::Vector{Cdouble}

    # Special callbacks (undefined by default).
    # (this functions do not depend on callback environments)
    ms_process::Function
    newpt_callback::Function
    mip_callback::Function
    user_callback::Function
    ms_initpt_callback::Function
    puts_callback::Function

    # Constructor.
    function Model()
        model = new(
            Env(),
            CallbackContext[],
            nothing,
            nothing,
            nothing,
            nothing,
            1,
            Inf,
            Cdouble[],
            Cdouble[],
        )
        # Add a destructor to properly delete model.
        finalizer(KN_free, model)
        return model
    end
    # Instantiate a new Knitro instance in current environment `env`.
    function Model(env::Env)
        return new(
            env,
            CallbackContext[],
            nothing,
            nothing,
            nothing,
            nothing,
            1,
            Inf,
            Cdouble[],
            Cdouble[],
        )
    end
end

Base.unsafe_convert(::Type{Ptr{Cvoid}}, kn::Model) = kn.env.ptr_env::Ptr{Cvoid}

"Free solver object."
KN_free(m::Model) = free_env(m.env)

"Create solver object."
KN_new() = Model()

is_valid(m::Model) = is_valid(m.env)

has_callbacks(m::Model) = !isempty(m.callbacks)

register_callback(model::Model, cb::CallbackContext) = push!(model.callbacks, cb)

function Base.show(io::IO, m::Model)
    if is_valid(m)
        println(io, "$(get_release())")
        println(io, "-----------------------")
        println(io, "Problem Characteristics")
        println(io, "-----------------------")
        println(io, "Objective goal:  Minimize")
        println(io, "Objective type:  $(KN_get_obj_type(m))")
        println(
            io,
            "Number of variables:                             $(KN_get_number_vars(m))",
        )
        println(
            io,
            "Number of constraints:                           $(KN_get_number_cons(m))",
        )
        println(
            io,
            "Number of nonzeros in Jacobian:                  $(KN_get_jacobian_nnz(m))",
        )
        println(
            io,
            "Number of nonzeros in Hessian:                   $(KN_get_hessian_nnz(m))",
        )

    else
        println(io, "KNITRO Problem: NULL")
    end
    return
end

#=
    LM license manager
=#

"""
Type declaration for the Artelys License Manager context object.
Applications must not modify any part of the context.
"""
mutable struct LMcontext
    ptr_lmcontext::Ptr{Cvoid}
    # Keep a pointer to instantiated models in order to free
    # memory properly.
    linked_models::Vector{Model}

    function LMcontext()
        ptrref = Ref{Ptr{Cvoid}}()
        res = KN_checkout_license(ptrref)
        if res != 0
            error("KNITRO: Error checkout license")
        end
        lm = new(ptrref[], Model[])
        finalizer(KN_release_license, lm)
        return lm
    end
end

Base.unsafe_convert(::Type{Ptr{Cvoid}}, lm::LMcontext) = lm.ptr_lmcontext::Ptr{Cvoid}

function Env(lm::LMcontext)
    ptrptr_env = Ref{Ptr{Cvoid}}()
    res = KN_new_lm(lm, ptrptr_env)
    if res != 0
        error("Fail to retrieve a valid KNITRO KN_context. Error $res")
    end
    return Env(ptrptr_env[])
end

function attach!(lm::LMcontext, model::Model)
    push!(lm.linked_models, model)
    return
end

# create Model with license manager
function Model(lm::LMcontext)
    model = Model(Env(lm))
    attach!(lm, model)
    return model
end

KN_new_lm(lm::LMcontext) = Model(lm)

function KN_release_license(lm::LMcontext)
    # First, ensure that all linked models are properly freed
    # before releasing license manager!
    KN_free.(lm.linked_models)
    if lm.ptr_lmcontext != C_NULL
        refptr = Ref{Ptr{Cvoid}}(lm.ptr_lmcontext)
        KN_release_license(refptr)
        lm.ptr_lmcontext = C_NULL
    end
    return
end

function KN_solve(m::Model)
    # Check sanity. If model has Julia callbacks, we need to ensure
    # that Knitro is not multithreaded. Otherwise, the code will segfault
    # as we have trouble calling Julia code from multithreaded C
    # code. See issue #93 on https://github.com/jump-dev/KNITRO.jl.
    if has_callbacks(m)
        if KNITRO_VERSION >= v"13.0"
            KN_set_int_param(m, KN_PARAM_MS_NUMTHREADS, 1)
            KN_set_int_param(m, KN_PARAM_NUMTHREADS, 1)
            KN_set_int_param(m, KN_PARAM_MIP_NUMTHREADS, 1)
        else
            KN_set_int_param_by_name(m, "par_numthreads", 1)
            KN_set_int_param_by_name(m, "par_msnumthreads", 1)
        end
    end
    # For KN_solve, we do not return an error if ret is different of 0.
    m.status = KN_solve(m.env)
    return m.status
end

#=
    GETTERS
=#

function KN_get_solution(m::Model)
    # we first check that the model is well defined to avoid segfault
    @assert m.env != C_NULL
    p = Ref{Cint}(0)
    KN_get_number_vars(m, p)
    nx = p[]
    KN_get_number_cons(m, p)
    nc = p[]

    x = zeros(Cdouble, nx)
    lambda = zeros(Cdouble, nx + nc)
    status, obj = Ref{Cint}(0), Ref{Cdouble}(0.0)
    KN_get_solution(m, status, obj, x, lambda)
    # Keep solution in cache.
    m.status = status[]
    m.x = x
    m.mult = lambda
    m.obj_val = obj[]
    return status[], obj[], x, lambda
end

# some wrapper functions for MOI
function get_status(m::Model)
    @assert m.env != C_NULL
    if m.status != 1
        return m.status
    end
    status, obj = Ref{Cint}(0), Ref{Cdouble}(0.0)
    KN_get_solution(m, status, obj, C_NULL, C_NULL)
    # Keep status in cache.
    m.status = status[]
    return status[]
end

function get_objective(m::Model)
    @assert m.env != C_NULL
    if isfinite(m.obj_val)
        return m.obj_val
    end
    status, obj = Ref{Cint}(0), Ref{Cdouble}(0.0)
    KN_get_solution(m, status, obj, C_NULL, C_NULL)
    # Keep objective value in cache.
    m.obj_val = obj[]
    return obj[]
end

function get_solution(m::Model)
    # We first check that the model is well defined to avoid segfault.
    @assert m.env != C_NULL
    if !isempty(m.x)
        return m.x
    end
    p = Ref{Cint}(0)
    KN_get_number_vars(m, p)
    nx = p[]
    x = zeros(Cdouble, nx)
    status, obj = Ref{Cint}(0), Ref{Cdouble}(0.0)
    KN_get_solution(m, status, obj, x, C_NULL)
    # Keep solution in cache.
    m.x = x
    return x
end
get_solution(m::Model, ix::Int) = isempty(m.x) ? get_solution(m)[ix] : m.x[ix]

function get_dual(m::Model)
    # we first check that the model is well defined to avoid segfault
    @assert m.env != C_NULL
    if !isempty(m.mult)
        return m.mult
    end
    p = Ref{Cint}(0)
    KN_get_number_vars(m, p)
    nx = p[]
    KN_get_number_cons(m, p)
    nc = p[]
    lambda = zeros(Cdouble, nx + nc)
    status, obj = Ref{Cint}(0), Ref{Cdouble}(0.0)
    KN_get_solution(m, status, obj, C_NULL, lambda)
    # Keep multipliers in cache.
    m.mult = lambda
    return lambda
end

get_dual(m::Model, ix::Int) = isempty(m.mult) ? get_dual(m)[ix] : m.mult[ix]
