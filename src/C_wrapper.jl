# Copyright (c) 2016: Ng Yee Sian, Miles Lubin, other contributors
#
# Use of this source code is governed by an MIT-style license that can be found
# in the LICENSE.md file or at https://opensource.org/licenses/MIT.

mutable struct Env
    ptr_env::Ptr{Cvoid}
end

Base.cconvert(::Type{Ptr{Cvoid}}, env::Env) = env
Base.unsafe_convert(::Type{Ptr{Cvoid}}, env::Env) = env.ptr_env::Ptr{Cvoid}

"""
Structure specifying the callback context.

Each evaluation callbacks (for objective, gradient or hessian)
is attached to a unique callback context.
"""
mutable struct CallbackContext
    context::Ptr{Cvoid}
    n::Int
    m::Int
    user_data::Any
    eval_f::Function
    eval_g::Function
    eval_h::Function
    eval_rsd::Function
    eval_jac_rsd::Function

    CallbackContext(ptr_cb::Ptr{Cvoid}) = new(ptr_cb, 0, 0, nothing)
end

Base.cconvert(::Type{Ptr{Cvoid}}, cb::CallbackContext) = cb
Base.unsafe_convert(::Type{Ptr{Cvoid}}, cb::CallbackContext) = cb.context::Ptr{Cvoid}

mutable struct Model
    env::Env
    callbacks::Vector{CallbackContext}
    status::Cint
    obj_val::Cdouble
    x::Vector{Cdouble}
    lambda::Vector{Cdouble}
    newpt_user_data::Any
    ms_process_user_data::Any
    mip_node_user_data::Any
    ms_initpt_user_data::Any
    puts_user_data::Any
    newpt_callback::Function
    ms_process_callback::Function
    mip_node_callback::Function
    ms_initpt_callback::Function
    puts_callback::Function

    function Model(env::Env)
        return new(
            env,
            CallbackContext[],
            1,
            NaN,
            Cdouble[],
            Cdouble[],
            nothing,
            nothing,
            nothing,
            nothing,
        )
    end
end

Base.cconvert(::Type{Ptr{Cvoid}}, model::Model) = model
Base.unsafe_convert(::Type{Ptr{Cvoid}}, kn::Model) = kn.env.ptr_env::Ptr{Cvoid}

"Free solver object."
function KN_free(model::Model)
    if model.env.ptr_env != C_NULL
        ret = KN_free(Ref(model.env.ptr_env))
        model.env.ptr_env = C_NULL
        return ret
    end
    return Cint(0)
end

"Create solver object."
function KN_new()
    ptrptr_env = Ref{Ptr{Cvoid}}()
    res = KN_new(ptrptr_env)
    if res != 0
        error("Fail to retrieve a valid KNITRO KN_context. Error $res")
    end
    model = Model(Env(ptrptr_env[]))
    finalizer(KN_free, model)
    return model
end

function Base.show(io::IO, model::Model)
    if model.env.ptr_env === C_NULL
        println(io, "KNITRO Problem: NULL")
        return
    end
    println(io, "$(knitro_version())")
    println(io, "-----------------------")
    println(io, "Problem Characteristics")
    println(io, "-----------------------")
    println(io, "Objective goal:  Minimize")
    p = Ref{Cint}()
    KN_get_obj_type(model, p)
    println(io, "Objective type:  $(p[])")
    KN_get_number_vars(model, p)
    println(io, "Number of variables:                             $(p[])")
    KN_get_number_cons(model, p)
    println(io, "Number of constraints:                           $(p[])")
    q = Ref{KNLONG}()
    KN_get_jacobian_nnz(model, q)
    println(io, "Number of nonzeros in Jacobian:                  $(q[])")
    KN_get_hessian_nnz(model, q)
    println(io, "Number of nonzeros in Hessian:                   $(q[])")
    return
end

"""
Type declaration for the Artelys License Manager context object.
Applications must not modify any part of the context.
"""
mutable struct LMcontext
    ptr_lmcontext::Ptr{Cvoid}
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

