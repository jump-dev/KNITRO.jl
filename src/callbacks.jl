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
    cb.n = KN_get_number_vars(model)
    return cb.m = KN_get_number_cons(model)
end

function KN_set_cb_user_params(m::Model, cb::CallbackContext, userParams=nothing)
    if userParams != nothing
        cb.userparams = userParams
    end
    # Link current callback context with Knitro model
    link!(cb, m)
    # Store callback context inside KNITRO user data.
    @kn_ccall(set_cb_user_params, Cint, (Ptr{Cvoid}, Ptr{Cvoid}, Any), m.env, cb, cb)
    return nothing
end

"""
Specify which gradient option `gradopt` will be used to evaluate
the first derivatives of the callback functions.  If `gradopt=KN_GRADOPT_EXACT`
then a gradient evaluation callback must be set by `KN_set_cb_grad()`
(or `KN_set_cb_rsd_jac()` for least squares).

"""
function KN_set_cb_gradopt(m::Model, cb::CallbackContext, gradopt::Integer)
    @kn_ccall(set_cb_gradopt, Cint, (Ptr{Cvoid}, Ptr{Cvoid}, Cint), m.env, cb, gradopt)
    return nothing
end

macro callback_getter(function_name, return_type)
    fname = Symbol("KN_" * string(function_name))
    quote
        function $(esc(fname))(kc::Ptr{Cvoid}, cb::Ptr{Cvoid})
            result = zeros($return_type, 1)
            @kn_ccall(
                $function_name,
                Cint,
                (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cint}),
                kc,
                cb,
                result
            )
            return result[1]
        end
    end
end

@callback_getter get_cb_number_cons Cint
@callback_getter get_cb_objgrad_nnz Cint
@callback_getter get_cb_jacobian_nnz KNLONG
@callback_getter get_cb_hessian_nnz KNLONG
@callback_getter get_cb_number_rsds Cint
@callback_getter get_cb_rsd_jacobian_nnz KNLONG

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
    return EvalResult(
        unsafe_wrap(Array, evalResult_.obj, 1),
        unsafe_wrap(Array, evalResult_.c, m),
        unsafe_wrap(Array, evalResult_.objGrad, KN_get_cb_objgrad_nnz(kc, cb)),
        unsafe_wrap(Array, evalResult_.jac, KN_get_cb_jacobian_nnz(kc, cb)),
        unsafe_wrap(Array, evalResult_.hess, KN_get_cb_hessian_nnz(kc, cb)),
        unsafe_wrap(Array, evalResult_.hessVec, n),
        unsafe_wrap(Array, evalResult_.rsd, KN_get_cb_number_rsds(kc, cb)),
        unsafe_wrap(Array, evalResult_.rsdJac, KN_get_cb_rsd_jacobian_nnz(kc, cb)),
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

# Eval callbacks should be of the form:
# callback(kc, cb, evalrequest, evalresult, usrparams)::Int

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
    @kn_ccall(
        add_eval_callback_all,
        Cint,
        (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}),
        m.env,
        c_f,
        rfptr
    )
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
    @kn_ccall(
        add_eval_callback_one,
        Cint,
        (Ptr{Cvoid}, Cint, Ptr{Cvoid}, Ptr{Cvoid}),
        m.env,
        Cint(-1),
        c_f,
        rfptr
    )
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
    @kn_ccall(
        add_eval_callback,
        Cint,
        (Ptr{Cvoid}, KNBOOL, Cint, Ptr{Cint}, Ptr{Cvoid}, Ptr{Cvoid}),
        m.env,
        KNBOOL(evalObj),
        nC,
        indexCons,
        c_f,
        rfptr
    )
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
    nnzJ::Integer=(iszero(KNITRO.KN_get_number_cons(m)) ? KNLONG(0) : KNITRO.KN_DENSE_COLMAJOR),
    objGradIndexVars=C_NULL,
    jacIndexCons=C_NULL,
    jacIndexVars=C_NULL,
)
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

    @kn_ccall(
        set_cb_grad,
        Cint,
        (Ptr{Cvoid}, Ptr{Cvoid}, Cint, Ptr{Cint}, KNLONG, Ptr{Cint}, Ptr{Cint}, Ptr{Cvoid}),
        m.env,
        cb,
        nV,
        objGradIndexVars,
        KNLONG(nnzJ),
        jacIndexCons,
        jacIndexVars,
        c_grad_g
    )
    return nothing
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

    @kn_ccall(
        set_cb_hess,
        Cint,
        (Ptr{Cvoid}, Ptr{Cvoid}, KNLONG, Ptr{Cint}, Ptr{Cint}, Ptr{Cvoid}),
        m.env,
        cb,
        nnzH,
        hessIndexVars1,
        hessIndexVars2,
        c_hess
    )

    return nothing
end

