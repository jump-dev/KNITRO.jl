
export
    KnitroProblem,
    createProblem, freeProblem,
    initializeProblem,
    solveProblem,
    restartProblem,
    setFuncCallback, setGradCallback, setHessCallback,
    setCallbacks, setMIPCallback,
    loadOptionsFile,
    loadTunerFile,
    setOption, getOption,
    applicationReturnStatus


mutable struct KnitroProblem
    # For KNITRO
    env::Ptr{Nothing} # pointer to KTR_context
    eval_status::Int32 # scalar input used only for reverse comms
    status::Int32  # Final status
    mip::Bool # whether it is a Mixed Integer Problem

    # For MathProgBase
    x::Vector{Float64}  # Starting and final solution
    lambda::Vector{Float64}
    g::Vector{Float64}  # Final constraint values
    obj_val::Vector{Float64}  # (length 1) Final objective

    # Callbacks
    eval_f::Function
    eval_g::Function
    eval_grad_f::Function
    eval_jac_g::Function
    eval_h::Function
    eval_hv::Function
    eval_mip_node::Function

    function KnitroProblem()
        kp = new(newcontext(),
                    0,
                    100, # Code for :Uninitialized
                    false)
        finalizer(freeProblem, kp)
        kp
    end
end

createProblem() = KnitroProblem()

function freeProblem(kp::KnitroProblem)
    kp.env == C_NULL && return
    return_code = @ktr_ccall(free, Int32, (Ptr{Nothing},), [kp.env])
    if return_code != 0
        error("KNITRO: Error freeing memory")
    end
    kp.env = C_NULL
end

function initializeKP(kp, x0, lambda0, g; mip = false)
    kp.status = 101 # code for :Initialized
    kp.mip = mip
    kp.x = x0
    kp.lambda = lambda0
    kp.g = g
    kp.obj_val = zeros(Float64, 1)
end

function initializeProblem(kp, objGoal, objType, x_l, x_u, c_Type, g_lb,
                            g_ub, jac_var, jac_con, hess_row, hess_col;
                            initial_x = C_NULL, initial_lambda = C_NULL)
    initializeKP(kp, (initial_x != C_NULL) ? initial_x :
                        zeros(Float64, length(x_l)),
                        (initial_lambda != C_NULL) ? initial_lambda :
                        zeros(Float64, length(x_l) + length(g_lb)),
                        zeros(Float64, length(g_lb)))
    init_problem(kp, objGoal, objType, x_l, x_u, c_Type, g_lb, g_ub,
                    jac_var, jac_con, hess_row, hess_col; initial_x=kp.x,
                    initial_lambda=kp.lambda)
end

function initializeProblem(kp, objGoal, objType, x_l, x_u, c_Type, g_lb,
                            g_ub, jac_var, jac_con; initial_x = C_NULL,
                            initial_lambda = C_NULL)
    hessopt = zeros(Int32 , 1)
    getOption(kp, "hessopt", hessopt)
    @assert hessopt[1] != KTR_HESSOPT_EXACT
    # KNITRO documentation:
    # If user option hessopt is not set to KTR_HESSOPT_EXACT, then Hessian
    # nonzeros will not be used. In this case, set nnzH=0, and pass NULL
    # pointers for hessIndexRows and hessIndexCols.
    initializeKP(kp, (initial_x != C_NULL) ? initial_x :
                        zeros(Float64, length(x_l)),
                        (initial_lambda != C_NULL) ? initial_lambda :
                        zeros(Float64, length(x_l) + length(g_lb)),
                        zeros(Float64, length(g_lb)))
    init_problem(kp, objGoal, objType, x_l, x_u, c_Type, g_lb, g_ub,
                    jac_var, jac_con; initial_x=kp.x,initial_lambda=kp.lambda)
end

# Initialization for MIP
function initializeProblem(kp, objGoal, objType, objFnType,
                            x_Type, x_l, x_u, c_Type, c_FnType, g_lb,
                            g_ub, jac_var, jac_con, hess_row, hess_col;
                            initial_x = C_NULL, initial_lambda = C_NULL)
    initializeKP(kp, (initial_x != C_NULL) ? initial_x :
                        zeros(Float64, length(x_l)),
                        (initial_lambda != C_NULL) ? initial_lambda :
                        zeros(Float64, length(x_l) + length(g_lb)),
                        zeros(Float64, length(g_lb)),
                        mip=true)
    mip_init_problem(kp, objGoal, objType, objFnType, x_Type, x_l, x_u,
                        c_Type, c_FnType, g_lb, g_ub, jac_var, jac_con,
                        hess_row, hess_col; initial_x=kp.x,
                        initial_lambda=kp.lambda)
end

function initializeProblem(kp, objGoal, objType, objFnType,
                            x_Type, x_l, x_u, c_Type, c_FnType, g_lb,
                            g_ub, jac_var, jac_con; initial_x = C_NULL,
                            initial_lambda = C_NULL)
    hessopt = Array(Int32, 1)
    getOption(kp, "hessopt", hessopt)
    @assert hessopt[1] != KTR_HESSOPT_EXACT
    # KNITRO documentation:
    # If user option hessopt is not set to KTR_HESSOPT_EXACT, then Hessian
    # nonzeros will not be used. In this case, set nnzH=0, and pass NULL
    # pointers for hessIndexRows and hessIndexCols.
    initializeKP(kp, (initial_x != C_NULL) ? initial_x :
                        zeros(Float64, length(x_l)),
                        (initial_lambda != C_NULL) ? initial_lambda :
                        zeros(Float64, length(x_l) + length(g_lb)),
                        zeros(Float64, length(g_lb)),
                        mip=true)
    mip_init_problem(kp, objGoal, objType, objFnType, x_Type, x_l, x_u,
                        c_Type, c_FnType, g_lb, g_ub, jac_var, jac_con;
                        initial_x=kp.x, initial_lambda=kp.lambda)