Base.cconvert(::Type{Ptr{Cvoid}}, lm::LMcontext) = lm
Base.unsafe_convert(::Type{Ptr{Cvoid}}, lm::LMcontext) = lm.ptr_lmcontext::Ptr{Cvoid}

function KN_new_lm(lm::LMcontext)
    ptrptr_env = Ref{Ptr{Cvoid}}()
    res = KN_new_lm(lm, ptrptr_env)
    if res != 0
        error("Fail to retrieve a valid KNITRO KN_context. Error $res")
    end
    model = Model(Env(ptrptr_env[]))
    push!(lm.linked_models, model)
    return model
end

function KN_release_license(lm::LMcontext)
    # First, ensure that all linked models are properly freed before releasing
    # license manager!
    KN_free.(lm.linked_models)
    if lm.ptr_lmcontext != C_NULL
        refptr = Ref{Ptr{Cvoid}}(lm.ptr_lmcontext)
        KN_release_license(refptr)
        lm.ptr_lmcontext = C_NULL
    end
    return
end

function KN_solve(model::Model)
    # Check sanity. If model has Julia callbacks, we need to ensure
    # that Knitro is not multithreaded. Otherwise, the code will segfault
    # as we have trouble calling Julia code from multithreaded C
    # code. See issue #93 on https://github.com/jump-dev/KNITRO.jl.
    if !isempty(model.callbacks)
        if knitro_version() >= v"13.0"
            KN_set_int_param(model, KN_PARAM_MS_NUMTHREADS, 1)
            KN_set_int_param(model, KN_PARAM_NUMTHREADS, 1)
            KN_set_int_param(model, KN_PARAM_MIP_NUMTHREADS, 1)
        else
            KN_set_int_param_by_name(model, "par_numthreads", 1)
            KN_set_int_param_by_name(model, "par_msnumthreads", 1)
        end
    end
    # For KN_solve, we do not return an error if ret is different of 0.
    model.status = KN_solve(model.env)
    return model.status
end

function KN_get_solution(model::Model)
    @assert model.env != C_NULL
    nx, nc = Ref{Cint}(0), Ref{Cint}(0)
    KN_get_number_vars(model, nx)
    KN_get_number_cons(model, nc)
    model.x = zeros(Cdouble, nx[])
    model.lambda = zeros(Cdouble, nx[] + nc[])
    status, obj = Ref{Cint}(0), Ref{Cdouble}(0.0)
    KN_get_solution(model, status, obj, model.x, model.lambda)
    model.status = status[]
    model.obj_val = obj[]
    return status[], obj[], model.x, model.lambda
end

function KN_set_cb_user_params(model::Model, cb::CallbackContext, user_data=nothing)
    cb.user_data = user_data
    # Note: we store here the number of constraints and variables defined
    # in the original Knitro model. We cannot retrieve these numbers during
    # callbacks invokation, as sometimes the number of variables and constraints
    # change internally in Knitro (e.g. when cuts are added when resolving
    # Branch&Bound). We prefer to use the number of variables and constraints
    # of the original model so that user's callbacks could consider that
    # the arrays of primal variable x and dual variable \lambda have fixed
    # sizes.
    p = Ref{Cint}(0)
    KN_get_number_vars(model, p)
    cb.n = p[]
    KN_get_number_cons(model, p)
    cb.m = p[]
    return KN_set_cb_user_params(model.env, cb, pointer_from_objref(cb))
end

mutable struct EvalRequest
    evalRequestCode::Cint
    threadID::Cint
    x::Array{Float64}
    lambda::Array{Float64}
    sigma::Float64
    vec::Array{Float64}

    function EvalRequest(::Ptr{Cvoid}, request::KN_eval_request, n::Int, m::Int)
        return new(
            request.type,
            request.threadID,
            unsafe_wrap(Array, request.x, n),
            unsafe_wrap(Array, request.lambda, n + m),
            request.sigma == C_NULL ? 1.0 : unsafe_wrap(Array, request.sigma, 1)[1],
            unsafe_wrap(Array, request.vec, n),
        )
    end
end

