# Copyright (c) 2016: Ng Yee Sian, Miles Lubin, other contributors
#
# Use of this source code is governed by an MIT-style license that can be found
# in the LICENSE.md file or at https://opensource.org/licenses/MIT.

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
    if !is_valid(m)
        println(io, "KNITRO Problem: NULL")
        return
    end
    println(io, "$(get_release())")
    println(io, "-----------------------")
    println(io, "Problem Characteristics")
    println(io, "-----------------------")
    println(io, "Objective goal:  Minimize")
    p = Ref{Cint}()
    KN_get_obj_type(m, p)
    println(io, "Objective type:  $(p[])")
    KN_get_number_vars(m, p)
    println(io, "Number of variables:                             $(p[])")
    KN_get_number_cons(m, p)
    println(io, "Number of constraints:                           $(p[])")
    q = Ref{KNLONG}()
    KN_get_jacobian_nnz(m, q)
    println(io, "Number of nonzeros in Jacobian:                  $(q[])")
    KN_get_hessian_nnz(m, q)
    println(io, "Number of nonzeros in Hessian:                   $(q[])")
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

function get_status(m::Model)
    @assert m.env != C_NULL
    if m.status != 1
        return m.status
    end
    status, obj = Ref{Cint}(0), Ref{Cdouble}(0.0)
    KN_get_solution(m, status, obj, C_NULL, C_NULL)
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

# Callbacks utilities.

# Note: we store here the number of constraints and variables defined
# in the original Knitro model. We cannot retrieve these numbers during
# callbacks invokation, as sometimes the number of variables and constraints
# change internally in Knitro (e.g. when cuts are added when resolving
# Branch&Bound). We prefer to use the number of variables and constraints
# of the original model so that user's callbacks could consider that
# the arrays of primal variable x and dual variable \lambda have fixed
# sizes.
function link!(cb::CallbackContext, model::Model)
    p = Ref{Cint}(0)
    KN_get_number_vars(model, p)
    cb.n = p[]
    KN_get_number_cons(model, p)
    cb.m = p[]
    return
end

function KN_set_cb_user_params(m::Model, cb::CallbackContext, userParams=nothing)
    if userParams != nothing
        cb.userparams = userParams
    end
    link!(cb, m)
    # TODO: use a wrapper for the model so it isn't cconverted on Ptr{Cvoid}
    ccall(
        (:KN_set_cb_user_params, libknitro),
        Cint,
        (KN_context_ptr, Ptr{Cvoid}, Any),
        m.env,
        cb,
        cb,
    )
    return
end

"""
Specify which gradient option `gradopt` will be used to evaluate
the first derivatives of the callback functions.  If `gradopt=KN_GRADOPT_EXACT`
then a gradient evaluation callback must be set by `KN_set_cb_grad()`
(or `KN_set_cb_rsd_jac()` for least squares).

"""
function KN_set_cb_gradopt(m::Model, cb::CallbackContext, gradopt::Integer)
    KN_set_cb_gradopt(m.env, cb, gradopt)
    return
end

# High level EvalRequest structure.
mutable struct EvalRequest
    evalRequestCode::Cint
    threadID::Cint
    x::Array{Float64}
    lambda::Array{Float64}
    sigma::Float64
    vec::Array{Float64}
end

# Import low level request to Julia object.
function EvalRequest(ptr_model::Ptr{Cvoid}, evalRequest_::KN_eval_request, n::Int, m::Int)
    # Import objective's scaling.
    sigma =
        (evalRequest_.sigma != C_NULL) ? unsafe_wrap(Array, evalRequest_.sigma, 1)[1] : 1.0
    # Wrap directly C arrays to avoid unnecessary copy.
    return EvalRequest(
        evalRequest_.type,
        evalRequest_.threadID,
        unsafe_wrap(Array, evalRequest_.x, n),
        unsafe_wrap(Array, evalRequest_.lambda, n + m),
        sigma,
        unsafe_wrap(Array, evalRequest_.vec, n),
    )
end

