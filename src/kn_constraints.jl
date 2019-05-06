# Constraints utilities


##################################################
# Constraint definition
"Add constraint to model."
function KN_add_cons(m::Model, ncons::Integer)
    ptr_cons = zeros(Cint, ncons)
    ret = @kn_ccall(add_cons, Cint, (Ptr{Cvoid}, Cint, Ptr{Cint}), m.env, ncons, ptr_cons)
    _checkraise(ret)
    return ptr_cons
end

function KN_add_con(m::Model)
    ptr_cons = Cint[0]
    ret = @kn_ccall(add_con, Cint, (Ptr{Cvoid}, Ptr{Cint}), m.env, ptr_cons)
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
    ret = @kn_ccall(set_con_eqbnd, Cint, (Ptr{Cvoid}, Cint, Cdouble), m.env, indexCons, bnds)
    _checkraise(ret)
end
KN_set_con_eqbnds(m::Model, indexCons::Integer, bnds::Cdouble) = KN_set_con_eqbnd(m, indexCons, bnds)

function KN_set_con_eqbnds(m::Model, consIndex::Vector{Cint}, eqBounds::Vector{Cdouble})
    ncons = length(consIndex)
    ret = @kn_ccall(set_con_eqbnds, Cint,
                    (Ptr{Cvoid}, Cint, Ptr{Cint}, Ptr{Cdouble}),
                    m.env, ncons, consIndex, eqBounds)
    _checkraise(ret)
end

function KN_set_con_eqbnds(m::Model, eqBnds::Vector{Cdouble})
    ret = @kn_ccall(set_con_eqbnds_all, Cint, (Ptr{Cvoid}, Ptr{Cdouble}), m.env, eqBnds)
    _checkraise(ret)
end


#--------------------------------------------------
# Inequality constraints
#--------------------------------------------------
# Upper bounds
function KN_set_con_upbnd(m::Model, indexCons::Integer, bnds::Cdouble)
    ret = @kn_ccall(set_con_upbnd, Cint, (Ptr{Cvoid}, Cint, Cdouble),
                    m.env, indexCons, bnds)
    _checkraise(ret)
end
KN_set_con_upbnds(m::Model, indexCons::Integer, bnds::Cdouble) = KN_set_con_upbnd(m, indexCons, bnds)

function KN_set_con_upbnds(m::Model, upBnds::Vector{Cdouble})
    ret = @kn_ccall(set_con_upbnds_all, Cint, (Ptr{Cvoid}, Ptr{Cdouble}), m.env, upBnds)
    _checkraise(ret)
end

function KN_set_con_upbnds(m::Model, consIndex::Vector{Cint}, upBounds::Vector{Cdouble})
    ncons = length(consIndex)
    ret = @kn_ccall(set_con_upbnds, Cint,
                    (Ptr{Cvoid}, Cint, Ptr{Cint}, Ptr{Cdouble}),
                    m.env, ncons, consIndex, upBounds)
    _checkraise(ret)
end

# Lower bounds
function KN_set_con_lobnd(m::Model, indexCons::Integer, bnds::Cdouble)
    ret = @kn_ccall(set_con_lobnd, Cint, (Ptr{Cvoid}, Cint, Cdouble),
                    m.env, indexCons, bnds)
    _checkraise(ret)
end
KN_set_con_lobnds(m::Model, indexCons::Integer, bnds::Cdouble) = KN_set_con_lobnd(m, indexCons, bnds)

# Lower bounds
function KN_set_con_lobnds(m::Model, loBnds::Vector{Cdouble})
    ret = @kn_ccall(set_con_lobnds_all, Cint, (Ptr{Cvoid}, Ptr{Cdouble}), m.env, loBnds)
    _checkraise(ret)
end

function KN_set_con_lobnds(m::Model, consIndex::Vector{Cint}, loBounds::Vector{Cdouble})
    ncons = length(consIndex)
    ret = @kn_ccall(set_con_lobnds, Cint,
                    (Ptr{Cvoid}, Cint, Ptr{Cint}, Ptr{Cdouble}),
                    m.env, ncons, consIndex, loBounds)
    _checkraise(ret)
end

##################################################
# Getters
##################################################
if KNITRO_VERSION >= v"12.0"
    @define_getters get_con_lobnds
    @define_getters get_con_upbnds
    @define_getters get_con_eqbnds
