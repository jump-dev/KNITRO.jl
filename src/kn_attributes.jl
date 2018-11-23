# Knitro model attributes


##################################################
# objective
##################################################

# set objective sense
function KN_set_obj_goal(m::Model, objgoal::Cint)
    ret = @kn_ccall(set_obj_goal, Cint, (Ptr{Nothing}, Cint),
                    m.env.ptr_env.x, objgoal)
    _checkraise(ret)
end

function KN_add_obj_linear_struct(m::Model,
                                  objIndices::Vector{Cint},
                                  objCoefs::Vector{Cdouble})
    nnz = length(objIndices)

    ret = @kn_ccall(add_obj_linear_struct, Cint,
                    (Ptr{Nothing}, Cint, Ptr{Cint}, Ptr{Cdouble}),
                    m.env.ptr_env.x,
                    nnz,
                    objIndices,
                    objCoefs)
    _checkraise(ret)
end


# quadratic part of objective
function KN_add_obj_quadratic_struct(m::Model,
                                     indexVars1::Vector{Cint},
                                     indexVars2::Vector{Cint},
                                     coefs::Vector{Cdouble})
    nnz = length(indexVars1)
    @assert nnz = length(indexVars2) == length(coefs)

    ret = @kn_ccall(add_obj_quadratic_struct, Cint,
                    (Ptr{Nothing}, Cint, Ptr{Cint}, Ptr{Cint}, Ptr{Cdouble}),
                    m.env.ptr_env.x,
                    nnz,
                    indexVars1,
                    indexVars2,
                    coefs)
    _checkraise(ret)
end

function KN_add_obj_constant(m::Model, constant::Cdouble)
    ret = @kn_ccall(add_obj_constant, Cint, (Ptr{Nothing}, Cdouble),
                    m.env.ptr_env.x, constant)
    _checkraise(ret)
end

function KN_set_obj_scaling(m::Model, objScaleFactor::Cdouble)
    ret = @kn_ccall(set_obj_scaling, Cint, (Ptr{Nothing}, Cdouble),
                    m.env.ptr_env.x, objScaleFactor)
    _checkraise(ret)
end

function KN_set_obj_name(m::Model, name::AbstractString)
    ret = @kn_ccall(set_obj_name, Cint, (Ptr{Nothing}, Ptr{Cchar}),
                    m.env.ptr_env.x, name)
    _checkraise(ret)
end


##################################################
# Generic getters
##################################################
function KN_get_number_vars(m::Model)
    num_vars = Cint[0]
    ret = @kn_ccall(get_number_vars, Cint, (Ptr{Nothing}, Ptr{Cint}),
                    m.env.ptr_env.x, num_vars)
    _checkraise(ret)
    return num_vars[1]
end

function KN_get_number_cons(m::Model)
    num_cons = Cint[0]
    ret = @kn_ccall(get_number_cons, Cint, (Ptr{Nothing}, Ptr{Cint}),
                    m.env.ptr_env.x, num_cons)
    _checkraise(ret)
    return num_cons[1]
end

function KN_get_obj_value(m::Model)
    obj = Cdouble[0]
    ret = @kn_ccall(get_obj_value, Cint, (Ptr{Nothing}, Ptr{Cdouble}),
                    m.env.ptr_env.x, obj)
    _checkraise(ret)
    return obj[1]
end

function KN_get_obj_type(m::Model)
    obj_type = Cint[0]
    ret = @kn_ccall(get_obj_type, Cint, (Ptr{Nothing}, Ptr{Cint}), m.env.ptr_env.x, obj_type)
    _checkraise(ret)
    return obj_type[1]
end


##################################################
# Constraints getters
##################################################
function KN_get_con_values(m::Model)
    nc = KN_get_number_cons(m)
    consvals = zeros(Cdouble, nc)
    ret = @kn_ccall(get_con_values_all, Cint, (Ptr{Nothing}, Ptr{Cdouble}),
                    m.env.ptr_env.x, consvals)
    _checkraise(ret)
    return consvals
end