# High level EvalResult structure.
mutable struct EvalResult
    obj::Array{Float64}
    c::Array{Float64}
    objGrad::Array{Float64}
    jac::Array{Float64}
    hess::Array{Float64}
    hessVec::Array{Float64}
    rsd::Array{Float64}
    rsdJac::Array{Float64}
end

function EvalResult(
    kc::Ptr{Cvoid},
    cb::Ptr{Cvoid},
    evalResult_::KN_eval_result,
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
    return EvalResult(
        unsafe_wrap(Array, evalResult_.obj, 1),
        unsafe_wrap(Array, evalResult_.c, m),
        unsafe_wrap(Array, evalResult_.objGrad, objgrad_nnz[]),
        unsafe_wrap(Array, evalResult_.jac, jacobian_nnz[]),
        unsafe_wrap(Array, evalResult_.hess, hessian_nnz[]),
        unsafe_wrap(Array, evalResult_.hessVec, n),
        unsafe_wrap(Array, evalResult_.rsd, num_rsds[]),
        unsafe_wrap(Array, evalResult_.rsdJac, rsd_jacobian_nnz[]),
    )
end

macro wrap_function(wrap_name, name)
    quote
        function $(esc(wrap_name))(
            ptr_model::Ptr{Cvoid},
            ptr_cb::Ptr{Cvoid},
            evalRequest_::Ptr{Cvoid},
            evalResults_::Ptr{Cvoid},
            userdata_::Ptr{Cvoid},
        )
            try
                # Load evalRequest object.
                ptr_request = Ptr{KN_eval_request}(evalRequest_)
                evalRequest = unsafe_load(ptr_request)::KN_eval_request
                # Load evalResult object.
                ptr_result = Ptr{KN_eval_result}(evalResults_)
                evalResult = unsafe_load(ptr_result)::KN_eval_result
                # Eventually, load callback context.
                cb = unsafe_pointer_to_objref(userdata_)
                # Ensure that cb is a CallbackContext.
                # Otherwise, we tell KNITRO that a problem occurs by returning a
                # non-zero status.
                if !isa(cb, CallbackContext)
                    return Cint(KN_RC_CALLBACK_ERR)
                end
                request = EvalRequest(ptr_model, evalRequest, cb.n, cb.m)
                result = EvalResult(ptr_model, ptr_cb, evalResult, cb.n, cb.m)
                res = cb.$name(ptr_model, ptr_cb, request, result, cb.userparams)
                return Cint(res)
            catch ex
                if isa(ex, InterruptException)
                    return Cint(KN_RC_USER_TERMINATION)
                end
                if isa(ex, DomainError)
                    return Cint(KN_RC_EVAL_ERR)
                else
                    @warn("Knitro encounters an exception in evaluation callback: $ex")
                    return Cint(KN_RC_CALLBACK_ERR)
                end
            end
        end
    end
end

@wrap_function eval_fc_wrapper eval_f
@wrap_function eval_ga_wrapper eval_g
@wrap_function eval_hess_wrapper eval_h

"""
    KN_add_eval_callback(m::Model, funccallback::Function)
    KN_add_eval_callback(m::Model, evalObj::Bool, indexCons::Vector{Cint},
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
function KN_add_eval_callback_all(m::Model, funccallback::Function)
    # wrap eval_callback_wrapper as C function
    # Wrap eval_callback_wrapper as C function.
    c_f = @cfunction(
        eval_fc_wrapper,
        Cint,
        (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid})
    )

    # Define callback context.
    rfptr = Ref{Ptr{Cvoid}}()

    # Add callback to context.
    KN_add_eval_callback_all(m.env, c_f, rfptr)
    cb = CallbackContext(rfptr[])
    register_callback(m, cb)

    # Store function in callback environment:
    cb.eval_f = funccallback

    # Store model in user params to access callback in C
    KN_set_cb_user_params(m, cb)

    return cb
end

# Evaluate only the objective
function KN_add_objective_callback(m::Model, objcallback::Function)
    # wrap eval_callback_wrapper as C function
    c_f = @cfunction(
        eval_fc_wrapper,
        Cint,
        (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid})
    )

    # define callback context
    rfptr = Ref{Ptr{Cvoid}}()

    # add callback to context
    KN_add_eval_callback_one(m.env, Cint(-1), c_f, rfptr)
    cb = CallbackContext(rfptr[])
    register_callback(m, cb)

    # store function in callback environment:
    cb.eval_f = objcallback

    # store model in user params to access callback in C
    KN_set_cb_user_params(m, cb)

    return cb
end

function KN_add_eval_callback(
    m::Model,
    evalObj::Bool,  # switch on obj eval
    indexCons::Vector{Cint},  # index of constaints
    funccallback::Function,
)   # callback
    nC = length(indexCons)

    # Wrap eval_callback_wrapper as C function.
    c_f = @cfunction(
        eval_fc_wrapper,
        Cint,
        (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid})
    )

    # Define callback context.
    rfptr = Ref{Ptr{Cvoid}}()

    # Add callback to context.
    KN_add_eval_callback(m.env, KNBOOL(evalObj), nC, indexCons, c_f, rfptr)
    cb = CallbackContext(rfptr[])
    register_callback(m, cb)

    # Store function in callback environment.
    cb.eval_f = funccallback

    KN_set_cb_user_params(m, cb)

    return cb
end

"""
    KN_set_cb_grad(m::Model, cb::CallbackContext, gradcallback;
                   nV::Integer=KN_DENSE, objGradIndexVars=C_NULL,
                   jacIndexCons=C_NULL, jacIndexVars=C_NULL)

This API function is used to set the objective gradient and constraint Jacobian
structure and also (optionally) a callback function to evaluate the objective
gradient and constraint Jacobian provided through this callback.

"""
function KN_set_cb_grad(
    m::Model,
    cb::CallbackContext,
    gradcallback;
    nV::Integer=KN_DENSE,
    nnzJ::Union{Nothing,Integer}=nothing,
    objGradIndexVars=C_NULL,
    jacIndexCons=C_NULL,
    jacIndexVars=C_NULL,
)
    if nnzJ === nothing
        p = Ref{Cint}(0)
        KN_get_number_cons(m, p)
        nnzJ = iszero(p[]) ? KNLONG(0) : KNITRO.KN_DENSE_COLMAJOR
    end
    # Check consistency of arguments.
    if (nV == 0 || nV == KN_DENSE)
        (objGradIndexVars != C_NULL) &&
            error("objGradIndexVars must be set to C_NULL when nV = $nV")
    else
        @assert (objGradIndexVars != C_NULL) && (length(objGradIndexVars) == nV)
    end

    if jacIndexCons != C_NULL && jacIndexVars != C_NULL
        @assert length(jacIndexCons) == length(jacIndexVars)
        nnzJ = KNLONG(length(jacIndexCons))
    end

    if gradcallback != nothing
        # Store grad function inside model.
        cb.eval_g = gradcallback

        # Wrap gradient wrapper as C function.
        c_grad_g = @cfunction(
            eval_ga_wrapper,
            Cint,
            (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid})
        )
    else
        c_grad_g = C_NULL
    end

    KN_set_cb_grad(
        m.env,
        cb,
        nV,
        objGradIndexVars,
        KNLONG(nnzJ),
        jacIndexCons,
        jacIndexVars,
        c_grad_g,
    )
    return
end

"""
    KN_set_cb_hess(m::Model, cb::CallbackContext, nnzH::Integer, hesscallback::Function;
                   hessIndexVars1=C_NULL, hessIndexVars2=C_NULL)

This API function is used to set the structure and a callback function to
evaluate the components of the Hessian of the Lagrangian provided through this
callback.  KN_set_cb_hess() should only be used when defining a user-supplied
Hessian callback function (via the `hessopt=KN_HESSOPT_EXACT` user option).
When Knitro is approximating the Hessian, it cannot make use of the Hessian
sparsity structure.

"""
function KN_set_cb_hess(
    m::Model,
    cb::CallbackContext,
    nnzH::Integer,
    hesscallback::Function;
    hessIndexVars1=C_NULL,
    hessIndexVars2=C_NULL,
)

    # If Hessian is dense, ensure that sparsity pattern is empty
    if nnzH == KN_DENSE_ROWMAJOR || nnzH == KN_DENSE_COLMAJOR
        @assert hessIndexVars1 == hessIndexVars2 == C_NULL
        # Otherwise, check validity of sparsity pattern
    elseif nnzH > 0
        @assert hessIndexVars1 != C_NULL && hessIndexVars2 != C_NULL
        @assert length(hessIndexVars1) == length(hessIndexVars2) == nnzH
    end
    # Store hessian function inside model.
    cb.eval_h = hesscallback

    # Wrap gradient wrapper as C function.
    c_hess = @cfunction(
        eval_hess_wrapper,
        Cint,
        (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid})
    )
    KN_set_cb_hess(m.env, cb, nnzH, hessIndexVars1, hessIndexVars2, c_hess)
    return
end

#=
    RESIDUALS
=#

@wrap_function eval_rj_wrapper eval_jac_rsd
@wrap_function eval_rsd_wrapper eval_rsd

# TODO: add _one and _* support
"""
    KN_add_lsq_eval_callback(m::Model, rsdCallBack::Function)

Add an evaluation callback for a least-squares models.  Similar to KN_add_eval_callback()
above, but for least-squares models.

* `m`: current KNITRO model
* `rsdCallback`: a function that evaluates any residual parts

After a callback is created by `KN_add_lsq_eval_callback()`, the user can then
specify residual Jacobian information and structure through `KN_set_cb_rsd_jac()`.
If not set, Knitro will approximate the residual Jacobian.  However, it is highly
recommended to provide a callback routine to specify the residual Jacobian if at all
possible as this will greatly improve the performance of Knitro.  Even if a callback
for the residual Jacobian is not provided, it is still helpful to provide the sparse
Jacobian structure for the residuals through `KN_set_cb_rsd_jac()` to improve the
efficiency of the finite-difference Jacobian approximation.

"""
function KN_add_lsq_eval_callback(m::Model, rsdCallBack::Function)
    c_f = @cfunction(
        eval_rsd_wrapper,
        Cint,
        (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid})
    )
    rfptr = Ref{Ptr{Cvoid}}()
    KN_add_lsq_eval_callback_all(m.env, c_f, rfptr)
    cb = CallbackContext(rfptr[])
    register_callback(m, cb)
    cb.eval_rsd = rsdCallBack
    KN_set_cb_user_params(m, cb)
    return cb
end

function KN_set_cb_rsd_jac(
    m::Model,
    cb::CallbackContext,
    nnzJ::Integer,
    evalRJ::Function;
    jacIndexRsds=C_NULL,
    jacIndexVars=C_NULL,
)
    if nnzJ == KN_DENSE_ROWMAJOR || nnzJ == KN_DENSE_COLMAJOR || nnzJ == 0
        @assert jacIndexRsds == jacIndexVars == C_NULL
    else
        @assert jacIndexRsds != C_NULL && jacIndexVars != C_NULL
        @assert length(jacIndexRsds) == length(jacIndexVars) == nnzJ
    end
    cb.eval_jac_rsd = evalRJ
    c_eval_rj = @cfunction(
        eval_rj_wrapper,
        Cint,
        (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid})
    )
    KN_set_cb_rsd_jac(m.env, cb, nnzJ, jacIndexRsds, jacIndexVars, c_eval_rj)
    return cb
end

#=
    USER CALLBACKS
=#

function newpt_wrapper(
    ptr_model::Ptr{Cvoid},
    ptr_x::Ptr{Cdouble},
    ptr_lambda::Ptr{Cdouble},
    userdata_::Ptr{Cvoid},
)
    try
        m = unsafe_pointer_to_objref(userdata_)::Model
        p = Ref{Cint}(0)
        KN_get_number_vars(m, p)
        nx = p[]
        KN_get_number_cons(m, p)
        nc = p[]
        x = unsafe_wrap(Array, ptr_x, nx)
        lambda = unsafe_wrap(Array, ptr_lambda, nx + nc)
        ret = m.newpt_callback(m, x, lambda, m.newpoint_user)
        return Cint(ret)
    catch ex
        if isa(ex, InterruptException)
            return Cint(KN_RC_USER_TERMINATION)
        else
            @warn("Knitro encounters an exception in newpoint callback: $ex")
            return Cint(KN_RC_CALLBACK_ERR)
        end
    end
end

"""
    KN_set_newpt_callback(m::Model, callback::Function)

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
function KN_set_newpt_callback(m::Model, callback::Function, userparams=nothing)
    m.newpt_callback = callback
    if userparams != nothing
        m.newpoint_user = userparams
    end
    c_func = @cfunction(
        newpt_wrapper,
        Cint,
        (Ptr{Cvoid}, Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cvoid})
    )
    # TODO: use a wrapper for the model so it isn't cconverted on Ptr{Cvoid}
    ccall(
        (:KN_set_newpt_callback, libknitro),
        Cint,
        (KN_context_ptr, Ptr{Cvoid}, Any),
        m.env,
        c_func,
        m,
    )
    return