end

##################################################
# Dual init values
##################################################
function KN_set_con_dual_init_values(m::Model, nindex::Integer, lambdaInitVal::Cdouble)
    ret = @kn_ccall(set_con_dual_init_value, Cint,
                    (Ptr{Cvoid}, Cint, Cdouble),
                    m.env, nindex, lambdaInitVal)
    _checkraise(ret)
end

function KN_set_con_dual_init_values(m::Model, indexCon::Vector{Cint}, lambdaInitVals::Vector{Cdouble})
    nvar = length(indexCon)
    @assert nvar == length(lambdaInitVals)
    ret = @kn_ccall(set_con_dual_init_values, Cint,
                    (Ptr{Cvoid}, Cint, Ptr{Cint}, Ptr{Cdouble}),
                    m.env, nvar, indexCon, lambdaInitVals)
    _checkraise(ret)
end

function KN_set_con_dual_init_values(m::Model, lambdaInitVals::Vector{Cdouble})
    ret = @kn_ccall(set_con_dual_init_values_all, Cint, (Ptr{Cvoid}, Ptr{Cdouble}),
                    m.env, lambdaInitVals)
    _checkraise(ret)
end

##################################################
# Constraint scalings
##################################################
"""
Set an array of constraint scaling values to perform a scaling
  cScaled[i] = cScaleFactors[i] * c[i]
for each constraint. These scaling factors should try to
represent the "typical" values of the inverse of the constraint
values "c" so that the scaled constraints ("cScaled") used
internally by Knitro are close to one.  Scaling factors for
standard constraints can be provided with "cScaleFactors", while
scalings for complementarity constraints can be specified with
"ccScaleFactors".  The values for cScaleFactors/ccScaleFactors
should be positive.  If a non-positive value is specified, that
constraint will use either the standard Knitro scaling
(KN_SCALE_USER_INTERNAL), or no scaling (KN_SCALE_USER_NONE).

"""
function KN_set_con_scalings(m::Model, nindex::Integer, cScaleFactors::Cdouble)
    ret = @kn_ccall(set_con_scaling, Cint,
                    (Ptr{Cvoid}, Cint, Cdouble),
                    m.env, nindex, cScaleFactors)
    _checkraise(ret)
end

function KN_set_con_scalings(m::Model, indexCon::Vector{Cint}, cScaleFactors::Vector{Cdouble})
    nvar = length(indexCon)
    ret = @kn_ccall(set_con_scalings, Cint,
                    (Ptr{Cvoid}, Cint, Ptr{Cint}, Ptr{Cdouble}),
                    m.env, nvar, indexCon, cScaleFactors)
    _checkraise(ret)
end

function KN_set_con_scalings(m::Model, cScaleFactors::Vector{Cdouble})
    ret = @kn_ccall(set_con_scalings_all, Cint, (Ptr{Cvoid}, Ptr{Cdouble}),
                    m.env, cScaleFactors)
    _checkraise(ret)
end


##################################################
# Constraints constants
##################################################
function KN_add_con_constants(m::Model, indexCons::Vector{Cint}, constants::Vector{Cdouble})
    nnc = length(constants)
    @assert length(indexCons) == length(constant)
    ret = @kn_ccall(add_con_constants, Cint,
                    (Ptr{Cvoid}, Cint, Ptr{Cint}, Ptr{Cdouble}),
                    m.env,
                    nnc,
                    indexCons,
                    constants)
    _checkraise(ret)
end

function KN_add_con_constants(m::Model, constants::Vector{Cdouble})
    nnc = length(constants)
    ret = @kn_ccall(add_con_constants_all, Cint,
                    (Ptr{Cvoid}, Ptr{Cdouble}),
                    m.env, constants)
    _checkraise(ret)
end

function KN_add_con_constant(m::Model, indexCon::Integer, constant::Cdouble)
    ret = @kn_ccall(add_con_constant, Cint,
                    (Ptr{Cvoid}, Cint, Cdouble),
                    m.env, indexCon, constant)
    _checkraise(ret)
end