function KN_get_con_values(m::Model, cIndex::Integer)
    nc = 1
    consvals = zeros(Cdouble, nc)
    ret = @kn_ccall(get_con_value, Cint, (Ptr{Nothing}, Cint, Ptr{Cdouble}),
                    m.env.ptr_env.x, cIndex, consvals)
    _checkraise(ret)
    return consvals[1]
end

function KN_get_con_types(m::Model)
    nc = KN_get_number_cons(m)
    constypes = zeros(Cint, nc)
    ret = @kn_ccall(get_con_types_all, Cint, (Ptr{Nothing}, Ptr{Cint}),
                    m.env.ptr_env.x, constypes)
    _checkraise(ret)
    return constypes
end

##################################################
# Continuous optimization results
##################################################
function KN_get_number_iters(m::Model)
    num_iters = Cint[0]
    ret = @kn_ccall(get_number_iters, Cint, (Ptr{Nothing}, Ptr{Cint}),
                    m.env.ptr_env.x, num_iters)
    _checkraise(ret)
    return num_iters[1]
end

function KN_get_number_cg_iters(m::Model)
    num_iters = Cint[0]
    ret = @kn_ccall(get_number_cg_iters, Cint, (Ptr{Nothing}, Ptr{Cint}),
                    m.env.ptr_env.x, num_iters)
    _checkraise(ret)
    return num_iters[1]
end

function KN_get_abs_feas_error(m::Model)
    res = Cdouble[0]
    ret = @kn_ccall(get_abs_feas_error, Cint, (Ptr{Nothing}, Ptr{Cdouble}),
                    m.env.ptr_env.x, res)
    _checkraise(ret)
    return res[1]
end

function KN_get_rel_feas_error(m::Model)
    res = Cdouble[0]
    ret = @kn_ccall(get_rel_feas_error, Cint, (Ptr{Nothing}, Ptr{Cdouble}),
                    m.env.ptr_env.x, res)
    _checkraise(ret)
    return res[1]
end

function KN_get_abs_opt_error(m::Model)
    res = Cdouble[0]
    ret = @kn_ccall(get_abs_opt_error, Cint, (Ptr{Nothing}, Ptr{Cdouble}),
                    m.env.ptr_env.x, res)
    _checkraise(ret)
    return res[1]
end

function KN_get_rel_opt_error(m::Model)
    res = Cdouble[0]
    ret = @kn_ccall(get_rel_opt_error, Cint, (Ptr{Nothing}, Ptr{Cdouble}),
                    m.env.ptr_env.x, res)
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
    ret = @kn_ccall(get_objgrad_nnz, Cint, (Ptr{Nothing}, Ptr{Cint}),
                    m.env.ptr_env.x, res)
    _checkraise(ret)
    return res[1]
end

function KN_get_objgrad_values(m::Model)
    nnz = KN_get_objgrad_nnz(m)
    indexVars = zeros(Cint, nnz)
    objGrad = zeros(Cdouble, nnz)
    ret = @kn_ccall(get_objgrad_values, Cint,
                    (Ptr{Nothing}, Ptr{Cint}, Ptr{Cdouble}),
                    m.env.ptr_env.x, indexVars, objGrad)
    _checkraise(ret)
    return indexVars, objGrad
end


#--------------------
# Jacobian
#--------------------
function KN_get_jacobian_nnz(m::Model)
    res = Cint[0]
    ret = @kn_ccall(get_jacobian_nnz, Cint, (Ptr{Nothing}, Ptr{Cint}),
                    m.env.ptr_env.x, res)
    _checkraise(ret)
    return res[1]
end

function KN_get_jacobian_values(m::Model)
    nnz = KN_get_jacobian_nnz(m)
    jacvars = zeros(Cint, nnz)
    jaccons = zeros(Cint, nnz)
    jaccoef = zeros(Cdouble, nnz)
    ret = @kn_ccall(get_jacobian_values, Cint,
                    (Ptr{Nothing}, Ptr{Cint}, Ptr{Cint}, Ptr{Cdouble}),
                    m.env.ptr_env.x, jacvars, jaccons, jaccoef)
    _checkraise(ret)
    return jacvars, jaccons, jaccoef