end

function ms_process_wrapper(
    ptr_model::Ptr{Cvoid},
    ptr_x::Ptr{Cdouble},
    ptr_lambda::Ptr{Cdouble},
    userdata_::Ptr{Cvoid},
)
    try
        m = unsafe_pointer_to_objref(userdata_)::Model
        p = Ref{Cint}(0)
        KN_get_number_vars(m, p)
        nx = p[]
        KN_get_number_cons(m, p)
        nc = p[]
        x = unsafe_wrap(Array, ptr_x, nx)
        lambda = unsafe_wrap(Array, ptr_lambda, nx + nc)
        res = m.ms_process(m, x, lambda, m.multistart_user)
        return Cint(res)
    catch ex
        if isa(ex, InterruptException)
            return Cint(KN_RC_USER_TERMINATION)
        else
            @warn("Knitro encounters an exception in multistart callback: $ex")
            return Cint(KN_RC_CALLBACK_ERR)
        end
    end
end

"""
    KN_set_ms_process_callback(m::Model, callback::Function)

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
function KN_set_ms_process_callback(m::Model, callback::Function, userparams=nothing)
    m.ms_process = callback
    if userparams != nothing
        m.multistart_user = userparams
    end
    c_func = @cfunction(
        ms_process_wrapper,
        Cint,
        (Ptr{Cvoid}, Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cvoid})
    )
    # TODO: use a wrapper for the model so it isn't cconverted on Ptr{Cvoid}
    ccall(
        (:KN_set_ms_process_callback, libknitro),
        Cint,
        (KN_context_ptr, Ptr{Cvoid}, Any),
        m.env,
        c_func,
        m,
    )
    return
end

function mip_node_callback_wrapper(
    ptr_model::Ptr{Cvoid},
    ptr_x::Ptr{Cdouble},
    ptr_lambda::Ptr{Cdouble},
    userdata_::Ptr{Cvoid},
)
    try
        m = unsafe_pointer_to_objref(userdata_)::Model
        p = Ref{Cint}(0)
        KN_get_number_vars(m, p)
        nx = p[]
        KN_get_number_cons(m, p)
        nc = p[]
        x = unsafe_wrap(Array, ptr_x, nx)
        lambda = unsafe_wrap(Array, ptr_lambda, nx + nc)
        res = m.mip_callback(m, x, lambda, m.mip_user)
        return Cint(res)
    catch ex
        if isa(ex, InterruptException)
            return Cint(KN_RC_USER_TERMINATION)
        else
            @warn("Knitro encounters an exception in MIP callback: $ex")
            return Cint(KN_RC_CALLBACK_ERR)
        end
    end
end

"""
    KN_set_mip_node_callback(m::Model, callback::Function)

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
function KN_set_mip_node_callback(m::Model, callback::Function, userparams=nothing)
    m.mip_callback = callback
    if userparams != nothing
        m.mip_user = userparams
    end
    c_func = @cfunction(
        mip_node_callback_wrapper,
        Cint,
        (Ptr{Cvoid}, Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cvoid})
    )
    # TODO: use a wrapper for the model so it isn't cconverted on Ptr{Cvoid}
    ccall(
        (:KN_set_mip_node_callback, libknitro),
        Cint,
        (KN_context_ptr, Ptr{Cvoid}, Any),
        m.env,
        c_func,
        m,
    )
    return
