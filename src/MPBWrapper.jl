import MathProgBase
const MPB = MathProgBase
using MathProgBase.SolverInterface

###############################################################################
# Solver objects
export KnitroSolver
struct KnitroSolver <: MPB.AbstractMathProgSolver
    options
end
KnitroSolver(;kwargs...) = KnitroSolver(kwargs)

mutable struct KnitroMathProgModel <: MPB.AbstractNonlinearModel
    options
    inner::Model

    numVar::Int
    numConstr::Int
    nnzJ::Int
    nnzH::Int

    varLB::Vector{Float64}
    varUB::Vector{Float64}
    constrLB::Vector{Float64}
    constrUB::Vector{Float64}

    jac_con::Vector{Int32}
    jac_var::Vector{Int32}
    hess_row::Vector{Int32}
    hess_col::Vector{Int32}

    varType::Vector{Int32}
    objType::Int32
    objFnType::Int32
    constrType::Vector{Int32}
    constrFnType::Vector{Int32}

    initial_x
    sense::Int32
    d::AbstractNLPEvaluator

    hasbeenrestarted::Bool

    solve_time::Float64

    function KnitroMathProgModel(;options...)
        new(options)
    end
end

MPB.NonlinearModel(s::KnitroSolver) = KnitroMathProgModel(;s.options...)
MPB.LinearQuadraticModel(s::KnitroSolver) = NonlinearToLPQPBridge(NonlinearModel(s))

function load!(m::KnitroMathProgModel, eval_f, eval_g, eval_h)
    kc = m.inner

    # define variables
    KN_add_vars!(kc, m.numVar)
    KN_set_var_lobnds(kc, m.varLB)
    KN_set_var_upbnds(kc, m.varUB)

    if m.initial_x != C_NULL
        KN_set_var_primal_init_values(kc, m.initial_x)
    end

    # define constraints
    KN_add_cons!(kc, m.numConstr)
    KN_set_con_lobnds(kc, m.constrLB)
    KN_set_con_upbnds(kc, m.constrUB)


    # add func callbacks globally
    cb = KN_add_eval_callback(kc, eval_f)

    if m.nnzJ != 0
        KN_set_cb_grad(kc, cb, eval_g, jacIndexCons=m.jac_con,
                    jacIndexVars=m.jac_var)
    else
        KN_set_cb_grad(kc, cb, eval_g)
    end

    if m.nnzH != 0
        KN_set_cb_hess(kc, cb, length(m.hess_row), eval_h,
                       hessIndexVars1=m.hess_row,
                       hessIndexVars2=m.hess_col)
    else
        KN_set_cb_hess(kc, cb, KN_DENSE_ROWMAJOR, eval_h)
    end


    # set sense
    KN_set_obj_goal(kc, m.sense)
end


###############################################################################
# Begin interface implementation

function sparse_merge_hess_duplicates(I, J, m, n)
    V = [Int[i] for i in 1:length(I)]
    for i in 1:length(I) # make upper triangular
        if I[i] > J[i]
            I[i],J[i] = J[i],I[i]
        end
    end
    findnz(sparse(I,J,V,m,n,vcat))
end

function sparse_merge_jac_duplicates(I, J, m, n)
    V = [Int[i] for i in 1:length(I)]
    findnz(sparse(I,J,V,m,n,vcat))
end

