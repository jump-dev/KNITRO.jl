# Callbacks utilities
mutable struct CallbackContext
    context::Ptr{Nothing}
end
CallbackContext() = CallbackContext(C_NULL)

##################################################
# callback context getters
# TODO: dry this code with a macro
function KN_get_cb_number_cons(m::Model, cb::Ptr{Cvoid})
    num = Cint[0]
    ret = @kn_ccall(get_cb_number_cons,
                    Cint, (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cint}),
                    m.env.ptr_env.x, cb, num)
    _checkraise(ret)
    return num[1]
end
function KN_get_cb_objgrad_nnz(m::Model, cb::Ptr{Cvoid})
    num = Cint[0]
    ret = @kn_ccall(get_cb_objgrad_nnz,
                    Cint, (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cint}),
                    m.env.ptr_env.x, cb, num)
    _checkraise(ret)
    return num[1]
end
function KN_get_cb_jacobian_nnz(m::Model, cb::Ptr{Cvoid})
    num = Cint[0]
    ret = @kn_ccall(get_cb_jacobian_nnz,
                    Cint, (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cint}),
                    m.env.ptr_env.x, cb, num)
    _checkraise(ret)
    return num[1]
end
function KN_get_cb_hessian_nnz(m::Model, cb::Ptr{Cvoid})
    num = Cint[0]
    ret = @kn_ccall(get_cb_hessian_nnz,
                    Cint, (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cint}),
                    m.env.ptr_env.x, cb, num)
    _checkraise(ret)
    return num[1]
end
function KN_get_cb_number_rsds(m::Model, cb::Ptr{Cvoid})
    num = Cint[0]
    ret = @kn_ccall(get_cb_number_rsds,
                    Cint, (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cint}),
                    m.env.ptr_env.x, cb, num)
    _checkraise(ret)
    return num[1]
end
function KN_get_cb_rsd_jacobian_nnz(m::Model, cb::Ptr{Cvoid})
    num = Cint[0]
    ret = @kn_ccall(get_cb_rsd_jacobian_nnz,
                    Cint, (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cint}),
                    m.env.ptr_env.x, cb, num)
    _checkraise(ret)
    return num[1]
end


##################################################
# EvalRequest

# low level EvalRequest structure
mutable struct KN_eval_request
    evalRequestCode::Cint
    threadID::Cint
    x::Ptr{Cdouble}
    lambda::Ptr{Cdouble}
    sigma::Ptr{Cdouble}
    vec::Ptr{Cdouble}
end

# high level EvalRequest structure
mutable struct EvalRequest
    evalRequestCode::Cint
    threadID::Cint
    x::Array{Float64}
    lambda::Array{Float64}
    sigma::Float64
    vec::Array{Float64}
end

# Import low level request to Julia object
function EvalRequest(m::Model, evalRequest_::KN_eval_request)
    nx = KN_get_number_vars(m)
    nc = KN_get_number_cons(m)

    # import scaling
    sigma = (evalRequest_.sigma != C_NULL) ? unsafe_wrap(Array, evalRequest_.sigma, 1)[1] : 1.
    # we use only views to C arrays to avoid unnecessary copy
    return EvalRequest(evalRequest_.evalRequestCode,
                      evalRequest_.threadID,
                      unsafe_wrap(Array, evalRequest_.x, nx),
                      unsafe_wrap(Array, evalRequest_.lambda, nx + nc),
                      sigma,
                      unsafe_wrap(Array, evalRequest_.vec, nx))
end


##################################################
# EvalResult

# low level EvalResult structure
mutable struct KN_eval_result
    obj::Ptr{Cdouble}
    c::Ptr{Cdouble}
    objGrad::Ptr{Cdouble}
    jac::Ptr{Cdouble}
    hess::Ptr{Cdouble}
    hessVec::Ptr{Cdouble}
    rsd::Ptr{Cdouble}
    rsdJac::Ptr{Cdouble}
end

# high level EvalRequest structure
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