end

function ms_initpt_wrapper(
    ptr_model::Ptr{Cvoid},
    nSolveNumber::Cint,
    ptr_x::Ptr{Cdouble},
    ptr_lambda::Ptr{Cdouble},
    userdata_::Ptr{Cvoid},
)
    m = unsafe_pointer_to_objref(userdata_)::Model
    p = Ref{Cint}(0)
    KN_get_number_vars(m, p)
    nx = p[]
    KN_get_number_cons(m, p)
    nc = p[]
    x = unsafe_wrap(Array, ptr_x, nx)
    lambda = unsafe_wrap(Array, ptr_lambda, nx + nc)
    res = m.ms_initpt_callback(m, nSolveNumber, x, lambda, m.multistart_user)
    return Cint(res)
end

"""
    KN_set_ms_initpt_callback(m::Model, callback::Function)
Type declaration for the callback that allows applications to
specify an initial point before each local solve in the multistart
procedure.

Callback is a function with signature:

    callback(kc, x, lambda, userdata)

On input, arguments `x` and `lambda` are the randomly
generated initial points determined by Knitro, which can be overwritten
by the user.  The argument `nSolveNumber` is the number of the
multistart solve.

"""
function KN_set_ms_initpt_callback(m::Model, callback::Function, userparams=nothing)
    m.ms_initpt_callback = callback
    if userparams != nothing
        m.multistart_user = userparams
    end
    c_func = @cfunction(
        ms_initpt_wrapper,
        Cint,
        (Ptr{Cvoid}, Cint, Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cvoid})
    )
    # TODO: use a wrapper for the model so it isn't cconverted on Ptr{Cvoid}
    ccall(
        (:KN_set_ms_initpt_callback, libknitro),
        Cint,
        (KN_context_ptr, Ptr{Cvoid}, Any),
        m.env,
        c_func,
        m,
    )
    return
