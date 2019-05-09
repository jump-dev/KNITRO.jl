# Knitro model attributes


##################################################
# objective
##################################################
# set objective sense
"Set objective goal."
function KN_set_obj_goal(m::Model, objgoal::Cint)
    ret = @kn_ccall(set_obj_goal, Cint, (Ptr{Cvoid}, Cint),
                    m.env, objgoal)
    _checkraise(ret)
end

"""
Add linear structure to the objective function.
Each component i of arrays indexVars and coefs adds a linear term
   coefs[i]*x[indexVars[i]]
to the objective.

"""
function KN_add_obj_linear_struct(m::Model,
                                  objIndices::Vector{Cint},
                                  objCoefs::Vector{Cdouble})
    nnz = length(objIndices)
    @assert nnz == length(objCoefs)
    ret = @kn_ccall(add_obj_linear_struct, Cint,
                    (Ptr{Cvoid}, KNLONG, Ptr{Cint}, Ptr{Cdouble}),
                    m.env,
                    nnz,
                    objIndices,
                    objCoefs)
    _checkraise(ret)
end
KN_add_obj_linear_struct(m::Model, objindex::Int, objCoefs::Cdouble) =
    KN_add_obj_linear_struct(m, Cint[objindex], [objCoefs])

# quadratic part of objective
"""
Add quadratic structure to the objective function.
Each component i of arrays indexVars1, indexVars2 and coefs adds a quadratic
term
   coefs[i]*x[indexVars1[i]]*x[indexVars2[i]]
to the objective.

Note: if indexVars2[i] is < 0 then it adds a linear term
      coefs[i]*x[indexVars1[i]] instead.

"""
function KN_add_obj_quadratic_struct(m::Model,
                                     indexVars1::Vector{Cint},
                                     indexVars2::Vector{Cint},
                                     coefs::Vector{Cdouble})
    nnz = length(indexVars1)
    @assert nnz == length(indexVars2) == length(coefs)
    ret = @kn_ccall(add_obj_quadratic_struct, Cint,
                    (Ptr{Cvoid}, KNLONG, Ptr{Cint}, Ptr{Cint}, Ptr{Cdouble}),
                    m.env,
                    nnz,
                    indexVars1,
                    indexVars2,
                    coefs)
    _checkraise(ret)
end

function KN_add_obj_constant(m::Model, constant::Cdouble)
    ret = @kn_ccall(add_obj_constant, Cint, (Ptr{Cvoid}, Cdouble),
                    m.env, constant)
    _checkraise(ret)
end

function KN_set_obj_scaling(m::Model, objScaleFactor::Cdouble)
    ret = @kn_ccall(set_obj_scaling, Cint, (Ptr{Cvoid}, Cdouble),
                    m.env, objScaleFactor)
    _checkraise(ret)
end

"""
Specify some properties of the objective and constraint functions.
Note: use bit-wise specification of the features:
bit value   meaning
  0     1   KN_OBJ_CONVEX/KN_CON_CONVEX
  1     2   KN_OBJ_CONCAVE/KN_CON_CONCAVE
  2     4   KN_OBJ_CONTINUOUS/KN_CON_CONTINUOUS
  3     8   KN_OBJ_DIFFERENTIABLE/KN_CON_DIFFERENTIABLE
  4    16   KN_OBJ_TWICE_DIFFERENTIABLE/KN_CON_TWICE_DIFFERENTIABLE
  5    32   KN_OBJ_NOISY/KN_CON_NOISY
  6    64   KN_OBJ_NONDETERMINISTIC/KN_CON_NONDETERMINISTIC

"""
function KN_set_obj_property(m::Model, objProperty::Cint)
    ret = @kn_ccall(set_obj_property, Cint, (Ptr{Cvoid}, Cint),
                    m.env, objProperty)
    _checkraise(ret)
end

function KN_set_obj_name(m::Model, name::AbstractString)
    ret = @kn_ccall(set_obj_name, Cint, (Ptr{Cvoid}, Ptr{Cchar}),
                    m.env, name)
    _checkraise(ret)
end

##################################################
# Generic getters
##################################################
function KN_get_number_vars(m::Model)
    num_vars = Cint[0]
    ret = @kn_ccall(get_number_vars, Cint, (Ptr{Cvoid}, Ptr{Cint}),
                    m.env, num_vars)
    _checkraise(ret)
    return num_vars[1]