function EvalResult(m::Model, cb::Ptr{Cvoid}, evalResult_::KN_eval_result)
    return EvalResult(
         unsafe_wrap(Array, evalResult_.obj, 1),
         unsafe_wrap(Array, evalResult_.c, KN_get_cb_number_cons(m, cb)),
         unsafe_wrap(Array, evalResult_.objGrad, KN_get_cb_objgrad_nnz(m, cb)),
         unsafe_wrap(Array, evalResult_.jac, KN_get_cb_jacobian_nnz(m, cb)),
         unsafe_wrap(Array, evalResult_.hess, KN_get_cb_hessian_nnz(m, cb)),
         unsafe_wrap(Array, evalResult_.hessVec, KN_get_number_vars(m)),
         unsafe_wrap(Array, evalResult_.rsd, KN_get_cb_number_rsds(m, cb)),
         unsafe_wrap(Array, evalResult_.rsdJac, KN_get_cb_rsd_jacobian_nnz(m, cb))
        )
end


##################################################
# Callbacks wrappers
# 1/ for eval function
function eval_fc_wrapper(ptr_model::Ptr{Cvoid}, ptr_cb::Ptr{Cvoid},
                                  evalRequest_::Ptr{Cvoid},
                                  evalResults_::Ptr{Cvoid},
                                  userdata_::Ptr{Cvoid})

    # load evalRequest object
    ptr0 = Ptr{KN_eval_request}(evalRequest_)
    evalRequest = unsafe_load(ptr0)::KN_eval_request

    # load evalResult object
    ptr = Ptr{KN_eval_result}(evalResults_)
    evalResult = unsafe_load(ptr)::KN_eval_result

    # and eventually, load KNITRO's Julia Model
    m = unsafe_pointer_to_objref(userdata_)::Model

    request = EvalRequest(m, evalRequest)
    result = EvalResult(m, ptr_cb, evalResult)

    m.eval_f(ptr_model, ptr_cb, request, result, m.userdata)

    return Cint(0)
end

# 2/ for gradient function
function eval_ga_wrapper(ptr_model::Ptr{Cvoid}, ptr_cb::Ptr{Cvoid},
                         evalRequest_::Ptr{Cvoid},
                         evalResults_::Ptr{Cvoid},
                         userdata_::Ptr{Cvoid})

    # load evalRequest object
    ptr0 = Ptr{KN_eval_request}(evalRequest_)
    evalRequest = unsafe_load(ptr0)::KN_eval_request

    # load evalResult object
    ptr = Ptr{KN_eval_result}(evalResults_)
    evalResult = unsafe_load(ptr)::KN_eval_result

    # and eventually, load KNITRO's Julia Model
    m = unsafe_pointer_to_objref(userdata_)::Model

    request = EvalRequest(m, evalRequest)
    result = EvalResult(m, ptr_cb, evalResult)

    m.eval_g(ptr_model, ptr_cb, request, result, m.userdata)

    return Cint(0)
end

# 3/ for hessian function
function eval_hess_wrapper(ptr_model::Ptr{Cvoid}, ptr_cb::Ptr{Cvoid},
                         evalRequest_::Ptr{Cvoid},
                         evalResults_::Ptr{Cvoid},
                         userdata_::Ptr{Cvoid})

    # load evalRequest object
    ptr0 = Ptr{KN_eval_request}(evalRequest_)
    evalRequest = unsafe_load(ptr0)::KN_eval_request

    if ((evalRequest.evalRequestCode != KNITRO.KN_RC_EVALH) &&
        (evalRequest.evalRequestCode != KNITRO.KN_RC_EVALH_NO_F))
        println("*** callbackEvalH incorrectly called with eval type ",
                evalRequest.evalRequestCode)
        return -1
    end

    # load evalResult object
    ptr = Ptr{KN_eval_result}(evalResults_)
    evalResult = unsafe_load(ptr)::KN_eval_result

    # and eventually, load KNITRO's Julia Model
    m = unsafe_pointer_to_objref(userdata_)::Model

    request = EvalRequest(m, evalRequest)
    result = EvalResult(m, ptr_cb, evalResult)

    m.eval_h(ptr_model, ptr_cb, request, result, m.userdata)

    return Cint(0)
end


################################################################################
################################################################################
################################################################################
################################################################################

function KN_set_cb_user_params(m::Model, cb::CallbackContext)
    # now, we store the Knitro Model inside user params
    ret = @kn_ccall(set_cb_user_params, Cint,
                    (Ptr{Cvoid}, Ptr{Cvoid}, Any),
                    m.env.ptr_env.x, cb.context, m)
    _checkraise(ret)
end


# User callback should be of the form:
# callback(kc, cb, evalrequest, evalresult, usrparams)::Int

