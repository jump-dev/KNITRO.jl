module Knitro
  if isfile(joinpath(Pkg.dir("Knitro.jl"),"deps","deps.jl"))
    include("../deps/deps.jl")
  else
    error("Knitro not properly installed.")
  end

  export
    KnitroProblem, createProblem, setCallbacks #, freeProblem

  # A macro to make calling C API a little cleaner
  macro ktr_ccall(func, args...)
    f = Base.Meta.quot(symbol("KTR_$(func)"))
    args = [esc(a) for a in args]
    quote
      ccall(($f,libknitro), $(args...))
    end
  end

  type KnitroProblem
    env::Ptr{Void} # pointer to KTR_context
    # Callbacks
    eval_f
    eval_g
    eval_grad_f
    eval_jac_g
    eval_h
    eval_hv
  end

  function createProblem()
    KnitroProblem(newcontext(),C_NULL,C_NULL,C_NULL,
                  C_NULL,C_NULL,C_NULL)
  end
  
  # doesn't work
  function freeProblem(kp::KnitroProblem)
    freecontext(kp.env)
    kp.env = C_NULL
  end

  function eval_fc_wrapper(evalRequestCode::Cint,
                           n::Cint,
                           m::Cint,
                           nnzJ::Cint,
                           nnzH::Cint,
                           x_::Ptr{Cdouble},
                           lambda_::Ptr{Cdouble},
                           obj_::Ptr{Cdouble},
                           c_::Ptr{Cdouble},
                           g_::Ptr{Cdouble},
                           J_::Ptr{Cdouble},
                           H_::Ptr{Cdouble},
                           HV_::Ptr{Cdouble},
                           userParams_::Ptr{Void})
    if evalRequestCode != KTR_RC_EVALFC
      return KTR_RC_CALLBACK_ERR
    end
    kp = unsafe_pointer_to_objref(userParams_)::KnitroProblem
    x = pointer_to_array(x_,n)

    # calculate the new objective function value
    unsafe_store!(obj_, kp.eval_f(x))
    # calculate the new constraint values
    kp.eval_g(x,pointer_to_array(c_,m))

    int32(0)
  end
  
  function eval_ga_wrapper(evalRequestCode::Cint,
                           n::Cint,
                           m::Cint,
                           nnzJ::Cint,
                           nnzH::Cint,
                           x_::Ptr{Cdouble},
                           lambda_::Ptr{Cdouble},
                           obj_::Ptr{Cdouble},
                           c_::Ptr{Cdouble},
                           g_::Ptr{Cdouble},
                           J_::Ptr{Cdouble},
                           H_::Ptr{Cdouble},
                           HV_::Ptr{Cdouble},
                           userParams_::Ptr{Void})
    if evalRequestCode != KTR_RC_EVALGA
      return KTR_RC_CALLBACK_ERR
    end
    kp = unsafe_pointer_to_objref(userParams_)::KnitroProblem
    x = pointer_to_array(x_,n)

    # evaluate the gradient
    kp.eval_grad_f(x,pointer_to_array(g_,n))
    # evaluate the jacobian
    kp.eval_jac_g(x,pointer_to_array(J_,nnzJ))

    int32(0)
  end

  function eval_hess_wrapper(evalRequestCode::Cint,
                             n::Cint,
                             m::Cint,
                             nnzJ::Cint,
                             nnzH::Cint,
                             x_::Ptr{Cdouble},
                             lambda_::Ptr{Cdouble},
                             obj_::Ptr{Cdouble},
                             c_::Ptr{Cdouble},
                             g_::Ptr{Cdouble},
                             J_::Ptr{Cdouble},
                             H_::Ptr{Cdouble},
                             HV_::Ptr{Cdouble},
                             userParams_::Ptr{Void})
    kp = unsafe_pointer_to_objref(userParams_)::KnitroProblem
    x = pointer_to_array(x_, n)
    lambda = pointer_to_array(lambda_, m+n)

    if evalRequestCode == KTR_RC_EVALH
      kp.eval_h(x, lambda, 1.0, pointer_to_array(H_, nnzH))
    elseif evalRequestCode == KTR_RC_EVALH_NO_F
      kp.eval_h(x, lambda, 0.0, pointer_to_array(H_, nnzH))
    elseif evalRequestCode == KTR_RC_EVALHV
      kp.eval_hv(x, lambda, 1.0, pointer_to_array(HV_, n))
    elseif evalRequestCode == KTR_RC_EVALHV_NO_F
      kp.eval_hv(x, lambda, 0.0, pointer_to_array(HV_, n))
    else
      return KTR_RC_CALLBACK_ERR
    end

    int32(0)
  end
  
  function setCallbacks(kp::KnitroProblem,
                        eval_f::Function,
                        eval_g::Function,
                        eval_grad_f::Function,
                        eval_jac_g::Function,
                        eval_h::Function,
                        eval_hv::Function)
    kp.eval_f = eval_f
    kp.eval_g = eval_g
    kp.eval_grad_f = eval_grad_f
    kp.eval_jac_g = eval_jac_g
    kp.eval_h = eval_h
    kp.eval_hv = eval_hv

    # set callbacks
    set_func_callback(kp,eval_fc_wrapper)
    set_grad_callback(kp,eval_ga_wrapper)
    set_hess_callback(kp,eval_hess_wrapper)
  end

  include("ktr_callbacks.jl")
  include("ktr_functions.jl")
  include("ktr_defines.jl")
end