mutable struct EvalResult
    obj::Array{Float64}
    c::Array{Float64}
    objGrad::Array{Float64}
    jac::Array{Float64}
    hess::Array{Float64}
    hessVec::Array{Float64}
    rsd::Array{Float64}
    rsdJac::Array{Float64}

    function EvalResult(
        kc::Ptr{Cvoid},
        cb::Ptr{Cvoid},
        result::KN_eval_result,
        n::Int,
        m::Int,
    )
        objgrad_nnz = Ref{Cint}()
        jacobian_nnz = Ref{KNLONG}()
        hessian_nnz = Ref{KNLONG}()
        num_rsds = Ref{Cint}()
        rsd_jacobian_nnz = Ref{KNLONG}()
        KN_get_cb_objgrad_nnz(kc, cb, objgrad_nnz)
        KN_get_cb_jacobian_nnz(kc, cb, jacobian_nnz)
        KN_get_cb_hessian_nnz(kc, cb, hessian_nnz)
        KN_get_cb_number_rsds(kc, cb, num_rsds)
        KN_get_cb_rsd_jacobian_nnz(kc, cb, rsd_jacobian_nnz)
        return new(
            unsafe_wrap(Array, result.obj, 1),
            unsafe_wrap(Array, result.c, m),
            unsafe_wrap(Array, result.objGrad, objgrad_nnz[]),
            unsafe_wrap(Array, result.jac, jacobian_nnz[]),
            unsafe_wrap(Array, result.hess, hessian_nnz[]),
            unsafe_wrap(Array, result.hessVec, n),
            unsafe_wrap(Array, result.rsd, num_rsds[]),
            unsafe_wrap(Array, result.rsdJac, rsd_jacobian_nnz[]),
        )
    end
end

function _try_catch_handler(f::F) where {F<:Function}
    try
        return f()
    catch ex
        if ex isa InterruptException
            return KN_RC_USER_TERMINATION
        elseif ex isa DomainError
            return KN_RC_EVAL_ERR
        else
            @warn("Knitro encounters an exception in puts callback: $ex")
            return KN_RC_CALLBACK_ERR
        end
    end
end

for (wrap_name, name) in [
    :_eval_fc_wrapper => :eval_f,
    :_eval_ga_wrapper => :eval_g,
    :_eval_hess_wrapper => :eval_h,
    :_eval_rj_wrapper => :eval_jac_rsd,
    :_eval_rsd_wrapper => :eval_rsd,
]
    @eval begin
        function $wrap_name(
            ptr_model::Ptr{Cvoid},
            ptr_cb::Ptr{Cvoid},
            ptr_eval_request::Ptr{Cvoid},
            ptr_eval_results::Ptr{Cvoid},
            user_data::Ptr{Cvoid},
        )::Cint
            return _try_catch_handler() do
                eval_request = unsafe_load(Ptr{KN_eval_request}(ptr_eval_request))
                eval_result = unsafe_load(Ptr{KN_eval_result}(ptr_eval_results))
                cb = unsafe_pointer_to_objref(user_data)::CallbackContext
                request = EvalRequest(ptr_model, eval_request, cb.n, cb.m)
                result = EvalResult(ptr_model, ptr_cb, eval_result, cb.n, cb.m)
                return cb.$name(ptr_model, ptr_cb, request, result, cb.user_data)
            end
        end
    end
end