end

#--------------------
# Rsd Jacobian
#--------------------
function KN_get_rsd_jacobian_nnz(m::Model)
    res = Cint[0]
    ret = @kn_ccall(get_rsd_jacobian_nnz, Cint, (Ptr{Nothing}, Ptr{Cint}),
                    m.env.ptr_env.x, res)
    _checkraise(ret)
    return res[1]
end

function KN_get_rsd_jacobian_values(m::Model)
    nnz = KN_get_rsd_jacobian_nnz(m)
    jacvars = zeros(Cint, nnz)
    jaccons = zeros(Cint, nnz)
    jaccoef = zeros(Cdouble, nnz)
    ret = @kn_ccall(get_rsd_jacobian_values, Cint,
                    (Ptr{Nothing}, Ptr{Cint}, Ptr{Cint}, Ptr{Cdouble}),
                    m.env.ptr_env.x, jacvars, jaccons, jaccoef)
    _checkraise(ret)
    return jacvars, jaccons, jaccoef
end


#--------------------
# Hessian
#--------------------
function KN_get_hessian_nnz(m::Model)
    res = Cint[0]
    ret = @kn_ccall(get_hessian_nnz, Cint, (Ptr{Nothing}, Ptr{Cint}),
                    m.env.ptr_env.x, res)
    _checkraise(ret)
    return res[1]
end

function KN_get_hessian_values(m::Model)
    nnz = KN_get_hessian_nnz(m)
    indexVars1 = zeros(Cint, nnz)
    indexVars2 = zeros(Cint, nnz)
    hess = zeros(Cdouble, nnz)
    ret = @kn_ccall(get_hessian_values, Cint,
                    (Ptr{Nothing}, Ptr{Cint}, Ptr{Cint}, Ptr{Cdouble}),
                    m.env.ptr_env.x, indexVars1, indexVars2, hess)
    _checkraise(ret)
    return indexVars1, indexVars2, hess
end



##################################################
# MIP utils
##################################################
#--------------------
# Getters
#--------------------
function KN_get_mip_number_nodes(m::Model)
    res = Cint[0]
    ret = @kn_ccall(get_mip_number_nodes, Cint, (Ptr{Nothing}, Ptr{Cint}),
                    m.env.ptr_env.x, res)
    _checkraise(ret)
    return res[1]
end

function KN_get_mip_number_solves(m::Model)
    res = Cint[0]
    ret = @kn_ccall(get_mip_number_solves, Cint, (Ptr{Nothing}, Ptr{Cint}),
                    m.env.ptr_env.x, res)
    _checkraise(ret)
    return res[1]
end

function KN_get_mip_abs_gap(m::Model)
    res = Cdouble[0]
    ret = @kn_ccall(get_mip_abs_gap, Cint, (Ptr{Nothing}, Ptr{Cdouble}),
                    m.env.ptr_env.x, res)
    _checkraise(ret)
    return res[1]
end

function KN_get_mip_rel_gap(m::Model)
    res = Cdouble[0]
    ret = @kn_ccall(get_mip_rel_gap, Cint, (Ptr{Nothing}, Ptr{Cdouble}),
                    m.env.ptr_env.x, res)
    _checkraise(ret)
    return res[1]
end

function KN_get_mip_incumbent_obj(m::Model)
    res = Cdouble[0]
    ret = @kn_ccall(get_mip_incumbent_obj, Cint, (Ptr{Nothing}, Ptr{Cdouble}),
                    m.env.ptr_env.x, res)
    _checkraise(ret)
    return res[1]
end

function KN_get_mip_relaxation_bnd(m::Model)
    res = Cdouble[0]
    ret = @kn_ccall(get_mip_relaxation_bnd, Cint, (Ptr{Nothing}, Ptr{Cdouble}),
                    m.env.ptr_env.x, res)
    _checkraise(ret)
    return res[1]
end