# generic nonlinear interface
function MPB.loadproblem!(m::KnitroMathProgModel,
                      numVar::Int,
                      numConstr::Int,
                      x_l, x_u, g_lb, g_ub,
                      sense::Symbol,
                      d::AbstractNLPEvaluator)

    features = features_available(d)
    has_hessian = (:Hess in features)
    init_feat = [:Grad]
    has_hessian && push!(init_feat, :Hess)
    numConstr > 0 && push!(init_feat, :Jac)

    initialize(d, init_feat)
    Ihess, Jhess = has_hessian ? hesslag_structure(d) : (Int[], Int[])
    Ijac, Jjac = numConstr > 0 ? jac_structure(d) : (Int[], Int[])

    m.nnzJ = length(Ijac)
    m.nnzH = length(Ihess)
    jac_tmp = zeros(Float64, m.nnzJ)
    hess_tmp = zeros(Float64, m.nnzH)
    @assert length(Ijac) == length(Jjac)
    @assert length(Ihess) == length(Jhess)
    m.jac_con, m.jac_var, jac_indices = sparse_merge_jac_duplicates(Ijac, Jjac,
                                                                numConstr,
                                                                numVar)
    m.jac_con = m.jac_con .- 1
    m.jac_var = m.jac_var .- 1
    m.hess_row, m.hess_col, hess_indices = sparse_merge_hess_duplicates(Ihess,
                                                                    Jhess,
                                                                    numVar,
                                                                    numVar)
    m.hess_row = m.hess_row .- 1
    m.hess_col = m.hess_col .- 1
    n_jac_indices = length(jac_indices)
    n_hess_indices = length(hess_indices)

    m.varLB = x_l
    m.varUB = x_u
    m.constrLB = g_lb
    m.constrUB = g_ub
    m.numVar = length(m.varLB)
    m.numConstr = length(m.constrLB)
    @assert m.numVar == length(m.varUB)
    @assert m.numConstr == length(m.constrUB)

    for i in 1:m.numVar
        if m.varLB[i] == -Inf
            m.varLB[i] = -KN_INFINITY
        end
        if m.varUB[i] == Inf
            m.varUB[i] = KN_INFINITY
        end
    end

    for i in 1:m.numConstr
        if m.constrLB[i] == -Inf
            m.constrLB[i] = -KN_INFINITY
        end
        if m.constrUB[i] == Inf
            m.constrUB[i] = KN_INFINITY
        end
    end
    m.initial_x = C_NULL

    @assert sense == :Min || sense == :Max
    m.sense = (sense == :Min) ? KN_OBJGOAL_MINIMIZE : KN_OBJGOAL_MAXIMIZE
    # allow for the possibility of specializing to LINEAR or QUADRATIC?
    if isobjlinear(d)
        m.objType = KN_OBJTYPE_LINEAR
    elseif isobjquadratic(d)
        m.objType = KN_OBJTYPE_QUADRATIC
    else
        m.objType = KN_OBJTYPE_GENERAL
    end

    m.constrType = fill(KN_CONTYPE_GENERAL, m.numConstr)
    for i=1:m.numConstr
        if isconstrlinear(d, i)
            m.constrType[i] = KN_CONTYPE_LINEAR
        end
    end

    m.varType = fill(KN_VARTYPE_CONTINUOUS, m.numVar)

    # Objective callback
    function eval_f_cb(kc, cb, evalRequest, evalResult, userParams)
        evalResult.obj[1]= MPB.eval_f(d, evalRequest.x)
        MPB.eval_g(d, evalResult.c, evalRequest.x)
        return 0
    end

    # Objective gradient callback
    function eval_g_cb(kc, cb, evalRequest, evalResult, userParams)
        MPB.eval_grad_f(d, evalResult.objGrad, evalRequest.x)
        # to update
        MPB.eval_jac_g(d, evalResult.jac, evalRequest.x)
        return 0
    end

    # Hessian callback
    function eval_h_cb(kc, cb, evalRequest, evalResult, userParams)
        MPB.eval_hesslag(d, evalResult.hess, evalRequest.x,
                         evalRequest.sigma, evalRequest.lambda)
        return 0
    end

    m.inner = KN_new()

    defined_hessopt = false; hessopt_value = 0
    for (param,value) in m.options
        param = string(param)
        if param == "KN_PARAM_HESSOPT"
            defined_hessopt = true; hessopt_value = value
        end
        if param == "options_file"
            KN_load_param_file(m.inner, value)
        elseif param == "tuner_file"
            KN_load_tuner_file(m.inner, value)
        else
            if haskey(KN_paramName2Indx, param) # KTR_PARAM_*
                KN_set_param(m.inner, KN_paramName2Indx[param], value)
            else # string name
                println(param)
                KN_set_param(m.inner, param, value)
            end
        end
    end

    # check and define default hessian option
    if (!has_hessian && !defined_hessopt) || (!has_hessian && !in(hessopt_value,2:6))
        KN_set_param(m.inner,KN_paramName2Indx["KN_PARAM_HESSOPT"],6)
    end

    # load inner problem in KNITRO
    load!(m, eval_f_cb, eval_g_cb, eval_h_cb)
end

MPB.getsense(m::KnitroMathProgModel) = m.sense
MPB.numvar(m::KnitroMathProgModel) = m.numVar
MPB.numconstr(m::KnitroMathProgModel) = m.numConstr

function MPB.optimize!(m::KnitroMathProgModel)
    # update variables' types
    KN_set_var_properties(m.inner, m.varType)
    t = time()
    KN_solve(m.inner)
    m.solve_time = time() - t
    m.hasbeenrestarted = false

    # udpate inner model with new solution
    nStatus, objSol, x, lambda_ =  KNITRO.KN_get_solution(m.inner)
    m.inner.status = nStatus
    m.inner.obj_val = objSol
    m.inner.lambda = lambda_
    m.inner.x = x
end

function MPB.status(m::KnitroMathProgModel)
    kp = m.inner
    if kp.status == -1
        # chosen not to clash with any of the KTR_RC_* codes
        return :Uninitialized
    elseif kp.status == 101
        # chosen not to clash with any of the KTR_RC_* codes
        return :Initialized
    elseif kp.status == 0
        return :Optimal
    elseif -109 <= kp.status <= -100
        return :FeasibleApproximate
    elseif -209 <= kp.status <= -200
        return :Infeasible
    elseif kp.status == -300
        return :Unbounded
    elseif -419 <= kp.status <= -400
        return :UserLimit
    elseif -599 <= kp.status <= -500
        return :KnitroError
    else
        return :Undefined
    end
end

MPB.getobjval(m::KnitroMathProgModel) = KN_get_obj_value(m.inner)
MPB.getobjbound(m::KnitroMathProgModel) = KN_get_mip_relaxation_bnd(m.inner)
MPB.getsolution(m::KnitroMathProgModel) = m.inner.x
MPB.getconstrsolution(m::KnitroMathProgModel) = KN_get_con_values(m.inner)
MPB.getreducedcosts(m::KnitroMathProgModel) = -1 .* m.inner.lambda[m.numConstr + 1:end]
MPB.getconstrduals(m::KnitroMathProgModel) = -1 .* m.inner.lambda[1:m.numConstr]
MPB.getrawsolver(m::KnitroMathProgModel) = m.inner
MPB.getsolvetime(m::KnitroMathProgModel) = m.solve_time

function warmstart(m::KnitroMathProgModel, x)
    m.initial_x = [Float64(i) for i in x]
end

MPB.setwarmstart!(m::KnitroMathProgModel, x) = warmstart(m,x)
MPB.setvartype!(m::KnitroMathProgModel, typ::Vector{Symbol}) =
    (m.varType = map(t->KN_rev_var_type_map[t], typ))

MPB.freemodel!(m::KnitroMathProgModel) = KN_free(m.inner)
