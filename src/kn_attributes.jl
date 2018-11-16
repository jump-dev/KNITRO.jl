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

    ret = @kn_ccall(add_obj_linear_struct, Cint,
                    (Ptr{Nothing}, Cint, Ptr{Cint}, Ptr{Cint}, Ptr{Cdouble}),
                    m.env.ptr_env.x,
                    nnz,
                    indexVars1,
                    indexVars2,
                    coefs)
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

##################################################
# setters
##################################################
function KN_set_param(m::Model, id::Integer, value::Integer)
    ret = @kn_ccall(set_int_param, Cint, (Ptr{Nothing}, Cint, Cint),
                             m.env.ptr_env.x, id, value)
    _checkraise(ret)
end