end

function KN_get_number_cons(m::Model)
    num_cons = Cint[0]
    ret = @kn_ccall(get_number_cons, Cint, (Ptr{Cvoid}, Ptr{Cint}),
                    m.env, num_cons)
    _checkraise(ret)
    return num_cons[1]
end

function KN_get_obj_value(m::Model)
    obj = Cdouble[0]
    ret = @kn_ccall(get_obj_value, Cint, (Ptr{Cvoid}, Ptr{Cdouble}),
                    m.env, obj)
    _checkraise(ret)
    return obj[1]
end

function KN_get_obj_type(m::Model)
    obj_type = Cint[0]
    ret = @kn_ccall(get_obj_type, Cint, (Ptr{Cvoid}, Ptr{Cint}), m.env, obj_type)
    _checkraise(ret)
    return obj_type[1]
end

##################################################
# Constraints getters
##################################################
function KN_get_con_values(m::Model)
    nc = KN_get_number_cons(m)
    consvals = zeros(Cdouble, nc)
    ret = @kn_ccall(get_con_values_all, Cint, (Ptr{Cvoid}, Ptr{Cdouble}),
                    m.env, consvals)
    _checkraise(ret)
    return consvals
end

function KN_get_con_values(m::Model, cIndex::Integer)
    nc = 1
    consvals = zeros(Cdouble, nc)
    ret = @kn_ccall(get_con_value, Cint, (Ptr{Cvoid}, Cint, Ptr{Cdouble}),
                    m.env, cIndex, consvals)
    _checkraise(ret)
    return consvals[1]
end

function KN_get_con_types(m::Model)
    nc = KN_get_number_cons(m)
    constypes = zeros(Cint, nc)
    ret = @kn_ccall(get_con_types_all, Cint, (Ptr{Cvoid}, Ptr{Cint}),
                    m.env, constypes)
    _checkraise(ret)
    return constypes
end

##################################################
# Continuous optimization results
##################################################
"""
Return the number of iterations made by KN_solve in "numIters".
"""
function KN_get_number_iters(m::Model)
    num_iters = Cint[0]
    ret = @kn_ccall(get_number_iters, Cint, (Ptr{Cvoid}, Ptr{Cint}),
                    m.env, num_iters)
    _checkraise(ret)
    return num_iters[1]
end

"""
Return the number of conjugate gradient (CG) iterations made by
KN_solve in "numCGiters".

"""
function KN_get_number_cg_iters(m::Model)
    num_iters = Cint[0]
    ret = @kn_ccall(get_number_cg_iters, Cint, (Ptr{Cvoid}, Ptr{Cint}),
                    m.env, num_iters)
    _checkraise(ret)
    return num_iters[1]
end

"""
Return the absolute feasibility error at the solution in "absFeasError".
Refer to the Knitro manual section on Termination Tests for a
detailed definition of this quantity.

"""
function KN_get_abs_feas_error(m::Model)
    res = Cdouble[0]
    ret = @kn_ccall(get_abs_feas_error, Cint, (Ptr{Cvoid}, Ptr{Cdouble}),
                    m.env, res)
    _checkraise(ret)
    return res[1]
end

"""
Return the relative feasibility error at the solution in "relFeasError".
Refer to the Knitro manual section on Termination Tests for a
detailed definition of this quantity.

"""
function KN_get_rel_feas_error(m::Model)
    res = Cdouble[0]
    ret = @kn_ccall(get_rel_feas_error, Cint, (Ptr{Cvoid}, Ptr{Cdouble}),
                    m.env, res)
    _checkraise(ret)
    return res[1]
end

"""
Return the absolute optimality error at the solution in "absOptError".
Refer to the Knitro manual section on Termination Tests for a
detailed definition of this quantity.

"""
function KN_get_abs_opt_error(m::Model)
    res = Cdouble[0]
    ret = @kn_ccall(get_abs_opt_error, Cint, (Ptr{Cvoid}, Ptr{Cdouble}),
                    m.env, res)
    _checkraise(ret)
    return res[1]
end

"""
Return the relative optimality error at the solution in "relOptError".
Refer to the Knitro manual section on Termination Tests for a
detailed definition of this quantity.

"""
function KN_get_rel_opt_error(m::Model)
    res = Cdouble[0]
    ret = @kn_ccall(get_rel_opt_error, Cint, (Ptr{Cvoid}, Ptr{Cdouble}),
                    m.env, res)
    _checkraise(ret)
    return res[1]