function KN_get_mip_lastnode_obj(m::Model)
    res = Cdouble[0]
    ret = @kn_ccall(get_mip_lastnode_obj, Cint, (Ptr{Nothing}, Ptr{Cdouble}),
                    m.env.ptr_env.x, res)
    _checkraise(ret)
    return res[1]
end

function KN_get_mip_incumbent_x(m::Model)
    res = Cdouble[0]
    ret = @kn_ccall(get_mip_incumbent_x, Cint, (Ptr{Nothing}, Ptr{Cdouble}),
                    m.env.ptr_env.x, res)
    _checkraise(ret)
    return res[1]
end

#--------------------
# Branching priorities
#--------------------
function KN_set_mip_branching_priorities(m::Model, nindex::Integer, xPriorities::Cint)
    ret = @kn_ccall(set_mip_branching_priority, Cint,
                    (Ptr{Nothing}, Cint, Cint),
                    m.env.ptr_env.x, nindex, xPriorities)
    _checkraise(ret)
end

function KN_set_mip_branching_priorities(m::Model, xIndex::Vector{Cint}, xPriorities::Vector{Cint})
    nvar = length(xIndex)
    @assert nvar == length(xPriorities)
    ret = @kn_ccall(set_mip_branching_priorities, Cint,
                    (Ptr{Nothing}, Cint, Ptr{Cint}, Ptr{Cint}),
                    m.env.ptr_env.x, nvar, xIndex, xPriorities)
    _checkraise(ret)
end

function KN_set_mip_branching_priorities(m::Model, xPriorities::Vector{Cint})
    ret = @kn_ccall(set_mip_branching_priorities_all, Cint, (Ptr{Nothing}, Ptr{Cint}),
                    m.env.ptr_env.x, xPriorities)
    _checkraise(ret)
end


#--------------------
# Intvar strategies
#--------------------
function KN_set_mip_intvar_strategies(m::Model, nindex::Integer, xStrategies::Cint)
    ret = @kn_ccall(set_mip_intvar_strategy, Cint,
                    (Ptr{Nothing}, Cint, Cint),
                    m.env.ptr_env.x, nindex, xStrategies)
    _checkraise(ret)
end

function KN_set_mip_intvar_strategies(m::Model, xIndex::Vector{Cint}, xStrategies::Vector{Cint})
    nvar = length(xIndex)
    @assert nvar == length(xStrategies)
    ret = @kn_ccall(set_mip_intvar_strategies, Cint,
                    (Ptr{Nothing}, Cint, Ptr{Cint}, Ptr{Cint}),
                    m.env.ptr_env.x, nvar, xIndex, xStrategies)
    _checkraise(ret)
end

function KN_set_mip_intvar_strategies(m::Model, xStrategies::Vector{Cint})
    ret = @kn_ccall(set_mip_intvar_strategies_all, Cint, (Ptr{Nothing}, Ptr{Cint}),
                    m.env.ptr_env.x, xStrategies)
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
    ret = @kn_ccall(set_int_param, Cint, (Ptr{Nothing}, Cint, Cint),
                    m.env.ptr_env.x, id, value)
    _checkraise(ret)
end

function KN_set_param(m::Model, param::AbstractString, value::Integer)
    ret = @kn_ccall(set_int_param_by_name, Cint, (Ptr{Nothing}, Ptr{Cchar}, Cint),
                    m.env.ptr_env.x, param, value)
    _checkraise(ret)
end

# Double params
function KN_set_param(m::Model, id::Integer, value::Cdouble)
    ret = @kn_ccall(set_double_param, Cint, (Ptr{Nothing}, Cint, Cdouble),
                    m.env.ptr_env.x, id, value)
    _checkraise(ret)
end

function KN_set_param(m::Model, param::AbstractString, value::Cdouble)
    ret = @kn_ccall(set_double_param_by_name, Cint, (Ptr{Nothing}, Ptr{Cchar}, Cdouble),
                    m.env.ptr_env.x, param, value)
    _checkraise(ret)
end