@kn_get_attribute get_number_FC_evals Cint
@kn_get_attribute get_number_GA_evals Cint
@kn_get_attribute get_number_H_evals Cint
@kn_get_attribute get_number_HV_evals Cint

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

    # Wrap eval_callback_wrapper as C function.
    c_f = @cfunction(
        eval_rsd_wrapper,
        Cint,
        (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid})
    )

    # Define callback context.
    rfptr = Ref{Ptr{Cvoid}}()

    # Add callback to context.
    @kn_ccall(
        add_lsq_eval_callback_all,
        Cint,
        (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}),
        m.env,
        c_f,
        rfptr
    )
    cb = CallbackContext(rfptr[])
    register_callback(m, cb)

    # Store function inside model.
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
    # Check consistency of arguments.
    if nnzJ == KN_DENSE_ROWMAJOR || nnzJ == KN_DENSE_COLMAJOR || nnzJ == 0
        @assert jacIndexRsds == jacIndexVars == C_NULL
    else
        @assert jacIndexRsds != C_NULL && jacIndexVars != C_NULL
        @assert length(jacIndexRsds) == length(jacIndexVars) == nnzJ
    end

    # Store function inside model.
    cb.eval_jac_rsd = evalRJ
    # Wrap as C function.
    c_eval_rj = @cfunction(
        eval_rj_wrapper,
        Cint,
        (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid})
    )
    @kn_ccall(
        set_cb_rsd_jac,
        Cint,
        (Ptr{Cvoid}, Ptr{Cvoid}, KNLONG, Ptr{Cint}, Ptr{Cint}, Ptr{Cvoid}),
        m.env,
        cb,
        nnzJ,
        jacIndexRsds,
        jacIndexVars,
        c_eval_rj
    )
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
    # Load KNITRO's Julia Model.
    try
        m = unsafe_pointer_to_objref(userdata_)::Model
        nx = KN_get_number_vars(m)
        nc = KN_get_number_cons(m)
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
    # Store callback function inside model.
    m.newpt_callback = callback
    if userparams != nothing
        m.newpoint_user = userparams
    end

    # Wrap user callback wrapper as C function.
    c_func = @cfunction(
        newpt_wrapper,
        Cint,
        (Ptr{Cvoid}, Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cvoid})
    )

    @kn_ccall(set_newpt_callback, Cint, (Ptr{Cvoid}, Ptr{Cvoid}, Any), m.env, c_func, m)
    return nothing
end

function ms_process_wrapper(
    ptr_model::Ptr{Cvoid},
    ptr_x::Ptr{Cdouble},
    ptr_lambda::Ptr{Cdouble},
    userdata_::Ptr{Cvoid},
)

    # Load KNITRO's Julia Model.
    try
        m = unsafe_pointer_to_objref(userdata_)::Model
        nx = KN_get_number_vars(m)
        nc = KN_get_number_cons(m)
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
    # Store callback function inside model.
    m.ms_process = callback
    if userparams != nothing
        m.multistart_user = userparams
    end

    # Wrap user callback wrapper as C function.
    c_func = @cfunction(
        ms_process_wrapper,
        Cint,
        (Ptr{Cvoid}, Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cvoid})
    )

    @kn_ccall(
        set_ms_process_callback,
        Cint,
        (Ptr{Cvoid}, Ptr{Cvoid}, Any),
        m.env,
        c_func,
        m
    )
    return nothing
end

function mip_node_callback_wrapper(
    ptr_model::Ptr{Cvoid},
    ptr_x::Ptr{Cdouble},
    ptr_lambda::Ptr{Cdouble},
    userdata_::Ptr{Cvoid},
)
    # Load KNITRO's Julia Model.
    try
        m = unsafe_pointer_to_objref(userdata_)::Model
        nx = KN_get_number_vars(m)
        nc = KN_get_number_cons(m)
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
    # Store callback function inside model.
    m.mip_callback = callback
    if userparams != nothing
        m.mip_user = userparams
    end

    # Wrap user callback wrapper as C function.
    c_func = @cfunction(
        mip_node_callback_wrapper,
        Cint,
        (Ptr{Cvoid}, Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cvoid})
    )

    @kn_ccall(
        set_mip_node_callback,
        Cint,
        (Ptr{Cvoid}, Ptr{Cvoid}, Any),
        m.env,
        c_func,
        m
    )
    return nothing
end

function ms_initpt_wrapper(
    ptr_model::Ptr{Cvoid},
    nSolveNumber::Cint,
    ptr_x::Ptr{Cdouble},
    ptr_lambda::Ptr{Cdouble},
    userdata_::Ptr{Cvoid},
)

    # Load KNITRO's Julia Model.
    m = unsafe_pointer_to_objref(userdata_)::Model
    nx = KN_get_number_vars(m)
    nc = KN_get_number_cons(m)

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
    # Store callback function inside model.
    m.ms_initpt_callback = callback
    if userparams != nothing
        m.multistart_user = userparams
    end

    # Wrap user callback wrapper as C function.
    c_func = @cfunction(
        ms_initpt_wrapper,
        Cint,
        (Ptr{Cvoid}, Cint, Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cvoid})
    )

    @kn_ccall(
        set_ms_initpt_callback,
        Cint,
        (Ptr{Cvoid}, Ptr{Cvoid}, Any),
        m.env,
        c_func,
        m
    )
    return nothing
end

function puts_callback_wrapper(str::Ptr{Cchar}, userdata_::Ptr{Cvoid})

    # Load KNITRO's Julia Model.
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
    # Store callback function inside model.
    m.puts_callback = callback
    if userparams != nothing
        m.puts_user = userparams
    end

    # Wrap user callback wrapper as C function.
    c_func = @cfunction(puts_callback_wrapper, Cint, (Ptr{Cchar}, Ptr{Cvoid}))

    @kn_ccall(set_puts_callback, Cint, (Ptr{Cvoid}, Ptr{Cvoid}, Any), m.env, c_func, m)
    return nothing
end
