# Callbacks utilities
mutable struct CallbackContext
    context::Ptr{Nothing}
    model::Model
end
CallbackContext(model::Model) = CallbackContext(C_NULL, model)

mutable struct KN_EvalRequest
    evalRequestCode::Cint
    threadID::Cint
    x::Ptr{Cdouble}
    lambda::Ptr{Cdouble}
    sigma::Ptr{Cdouble}
    vec::Ptr{Cdouble}
end

mutable struct KN_EvalResult
    obj::Ptr{Cdouble}
    c::Ptr{Cdouble}
    objGrad::Ptr{Cdouble}
    jac::Ptr{Cdouble}
    hess::Ptr{Cdouble}
    hessVec::Ptr{Cdouble}
    rsd::Ptr{Cdouble}
    rsdJac::Ptr{Cdouble}
end


function KN_eval_callback_wrapper(ptr_model::Ptr{Cvoid}, ptr_cb::Ptr{Cvoid},
                                  evalRequest_::Ptr{Cvoid},
                                  evalResults_::Ptr{Cvoid},
                                  userdata_::Ptr{Cvoid})
    println("Hello!!")
    println(ptr_model)

    # load evalRequest object
    ptr0 = Ptr{KN_EvalRequest}(evalRequest_)
    evalRequest = unsafe_load(ptr0)::KN_EvalRequest

    if evalRequest.evalRequestCode != KN_RC_EVALFC
        println("*** callbackEvalF incorrectly called with eval type ",
                evalRequest.evalRequestCode)
        return Cint(-1)
    end

    # load evalResult object
    ptr = Ptr{KN_EvalResult}(evalResults_)
    evalResult = unsafe_load(ptr)::KN_EvalResult

    kp = unsafe_pointer_to_objref(userdata_)::Model


    obj = kp.eval_f(ptr_model, ptr_cb, evalRequest, evalResults, kp.userdata)


    return Cint(0)
end

# User callback should be of the form:
# callback(kc, cb, evalrequest, evalresult, usrparams)
#
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
