# Constraints utilities


##################################################
# Constraint definition
function KN_add_cons!(m::Model, ncons::Integer)
    ptr_cons = zeros(Cint, ncons)
    ret = @kn_ccall(add_cons, Cint, (Ptr{Nothing}, Cint, Ptr{Cint}), m.env.ptr_env.x, ncons, ptr_cons)
    _checkraise(ret)
    return ptr_cons
end

function KN_add_con!(m::Model)
    ptr_cons = Cint[0]
    ret = @kn_ccall(add_con, Cint, (Ptr{Nothing}, Ptr{Cint}), m.env.ptr_env.x, ptr_cons)
    _checkraise(ret)
    return ptr_cons[1]
end


##################################################
# Constraint bounds
##################################################
#--------------------------------------------------
# Equality constraints
#--------------------------------------------------
function KN_set_con_eqbnd(m::Model, indexCons::Integer, bnds::Cdouble)
    ret = @kn_ccall(set_con_eqbnd, Cint, (Ptr{Nothing}, Cint, Cdouble), m.env.ptr_env.x, indexCons, bnds)
    _checkraise(ret)
end
KN_set_con_eqbnds(m::Model, indexCons::Integer, bnds::Cdouble) = KN_set_con_eqbnd(m, indexCons, bnds)

function KN_set_con_eqbnds(m::Model, consIndex::Vector{Cint}, eqBounds::Vector{Cdouble})
    ncons = length(consIndex)
    ret = @kn_ccall(set_con_eqbnds, Cint,
                    (Ptr{Nothing}, Cint, Ptr{Cint}, Ptr{Cdouble}),
                    m.env.ptr_env.x, ncons, consIndex, eqBounds)
    _checkraise(ret)
end

function KN_set_con_eqbnds(m::Model, eqBnds::Vector{Cdouble})
    ret = @kn_ccall(set_con_eqbnds_all, Cint, (Ptr{Nothing}, Ptr{Cdouble}), m.env.ptr_env.x, eqBnds)
    _checkraise(ret)
end


#--------------------------------------------------
# Inequality constraints
#--------------------------------------------------
# Upper bounds
function KN_set_con_upbnd(m::Model, indexCons::Integer, bnds::Cdouble)
    ret = @kn_ccall(set_con_upbnd, Cint, (Ptr{Nothing}, Cint, Cdouble),
                    m.env.ptr_env.x, indexCons, bnds)
    _checkraise(ret)
end
KN_set_con_upbnds(m::Model, indexCons::Integer, bnds::Cdouble) = KN_set_con_upbnd(m, indexCons, bnds)

function KN_set_con_upbnds(m::Model, upBnds::Vector{Cdouble})
    ret = @kn_ccall(set_con_upbnds_all, Cint, (Ptr{Nothing}, Ptr{Cdouble}), m.env.ptr_env.x, upBnds)
    _checkraise(ret)
end

function KN_set_con_upbnds(m::Model, consIndex::Vector{Cint}, upBounds::Vector{Cdouble})
    ncons = length(consIndex)
    ret = @kn_ccall(set_con_upbnds, Cint,
                    (Ptr{Nothing}, Cint, Ptr{Cint}, Ptr{Cdouble}),
                    m.env.ptr_env.x, ncons, consIndex, upBounds)
    _checkraise(ret)
end

# Lower bounds
function KN_set_con_lobnd(m::Model, indexCons::Integer, bnds::Cdouble)
    ret = @kn_ccall(set_con_lobnd, Cint, (Ptr{Nothing}, Cint, Cdouble),
                    m.env.ptr_env.x, indexCons, bnds)
    _checkraise(ret)
end
KN_set_con_lobnds(m::Model, indexCons::Integer, bnds::Cdouble) = KN_set_con_lobnd(m, indexCons, bnds)

# Lower bounds
function KN_set_con_lobnds(m::Model, loBnds::Vector{Cdouble})
    ret = @kn_ccall(set_con_lobnds_all, Cint, (Ptr{Nothing}, Ptr{Cdouble}), m.env.ptr_env.x, loBnds)
    _checkraise(ret)
end

function KN_set_con_lobnds(m::Model, consIndex::Vector{Cint}, loBounds::Vector{Cdouble})
    ncons = length(consIndex)
    ret = @kn_ccall(set_con_lobnds, Cint,
                    (Ptr{Nothing}, Cint, Ptr{Cint}, Ptr{Cdouble}),
                    m.env.ptr_env.x, ncons, consIndex, loBounds)
    _checkraise(ret)
end