function KN_add_eval_callback(m::Model, funccallback::Function)
    # store function inside model:
    m.eval_f = funccallback

    # wrap eval_callback_wrapper as C function
    c_f = @cfunction(eval_fc_wrapper, Cint,
                   (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}))

    # define callback context
    rfptr = Ref{Ptr{Cvoid}}()

    # add callback to context
    ret = @kn_ccall(add_eval_callback_all, Cint,
                    (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}),
                    m.env.ptr_env.x, c_f, rfptr)
    _checkraise(ret)
    cb = CallbackContext(rfptr.x)
    KN_set_cb_user_params(m, cb)

    return cb
end
function KN_add_eval_callback(m::Model, evalObj::Bool, indexCons::Vector{Cint},
                              funccallback::Function)
    nC = length(indexCons)
    # store function inside model:
    m.eval_f = funccallback

    # wrap eval_callback_wrapper as C function
    c_f = @cfunction(eval_fc_wrapper, Cint,
                   (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}))

    # define callback context
    rfptr = Ref{Ptr{Cvoid}}()

    # add callback to context
    ret = @kn_ccall(add_eval_callback, Cint,
                    (Ptr{Cvoid}, Cuchar, Cint, Ptr{Cint}, Ptr{Cvoid}, Ptr{Cvoid}),
                    m.env.ptr_env.x, evalObj, nC, indexCons, c_f, rfptr)
    _checkraise(ret)
    cb = CallbackContext(rfptr.x)
    KN_set_cb_user_params(m, cb)

    return cb
end


function KN_set_cb_grad(m::Model, cb::CallbackContext, gradcallback;
                        nV::Integer=KN_DENSE, objGradIndexVars=C_NULL,
                        jacIndexCons=C_NULL, jacIndexVars=C_NULL)
    # check consistency of arguments
    if (nV == 0 || nV == KN_DENSE )
        (objGradIndexVars != C_NULL) && error("objGradIndexVars must be set to C_NULL when nV = $nV")
    else
        @assert (objGradIndexVars != C_NULL) && (length(objGradIndexVars) == nV)
    end

    nnzJ = KNLONG(0)
    if jacIndexCons != C_NULL && jacIndexVars != C_NULL
        @assert length(jacIndexCons) == length(jacIndexVars)
        nnzJ = KNLONG(length(jacIndexCons))
    end

    if gradcallback != nothing
        # store grad function inside model:
        m.eval_g = gradcallback

        # wrap gradient wrapper as C function
        c_grad_g = @cfunction(eval_ga_wrapper, Cint,
                            (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}))
    else
        c_grad_g = C_NULL
    end

    ret = @kn_ccall(set_cb_grad, Cint,
                    (Ptr{Cvoid}, Ptr{Cvoid}, Cint, Ptr{Cint},
                     KNLONG, Ptr{Cint}, Ptr{Cint}, Ptr{Cvoid}),
                    m.env.ptr_env.x, cb.context, nV,
                    objGradIndexVars, nnzJ, jacIndexCons, jacIndexVars,
                    c_grad_g)
    _checkraise(ret)

    return nothing
end


function KN_set_cb_hess(m::Model, cb::CallbackContext, nnzH::Integer, hesscallback::Function;
                        hessIndexVars1=C_NULL, hessIndexVars2=C_NULL)

    if nnzH == KN_DENSE_ROWMAJOR || nnzH == KN_DENSE_COLMAJOR
        @assert hessIndexVars1 == hessIndexVars2 == C_NULL
    else
        @assert hessIndexVars1 != C_NULL && hessIndexVars2 != C_NULL
        @assert length(hessIndexVars1) == length(hessIndexVars2) == nnzH
    end
    # store hessian function inside model:
    m.eval_h = hesscallback

    # wrap gradient wrapper as C function
    c_hess = @cfunction(eval_hess_wrapper, Cint,
                        (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}))

    ret = @kn_ccall(set_cb_hess, Cint,
                    (Ptr{Cvoid}, Ptr{Cvoid}, KNLONG, Ptr{Cint}, Ptr{Cint}, Ptr{Cvoid}),
                    m.env.ptr_env.x, cb.context, nnzH,
                    hessIndexVars1, hessIndexVars2, c_hess)
    _checkraise(ret)

    return nothing
end


##################################################
# Get callbacks info
##################################################
function KN_get_number_FC_evals(m::Model)
    fc_eval = Int32[0]
    ret = @kn_ccall(get_number_FC_evals, Cint, (Ptr{Nothing}, Ptr{Cint}),
                    m.env.ptr_env.x, fc_eval)
    _checkraise(ret)
    return fc_eval[1]