"""
    KN_add_eval_callback(model::Model, funccallback::Function)
    KN_add_eval_callback(model::Model, evalObj::Bool, indexCons::Vector{Cint},
                         funccallback::Function)

This is the routine for adding a callback for (nonlinear) evaluations
of objective and constraint functions.  This routine can be called
multiple times to add more than one callback structure (e.g. to create
different callback structures to handle different blocks of constraints).
This routine specifies the minimal information needed for a callback, and
creates the callback structure `cb`, which can then be passed to other
callback functions to set additional information for that callback.

# Parameters
* `evalObj`: boolean indicating whether or not any part of the objective
                  function is evaluated in the callback
* `indexCons`: (length nC) index of constraints evaluated in the callback
                  (set to NULL if nC=0)
* `funcCallback`: a function that evaluates the objective parts
                  (if evalObj=KNTRUE) and any constraint parts (specified by
                  nC and indexCons) involved in this callback; when
                  eval_fcga=KN_EVAL_FCGA_YES, this callback should also evaluate
                  the relevant first derivatives/gradients

# Returns
* `cb`: the callback structure that gets created by
                  calling this function; all the memory for this structure is
                  handled by Knitro

After a callback is created by `KN_add_eval_callback()`, the user can then specify
gradient information and structure through `KN_set_cb_grad()` and Hessian
information and structure through `KN_set_cb_hess()`.  If not set, Knitro will
approximate these.  However, it is highly recommended to provide a callback routine
to specify the gradients if at all possible as this will greatly improve the
performance of Knitro.  Even if a gradient callback is not provided, it is still
helpful to provide the sparse Jacobian structure through `KN_set_cb_grad()` to
improve the efficiency of the finite-difference gradient approximations.
Other optional information can also be set via `KN_set_cb_*()` functions as
detailed below.
"""
function KN_add_eval_callback_all(model::Model, callback::Function)
    c_func = @cfunction(
        _eval_fc_wrapper,
        Cint,
        (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid})
    )
    rfptr = Ref{Ptr{Cvoid}}()
    KN_add_eval_callback_all(model, c_func, rfptr)
    cb = CallbackContext(rfptr[])
    push!(model.callbacks, cb)
    cb.eval_f = callback
    KN_set_cb_user_params(model, cb)
    return cb
end

function KN_add_objective_callback(model::Model, callback::Function)
    c_func = @cfunction(
        _eval_fc_wrapper,
        Cint,
        (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid})
    )
    rfptr = Ref{Ptr{Cvoid}}()
    KN_add_eval_callback_one(model, Cint(-1), c_func, rfptr)
    cb = CallbackContext(rfptr[])
    push!(model.callbacks, cb)
    cb.eval_f = callback
    KN_set_cb_user_params(model, cb)
    return cb
end

function KN_add_eval_callback(
    model::Model,
    evalObj::Bool,
    indexCons::Vector{Cint},
    callback::Function,
)
    c_func = @cfunction(
        _eval_fc_wrapper,
        Cint,
        (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid})
    )
    rfptr = Ref{Ptr{Cvoid}}()
    KN_add_eval_callback(model, evalObj, length(indexCons), indexCons, c_func, rfptr)
    cb = CallbackContext(rfptr[])
    push!(model.callbacks, cb)
    cb.eval_f = callback
    KN_set_cb_user_params(model, cb)
    return cb
end

"""
    KN_set_cb_grad(model::Model, cb::CallbackContext, gradcallback;
                   nV::Integer=KN_DENSE, objGradIndexVars=C_NULL,
                   jacIndexCons=C_NULL, jacIndexVars=C_NULL)

This API function is used to set the objective gradient and constraint Jacobian
structure and also (optionally) a callback function to evaluate the objective
gradient and constraint Jacobian provided through this callback.
"""
function KN_set_cb_grad(
    model::Model,
    cb::CallbackContext,
    callback;
    nV::Integer=KN_DENSE,
    nnzJ::Union{Nothing,Integer}=nothing,
    objGradIndexVars=C_NULL,
    jacIndexCons=C_NULL,
    jacIndexVars=C_NULL,
)
    if nnzJ === nothing
        p = Ref{Cint}(0)
        KN_get_number_cons(model, p)
        nnzJ = iszero(p[]) ? KNLONG(0) : KNITRO.KN_DENSE_COLMAJOR
    end
    if (nV == 0 || nV == KN_DENSE)
        if objGradIndexVars != C_NULL
            error("objGradIndexVars must be set to C_NULL when nV = $nV")
        end
    else
        @assert (objGradIndexVars != C_NULL) && (length(objGradIndexVars) == nV)
    end
    if jacIndexCons != C_NULL && jacIndexVars != C_NULL
        @assert length(jacIndexCons) == length(jacIndexVars)
        nnzJ = KNLONG(length(jacIndexCons))
    end
    c_func = C_NULL
    if callback !== nothing
        cb.eval_g = callback
        c_func = @cfunction(
            _eval_ga_wrapper,
            Cint,
            (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid})
        )
    end
    return KN_set_cb_grad(
        model,
        cb,
        nV,
        objGradIndexVars,
        nnzJ,
        jacIndexCons,
        jacIndexVars,
        c_func,
    )
