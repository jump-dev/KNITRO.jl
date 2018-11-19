# Variables utilities


function KN_add_var!(m::Model)

    ptr_int = Cint[0]
    ret = @kn_ccall(add_var, Cint, (Ptr{Nothing}, Ptr{Cint}), m.env.ptr_env.x, ptr_int)
    _checkraise(ret)
    return ptr_int[1]
end


function KN_add_vars!(m::Model, nvars::Int)

    ptr_int = zeros(Cint, nvars)
    ret = @kn_ccall(add_vars, Cint, (Ptr{Nothing}, Cint, Ptr{Cint}), m.env.ptr_env.x, nvars, ptr_int)
    _checkraise(ret)
    return ptr_int
end

##################################################
## Upper and lower bounds utilies
##################################################

# lower bounds
function KN_set_var_lobnd(m::Model, nindex::Integer, val::Cdouble)
    ret = @kn_ccall(set_var_lobnd, Cint, (Ptr{Nothing}, Cint, Cdouble), m.env.ptr_env.x, nindex, val)
    _checkraise(ret)
end


function KN_set_var_lobnds(m::Model, valindex::Vector{Cint}, lobnds::Vector{Cdouble})
    nvar = length(valindex)
    ret = @kn_ccall(set_var_lobnds, Cint,
                    (Ptr{Nothing}, Cint, Ptr{Cint}, Ptr{Cdouble}),
                    m.env.ptr_env.x, nvar, valindex, lobnds)
    _checkraise(ret)
end
function KN_set_var_lobnds(m::Model, lobnds::Vector{Cdouble})
    ret = @kn_ccall(set_var_lobnds_all, Cint, (Ptr{Nothing}, Ptr{Cdouble}),
                    m.env.ptr_env.x, lobnds)
    _checkraise(ret)
end


# upper bounds
function KN_set_var_upbnd(m::Model, nindex::Integer, val::Cdouble)
    ret = @kn_ccall(set_var_upbnd, Cint, (Ptr{Nothing}, Cint, Cdouble), m.env.ptr_env.x, nindex, val)
    _checkraise(ret)
end


function KN_set_var_upbnds(m::Model, valindex::Vector{Cint}, upbnds::Vector{Cdouble})
    nvar = length(valindex)
    ret = @kn_ccall(set_var_upbnds, Cint,
                    (Ptr{Nothing}, Cint, Ptr{Cint}, Ptr{Cdouble}),
                    m.env.ptr_env.x, nvar, valindex, upbnds)
    _checkraise(ret)
end
function KN_set_var_upbnds(m::Model, upbnds::Vector{Cdouble})
    ret = @kn_ccall(set_var_upbnds_all, Cint, (Ptr{Nothing}, Ptr{Cdouble}),
                    m.env.ptr_env.x, upbnds)
    _checkraise(ret)
end


##################################################
## Initial values
##################################################
function KN_set_var_primal_init_values(m::Model, xinitval::Vector{Cdouble})
    ret = @kn_ccall(set_var_primal_init_values_all, Cint,
                    (Ptr{Nothing}, Ptr{Cdouble}),
                    m.env.ptr_env.x, xinitval)
    _checkraise(ret)
end
