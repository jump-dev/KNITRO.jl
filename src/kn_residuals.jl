# Residuals utilities


##################################################
# Residuals definition
function KN_add_rsds!(m::Model, ncons::Integer)
    ptr_cons = zeros(Cint, ncons)
    ret = @kn_ccall(add_rsds, Cint, (Ptr{Nothing}, Cint, Ptr{Cint}), m.env.ptr_env.x, ncons, ptr_cons)
    _checkraise(ret)
    return ptr_cons
end


function KN_add_rsd!(m::Model)
    ptr_cons = Cint[0]
    ret = @kn_ccall(add_rsd, Cint, (Ptr{Nothing}, Ptr{Cint}), m.env.ptr_env.x, ptr_cons)
    _checkraise(ret)
    return ptr_cons[1]
end


##################################################
# Residuals structure
##################################################

# add structure of linear constraint
function KN_add_rsd_linear_struct(m::Model,
                                  indexRsds::Vector{Cint},
                                  indexVars::Vector{Cint},
                                  coefs::Vector{Float64})
    # get number of constraints
    nnz = length(indexRsds)
    @assert nnz == length(indexVars) == length(coefs)
    ret = @kn_ccall(add_rsd_linear_struct,
                    Cint,
                    (Ptr{Nothing}, Cint, Ptr{Cint}, Ptr{Cint}, Ptr{Cdouble}),
                    m.env.ptr_env.x,
                    nnz,
                    indexRsds,
                    indexVars,
                    coefs)
    _checkraise(ret)
end
function KN_add_rsd_linear_struct(m::Model,
                                  indexRsd::Integer,
                                  indexVar::Vector{Cint},
                                  coefs::Vector{Float64})
    # get number of constraints
    nnz = length(indexVar)
    @assert nnz == length(coefs)
    ret = @kn_ccall(add_rsd_linear_struct_one,
                    Cint,
                    (Ptr{Nothing}, Cint, Cint, Ptr{Cint}, Ptr{Cdouble}),
                    m.env.ptr_env.x,
                    nnz,
                    indexRsd,
                    indexVar,
                    coefs)
    _checkraise(ret)
end
KN_add_rsd_linear_struct(m::Model, indexRsd::Integer, indexVar::Integer, coef::Float64) =  KN_add_rsd_linear_struct(m, indexRsd, Int32[indexVar], [coef])


##################################################
# Residuals constants
##################################################
function KN_add_rsd_constants(m::Model, indexRsds::Vector{Cint}, constants::Vector{Cdouble})
    nnc = length(constants)
    @assert length(indexRsds) == length(constant)
    ret = @kn_ccall(add_rsd_constants, Cint,
                    (Ptr{Nothing}, Cint, Ptr{Cint}, Ptr{Cdouble}),
                    m.env.ptr_env.x,
                    nnc,
                    indexRsds,
                    constants)
    _checkraise(ret)
end
function KN_add_rsd_constants(m::Model, constants::Vector{Cdouble})
    nnc = length(constants)
    ret = @kn_ccall(add_rsd_constants_all, Cint,
                    (Ptr{Nothing}, Ptr{Cdouble}),
                    m.env.ptr_env.x, constants)
    _checkraise(ret)
end
function KN_add_rsd_constant(m::Model, indexRsd::Integer, constant::Cdouble)
    ret = @kn_ccall(add_rsd_constant, Cint,
                    (Ptr{Nothing}, Cint, Cdouble),
                    m.env.ptr_env.x, indexRsd, constant)
    _checkraise(ret)
end
