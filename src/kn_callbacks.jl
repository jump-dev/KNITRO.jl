# Callbacks utilities
mutable struct CallbackContext
    context::Ptr{Nothing}
    model::Model
end
CallbackContext(model::Model) = CallbackContext(C_NULL, model)

mutable struct KN_EvalRequest
    type::Cint
    evalRequestCode::Cint
    threadID::Cint
    x::Vector{Cdouble}
    lambda::Vector{Cdouble}
    sigma::Vector{Cdouble}
    vec::Vector{Cdouble}
end

mutable struct KN_EvalResult
    obj::Cdouble
    c::Cdouble
    objGrad::Cdouble
    jac::Cdouble
    hess::Cdouble
    hessVec::Cdouble
    rsd::Cdouble
    rsdJac::Cdouble
end


function KN_eval_callback_wrapper(ptr_model::Ptr{Cvoid}, ptr_cb::Ptr{Cvoid},
                                  evalRequest_::Ptr{Cvoid} ,
                                  evalResults_::Ptr{Cvoid},
                                  userdata_::Ptr{Cvoid})
    evalRequest = unsafe_load(evalRequests_)
    if evalRequest.evalRequestCode != KN_RC_EVALFC
        println("*** callbackEvalF incorrectly called with eval type ", evalRequest.evalRequestCode)
        return Cint(-1)
    end

    kp = unsafe_pointer_to_objref(userdata_)::Model
    x = unsafe_load(evalResults_).c

    obj = kp.eval_f(ptr_model, ptr_cb, evalRequest, evalResults, kp.userdata)
    unsafe_store!(evalResults_.obj, obj)


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

    cb = CallbackContext(rfptr.x, m)
    _checkraise(ret)

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