end

##################################################
# Fetch solution utils
##################################################
#--------------------
# Objective gradient
#--------------------
function KN_get_objgrad_nnz(m::Model)
    res = Cint[0]
    ret = @kn_ccall(get_objgrad_nnz, Cint, (Ptr{Cvoid}, Ptr{Cint}),
                    m.env, res)
    _checkraise(ret)
    return res[1]
end

function KN_get_objgrad_values(m::Model)
    nnz = KN_get_objgrad_nnz(m)
    indexVars = zeros(Cint, nnz)
    objGrad = zeros(Cdouble, nnz)
    ret = @kn_ccall(get_objgrad_values, Cint,
                    (Ptr{Cvoid}, Ptr{Cint}, Ptr{Cdouble}),
                    m.env, indexVars, objGrad)
    _checkraise(ret)
    return indexVars, objGrad
end

#--------------------
# Jacobian
#--------------------
function KN_get_jacobian_nnz(m::Model)
    res = KNLONG[0]
    ret = @kn_ccall(get_jacobian_nnz, Cint, (Ptr{Cvoid}, Ptr{KNLONG}),
                    m.env, res)
    _checkraise(ret)
    return res[1]
end

function KN_get_jacobian_values(m::Model)
    nnz = KN_get_jacobian_nnz(m)
    jacvars = zeros(Cint, nnz)
    jaccons = zeros(Cint, nnz)
    jaccoef = zeros(Cdouble, nnz)
    ret = @kn_ccall(get_jacobian_values, Cint,
                    (Ptr{Cvoid}, Ptr{Cint}, Ptr{Cint}, Ptr{Cdouble}),
                    m.env, jacvars, jaccons, jaccoef)
    _checkraise(ret)
    return jacvars, jaccons, jaccoef
end

#--------------------
# Rsd Jacobian
#--------------------
function KN_get_rsd_jacobian_nnz(m::Model)
    res = KNLONG[0]
    ret = @kn_ccall(get_rsd_jacobian_nnz, Cint, (Ptr{Cvoid}, Ptr{KNLONG}),
                    m.env, res)
    _checkraise(ret)
    return res[1]
end

"""
Return the values of the residual Jacobian in "indexRsds", "indexVars",
and "rsdJac".  The Jacobian values returned correspond to the non-zero
sparse Jacobian indices provided by the user.

"""
function KN_get_rsd_jacobian_values(m::Model)
    nnz = KN_get_rsd_jacobian_nnz(m)
    jacvars = zeros(Cint, nnz)
    jaccons = zeros(Cint, nnz)
    jaccoef = zeros(Cdouble, nnz)
    ret = @kn_ccall(get_rsd_jacobian_values, Cint,
                    (Ptr{Cvoid}, Ptr{Cint}, Ptr{Cint}, Ptr{Cdouble}),
                    m.env, jacvars, jaccons, jaccoef)
    _checkraise(ret)
    return jacvars, jaccons, jaccoef
end

#--------------------
# Hessian
#--------------------
function KN_get_hessian_nnz(m::Model)
    res = KNLONG[0]
    ret = @kn_ccall(get_hessian_nnz, Cint, (Ptr{Cvoid}, Ptr{KNLONG}),
                    m.env, res)
    _checkraise(ret)
    return res[1]
end

function KN_get_hessian_values(m::Model)
    nnz = KN_get_hessian_nnz(m)
    indexVars1 = zeros(Cint, nnz)
    indexVars2 = zeros(Cint, nnz)
    hess = zeros(Cdouble, nnz)
    ret = @kn_ccall(get_hessian_values, Cint,
                    (Ptr{Cvoid}, Ptr{Cint}, Ptr{Cint}, Ptr{Cdouble}),
                    m.env, indexVars1, indexVars2, hess)
    _checkraise(ret)
    return indexVars1, indexVars2, hess
end