end

function puts_callback_wrapper(str::Ptr{Cchar}, userdata_::Ptr{Cvoid})
    try
        m = unsafe_pointer_to_objref(userdata_)::Model
        res = m.puts_callback(unsafe_string(str), m.puts_user)
        return Cint(res)
    catch ex
        if isa(ex, InterruptException)
            return Cint(KN_RC_USER_TERMINATION)
        else
            @warn("Knitro encounters an exception in puts callback: $ex")
            return Cint(KN_RC_CALLBACK_ERR)
        end
    end
end

"""
    KN_set_puts_callback(m::Model, callback::Function)

Set the callback that allows applications to handle
output. Applications can set a `put string` callback function to handle
output generated by the Knitro solver.  By default Knitro prints to
stdout or a file named `knitro.log`, as determined by KN_PARAM_OUTMODE.

Callback is a function with signature:

    callback(str::String, userdata)

The KN_puts callback function takes a `userParams` argument which is a pointer
passed directly from KN_solve. The function should return the number of
characters that were printed.

"""
function KN_set_puts_callback(m::Model, callback::Function, userparams=nothing)
    m.puts_callback = callback
    if userparams != nothing
        m.puts_user = userparams
    end
    c_func = @cfunction(puts_callback_wrapper, Cint, (Ptr{Cchar}, Ptr{Cvoid}))
    # TODO: use a wrapper for the model so it isn't cconverted on Ptr{Cvoid}
    ccall(
        (:KN_set_puts_callback, libknitro),
        Cint,
        (KN_context_ptr, Ptr{Cvoid}, Any),
        m.env,
        c_func,
        m,
    )
    return
end