end

"""
    KN_set_cb_hess(
        model::Model,
        cb::CallbackContext,
        nnzH::Integer,
        callback::Function;
        hessIndexVars1=C_NULL,
        hessIndexVars2=C_NULL,
    )

This API function is used to set the structure and a callback function to
evaluate the components of the Hessian of the Lagrangian provided through this
callback.  KN_set_cb_hess() should only be used when defining a user-supplied
Hessian callback function (via the `hessopt=KN_HESSOPT_EXACT` user option).
When Knitro is approximating the Hessian, it cannot make use of the Hessian
sparsity structure.
"""
function KN_set_cb_hess(
    model::Model,
    cb::CallbackContext,
    nnzH::Integer,
    callback::Function;
    hessIndexVars1=C_NULL,
    hessIndexVars2=C_NULL,
)
    if nnzH == KN_DENSE_ROWMAJOR || nnzH == KN_DENSE_COLMAJOR
        @assert hessIndexVars1 == hessIndexVars2 == C_NULL
    elseif nnzH > 0
        @assert hessIndexVars1 != C_NULL && hessIndexVars2 != C_NULL
        @assert length(hessIndexVars1) == length(hessIndexVars2) == nnzH
    end
    cb.eval_h = callback
    c_func = @cfunction(
        _eval_hess_wrapper,
        Cint,
        (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid})
    )
    return KN_set_cb_hess(model, cb, nnzH, hessIndexVars1, hessIndexVars2, c_func)
end

"""
    KN_add_lsq_eval_callback(model::Model, callback::Function)

Add an evaluation callback for a least-squares models.  Similar to KN_add_eval_callback()
above, but for least-squares models.

* `model`: current KNITRO model
* `callback`: a function that evaluates any residual parts

After a callback is created by `KN_add_lsq_eval_callback()`, the user can then
specify residual Jacobian information and structure through `KN_set_cb_rsd_jac()`.
If not set, Knitro will approximate the residual Jacobian.  However, it is highly
recommended to provide a callback routine to specify the residual Jacobian if at all
possible as this will greatly improve the performance of Knitro.  Even if a callback
for the residual Jacobian is not provided, it is still helpful to provide the sparse
Jacobian structure for the residuals through `KN_set_cb_rsd_jac()` to improve the
efficiency of the finite-difference Jacobian approximation.
"""
function KN_add_lsq_eval_callback(model::Model, callback::Function)
    c_func = @cfunction(
        _eval_rsd_wrapper,
        Cint,
        (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid})
    )
    rfptr = Ref{Ptr{Cvoid}}()
    KN_add_lsq_eval_callback_all(model, c_func, rfptr)
    cb = CallbackContext(rfptr[])
    push!(model.callbacks, cb)
    cb.eval_rsd = callback
    KN_set_cb_user_params(model, cb)
    return cb
end

function KN_set_cb_rsd_jac(
    model::Model,
    cb::CallbackContext,
    nnzJ::Integer,
    callback::Function;
    jacIndexRsds=C_NULL,
    jacIndexVars=C_NULL,
)
    if nnzJ == KN_DENSE_ROWMAJOR || nnzJ == KN_DENSE_COLMAJOR || nnzJ == 0
        @assert jacIndexRsds == jacIndexVars == C_NULL
    else
        @assert jacIndexRsds != C_NULL && jacIndexVars != C_NULL
        @assert length(jacIndexRsds) == length(jacIndexVars) == nnzJ
    end
    cb.eval_jac_rsd = callback
    c_func = @cfunction(
        _eval_rj_wrapper,
        Cint,
        (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid})
    )
    return KN_set_cb_rsd_jac(model, cb, nnzJ, jacIndexRsds, jacIndexVars, c_func)
end

# KN_set_newpt_callback