##################################################
# Dual init values
##################################################
function KN_set_con_dual_init_values(m::Model, nindex::Integer, lambdaInitVal::Cdouble)
    ret = @kn_ccall(set_con_dual_init_value, Cint,
                    (Ptr{Nothing}, Cint, Cdouble),
                    m.env.ptr_env.x, nindex, lambdaInitVal)
    _checkraise(ret)
end

function KN_set_con_dual_init_values(m::Model, indexCon::Vector{Cint}, lambdaInitVals::Vector{Cdouble})
    nvar = length(indexCon)
    @assert nvar == length(lambdaInitVals)
    ret = @kn_ccall(set_con_dual_init_values, Cint,
                    (Ptr{Nothing}, Cint, Ptr{Cint}, Ptr{Cdouble}),
                    m.env.ptr_env.x, nvar, indexCon, lambdaInitVals)
    _checkraise(ret)
end

function KN_set_con_dual_init_values(m::Model, lambdaInitVals::Vector{Cdouble})
    ret = @kn_ccall(set_con_dual_init_values_all, Cint, (Ptr{Nothing}, Ptr{Cdouble}),
                    m.env.ptr_env.x, lambdaInitVals)
    _checkraise(ret)
end

##################################################
# Constraint scalings
##################################################
function KN_set_con_scalings(m::Model, nindex::Integer, cScaleFactors::Cdouble)
    ret = @kn_ccall(set_con_scaling, Cint,
                    (Ptr{Nothing}, Cint, Cdouble),
                    m.env.ptr_env.x, nindex, cScaleFactors)
    _checkraise(ret)
end

function KN_set_con_scalings(m::Model, indexCon::Vector{Cint}, cScaleFactors::Vector{Cdouble})
    nvar = length(indexCon)
    ret = @kn_ccall(set_con_scalings, Cint,
                    (Ptr{Nothing}, Cint, Ptr{Cint}, Ptr{Cdouble}),
                    m.env.ptr_env.x, nvar, indexCon, cScaleFactors)
    _checkraise(ret)
end

function KN_set_con_scalings(m::Model, cScaleFactors::Vector{Cdouble})
    ret = @kn_ccall(set_con_scalings_all, Cint, (Ptr{Nothing}, Ptr{Cdouble}),
                    m.env.ptr_env.x, cScaleFactors)
    _checkraise(ret)
end


##################################################
# Constraints constants
##################################################
function KN_add_con_constants(m::Model, indexCons::Vector{Cint}, constants::Vector{Cdouble})
    nnc = length(constants)
    @assert length(indexCons) == length(constant)
    ret = @kn_ccall(add_con_constants, Cint,
                    (Ptr{Nothing}, Cint, Ptr{Cint}, Ptr{Cdouble}),
                    m.env.ptr_env.x,
                    nnc,
                    indexCons,
                    constants)
    _checkraise(ret)
end

function KN_add_con_constants(m::Model, constants::Vector{Cdouble})
    nnc = length(constants)
    ret = @kn_ccall(add_con_constants_all, Cint,
                    (Ptr{Nothing}, Ptr{Cdouble}),
                    m.env.ptr_env.x, constants)
    _checkraise(ret)
end

function KN_add_con_constant(m::Model, indexCon::Integer, constant::Cdouble)
    ret = @kn_ccall(add_con_constant, Cint,
                    (Ptr{Nothing}, Cint, Cdouble),
                    m.env.ptr_env.x, indexCon, constant)
    _checkraise(ret)
end

##################################################
# Constraint structure
##################################################
#------------------------------
# add structure of linear constraint
#------------------------------
function KN_add_con_linear_struct(m::Model,
                                  jacIndexCons::Vector{Cint},
                                  jacIndexVars::Vector{Cint},
                                  jacCoefs::Vector{Float64})
    # get number of constraints
    nnz = length(jacIndexCons)
    @assert nnz == length(jacIndexVars) == length(jacCoefs)
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
                                  indexCon::Integer,
                                  indexVar::Vector{Cint},
                                  coefs::Vector{Float64})
    # get number of constraints
    nnz = length(indexVar)
    @assert nnz == length(coefs)
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
KN_add_con_linear_struct(m::Model, indexCon::Integer, indexVar::Integer, coef::Float64) =
    KN_add_con_linear_struct(m, indexCon, Int32[indexVar], [coef])

#------------------------------
# add constraint quadratic structure
#------------------------------
function KN_add_con_quadratic_struct(m::Model,
                                     indexCons::Vector{Cint},
                                     indexVars1::Vector{Cint},
                                     indexVars2::Vector{Cint},
                                     coefs::Vector{Cdouble})
    # get number of constraints
    nnz = length(indexVars1)
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