# Char params
function KN_set_param(m::Model, id::Integer, value::AbstractString)
    ret = @kn_ccall(set_char_param, Cint, (Ptr{Nothing}, Cint, Ptr{Cchar}),
                    m.env.ptr_env.x, id, value)
    _checkraise(ret)
end

function KN_set_param(m::Model, param::AbstractString, value::AbstractString)
    ret = @kn_ccall(set_char_param_by_name, Cint, (Ptr{Nothing}, Ptr{Cchar}, Ptr{Cchar}),
                    m.env.ptr_env.x, param, value)
    _checkraise(ret)
end


#------------------------------
# Getters
#------------------------------

# Int params
function KN_get_int_param(m::Model, id::Integer)
    res = Cint[0]
    ret = @kn_ccall(get_int_param, Cint, (Ptr{Nothing}, Cint, Ptr{Cint}),
                    m.env.ptr_env.x, id, res)
    _checkraise(ret)
    return res[1]
end

function KN_get_int_param(m::Model, param::AbstractString)
    res = Cint[0]
    ret = @kn_ccall(get_int_param_by_name, Cint, (Ptr{Nothing}, Ptr{Cchar}, Ptr{Cint}),
                    m.env.ptr_env.x, param, res)
    _checkraise(ret)
    return res[1]
end

# Double params
function KN_get_double_param(m::Model, id::Integer)
    res = Cdouble[0.]
    ret = @kn_ccall(get_double_param, Cint, (Ptr{Nothing}, Cint, Ptr{Cdouble}),
                    m.env.ptr_env.x, id, res)
    _checkraise(ret)
    return res[1]
end

function KN_get_double_param(m::Model, param::AbstractString)
    res = Cdouble[0.]
    ret = @kn_ccall(get_double_param_by_name, Cint, (Ptr{Nothing}, Ptr{Cchar}, Ptr{Cdouble}),
                    m.env.ptr_env.x, param, res)
    _checkraise(ret)
    return res[1]
end


#------------------------------
# Params information
#------------------------------
function KN_get_param_name(m::Model, id::Integer)
    output_size = 128
    res = " "^output_size
    ret = @kn_ccall(get_param_name, Cint, (Ptr{Nothing}, Cint, Ptr{Cchar}, Csize_t),
                    m.env.ptr_env.x, id, res, output_size)
    _checkraise(ret)
    return format_output(res)
end

function KN_get_param_doc(m::Model, id::Integer)
    output_size = 128
    res = " "^output_size
    ret = @kn_ccall(get_param_doc, Cint, (Ptr{Nothing}, Cint, Ptr{Cchar}, Csize_t),
                    m.env.ptr_env.x, id, res, output_size)
    _checkraise(ret)
    return format_output(res)
end

function KN_get_param_type(m::Model, id::Integer)
    res = Cint[0]
    ret = @kn_ccall(get_param_type, Cint, (Ptr{Nothing}, Cint, Ptr{Cint}),
                    m.env.ptr_env.x, id, res)
    _checkraise(ret)
    return res[1]
end

function KN_get_num_param_values(m::Model, id::Integer)
    res = Cint[0]
    ret = @kn_ccall(get_num_param_values, Cint, (Ptr{Nothing}, Cint, Ptr{Cint}),
                    m.env.ptr_env.x, id, res)
    _checkraise(ret)
    return res[1]
end

function KN_get_param_value_doc(m::Model, id::Integer, value_id::Integer)
    output_size = 128
    res = " "^output_size
    ret = @kn_ccall(get_param_value_doc, Cint,
                    (Ptr{Nothing}, Cint, Cint, Ptr{Cchar}, Csize_t),
                    m.env.ptr_env.x, id, value_id, res, output_size)
    _checkraise(ret)
    return format_output(res)
end

function KN_get_param_id(m::Model, name::AbstractString)
    res = Cint[0]
    ret = @kn_ccall(get_param_id, Cint, (Ptr{Nothing}, Ptr{Cchar}, Ptr{Cint}),
                    m.env.ptr_env.x, name, res)
    _checkraise(ret)
    return res[1]
end