function _newpt_wrapper(
    ptr_model::Ptr{Cvoid},
    ptr_x::Ptr{Cdouble},
    ptr_lambda::Ptr{Cdouble},
    user_data::Ptr{Cvoid},
)::Cint
    return _try_catch_handler() do
        model = unsafe_pointer_to_objref(user_data)::Model
        nx, nc = Ref{Cint}(0), Ref{Cint}(0)
        KN_get_number_vars(model, nx)
        KN_get_number_cons(model, nc)
        x = unsafe_wrap(Array, ptr_x, nx[])
        lambda = unsafe_wrap(Array, ptr_lambda, nx[] + nc[])
        return model.newpt_callback(model, x, lambda, model.newpt_user_data)
    end
end

"""
    KN_set_newpt_callback(model::Model, callback::Function)

Set the callback function that is invoked after Knitro computes a
new estimate of the solution point (i.e., after every iteration).
The function should not modify any Knitro arguments.

Callback is a function with signature:

    callback(kc, x, lambda, userdata)

Argument `kc` passed to the callback from inside Knitro is the
context pointer for the current problem being solved inside Knitro
(either the main single-solve problem, or a subproblem when using
multi-start, Tuner, etc.).
Arguments `x` and `lambda` contain the latest solution estimates.
Other values (such as objective, constraint, jacobian, etc.) can be
queried using the corresonding KN_get_XXX_values methods.

Note: Currently only active for continuous models.

"""
function KN_set_newpt_callback(model::Model, callback::Function, user_data=nothing)
    model.newpt_callback, model.newpt_user_data = callback, user_data
    c_func = @cfunction(
        _newpt_wrapper,
        Cint,
        (Ptr{Cvoid}, Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cvoid})
    )
    KN_set_newpt_callback(model, c_func, pointer_from_objref(model))
    return
end

# KN_set_ms_process_callback

function _ms_process_wrapper(
    ptr_model::Ptr{Cvoid},
    ptr_x::Ptr{Cdouble},
    ptr_lambda::Ptr{Cdouble},
    user_data::Ptr{Cvoid},
)::Cint
    return _try_catch_handler() do
        model = unsafe_pointer_to_objref(user_data)::Model
        nx, nc = Ref{Cint}(0), Ref{Cint}(0)
        KN_get_number_vars(model, nx)
        KN_get_number_cons(model, nc)
        x = unsafe_wrap(Array, ptr_x, nx[])
        lambda = unsafe_wrap(Array, ptr_lambda, nx[] + nc[])
        return model.ms_process_callback(model, x, lambda, model.ms_process_user_data)
    end
end

"""
    KN_set_ms_process_callback(model::Model, callback::Function)

This callback function is for multistart (MS) problems only.
Set the callback function that is invoked after Knitro finishes
processing a multistart solve.

Callback is a function with signature:

    callback(kc, x, lambda, userdata)

Argument `kc` passed to the callback
from inside Knitro is the context pointer for the last multistart
subproblem solved inside Knitro.  The function should not modify any
Knitro arguments.  Arguments `x` and `lambda` contain the solution from
the last solve.

"""
function KN_set_ms_process_callback(model::Model, callback::Function, user_data=nothing)
    model.ms_process_callback, model.ms_process_user_data = callback, user_data
    c_func = @cfunction(
        _ms_process_wrapper,
        Cint,
        (Ptr{Cvoid}, Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cvoid})
    )
    KN_set_ms_process_callback(model, c_func, pointer_from_objref(model))
    return
end

# KN_set_mip_node_callback

function _mip_node_callback_wrapper(
    ptr_model::Ptr{Cvoid},
    ptr_x::Ptr{Cdouble},
    ptr_lambda::Ptr{Cdouble},
    user_data::Ptr{Cvoid},
)::Cint
    return _try_catch_handler() do
        model = unsafe_pointer_to_objref(user_data)::Model
        nx, nc = Ref{Cint}(0), Ref{Cint}(0)
        KN_get_number_vars(model, nx)
        KN_get_number_cons(model, nc)
        x = unsafe_wrap(Array, ptr_x, nx[])
        lambda = unsafe_wrap(Array, ptr_lambda, nx[] + nc[])
        return model.mip_node_callback(model, x, lambda, model.mip_node_user_data)
    end
