# Callbacks utilities
mutable struct CallbackContext
    context::Ptr{Nothing}
    model::Model
end
CallbackContext(model::Model) = CallbackContext(C_NULL, model)

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
    sigma::Array{Float64}
    vec::Array{Float64}
end

# Import low level request to Julia object
function EvalRequest(m::Model, evalRequest_::KN_eval_request)
    nx = KN_get_number_vars(m)
    nc = KN_get_number_cons(m)

    # we use only views to C arrays to avoid unnecessary copy
    return EvalRequest(evalRequest_.evalRequestCode,
                      evalRequest_.threadID,
                      unsafe_wrap(Array, evalRequest_.x, nx),
                      unsafe_wrap(Array, evalRequest_.lambda, nx + nc),
                      zeros(Float64, 0), # TODO: not implemented
                      zeros(Float64, 0)) # TODO: not implemented
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
function KN_eval_callback_wrapper(ptr_model::Ptr{Cvoid}, ptr_cb::Ptr{Cvoid},
                                  evalRequest_::Ptr{Cvoid},
                                  evalResults_::Ptr{Cvoid},
                                  userdata_::Ptr{Cvoid})

    # load evalRequest object
    ptr0 = Ptr{KN_eval_request}(evalRequest_)
    evalRequest = unsafe_load(ptr0)::KN_eval_request

    if evalRequest.evalRequestCode != KN_RC_EVALFC
        println("*** callbackEvalF incorrectly called with eval type ",
                evalRequest.evalRequestCode)
        return Cint(-1)
    end

    # load evalResult object
    ptr = Ptr{KN_eval_result}(evalResults_)
    evalResult = unsafe_load(ptr)::KN_eval_result

    # and eventually, load KNITRO's Julia Model
    m = unsafe_pointer_to_objref(userdata_)::Model

    request = EvalRequest(m, evalRequest)
    result = EvalResult(m, ptr_cb, evalResult)

    error("Foo")
    obj = kp.eval_f(ptr_model, ptr_cb, evalRequest, evalResults, kp.userdata)


    return Cint(0)
end

# User callback should be of the form:
# callback(kc, cb, evalrequest, evalresult, usrparams)::Int

function KN_add_eval_callback(m::Model, evalObj::Bool, funccallback::Function)
    # store function inside model:
    m.eval_f = funccallback

    # wrap eval_callback_wrapper as C function
    f = @cfunction(KN_eval_callback_wrapper,  Cint,
                   (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}))

    # define callback context
    rfptr = Ref{Ptr{Cvoid}}()

    # add callback to context
    ret = @kn_ccall(add_eval_callback_all, Cint,
                    (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}),
                    m.env.ptr_env.x, f, rfptr)
    _checkraise(ret)
    cb = CallbackContext(rfptr.x, m)

    # now, we store the Knitro Model inside user params
    ret = @kn_ccall(set_cb_user_params, Cint,
                    (Ptr{Cvoid}, Ptr{Cvoid}, Any),
                    m.env.ptr_env.x, cb.context, m)


    return cb
end

function KN_set_cb_grad(m::Model, cb::CallbackContext, gradcallback::Function)
    error("Not implemented")
end

function KN_set_cb_hess(m::Model, cb::CallbackContext, hesscallback::Function)
    error("Not implemented")
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
