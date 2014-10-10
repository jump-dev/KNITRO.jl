module Knitro

    using Docile
    @docstrings

    if isfile(joinpath(Pkg.dir("Knitro.jl"),"deps","deps.jl"))
        include("../deps/deps.jl")
    else
        error("Knitro not properly installed.")
    end

    export
        KnitroProblem,
        createProblem, #freeProblem,
        initializeProblem,
        solveProblem,
        restartProblem,
        setCallbacks,
        loadOptionsFile,
        loadTunerFile,
        setOption, getOption,
        applicationReturnStatus

    @doc "A macro to make calling KNITRO's C API a little cleaner" ->
    macro ktr_ccall(func, args...)
        f = Base.Meta.quot(symbol("KTR_$(func)"))
        args = [esc(a) for a in args]
        quote
            ccall(($f,libknitro), $(args...))
        end
    end

    type KnitroProblem
        env::Ptr{Void} # pointer to KTR_context

        # For MathProgBase
        sense::Symbol
        n::Int  # Num vars
        m::Int  # Num cons
        x::Vector{Float64}  # Starting and final solution
        lambda::Vector{Float64}
        g::Vector{Float64}  # Final constraint values
        obj_val::Vector{Float64}  # (length 1) Final objective
        status::Int32  # Final status

        # Callbacks
        eval_f::Function
        eval_g::Function
        eval_grad_f::Function
        eval_jac_g::Function
        eval_h::Function
        eval_hv::Function
        eval_mip_node::Function

        function KnitroProblem()
            prob = new(newcontext())
            # finalizer segfaults upon termination of the running script
            # finalizer(prob, freeProblem)
            prob
        end
    end

    createProblem() = KnitroProblem()

    function freeProblem(kp::KnitroProblem)
        freecontext(kp.env)
        #kp.env = C_NULL
    end

    function initializeProblem(kp, objGoal, objType, x_l, x_u, c_Type, g_lb,
                               g_ub, jac_var, jac_con, hess_row, hess_col,
                               x0 = C_NULL, lambda0 = C_NULL)
        # TODO: check return code?
        init_problem(kp, objGoal, objType, x_l, x_u, c_Type, g_lb, g_ub,
                     jac_var, jac_con, hess_row, hess_col, x0, lambda0)
        if objGoal == KTR_OBJGOAL_MINIMIZE
            kp.sense = :Min 
        else
            kp.sense = :Max 
        end
        kp.n = length(x_l)
        kp.m = length(g_lb)

        if x0 != C_NULL
            kp.x = x0
        else
            kp.x = zeros(Float64, kp.n)
        end

        if lambda0 != C_NULL
            kp.lambda = lambda0
        else
            kp.lambda = zeros(Float64, kp.n + kp.m)
        end

        kp.g = Array(Float64, kp.m)
        kp.obj_val = Array(Float64, 1)
        kp.status = int32(0)
    end

    solveProblem(kp::KnitroProblem) = solve_problem(kp, kp.x, kp.lambda,
                                                    kp.status, kp.obj_val)
    function solveProblem(kp::KnitroProblem,
                          cons::Vector{Float64},
                          objGrad::Vector{Float64},
                          jac::Vector{Float64},
                          hess::Vector{Float64},
                          hessVector::Vector{Float64})
        solve_problem(kp, kp.x, kp.lambda, kp.status, kp.obj_val, cons,
                      objGrad, jac, hess, hessVector)
    end

    function restartProblem(kp, x0, lambda0)
        kp.status = int32(0)
        restart_problem(kp, x0, lambda0)
    end

    # -----
    # Callback Wrappers
    # -----
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

    function setFuncCallback(kp::KnitroProblem,
                             eval_f::Function,
                             eval_g::Function)
        kp.eval_f = eval_f
        kp.eval_g = eval_g
        set_func_callback(kp,eval_fc_wrapper)
    end

    function setGradCallback(kp::KnitroProblem,
                             eval_grad_f::Function,
                             eval_jac_g::Function)
        kp.eval_grad_f = eval_grad_f
        kp.eval_jac_g = eval_jac_g
        set_grad_callback(kp,eval_ga_wrapper)
    end

    function setHessCallback(kp::KnitroProblem,
                             eval_h::Function,
                             eval_hv::Function)
        kp.eval_h = eval_h
        kp.eval_hv = eval_hv
        set_hess_callback(kp,eval_hess_wrapper)
    end

    function setCallbacks(kp::KnitroProblem,
                          eval_f::Function,
                          eval_g::Function,
                          eval_grad_f::Function,
                          eval_jac_g::Function,
                          eval_h::Function,
                          eval_hv::Function)
        setFuncCallback(kp, eval_f, eval_g)
        setGradCallback(kp, eval_grad_f, eval_jac_g)
        setHessCallback(kp, eval_h, eval_hv)
    end

    # Getters and Setters for Parameters/Options
    loadOptionsFile(kp, filename) = load_param_file(kp, filename)
    loadTunerFile(kp, filename) = load_tuner_file(kp, filename)
    setOption(args...) = set_param(args...)
    getOption(args...) = get_param(args...)

    function applicationReturnStatus(kp::KnitroProblem)
        @assert int32(-599) <= kp.status <= int32(0)
        if kp.status == int32(0)
            return :Optimal
        elseif int32(-199) <= kp.status <= int32(-100)
            return :FeasibleApproximate
        elseif int32(-299) <= kp.status <= int32(-200)
            return :Infeasible
        elseif status == int32(-300)
            return :Unbounded
        elseif int32(-499) <= kp.status <= int32(-400)
            return :PredefinedLimit
        else #int32(-599) <= kp.status <= int32(-500)
            return :Error
        end
    end

    include("ktr_callbacks.jl")
    include("ktr_functions.jl")
    include("ktr_defines.jl")
    include("KnitroSolverInterface.jl")
end