##################################################
# Constraint structure
##################################################
#------------------------------
# add structure of linear constraint
#------------------------------
"""
Add linear structure to the constraint unctions.
Each component i of arrays indexCons, indexVars and coefs adds a linear
term:
   coefs[i]*x[indexVars[i]]
to constraint c[indexCons[i]].

"""
function KN_add_con_linear_struct(m::Model,
                                  jacIndexCons::Vector{Cint},
                                  jacIndexVars::Vector{Cint},
                                  jacCoefs::Vector{Float64})
    # get number of constraints
    nnz = length(jacIndexCons)
    @assert nnz == length(jacIndexVars) == length(jacCoefs)
    ret = @kn_ccall(add_con_linear_struct,
                    Cint,
                    (Ptr{Cvoid}, KNLONG, Ptr{Cint}, Ptr{Cint}, Ptr{Cdouble}),
                    m.env,
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
                    (Ptr{Cvoid}, KNLONG, Cint, Ptr{Cint}, Ptr{Cdouble}),
                    m.env,
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
"""
Add quadratic structure to the constraint functions.
Each component i of arrays indexCons, indexVars1, indexVars2 and coefs adds a
quadratic term:
   coefs[i]*x[indexVars1[i]]*x[indexVars2[i]]
to the constraint c[indexCons[i]].

"""
function KN_add_con_quadratic_struct(m::Model,
                                     indexCons::Vector{Cint},
                                     indexVars1::Vector{Cint},
                                     indexVars2::Vector{Cint},
                                     coefs::Vector{Cdouble})
    # get number of constraints
    nnz = length(indexVars1)
    @assert nnz == length(indexCons) == length(indexVars2) == length(coefs)
    ret = @kn_ccall(add_con_quadratic_struct,
                    Cint,
                    (Ptr{Cvoid}, KNLONG, Ptr{Cint}, Ptr{Cint}, Ptr{Cint}, Ptr{Cdouble}),
                    m.env,
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
    @assert nnz == length(indexVars2) == length(coefs)
    ret = @kn_ccall(add_con_quadratic_struct_one,
                    Cint,
                    (Ptr{Cvoid}, KNLONG, Cint, Ptr{Cint}, Ptr{Cint}, Ptr{Cdouble}),
                    m.env,
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
"""
Add L2 norm structure of the form ||Ax + b||_2 to a constraint.
  indexCon:    The constraint index that the L2 norm term will be added to.
  nCoords:     The number of rows in "A" (or dimension of "b")
  nnz:         The number of sparse non-zero elements in "A"
  indexCoords: The coordinate (row) index for each non-zero element in "A".
  indexVars:   The variable (column) index for each non-zero element in "A"
  coefs:       The coefficient value for each non-zero element in "A"
  constants:   The array "b" - may be set to NULL to ignore "b"

#Note
L2 norm structure can currently only be added to constraints that
otherwise only have linear (or constant) structure.  In this way
they can be used to define conic constraints of the form
||Ax + b|| <= c'x + d.  The "c" coefficients should be added through
"KN_add_con_linear_struct()" and "d" can be set as a constraint bound
or through "KN_add_con_constants()".

#Note
Models with L2 norm structure are currently only handled by the
Interior/Direct (KN_ALG_BAR_DIRECT) algorithm in Knitro.  Any model
with structure defined with KN_add_L2norm() will automatically be
forced to use this algorithm.

"""
function KN_add_con_L2norm(m::Model, indexCon::Integer, nCoords::Integer, nnz::Integer,
                       indexCoords::Vector{Cint}, indexVars::Vector{Cint},
                       coefs::Vector{Cdouble}, constants::Vector{Cdouble})
    @assert length(coefs) == length(indexVars) == length(indexCoords) == nnz
    ret = @kn_ccall(add_con_L2norm,
                    Cint,
                    (Ptr{Cvoid}, Cint, Cint, KNLONG, Ptr{Cint}, Ptr{Cint},
                     Ptr{Cdouble}, Ptr{Cdouble}),
                    m.env, indexCon, nCoords, nnz, indexCoords,
                    indexVars, coefs, constants)
    _checkraise(ret)
end

##################################################
# Complementary constraints
##################################################
"""
This function adds complementarity constraints to the problem.
The two lists are of equal length, and contain matching pairs of
variable indices.  Each pair defines a complementarity constraint
between the two variables.  The function can only be called once.
The array "ccTypes" specifies the type of complementarity:
   KN_CCTYPE_VARVAR: two (non-negative) variables
   KN_CCTYPE_VARCON: a variable and a constraint
   KN_CCTYPE_CONCON: two constraints

#Note
Currently only KN_CCTYPE_VARVAR is supported.  The other
"ccTypes" will be added in future releases.

"""
function KN_set_compcons(m::Model,
                         ccTypes::Vector{Cint},
                         indexComps1::Vector{Cint},
                         indexComps2::Vector{Cint})
    # get number of constraints
    nnc = length(ccTypes)
    @assert nnc == length(indexComps1) == length(indexComps2)
    ret = @kn_ccall(set_compcons,
                    Cint,
                    (Ptr{Cvoid}, Cint, Ptr{Cint}, Ptr{Cint}, Ptr{Cint}),
                    m.env,
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
                    (Ptr{Cvoid}, Cint, Cdouble),
                    m.env, nindex, cScaleFactors)
    _checkraise(ret)
end

function KN_set_compcon_scalings(m::Model, indexCompCon::Vector{Cint}, cScaleFactors::Vector{Cdouble})
    nvar = length(indexCompCon)
    ret = @kn_ccall(set_compcon_scalings, Cint,
                    (Ptr{Cvoid}, Cint, Ptr{Cint}, Ptr{Cdouble}),
                    m.env, nvar, indexCompCon, cScaleFactors)
    _checkraise(ret)
end

function KN_set_compcon_scalings(m::Model, cScaleFactors::Vector{Cdouble})
    ret = @kn_ccall(set_compcon_scalings_all, Cint, (Ptr{Cvoid}, Ptr{Cdouble}),
                    m.env, cScaleFactors)
    _checkraise(ret)
end

##################################################
## Naming constraints
##################################################
function KN_set_con_names(m::Model, nindex::Integer, name::String)
    ret = @kn_ccall(set_con_name, Cint,
                    (Ptr{Cvoid}, Cint, Ptr{Cchar}),
                    m.env, nindex, name)
    _checkraise(ret)
end

function KN_set_con_names(m::Model, conIndex::Vector{Cint}, names::Vector{String})
    ncon = length(conIndex)
    ret = @kn_ccall(set_con_names, Cint,
                    (Ptr{Cvoid}, Cint, Ptr{Cint}, Ptr{Ptr{Char}}),
                    m.env, ncon, conIndex, names)
    _checkraise(ret)
end

function KN_set_con_names(m::Model, names::Vector{String})
    ret = @kn_ccall(set_con_names_all, Cint, (Ptr{Cvoid}, Ptr{Ptr{Cchar}}),
                    m.env, names)
    _checkraise(ret)
end

function KN_set_compcon_names(m::Model, nindex::Integer, name::String)
    ret = @kn_ccall(set_compcon_name, Cint,
                    (Ptr{Cvoid}, Cint, Ptr{Cchar}),
                    m.env, nindex, name)
    _checkraise(ret)
end

function KN_set_compcon_names(m::Model, conIndex::Vector{Cint}, names::Vector{String})
    ncon = length(conIndex)
    ret = @kn_ccall(set_compcon_names, Cint,
                    (Ptr{Cvoid}, Cint, Ptr{Cint}, Ptr{Ptr{Char}}),
                    m.env, ncon, conIndex, names)
    _checkraise(ret)
end

function KN_set_compcon_names(m::Model, names::Vector{String})
    ret = @kn_ccall(set_compcon_names_all, Cint, (Ptr{Cvoid}, Ptr{Ptr{Cchar}}),
                    m.env, names)
    _checkraise(ret)
end

# Getters
if KNITRO_VERSION >= v"12.0"
    function KN_get_con_names(m::Model, max_length=1024)
        return String[KN_get_con_names(m, Cint(id-1), max_length) for id in 1:KN_get_number_cons(m)]
    end

    function KN_get_con_names(m::Model, index::Vector{Cint}, max_length=1024)
        return String[KN_get_con_names(m, id, max_length) for id in index]
    end

    function KN_get_con_names(m::Model, index::Cint, max_length=1024)
        rawname = zeros(Cchar, max_length)
        ret = @kn_ccall(get_con_name, Cint,
                        (Ptr{Cvoid}, Cint, Cint, Ptr{Cchar}),
                        m.env, index, max_length, rawname)
        _checkraise(ret)
        name = String(strip(String(convert(Vector{UInt8}, rawname)), '\0'))
        return name
    end
end

##################################################
## Feasibility tolerance
##################################################
function KN_set_con_feastols(m::Model, nindex::Integer, cFeasTol::Cdouble)
    ret = @kn_ccall(set_con_feastol, Cint, (Ptr{Cvoid}, Cint, Cdouble),
                    m.env, nindex, cFeasTol)
    _checkraise(ret)
end

function KN_set_con_feastols(m::Model, cIndex::Vector{Cint}, cFeasTols::Vector{Cdouble})
    ncon = length(cIndex)
    @assert length(cFeasTols) == ncon
    ret = @kn_ccall(set_con_feastols, Cint,
                    (Ptr{Cvoid}, Cint, Ptr{Cint}, Ptr{Cdouble}),
                    m.env, ncon, cIndex, cFeasTols)
    _checkraise(ret)
end

function KN_set_con_feastols(m::Model, cFeasTols::Vector{Cdouble})
    ret = @kn_ccall(set_con_feastols_all, Cint, (Ptr{Cvoid}, Ptr{Cdouble}),
                    m.env, cFeasTols)
    _checkraise(ret)
end

function KN_set_compcon_feastols(m::Model, nindex::Integer, cFeasTol::Cdouble)
    ret = @kn_ccall(set_compcon_feastol, Cint, (Ptr{Cvoid}, Cint, Cdouble),
                    m.env, nindex, cFeasTol)
    _checkraise(ret)
end

function KN_set_compcon_feastols(m::Model, cIndex::Vector{Cint}, cFeasTols::Vector{Cdouble})
    ncon = length(cIndex)
    @assert length(cFeasTols) == ncon
    ret = @kn_ccall(set_compcon_feastols, Cint,
                    (Ptr{Cvoid}, Cint, Ptr{Cint}, Ptr{Cdouble}),
                    m.env, ncon, cIndex, cFeasTols)
    _checkraise(ret)
end

function KN_set_compcon_feastols(m::Model, cFeasTols::Vector{Cdouble})
    ret = @kn_ccall(set_compcon_feastols_all, Cint, (Ptr{Cvoid}, Ptr{Cdouble}),
                    m.env, cFeasTols)
    _checkraise(ret)
end

##################################################
## Constraint property
##################################################
"""
Specify some properties of the objective and constraint functions.

# Note
Use bit-wise specification of the features:
bit value   meaning
  0     1   KN_OBJ_CONVEX/KN_CON_CONVEX
  1     2   KN_OBJ_CONCAVE/KN_CON_CONCAVE
  2     4   KN_OBJ_CONTINUOUS/KN_CON_CONTINUOUS
  3     8   KN_OBJ_DIFFERENTIABLE/KN_CON_DIFFERENTIABLE
  4    16   KN_OBJ_TWICE_DIFFERENTIABLE/KN_CON_TWICE_DIFFERENTIABLE
  5    32   KN_OBJ_NOISY/KN_CON_NOISY
  6    64   KN_OBJ_NONDETERMINISTIC/KN_CON_NONDETERMINISTIC
default = 28 (bits 2-4 enabled: e.g. continuous, differentiable, twice-differentiable)

"""
function KN_set_con_properties(m::Model, nindex::Integer, cProperty::Cint)
    ret = @kn_ccall(set_con_property, Cint, (Ptr{Cvoid}, Cint, Cint),
                    m.env, nindex, cProperty)
    _checkraise(ret)
end

function KN_set_con_properties(m::Model, cIndex::Vector{Cint}, cProperties::Vector{Cint})
    ncon = length(cIndex)
    @assert length(cProperties) == ncon
    ret = @kn_ccall(set_con_properties, Cint,
                    (Ptr{Cvoid}, Cint, Ptr{Cint}, Ptr{Cint}),
                    m.env, ncon, cIndex, cProperties)
    _checkraise(ret)
end

function KN_set_con_properties(m::Model, cProperties::Vector{Cint})
    ret = @kn_ccall(set_con_properties_all, Cint, (Ptr{Cvoid}, Ptr{Cint}),
                    m.env, cProperties)
    _checkraise(ret)
end