end

"""
    KN_set_mip_node_callback(model::Model, callback::Function)

This callback function is for mixed integer (MIP) problems only.
Set the callback function that is invoked after Knitro finishes
processing a node on the branch-and-bound tree (i.e., after a relaxed
subproblem solve in the branch-and-bound procedure).

Callback is a function with signature:

    callback(kc, x, lambda, userdata)

Argument `kc` passed to the callback from inside Knitro is the
context pointer for the last node subproblem solved inside Knitro.
The function should not modify any Knitro arguments.
Arguments `x` and `lambda` contain the solution from the node solve.

"""
function KN_set_mip_node_callback(model::Model, callback::Function, user_data=nothing)
    model.mip_node_callback, model.mip_node_user_data = callback, user_data
    c_func = @cfunction(
        _mip_node_callback_wrapper,
        Cint,
        (Ptr{Cvoid}, Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cvoid})
    )
    KN_set_mip_node_callback(model, c_func, pointer_from_objref(model))
    return
end

# KN_set_ms_initpt_callback

function _ms_initpt_wrapper(
    ptr_model::Ptr{Cvoid},
    nSolveNumber::Cint,
    ptr_x::Ptr{Cdouble},
    ptr_lambda::Ptr{Cdouble},
    user_data::Ptr{Cvoid},
)::Cint
    model = unsafe_pointer_to_objref(user_data)::Model
    nx, nc = Ref{Cint}(0), Ref{Cint}(0)
    KN_get_number_vars(model, nx)
    KN_get_number_cons(model, nc)
    x = unsafe_wrap(Array, ptr_x, nx[])
    lambda = unsafe_wrap(Array, ptr_lambda, nx[] + nc[])
    return model.ms_initpt_callback(
        model,
        nSolveNumber,
        x,
        lambda,
        model.ms_initpt_user_data,
    )
end

"""
    KN_set_ms_initpt_callback(model::Model, callback::Function)

Set a callback that allows applications to specify an initial point before each local solve
in the multistart procedure.

Callback is a function with signature:

```julia
callback(kc, x, lambda, userdata)
```

On input, arguments `x` and `lambda` are the randomly generated initial points determined by
Knitro, which can be overwritten by the user.  The argument `nSolveNumber` is the number of
the multistart solve.
"""
function KN_set_ms_initpt_callback(model::Model, callback::Function, user_data=nothing)
    model.ms_initpt_callback, model.ms_initpt_user_data = callback, user_data
    c_func = @cfunction(
        _ms_initpt_wrapper,
        Cint,
        (Ptr{Cvoid}, Cint, Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cvoid})
    )
    KN_set_ms_initpt_callback(model, c_func, pointer_from_objref(model))
    return
end

# KN_set_puts_callback

function _puts_callback_wrapper(str::Ptr{Cchar}, user_data::Ptr{Cvoid})::Cint
    return _try_catch_handler() do
        model = unsafe_pointer_to_objref(user_data)::Model
        return model.puts_callback(unsafe_string(str), model.puts_user_data)
    end
end

"""
    KN_set_puts_callback(model::Model, callback::Function)

Set the callback that allows applications to handle output.

Applications can set a `put string` callback function to handle output generated by the
Knitro solver.  By default Knitro prints to stdout or a file named `knitro.log`, as
determined by KN_PARAM_OUTMODE.

The `callback` is a function with signature:
```julia
callback(str::String, user_data) -> Cint
```

The KN_puts callback function takes a `user_data` argument which is a pointer
passed directly from KN_solve. The function should return the number of
characters that were printed.
"""
function KN_set_puts_callback(model::Model, callback::Function, user_data=nothing)
    model.puts_callback, model.puts_user_data = callback, user_data
    c_func = @cfunction(_puts_callback_wrapper, Cint, (Ptr{Cchar}, Ptr{Cvoid}))
    KN_set_puts_callback(model, c_func, pointer_from_objref(model))
    return
end
