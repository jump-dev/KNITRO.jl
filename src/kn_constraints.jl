# Constraints utilities


##################################################
# Constraint definition
function KN_add_cons!(m::Model, ncons::Int)
    ptr_cons = zeros(Cint, ncons)
    ret = @kn_ccall(add_cons, Cint, (Ptr{Nothing}, Cint, Ptr{Cint}), m.env.ptr_env.x, ncons, ptr_cons)
    _checkraise(ret)
    return ptr_cons
end


function KN_add_con!(m::Model)
    ptr_cons = [0]
    ret = @kn_ccall(add_con, Cint, (Ptr{Nothing}, Ptr{Cint}), m.env.ptr_env.x, ptr_cons)
    _checkraise(ret)
    return ptr_cons[1]
end


##################################################
# Constraint bounds
##################################################
#
####################
# Equality constraints
function KN_set_con_eqbnds(m::Model, indexCons::Vector{Cint})
    error("To implement")
end

function KN_set_con_eqbnds(m::Model, eqBnds::Vector{Cdouble})
    ret = @kn_ccall(set_con_eqbnds_all, Cint, (Ptr{Nothing}, Ptr{Cdouble}), m.env.ptr_env.x, eqBnds)
    _checkraise(ret)
end



####################
# Inequality constraints
# Upper bounds
function KN_set_con_upbnds(m::Model, upBnds::Vector{Cdouble})
    ret = @kn_ccall(set_con_upbnds_all, Cint, (Ptr{Nothing}, Ptr{Cdouble}), m.env.ptr_env.x, upBnds)
    _checkraise(ret)
end
function KN_set_con_upbnd(m::Model, indexcons::Integer, upbd::Cdouble)
    ret = @kn_ccall(set_con_upbnd, Cint,
                    (Ptr{Nothing}, Cint, Cdouble),
                    m.env.ptr_env.x, indexcons, upbd)
    _checkraise(ret)
end

# Lower bounds
function KN_set_con_lobnds(m::Model, loBnds::Vector{Cdouble})
    ret = @kn_ccall(set_con_lobnds_all, Cint, (Ptr{Nothing}, Ptr{Cdouble}), m.env.ptr_env.x, loBnds)
    _checkraise(ret)
end



##################################################
# Constraint structure
##################################################

# add structure of linear constraint
function KN_add_con_linear_struct(m::Model,
                                  jacIndexCons::Vector{Int},
                                  jacIndexVars::Vector{Int},
                                  jacCoefs::Vector{Float64})
    # get number of constraints
    nnz = length(jacIndexCons)
    ret = @kn_ccall(add_con_linear_struct,
                    Cint,
                    (Ptr{Nothing}, Cint, Ptr{Cint}, Ptr{Cint}, Ptr{Cdouble}),
                    m.env.ptr_env.x,
                    nnz,
                    jacIndexCons,
                    jacIndexVars,
                    jacCoefs)
    _checkraise(ret)
end
function KN_add_con_linear_struct(m::Model,
                                  indexCon::Int,
                                  indexVar::Vector{Int},
                                  coefs::Vector{Float64})
    # get number of constraints
    nnz = length(indexVar)
    ret = @kn_ccall(add_con_linear_struct_one,
                    Cint,
                    (Ptr{Nothing}, Cint, Cint, Ptr{Cint}, Ptr{Cdouble}),
                    m.env.ptr_env.x,
                    nnz,
                    indexCon,
                    indexVar,
                    coefs)
    _checkraise(ret)
end
KN_add_con_linear_struct(m::Model, indexCon::Int, indexVar::Int, coef::Float64) =  KN_add_con_linear_struct(m, indexCon, [indexVar], [coef])



# add constraint quadratic structure
function KN_add_con_quadratic_struct(m::Model,
                                  indexCons::Vector{Int},
                                  indexVars1::Vector{Int},
                                  indexVars2::Vector{Int},
                                  coefs::Vector{Cdouble})
    # get number of constraints
    nnz = length(jacIndexCons)
    ret = @kn_ccall(add_con_quadratic_struct,
                    Cint,
                    (Ptr{Nothing}, Cint, Ptr{Cint}, Ptr{Cint}, Ptr{Cint}, Ptr{Cdouble}),
                    m.env.ptr_env.x,
                    nnz,
                    indexCons,
                    indexVars1,
                    indexVars2,
                    coefs)
    _checkraise(ret)
end