# Getters for CPU time are implemented only for Knitro version >= 12.0.
if KNITRO_VERSION >= v"12.0"
    function KN_get_solve_time_cpu(m::Model)
        tcpu = zeros(Cdouble, 1)
        ret = @kn_ccall(get_solve_time_cpu, Cint,
                        (Ptr{Cvoid}, Ptr{Cdouble}), m.env, tcpu)
        _checkraise(ret)
        return tcpu[1]
    end

    function KN_get_solve_time_real(m::Model)
        treal = zeros(Cdouble, 1)
        ret = @kn_ccall(get_solve_time_real, Cint,
                        (Ptr{Cvoid}, Ptr{Cdouble}), m.env, treal)
        _checkraise(ret)
        return treal[1]
    end
end
##################################################
# MIP utils
##################################################
#--------------------
# Getters
#--------------------
"""
Return the number of nodes processed in the MIP solve
in "numNodes".

"""
function KN_get_mip_number_nodes(m::Model)
    res = Cint[0]
    ret = @kn_ccall(get_mip_number_nodes, Cint, (Ptr{Cvoid}, Ptr{Cint}),
                    m.env, res)
    _checkraise(ret)
    return res[1]
end

"""
Return the number of continuous subproblems processed in the
MIP solve in "numSolves".

"""
function KN_get_mip_number_solves(m::Model)
    res = Cint[0]
    ret = @kn_ccall(get_mip_number_solves, Cint, (Ptr{Cvoid}, Ptr{Cint}),
                    m.env, res)
    _checkraise(ret)
    return res[1]
end

"""
Return the final absolute integrality gap in the MIP solve
in "absGap". Refer to the Knitro manual section on Termination
Tests for a detailed definition of this quantity. Set to
KN_INFINITY if no incumbent (i.e., integer feasible) point found.

"""
function KN_get_mip_abs_gap(m::Model)
    res = Cdouble[0]
    ret = @kn_ccall(get_mip_abs_gap, Cint, (Ptr{Cvoid}, Ptr{Cdouble}),
                    m.env, res)
    _checkraise(ret)
    return res[1]
end

"""
Return the final absolute integrality gap in the MIP solve
int "relGap". Refer to the Knitro manual section on Termination
Tests for a detailed definition of this quantity.  Set to
KN_INFINITY if no incumbent (i.e., integer feasible) point found.

"""
function KN_get_mip_rel_gap(m::Model)
    res = Cdouble[0]
    ret = @kn_ccall(get_mip_rel_gap, Cint, (Ptr{Cvoid}, Ptr{Cdouble}),
                    m.env, res)
    _checkraise(ret)
    return res[1]
end

"""
Return the objective value of the MIP incumbent solution in
"incumbentObj". Set to KN_INFINITY if no incumbent (i.e., integer
feasible) point found.

"""
function KN_get_mip_incumbent_obj(m::Model)
    res = Cdouble[0]
    ret = @kn_ccall(get_mip_incumbent_obj, Cint, (Ptr{Cvoid}, Ptr{Cdouble}),
                    m.env, res)
    _checkraise(ret)
    return res[1]
end

"""
Return the value of the current MIP relaxation bound in "relaxBound".

"""
function KN_get_mip_relaxation_bnd(m::Model)
    res = Cdouble[0]
    ret = @kn_ccall(get_mip_relaxation_bnd, Cint, (Ptr{Cvoid}, Ptr{Cdouble}),
                    m.env, res)
    _checkraise(ret)
    return res[1]
end

"""
Return the objective value of the most recently solved MIP
node subproblem in "lastNodeObj".

"""
function KN_get_mip_lastnode_obj(m::Model)
    res = Cdouble[0]
    ret = @kn_ccall(get_mip_lastnode_obj, Cint, (Ptr{Cvoid}, Ptr{Cdouble}),
                    m.env, res)
    _checkraise(ret)
    return res[1]
end

"Return the MIP incumbent solution in 'x' if one exists."
function KN_get_mip_incumbent_x(m::Model)
    res = Cdouble[0]
    ret = @kn_ccall(get_mip_incumbent_x, Cint, (Ptr{Cvoid}, Ptr{Cdouble}),
                    m.env, res)
    _checkraise(ret)
    return res[1]
end

