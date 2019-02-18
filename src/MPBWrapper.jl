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
    inner::KnitroProblem

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
            m.varLB[i] = -KTR_INFBOUND
        end
        if m.varUB[i] == Inf
            m.varUB[i] = KTR_INFBOUND
        end
    end

    for i in 1:m.numConstr
        if m.constrLB[i] == -Inf
            m.constrLB[i] = -KTR_INFBOUND
        end
        if m.constrUB[i] == Inf
            m.constrUB[i] = KTR_INFBOUND
        end
    end
    m.initial_x = C_NULL

    @assert sense == :Min || sense == :Max
    m.sense = (sense == :Min) ? KTR_OBJGOAL_MINIMIZE : KTR_OBJGOAL_MAXIMIZE
    # allow for the possibility of specializing to LINEAR or QUADRATIC?
    if isobjlinear(d)
        m.objType = KTR_OBJTYPE_LINEAR
        m.objFnType = KTR_FNTYPE_CONVEX
    elseif isobjquadratic(d)
        m.objType = KTR_OBJTYPE_QUADRATIC
        m.objFnType = KTR_FNTYPE_UNCERTAIN
    else
        m.objType = KTR_OBJTYPE_GENERAL
        m.objFnType = KTR_FNTYPE_UNCERTAIN
    end

    m.constrType = fill(KTR_CONTYPE_GENERAL, m.numConstr)
    m.constrFnType = fill(KTR_FNTYPE_UNCERTAIN, m.numConstr)
    for i=1:m.numConstr
        if isconstrlinear(d, i)
            m.constrType[i] = KTR_CONTYPE_LINEAR
            m.constrFnType[i] = KTR_FNTYPE_CONVEX
        end
    end

    m.varType = fill(KTR_VARTYPE_CONTINUOUS, m.numVar)

    # Objective callback
    eval_f_cb(x) = eval_f(d,x)

    # Objective gradient callback
    eval_grad_f_cb(x, grad_f) = eval_grad_f(d, grad_f, x)

    # Constraint value callback
    eval_g_cb(x, g) = eval_g(d, g, x)

    # Jacobian callback
    function eval_jac_g_cb(x, jac)
        eval_jac_g(d, jac_tmp, x)
        for i in 1:n_jac_indices
            jac[i] = sum(jac_tmp[jac_indices[i]])
        end
    end

    # Hessian callback
    function eval_h_cb(x, lambda, sigma, hess)
        eval_hesslag(d, hess_tmp, x, sigma, lambda)
        for i in 1:n_hess_indices
            hess[i] = sum(hess_tmp[hess_indices[i]])
        end
    end

    # Hessian-vector callback
    eval_hv_cb(x, lambda, sigma, hv) = begin
        v = copy(hv)
        eval_hesslag_prod(d, hv, x, v, sigma, lambda)
    end

    m.inner = createProblem()
    defined_hessopt = false; hessopt_value = 0
    for (param,value) in m.options
        param = string(param)
        if param == "KTR_PARAM_HESSOPT"
            defined_hessopt = true; hessopt_value = value
        end
        if param == "options_file"
            loadOptionsFile(m.inner, value)
        elseif param == "tuner_file"
            loadTunerFile(m.inner, value)
        else
            if haskey(paramName2Indx, param) # KTR_PARAM_*
                setOption(m.inner, paramName2Indx[param], value)
            else # string name
                setOption(m.inner, param, value)
            end
        end
    end

    # check and define default hessian option
    if (!has_hessian && !defined_hessopt) || (!has_hessian && !in(hessopt_value,2:6))
        setOption(m.inner,paramName2Indx["KTR_PARAM_HESSOPT"],6)
    end

    setCallbacks(m.inner, eval_f_cb, eval_g_cb, eval_grad_f_cb, eval_jac_g_cb,
                 eval_h_cb, eval_hv_cb)
end

MPB.getsense(m::KnitroMathProgModel) = m.sense
MPB.numvar(m::KnitroMathProgModel) = m.numVar
MPB.numconstr(m::KnitroMathProgModel) = m.numConstr

function MPB.optimize!(m::KnitroMathProgModel)
    if applicationReturnStatus(m.inner) == :Uninitialized
        if all(x->x==KTR_VARTYPE_CONTINUOUS, m.varType)
            initializeProblem(m.inner, m.sense, m.objType, m.varLB, m.varUB,
                              m.constrType, m.constrLB, m.constrUB, m.jac_var,
                              m.jac_con, m.hess_row, m.hess_col;
                              initial_x = m.initial_x)
        else
            initializeProblem(m.inner, m.sense, m.objType, m.objFnType,
                              m.varType, m.varLB, m.varUB, m.constrType,
                              m.constrFnType, m.constrLB, m.constrUB,
                              m.jac_var, m.jac_con, m.hess_row, m.hess_col;
                              initial_x = m.initial_x)
        end
    elseif !m.hasbeenrestarted
        restartProblem(m.inner)
    end
    t = time()
    solveProblem(m.inner)
    m.solve_time = time() - t
    m.hasbeenrestarted = false
end

function MPB.status(m::KnitroMathProgModel)
    applicationReturnStatus(m.inner)
end

MPB.getobjval(m::KnitroMathProgModel) = m.inner.obj_val[1]
MPB.getobjbound(m::KnitroMathProgModel) = get_mip_relaxation_bnd(m.inner)
MPB.getsolution(m::KnitroMathProgModel) = m.inner.x
MPB.getconstrsolution(m::KnitroMathProgModel) = m.inner.g
MPB.getreducedcosts(m::KnitroMathProgModel) =
    -1 .* m.inner.lambda[m.numConstr + 1:end]
MPB.getconstrduals(m::KnitroMathProgModel) = -1 .* m.inner.lambda[1:m.numConstr]
MPB.getrawsolver(m::KnitroMathProgModel) = m.inner
MPB.getsolvetime(m::KnitroMathProgModel) = m.solve_time

function warmstart(m::KnitroMathProgModel, x)
    m.initial_x = [Float64(i) for i in x]
    if applicationReturnStatus(m.inner) != :Uninitialized
        restartProblem(m.inner, m.initial_x, m.inner.lambda)
        m.hasbeenrestarted = true
    end
end

MPB.setwarmstart!(m::KnitroMathProgModel, x) = warmstart(m,x)
MPB.setvartype!(m::KnitroMathProgModel, typ::Vector{Symbol}) =
    (m.varType = map(t->rev_var_type_map[t], typ))

MPB.freemodel!(m::KnitroMathProgModel) = freeProblem(m.inner)
