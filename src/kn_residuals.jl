# Residuals utilities


##################################################
# Residuals definition
"Add residuals for least squares optimization."
function KN_add_rsds(m::Model, ncons::Integer)
    ptr_cons = zeros(Cint, ncons)
    ret = @kn_ccall(add_rsds, Cint, (Ptr{Cvoid}, Cint, Ptr{Cint}), m.env, ncons, ptr_cons)
    _checkraise(ret)
    return ptr_cons
end

function KN_add_rsd(m::Model)
    ptr_cons = Cint[0]
    ret = @kn_ccall(add_rsd, Cint, (Ptr{Cvoid}, Ptr{Cint}), m.env, ptr_cons)
    _checkraise(ret)
    return ptr_cons[1]
end


##################################################
# Residuals structure
##################################################

# add structure of linear constraint
"""
Add linear structure to the residual functions.
Each component i of arrays indexRsds, indexVars and coefs adds a linear
term:
   coefs[i]*x[indexVars[i]]
to residual r[indexRsds[i]].

"""
function KN_add_rsd_linear_struct(m::Model,
                                  indexRsds::Vector{Cint},
                                  indexVars::Vector{Cint},
                                  coefs::Vector{Float64})
    # get number of constraints
    nnz = length(indexRsds)
    @assert nnz == length(indexVars) == length(coefs)
    ret = @kn_ccall(add_rsd_linear_struct,
                    Cint,
                    (Ptr{Cvoid}, KNLONG, Ptr{Cint}, Ptr{Cint}, Ptr{Cdouble}),
                    m.env,
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
                    (Ptr{Cvoid}, KNLONG, Cint, Ptr{Cint}, Ptr{Cdouble}),
                    m.env,
                    nnz,
                    indexRsd,
                    indexVar,
                    coefs)
    _checkraise(ret)
end
KN_add_rsd_linear_struct(m::Model, indexRsd::Integer, indexVar::Integer, coef::Float64) =
    KN_add_rsd_linear_struct(m, indexRsd, Int32[indexVar], [coef])


##################################################
# Residuals getters
##################################################
function KN_get_rsd_values(m::Model)
    nc = KN_get_number_cons(m)
    rsdvals = zeros(Cdouble, nc)
    ret = @kn_ccall(get_rsd_values_all, Cint, (Ptr{Cvoid}, Ptr{Cdouble}),
                    m.env, rsdvals)
    _checkraise(ret)
    return rsdvals
end

function KN_get_rsd_values(m::Model, indexRsds::Vector{Cint})
    nc = length(indexRsds)
    rsdvals = zeros(Cdouble, nc)
    ret = @kn_ccall(get_rsd_values, Cint,
                    (Ptr{Cvoid}, Cint, Ptr{Cint}, Ptr{Cdouble}),
                    m.env, nc, indexRsds, rsdvals)
    _checkraise(ret)
    return rsdvals
end

function KN_get_rsd_values(m::Model, indexRsd::Integer)
    nc = 1
    rsdvals = zeros(Cdouble, nc)
    ret = @kn_ccall(get_rsd_value, Cint, (Ptr{Cvoid}, Cint, Ptr{Cdouble}),
                    m.env, indexRsd, rsdvals)
    _checkraise(ret)
    return rsdvals
end

##################################################
# Residuals constants
##################################################
function KN_add_rsd_constants(m::Model, indexRsds::Vector{Cint}, constants::Vector{Cdouble})
    nnc = length(constants)
    @assert length(indexRsds) == length(constant)
    ret = @kn_ccall(add_rsd_constants, Cint,
                    (Ptr{Cvoid}, Cint, Ptr{Cint}, Ptr{Cdouble}),
                    m.env,
                    nnc,
                    indexRsds,
                    constants)
    _checkraise(ret)
end

function KN_add_rsd_constants(m::Model, constants::Vector{Cdouble})
    nnc = length(constants)
    ret = @kn_ccall(add_rsd_constants_all, Cint,
                    (Ptr{Cvoid}, Ptr{Cdouble}),
                    m.env, constants)
    _checkraise(ret)
end

function KN_add_rsd_constant(m::Model, indexRsd::Integer, constant::Cdouble)
    ret = @kn_ccall(add_rsd_constant, Cint,
                    (Ptr{Cvoid}, Cint, Cdouble),
                    m.env, indexRsd, constant)
    _checkraise(ret)
end