#--------------------
# Branching priorities
#--------------------
"""
Set the branching priorities for integer variables. Must first
set the types of variables (e.g. by calling KN_set_var_types) before
calling this function. Priorities must be positive numbers
(variables with non-positive values are ignored).  Variables with
higher priority values will be considered for branching before
variables with lower priority values.  When priorities for a subset
of variables are equal, the branching rule is applied as a tiebreaker.
Values for continuous variables are ignored.  Knitro makes a local
copy of all inputs, so the application may free memory after the call.

"""
function KN_set_mip_branching_priorities(m::Model, nindex::Integer, xPriorities::Cint)
    ret = @kn_ccall(set_mip_branching_priority, Cint,
                    (Ptr{Cvoid}, Cint, Cint),
                    m.env, nindex, xPriorities)
    _checkraise(ret)
end

function KN_set_mip_branching_priorities(m::Model, xIndex::Vector{Cint}, xPriorities::Vector{Cint})
    nvar = length(xIndex)
    @assert nvar == length(xPriorities)
    ret = @kn_ccall(set_mip_branching_priorities, Cint,
                    (Ptr{Cvoid}, Cint, Ptr{Cint}, Ptr{Cint}),
                    m.env, nvar, xIndex, xPriorities)
    _checkraise(ret)
end

function KN_set_mip_branching_priorities(m::Model, xPriorities::Vector{Cint})
    ret = @kn_ccall(set_mip_branching_priorities_all, Cint, (Ptr{Cvoid}, Ptr{Cint}),
                    m.env, xPriorities)
    _checkraise(ret)
end

#--------------------
# Intvar strategies
#--------------------
"""
Set strategies for dealing with individual integer variables. Possible
strategy values include:
  KN_MIP_INTVAR_STRATEGY_NONE    0 (default)
  KN_MIP_INTVAR_STRATEGY_RELAX   1
  KN_MIP_INTVAR_STRATEGY_MPEC    2 (binary variables only)
indexVars should be an index value corresponding to an integer variable
(nothing is done if the index value corresponds to a continuous variable),
and xStrategies should correspond to one of the strategy values listed above.

"""
function KN_set_mip_intvar_strategies(m::Model, nindex::Integer, xStrategies::Cint)
    ret = @kn_ccall(set_mip_intvar_strategy, Cint,
                    (Ptr{Cvoid}, Cint, Cint),
                    m.env, nindex, xStrategies)
    _checkraise(ret)
end

function KN_set_mip_intvar_strategies(m::Model, xIndex::Vector{Cint}, xStrategies::Vector{Cint})
    nvar = length(xIndex)
    @assert nvar == length(xStrategies)
    ret = @kn_ccall(set_mip_intvar_strategies, Cint,
                    (Ptr{Cvoid}, Cint, Ptr{Cint}, Ptr{Cint}),
                    m.env, nvar, xIndex, xStrategies)
    _checkraise(ret)
end

function KN_set_mip_intvar_strategies(m::Model, xStrategies::Vector{Cint})
    ret = @kn_ccall(set_mip_intvar_strategies_all, Cint, (Ptr{Cvoid}, Ptr{Cint}),
                    m.env, xStrategies)
    _checkraise(ret)
end


##################################################
# Parameters
##################################################
#------------------------------
# Setters
#------------------------------
# Int params
function KN_set_param(m::Model, id::Integer, value::Integer)
    ret = @kn_ccall(set_int_param, Cint, (Ptr{Cvoid}, Cint, Cint),
                    m.env, id, value)
    _checkraise(ret)
end

function KN_set_param(m::Model, param::AbstractString, value::Integer)
    ret = @kn_ccall(set_int_param_by_name, Cint, (Ptr{Cvoid}, Ptr{Cchar}, Cint),
                    m.env, param, value)
    _checkraise(ret)
end

# Double params
function KN_set_param(m::Model, id::Integer, value::Cdouble)
    ret = @kn_ccall(set_double_param, Cint, (Ptr{Cvoid}, Cint, Cdouble),
                    m.env, id, value)
    _checkraise(ret)
end

function KN_set_param(m::Model, param::AbstractString, value::Cdouble)
    ret = @kn_ccall(set_double_param_by_name, Cint, (Ptr{Cvoid}, Ptr{Cchar}, Cdouble),
                    m.env, param, value)
    _checkraise(ret)
end

# Char params
function KN_set_param(m::Model, id::Integer, value::AbstractString)
    ret = @kn_ccall(set_char_param, Cint, (Ptr{Cvoid}, Cint, Ptr{Cchar}),
                    m.env, id, value)
    _checkraise(ret)
end