function KN_add_con_quadratic_struct(m::Model,
                                     indexCons::Integer,
                                     indexVars1::Vector{Cint},
                                     indexVars2::Vector{Cint},
                                     coefs::Vector{Cdouble})
    # get number of constraints
    nnz = length(indexVars1)
    ret = @kn_ccall(add_con_quadratic_struct_one,
                    Cint,
                    (Ptr{Nothing}, Cint, Cint, Ptr{Cint}, Ptr{Cint}, Ptr{Cdouble}),
                    m.env.ptr_env.x,
                    nnz,
                    indexCons,
                    indexVars1,
                    indexVars2,
                    coefs)
    _checkraise(ret)
end
KN_add_con_quadratic_struct(m, indexCons::Integer, indexVar1::Integer, indexVar2::Integer, coef::Cdouble) =
KN_add_con_quadratic_struct(m, indexCons, Cint[indexVar1], Cint[indexVar2], Cdouble[coef])

#------------------------------
# Conic structure
#------------------------------
function KN_add_L2norm(m::Model, indexCon::Integer, nCoords::Integer, nnz::Integer,
                       indexCoords::Vector{Cint}, indexVars::Vector{Cint},
                       coefs::Vector{Cdouble}, constants::Vector{Cdouble})
    @assert lenght(coefs) == length(indexVars) == length(indexCoords) == nnz
    ret = @kn_ccall(add_L2norm,
                    Cint,
                    (Ptr{Nothing}, Cint, Cint, KNLONG, Ptr{Cint}, Ptr{Cint},
                     Ptr{Cdouble}, Ptr{Cdouble}),
                    m.env.ptr_env.x, indexCon, nCoords, nnz, indexCoords,
                    indexVars, coefs, constants)
    _checkraise(ret)
end

##################################################
# Complementary constraints
##################################################
function KN_set_compcons(m::Model,
                         ccTypes::Vector{Cint},
                         indexComps1::Vector{Cint},
                         indexComps2::Vector{Cint})
    # get number of constraints
    nnc = length(ccTypes)
    @assert ncc = length(indexComps1) == length(indexComps2)
    ret = @kn_ccall(set_compcons,
                    Cint,
                    (Ptr{Nothing}, Cint, Ptr{Cint}, Ptr{Cint}, Ptr{Cint}),
                    m.env.ptr_env.x,
                    nnc,
                    ccTypes,
                    indexComps1,
                    indexComps2)
    _checkraise(ret)
end

##################################################
# Complementary constraint scalings
##################################################

function KN_set_compcon_scalings(m::Model, nindex::Integer, cScaleFactors::Cdouble)
    ret = @kn_ccall(set_compcon_scaling, Cint,
                    (Ptr{Nothing}, Cint, Cdouble),
                    m.env.ptr_env.x, nindex, cScaleFactors)
    _checkraise(ret)
end

function KN_set_compcon_scalings(m::Model, indexCompCon::Vector{Cint}, cScaleFactors::Vector{Cdouble})
    nvar = length(indexCompCon)
    ret = @kn_ccall(set_compcon_scalings, Cint,
                    (Ptr{Nothing}, Cint, Ptr{Cint}, Ptr{Cdouble}),
                    m.env.ptr_env.x, nvar, indexCompCon, cScaleFactors)
    _checkraise(ret)
end

function KN_set_compcon_scalings(m::Model, cScaleFactors::Vector{Cdouble})
    ret = @kn_ccall(set_compcon_scalings_all, Cint, (Ptr{Nothing}, Ptr{Cdouble}),
                    m.env.ptr_env.x, cScaleFactors)
    _checkraise(ret)
end

##################################################
## Naming constraints
##################################################
function KN_set_con_names(m::Model, nindex::Integer, name::String)
    ret = @kn_ccall(set_con_name, Cint,
                    (Ptr{Nothing}, Cint, Ptr{Cchar}),
                    m.env.ptr_env.x, nindex, name)
    _checkraise(ret)
end

function KN_set_con_names(m::Model, conIndex::Vector{Cint}, names::Vector{String})
    ncon = length(conIndex)
    ret = @kn_ccall(set_con_names, Cint,
                    (Ptr{Nothing}, Cint, Ptr{Cint}, Ptr{Ptr{Char}}),
                    m.env.ptr_env.x, ncon, conIndex, names)
    _checkraise(ret)
end