end

function solveProblem(kp::KnitroProblem)
    if kp.mip
        kp.status = mip_solve_problem(kp, kp.x, kp.lambda, kp.eval_status,
                                        kp.obj_val)
    else
        kp.status = solve_problem(kp, kp.x, kp.lambda, kp.eval_status,
                                    kp.obj_val)
    end
end

function solveProblem(kp::KnitroProblem,
                        cons::Vector{Float64},
                        objGrad::Vector{Float64},
                        jac::Vector{Float64},
                        hess::Vector{Float64},
                        hessVector::Vector{Float64})
    if kp.mip
        kp.status = mip_solve_problem(kp, kp.x, kp.lambda, kp.eval_status,
                                        kp.obj_val, cons, objGrad, jac, hess,
                                        hessVector)
    else
        kp.status = solve_problem(kp, kp.x, kp.lambda, kp.eval_status,
                                    kp.obj_val, cons, objGrad, jac, hess,
                                    hessVector)
    end
end

function restartProblem(kp, x0, lambda0)
    kp.status = 101 # code for :Initialized
    kp.eval_status = 0
    restart_problem(kp, x0, lambda0)
end

function restartProblem(kp)
    kp.status = 101 # code for :Initialized
    kp.eval_status = 0
    restart_problem(kp)
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
                            userParams_::Ptr{Nothing})
    if evalRequestCode != KTR_RC_EVALFC
        return KTR_RC_CALLBACK_ERR
    end
    kp = unsafe_pointer_to_objref(userParams_)::KnitroProblem
    x = unsafe_wrap(Array,x_,n)

    # calculate the new objective function value
    unsafe_store!(obj_, kp.eval_f(x))
    # calculate the new constraint values
    kp.eval_g(x,unsafe_wrap(Array,c_,m))

    Int32(0)
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
                            userParams_::Ptr{Nothing})
    if evalRequestCode != KTR_RC_EVALGA
        return KTR_RC_CALLBACK_ERR
    end
    kp = unsafe_pointer_to_objref(userParams_)::KnitroProblem
    x = unsafe_wrap(Array,x_,n)

    # evaluate the gradient
    kp.eval_grad_f(x,unsafe_wrap(Array,g_,n))
    # evaluate the jacobian
    if m > 0
        kp.eval_jac_g(x,unsafe_wrap(Array,J_,nnzJ))
    end

    Int32(0)
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
                            userParams_::Ptr{Nothing})
    kp = unsafe_pointer_to_objref(userParams_)::KnitroProblem
    x = unsafe_wrap(Array,x_, n)
    lambda = unsafe_wrap(Array,lambda_, m+n)

    if evalRequestCode == KTR_RC_EVALH
        kp.eval_h(x, lambda, 1.0, unsafe_wrap(Array,H_, nnzH))
    elseif evalRequestCode == KTR_RC_EVALH_NO_F
        kp.eval_h(x, lambda, 0.0, unsafe_wrap(Array,H_, nnzH))
    elseif evalRequestCode == KTR_RC_EVALHV
        kp.eval_hv(x, lambda, 1.0, unsafe_wrap(Array,HV_, n))
    elseif evalRequestCode == KTR_RC_EVALHV_NO_F
        kp.eval_hv(x, lambda, 0.0, unsafe_wrap(Array,HV_, n))
    else
        return KTR_RC_CALLBACK_ERR
    end
    Int32(0)
end

function eval_mip_node_wrapper(evalRequestCode::Cint,
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
                            userParams_::Ptr{Nothing})
    kp = unsafe_pointer_to_objref(userParams_)::KnitroProblem
    obj = unsafe_load(obj_)
    kp.eval_mip_node(kp,obj)
    Int32(0)
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

function setMIPCallback(kp::KnitroProblem, eval_mip_node::Function)
    kp.eval_mip_node = eval_mip_node
    set_mip_node_callback(kp,eval_mip_node_wrapper)
end

# Getters and Setters for Parameters/Options
loadOptionsFile(kp, filename) = load_param_file(kp, filename)
loadTunerFile(kp, filename) = load_tuner_file(kp, filename)
setOption(args...) = set_param(args...)
getOption(args...) = get_param(args...)

function applicationReturnStatus(kp::KnitroProblem)
    if kp.status == 100
        # chosen not to clash with any of the KTR_RC_* codes
        return :Uninitialized
    elseif kp.status == 101
        # chosen not to clash with any of the KTR_RC_* codes
        return :Initialized
    elseif kp.status == 0
        return :Optimal
    elseif 1 <= kp.status <= 11
        return :ReverseComms
    elseif -199 <= kp.status <= -100
        return :FeasibleApproximate
    elseif -299 <= kp.status <= -200
        return :Infeasible
    elseif kp.status == -300
        return :Unbounded
    elseif -499 <= kp.status <= -400
        return :UserLimit
    elseif -599 <= kp.status <= -500
        return :KnitroError
    else
        return :Undefined
    end
end
