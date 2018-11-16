# Knitro model attributes

##################################################
# Low level attribute getters/setters
##################################################



##################################################
# objective
#
# set objective sense
function KN_set_obj_goal(m::Model, objgoal::Cint)
    ret = @kn_ccall(set_obj_goal, Cint, (Ptr{Nothing}, Cint),
                             m.env.ptr_env.x, objgoal)
    _checkraise(ret)
end

function KN_add_obj_linear_struct(m::Model,
                                  objIndices::Vector{Int},
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
                                  indexVars1::Vector{Int},
                                  indexVars2::Vector{Int},
                                  coefs::Vector{Cdouble})
    nnz = length(indexVars1)

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

##################################################
# getters
##################################################
function KN_get_number_vars(m::Model)
    num_vars = Int32[0]
    ret = @kn_ccall(get_number_vars, Cint, (Ptr{Nothing}, Ptr{Cint}),
                    m.env.ptr_env.x, num_vars)
    _checkraise(ret)
    return num_vars[1]
end

function KN_get_number_cons(m::Model)
    num_cons = Int32[0]
    ret = @kn_ccall(get_number_vars, Cint, (Ptr{Nothing}, Ptr{Cint}),
                    m.env.ptr_env.x, num_cons)
    _checkraise(ret)
    return num_cons[1]
end

function KN_get_obj_value(m::Model)
    obj = Cdouble[0]
    ret = @kn_ccall(get_number_vars, Cint, (Ptr{Nothing}, Ptr{Cdouble}),
                    m.env.ptr_env.x, objj)
    _checkraise(ret)
    return obj[1]
end

function KN_get_obj_type(m::Model)
    obj_type = Int32[0]
    ret = @kn_ccall(get_number_vars, Cint, (Ptr{Nothing}, Ptr{Cint}), m.env.ptr_env.x, obj_type)
    _checkraise(ret)
    return obj_type[1]
end


####################
# Constraints getters
####################
function KN_get_con_values(m::Model)
    nc = KN_get_number_cons(m)
    consvals = zeros(Cdouble, nc)
    ret = @kn_ccall(get_con_values_all, Cint, (Ptr{Nothing}, Ptr{Cdouble}),
                    m.env.ptr_env.x, consvals)
    _checkraise(ret)
    return consvals
end

function KN_get_con_types(m::Model)
    nc = KN_get_number_cons(m)
    constypes = zeros(Cint, nc)
    ret = @kn_ccall(get_con_types_all, Cint, (Ptr{Nothing}, Ptr{Cint}),
                    m.env.ptr_env.x, constypes)
    _checkraise(ret)
    return constypes
end

####################
# Continuous optimization results
####################
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
# setters
##################################################
function KN_set_param(m::Model, id::Integer, value::Integer)
    ret = @kn_ccall(set_int_param, Cint, (Ptr{Nothing}, Cint, Cint),
                             m.env.ptr_env.x, id, value)
    _checkraise(ret)
end

function KN_set_obj_scaling(m::Model, objScaleFactor::Cdouble)
    ret = @kn_ccall(set_obj_scaling, Cint, (Ptr{Nothing}, Cdouble),
                    m.env.ptr_env.x, objScaleFactor)
    _checkraise(ret)
end