function KN_set_param(m::Model, param::AbstractString, value::AbstractString)
    ret = @kn_ccall(set_char_param_by_name, Cint, (Ptr{Cvoid}, Ptr{Cchar}, Ptr{Cchar}),
                    m.env, param, value)
    _checkraise(ret)
end

#------------------------------
# Getters
#------------------------------

# Int params
function KN_get_int_param(m::Model, id::Integer)
    res = Cint[0]
    ret = @kn_ccall(get_int_param, Cint, (Ptr{Cvoid}, Cint, Ptr{Cint}),
                    m.env, id, res)
    _checkraise(ret)
    return res[1]
end

function KN_get_int_param(m::Model, param::AbstractString)
    res = Cint[0]
    ret = @kn_ccall(get_int_param_by_name, Cint, (Ptr{Cvoid}, Ptr{Cchar}, Ptr{Cint}),
                    m.env, param, res)
    _checkraise(ret)
    return res[1]
end

# Double params
function KN_get_double_param(m::Model, id::Integer)
    res = Cdouble[0.]
    ret = @kn_ccall(get_double_param, Cint, (Ptr{Cvoid}, Cint, Ptr{Cdouble}),
                    m.env, id, res)
    _checkraise(ret)
    return res[1]
end

function KN_get_double_param(m::Model, param::AbstractString)
    res = Cdouble[0.]
    ret = @kn_ccall(get_double_param_by_name, Cint, (Ptr{Cvoid}, Ptr{Cchar}, Ptr{Cdouble}),
                    m.env, param, res)
    _checkraise(ret)
    return res[1]
end

#------------------------------
# Params information
#------------------------------
function KN_get_param_name(m::Model, id::Integer)
    output_size = 128
    res = " "^output_size
    ret = @kn_ccall(get_param_name, Cint, (Ptr{Cvoid}, Cint, Ptr{Cchar}, Csize_t),
                    m.env, id, res, output_size)
    _checkraise(ret)
    return format_output(res)
end

function KN_get_param_doc(m::Model, id::Integer)
    output_size = 128
    res = " "^output_size
    ret = @kn_ccall(get_param_doc, Cint, (Ptr{Cvoid}, Cint, Ptr{Cchar}, Csize_t),
                    m.env, id, res, output_size)
    _checkraise(ret)
    return format_output(res)
end

function KN_get_param_type(m::Model, id::Integer)
    res = Cint[0]
    ret = @kn_ccall(get_param_type, Cint, (Ptr{Cvoid}, Cint, Ptr{Cint}),
                    m.env, id, res)
    _checkraise(ret)
    return res[1]
end

function KN_get_num_param_values(m::Model, id::Integer)
    res = Cint[0]
    ret = @kn_ccall(get_num_param_values, Cint, (Ptr{Cvoid}, Cint, Ptr{Cint}),
                    m.env, id, res)
    _checkraise(ret)
    return res[1]
end

function KN_get_param_value_doc(m::Model, id::Integer, value_id::Integer)
    output_size = 128
    res = " "^output_size
    ret = @kn_ccall(get_param_value_doc, Cint,
                    (Ptr{Cvoid}, Cint, Cint, Ptr{Cchar}, Csize_t),
                    m.env, id, value_id, res, output_size)
    _checkraise(ret)
    return format_output(res)
end

function KN_get_param_id(m::Model, name::AbstractString)
    res = Cint[0]
    ret = @kn_ccall(get_param_id, Cint, (Ptr{Cvoid}, Ptr{Cchar}, Ptr{Cint}),
                    m.env, name, res)
    _checkraise(ret)
    return res[1]
end


function Base.show(io::IO, m::Model)
    if is_valid(m)
        println(io, "$(get_release())")
        println(io, "-----------------------")
        println(io, "Problem Characteristics")
        println(io, "-----------------------")
        println(io, "Objective goal:  Minimize")
        println(io, "Objective type:  $(KN_get_obj_type(m))")
        println(io, "Number of variables:                             $(KN_get_number_vars(m))")
        println(io, "Number of constraints:                           $(KN_get_number_cons(m))")
        println(io, "Number of nonzeros in Jacobian:                  $(KN_get_jacobian_nnz(m))")
        println(io, "Number of nonzeros in Hessian:                   $(KN_get_hessian_nnz(m))")

    else
        println(io, "KNITRO Problem: NULL")
    end
end