end

function KN_get_number_GA_evals(m::Model)
    fc_eval = Int32[0]
    ret = @kn_ccall(get_number_GA_evals, Cint, (Ptr{Nothing}, Ptr{Cint}),
                    m.env.ptr_env.x, fc_eval)
    _checkraise(ret)
    return fc_eval[1]
end

function KN_get_number_H_evals(m::Model)
    fc_eval = Int32[0]
    ret = @kn_ccall(get_number_H_evals, Cint, (Ptr{Nothing}, Ptr{Cint}),
                    m.env.ptr_env.x, fc_eval)
    _checkraise(ret)
    return fc_eval[1]
end

function KN_get_number_HV_evals(m::Model)
    fc_eval = Int32[0]
    ret = @kn_ccall(get_number_HV_evals, Cint, (Ptr{Nothing}, Ptr{Cint}),
                    m.env.ptr_env.x, fc_eval)
    _checkraise(ret)
    return fc_eval[1]
end

##################################################
# Residual callbacks
##################################################
function eval_rsd_wrapper(ptr_model::Ptr{Cvoid}, ptr_cb::Ptr{Cvoid},
                          evalRequest_::Ptr{Cvoid},
                          evalResults_::Ptr{Cvoid},
                          userdata_::Ptr{Cvoid})

    # load evalRequest object
    ptr0 = Ptr{KN_eval_request}(evalRequest_)
    evalRequest = unsafe_load(ptr0)::KN_eval_request

    # load evalResult object
    ptr = Ptr{KN_eval_result}(evalResults_)
    evalResult = unsafe_load(ptr)::KN_eval_result

    # and eventually, load KNITRO's Julia Model
    m = unsafe_pointer_to_objref(userdata_)::Model

    request = EvalRequest(m, evalRequest)
    result = EvalResult(m, ptr_cb, evalResult)

    m.eval_rsd(ptr_model, ptr_cb, request, result, m.userdata)

    return Cint(0)
end

# TODO: add _one and _* support
function KN_add_lsq_eval_callback(m::Model, rsdCallBack::Function)
    # store function inside model:
    m.eval_rsd = rsdCallBack

    # wrap eval_callback_wrapper as C function
    c_f = @cfunction(eval_rsd_wrapper, Cint,
                   (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}))

    # define callback context
    rfptr = Ref{Ptr{Cvoid}}()

    # add callback to context
    ret = @kn_ccall(add_lsq_eval_callback_all, Cint,
                    (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}),
                    m.env.ptr_env.x, c_f, rfptr)
    _checkraise(ret)
    cb = CallbackContext(rfptr.x)
    KN_set_cb_user_params(m, cb)

    return cb
end



function eval_rj_wrapper(ptr_model::Ptr{Cvoid}, ptr_cb::Ptr{Cvoid},
                          evalRequest_::Ptr{Cvoid},
                          evalResults_::Ptr{Cvoid},
                          userdata_::Ptr{Cvoid})

    # load evalRequest object
    ptr0 = Ptr{KN_eval_request}(evalRequest_)
    evalRequest = unsafe_load(ptr0)::KN_eval_request

    # load evalResult object
    ptr = Ptr{KN_eval_result}(evalResults_)
    evalResult = unsafe_load(ptr)::KN_eval_result

    # and eventually, load KNITRO's Julia Model
    m = unsafe_pointer_to_objref(userdata_)::Model

    request = EvalRequest(m, evalRequest)
    result = EvalResult(m, ptr_cb, evalResult)

    m.eval_rsdj(ptr_model, ptr_cb, request, result, m.userdata)

    return Cint(0)
end