function KN_set_con_names(m::Model, names::Vector{String})
    ret = @kn_ccall(set_con_names_all, Cint, (Ptr{Nothing}, Ptr{Ptr{Cchar}}),
                    m.env.ptr_env.x, names)
    _checkraise(ret)
end

function KN_set_compcon_names(m::Model, nindex::Integer, name::String)
    ret = @kn_ccall(set_compcon_name, Cint,
                    (Ptr{Nothing}, Cint, Ptr{Cchar}),
                    m.env.ptr_env.x, nindex, name)
    _checkraise(ret)
end

function KN_set_compcon_names(m::Model, conIndex::Vector{Cint}, names::Vector{String})
    ncon = length(conIndex)
    ret = @kn_ccall(set_compcon_names, Cint,
                    (Ptr{Nothing}, Cint, Ptr{Cint}, Ptr{Ptr{Char}}),
                    m.env.ptr_env.x, ncon, conIndex, names)
    _checkraise(ret)
end

function KN_set_compcon_names(m::Model, names::Vector{String})
    ret = @kn_ccall(set_compcon_names_all, Cint, (Ptr{Nothing}, Ptr{Ptr{Cchar}}),
                    m.env.ptr_env.x, names)
    _checkraise(ret)
end

##################################################
## Feasibility tolerance
##################################################
function KN_set_con_feastols(m::Model, nindex::Integer, cFeasTol::Cdouble)
    ret = @kn_ccall(set_con_feastol, Cint, (Ptr{Nothing}, Cint, Cdouble),
                    m.env.ptr_env.x, nindex, cFeasTol)
    _checkraise(ret)
end

function KN_set_con_feastols(m::Model, cIndex::Vector{Cint}, cFeasTols::Vector{Cdouble})
    ncon = length(cIndex)
    @assert length(cFeasTols) == ncon
    ret = @kn_ccall(set_con_feastols, Cint,
                    (Ptr{Nothing}, Cint, Ptr{Cint}, Ptr{Cdouble}),
                    m.env.ptr_env.x, ncon, cIndex, cFeasTols)
    _checkraise(ret)
end

function KN_set_con_feastols(m::Model, cFeasTols::Vector{Cdouble})
    ret = @kn_ccall(set_con_feastols_all, Cint, (Ptr{Nothing}, Ptr{Cdouble}),
                    m.env.ptr_env.x, cFeasTols)
    _checkraise(ret)
end

function KN_set_compcon_feastols(m::Model, nindex::Integer, cFeasTol::Cdouble)
    ret = @kn_ccall(set_compcon_feastol, Cint, (Ptr{Nothing}, Cint, Cdouble),
                    m.env.ptr_env.x, nindex, cFeasTol)
    _checkraise(ret)
end

function KN_set_compcon_feastols(m::Model, cIndex::Vector{Cint}, cFeasTols::Vector{Cdouble})
    ncon = length(cIndex)
    @assert length(cFeasTols) == ncon
    ret = @kn_ccall(set_compcon_feastols, Cint,
                    (Ptr{Nothing}, Cint, Ptr{Cint}, Ptr{Cdouble}),
                    m.env.ptr_env.x, ncon, cIndex, cFeasTols)
    _checkraise(ret)
end

function KN_set_compcon_feastols(m::Model, cFeasTols::Vector{Cdouble})
    ret = @kn_ccall(set_compcon_feastols_all, Cint, (Ptr{Nothing}, Ptr{Cdouble}),
                    m.env.ptr_env.x, cFeasTols)
    _checkraise(ret)
end

##################################################
## Constraint property
##################################################
function KN_set_con_properties(m::Model, nindex::Integer, cProperty::Cint)
    ret = @kn_ccall(set_con_property, Cint, (Ptr{Nothing}, Cint, Cint),
                    m.env.ptr_env.x, nindex, cProperty)
    _checkraise(ret)
end

function KN_set_con_properties(m::Model, cIndex::Vector{Cint}, cProperties::Vector{Cint})
    ncon = length(cIndex)
    @assert length(cProperties) == ncon
    ret = @kn_ccall(set_con_properties, Cint,
                    (Ptr{Nothing}, Cint, Ptr{Cint}, Ptr{Cint}),
                    m.env.ptr_env.x, ncon, cIndex, cProperties)
    _checkraise(ret)
end

function KN_set_con_properties(m::Model, cProperties::Vector{Cint})
    ret = @kn_ccall(set_con_properties_all, Cint, (Ptr{Nothing}, Ptr{Cint}),
                    m.env.ptr_env.x, cProperties)
    _checkraise(ret)
end
