importall MathProgBase.SolverInterface

###############################################################################
# Solver objects
export KnitroSolver
immutable KnitroSolver <: AbstractMathProgSolver
  options
end
KnitroSolver(;kwargs...) = KnitroSolver(kwargs)

type KnitroMathProgModel <: AbstractMathProgModel
  inner
  options
end
function KnitroMathProgModel(;options...)
  KnitroMathProgModel(nothing,options)
end
model(s::KnitroSolver) = KnitroMathProgModel(;s.options...)
export model

###############################################################################
# Begin interface implementation

function sparse_merge_hess_duplicates(I,J, m, n)
  V = [Int[i] for i in 1:length(I)]
  for i in 1:length(I) # make upper triangular
    if I[i] > J[i]
      I[i],J[i] = J[i],I[i]
    end
  end
  findnz(sparse(I,J,V,m,n,vcat))
end

function sparse_merge_jac_duplicates(I,J, m, n)
  V = [Int[i] for i in 1:length(I)]
  findnz(sparse(I,J,V,m,n,vcat))
end

# generic nonlinear interface
function loadnonlinearproblem!(m::KnitroMathProgModel,
                               numVar::Integer,
                               numConstr::Integer,
                               x_l, x_u, g_lb, g_ub,
                               sense::Symbol,
                               d::AbstractNLPEvaluator)

  initialize(d, [:Grad, :Jac, :Hess])
  Ijac, Jjac = jac_structure(d)
  Ihess, Jhess = hesslag_structure(d)
  nnzJ = length(Ijac)
  nnzH = length(Ihess)
  jac_tmp = Array(Float64, nnzJ)
  hess_tmp = Array(Float64, nnzH)
  @assert length(Ijac) == length(Jjac)
  @assert length(Ihess) == length(Jhess)
  jac_con, jac_var, jac_indices = sparse_merge_jac_duplicates(Ijac, Jjac, numConstr, numVar)
  hess_row, hess_col, hess_indices = sparse_merge_hess_duplicates(Ihess, Jhess, numVar, numVar)
  n_jac_indices = length(jac_indices)
  n_hess_indices = length(hess_indices)

  x_l, x_u, g_lb, g_ub = float(x_l), float(x_u), float(g_lb), float(g_ub)
  @assert length(x_l) == length(x_u)
  @assert length(g_lb) == length(g_ub)
  for i in 1:length(x_l)
    if x_l[i] == -Inf
      x_l[i] = -KTR_INFBOUND
    end
    if x_u[i] == Inf
      x_u[i] = KTR_INFBOUND
    end
  end

  for i in 1:length(g_lb)
    if g_lb[i] == -Inf
      g_lb[i] = -KTR_INFBOUND
    end
    if g_ub[i] == Inf
      g_ub[i] = KTR_INFBOUND
    end
  end

  @assert sense == :Min || sense == :Max

  # Objective sense
  if sense == :Min
    objGoal = KTR_OBJGOAL_MINIMIZE
  else
    objGoal = KTR_OBJGOAL_MAXIMIZE
  end
  # allow for the possibility of specializing to LINEAR or QUADRATIC?
  objType = KTR_OBJTYPE_GENERAL
  c_Type = fill(KTR_CONTYPE_GENERAL, numConstr)
  
  # Objective callback
  if sense == :Min
    eval_f_cb(x) = eval_f(d,x)
  else
    eval_f_cb(x) = -eval_f(d,x)
  end

  # Objective gradient callback
  if sense == :Min
      eval_grad_f_cb(x, grad_f) = eval_grad_f(d, grad_f, x)
  else
      eval_grad_f_cb(x, grad_f) = (eval_grad_f(d, grad_f, x); scale!(grad_f,-1))
  end

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
  eval_hv_cb(x, lambda, sigma, hv) = eval_hesslag_prod(d, hv, x, sigma, lambda)

  m.inner = createProblem()
  # ---
  # set options/parameters here
  # ---
  initializeProblem(m.inner, objGoal, objType, x_l, x_u, c_Type, g_lb, g_ub,
                    int32(jac_var-1), int32(jac_con-1), int32(hess_row-1), int32(hess_col-1))
  setCallbacks(m.inner, eval_f_cb, eval_g_cb, eval_grad_f_cb,
               eval_jac_g_cb, eval_h_cb, eval_hv_cb)
end

getsense(m::KnitroMathProgModel) = int32(m.inner.sense)
numvar(m::KnitroMathProgModel) = int32(m.inner.n)
numconstr(m::KnitroMathProgModel) = int32(m.inner.m)
optimize!(m::KnitroMathProgModel) = solveProblem(m.inner)

function status(m::KnitroMathProgModel)
  applicationReturnStatus(m.inner)
end

getobjval(m::KnitroMathProgModel) = m.inner.obj_val[1] * (m.inner.sense == :Max ? -1 : +1)
getsolution(m::KnitroMathProgModel) = m.inner.x
getconstrsolution(m::KnitroMathProgModel) = m.inner.g
getreducedcosts(m::KnitroMathProgModel) = zeros(m.inner.n)
getconstrduals(m::KnitroMathProgModel) = zeros(m.inner.m)
getrawsolver(m::KnitroMathProgModel) = m.inner
setwarmstart!(m::KnitroMathProgModel, x) = copy!(m.inner.x, x) # starting point