function KN_set_cb_rsd_jac(m::Model, cb::CallbackContext, nnzJ::Integer, evalRJ::Function;
                        jacIndexRsds=C_NULL, jacIndexVars=C_NULL)
    # check consistency of arguments
    if nnzJ == KN_DENSE_ROWMAJOR || nnzJ == KN_DENSE_COLMAJOR || nnzJ == 0
        @assert jacIndexRsds == jacIndexVars == C_NULL
    else
        @assert hessIndexVars1 != C_NULL && hessIndexVars2 != C_NULL
        @assert length(jacIndexCons) == length(jacIndexVars) == nnzJ
    end

    # store function inside model:
    m.eval_rsdj = evalRJ
    # wrap as C function
    c_eval_rj = @cfunction(eval_rj_wrapper, Cint,
                           (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}))
    ret = @kn_ccall(set_cb_rsd_jac, Cint,
                    (Ptr{Cvoid}, Ptr{Cvoid}, KNLONG, Ptr{Cint}, Ptr{Cint}, Ptr{Cvoid}),
                    m.env.ptr_env.x, cb.context, nnzJ,
                    jacIndexRsds, jacIndexVars, c_eval_rj)

    _checkraise(ret)

    return cb
end


##################################################
# User callbacks wrapper
##################################################
# TODO: dry this function with a macro
#--------------------
# New estimate callback
#--------------------
function newpt_wrapper(ptr_model::Ptr{Cvoid},
                               ptr_x::Ptr{Cdouble},
                               ptr_lambda::Ptr{Cdouble},
                               userdata_::Ptr{Cvoid})

    # Load KNITRO's Julia Model
    m = unsafe_pointer_to_objref(userdata_)::Model
    nx = KN_get_number_vars(m)
    nc = KN_get_number_cons(m)

    x = unsafe_wrap(Array, ptr_x, nx)
    lambda = unsafe_wrap(Array, ptr_lambda, nx + nc)
    m.user_callback(ptr_model, x, lambda, m)

    return Cint(0)
end


function KN_set_newpt_callback(m::Model, callback::Function)
    # store callback function inside model:
    m.user_callback = callback

    # wrap user callback wrapper as C function
    c_func = @cfunction(newpt_wrapper, Cint,
                        (Ptr{Cvoid}, Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cvoid}))

    ret = @kn_ccall(set_newpt_callback, Cint,
                    (Ptr{Cvoid}, Ptr{Cvoid}, Any),
                    m.env.ptr_env.x, c_func, m)
    _checkraise(ret)

    return nothing
end

#--------------------
# Multistart callback
#--------------------
function ms_process_wrapper(ptr_model::Ptr{Cvoid},
                            ptr_x::Ptr{Cdouble},
                            ptr_lambda::Ptr{Cdouble},
                            userdata_::Ptr{Cvoid})

    # Load KNITRO's Julia Model
    m = unsafe_pointer_to_objref(userdata_)::Model
    nx = KN_get_number_vars(m)
    nc = KN_get_number_cons(m)

    x = unsafe_wrap(Array, ptr_x, nx)
    lambda = unsafe_wrap(Array, ptr_lambda, nx + nc)
    m.ms_process(ptr_model, x, lambda, m)

    return Cint(0)
end


function KN_set_ms_process_callback(m::Model, callback::Function)
    # store callback function inside model:
    m.ms_process = callback

    # wrap user callback wrapper as C function
    c_func = @cfunction(ms_process_wrapper, Cint,
                        (Ptr{Cvoid}, Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cvoid}))

    ret = @kn_ccall(set_ms_process_callback, Cint,
                    (Ptr{Cvoid}, Ptr{Cvoid}, Any),
                    m.env.ptr_env.x, c_func, m)
    _checkraise(ret)
end


#--------------------
# MIP callback
#--------------------
function mip_node_callback_wrapper(ptr_model::Ptr{Cvoid},
                                   ptr_x::Ptr{Cdouble},
                                   ptr_lambda::Ptr{Cdouble},
                                   userdata_::Ptr{Cvoid})

    # Load KNITRO's Julia Model
    m = unsafe_pointer_to_objref(userdata_)::Model
    nx = KN_get_number_vars(m)
    nc = KN_get_number_cons(m)

    x = unsafe_wrap(Array, ptr_x, nx)
    lambda = unsafe_wrap(Array, ptr_lambda, nx + nc)
    m.mip_callback(ptr_model, x, lambda, m)

    return Cint(0)
end


function KN_set_mip_node_callback(m::Model, callback::Function)
    # store callback function inside model:
    m.mip_callback = callback

    # wrap user callback wrapper as C function
    c_func = @cfunction(mip_node_callback_wrapper, Cint,
                        (Ptr{Cvoid}, Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cvoid}))

    ret = @kn_ccall(set_mip_node_callback, Cint,
                    (Ptr{Cvoid}, Ptr{Cvoid}, Any),
                    m.env.ptr_env.x, c_func, m)
    _checkraise(ret)
end
