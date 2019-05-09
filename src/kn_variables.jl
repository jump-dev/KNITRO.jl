# Variables utilities

"Add variable to model."
function KN_add_var(m::Model)
    ptr_int = Cint[0]
    ret = @kn_ccall(add_var, Cint, (Ptr{Cvoid}, Ptr{Cint}), m.env, ptr_int)
    _checkraise(ret)
    return ptr_int[1]
end


function KN_add_vars(m::Model, nvars::Int)
    ptr_int = zeros(Cint, nvars)
    ret = @kn_ccall(add_vars, Cint, (Ptr{Cvoid}, Cint, Ptr{Cint}), m.env, nvars, ptr_int)
    _checkraise(ret)
    return ptr_int
end

##################################################
## Upper and lower bounds utilies
##################################################

# lower bounds
function KN_set_var_lobnds(m::Model, nindex::Integer, val::Cdouble)
    ret = @kn_ccall(set_var_lobnd, Cint, (Ptr{Cvoid}, Cint, Cdouble), m.env, nindex, val)
    _checkraise(ret)
end

function KN_set_var_lobnds(m::Model, valindex::Vector{Cint}, lobnds::Vector{Cdouble})
    nvar = length(valindex)
    ret = @kn_ccall(set_var_lobnds, Cint,
                    (Ptr{Cvoid}, Cint, Ptr{Cint}, Ptr{Cdouble}),
                    m.env, nvar, valindex, lobnds)
    _checkraise(ret)
end

function KN_set_var_lobnds(m::Model, lobnds::Vector{Cdouble})
    ret = @kn_ccall(set_var_lobnds_all, Cint, (Ptr{Cvoid}, Ptr{Cdouble}),
                    m.env, lobnds)
    _checkraise(ret)
end


# upper bounds
function KN_set_var_upbnds(m::Model, nindex::Integer, val::Cdouble)
    ret = @kn_ccall(set_var_upbnd, Cint, (Ptr{Cvoid}, Cint, Cdouble), m.env, nindex, val)
    _checkraise(ret)
end

function KN_set_var_upbnds(m::Model, valindex::Vector{Cint}, upbnds::Vector{Cdouble})
    nvar = length(valindex)
    ret = @kn_ccall(set_var_upbnds, Cint,
                    (Ptr{Cvoid}, Cint, Ptr{Cint}, Ptr{Cdouble}),
                    m.env, nvar, valindex, upbnds)
    _checkraise(ret)
end

function KN_set_var_upbnds(m::Model, upbnds::Vector{Cdouble})
    ret = @kn_ccall(set_var_upbnds_all, Cint, (Ptr{Cvoid}, Ptr{Cdouble}),
                    m.env, upbnds)
    _checkraise(ret)
end

##################################################
# Getters
##################################################
if KNITRO_VERSION >= v"12.0"
    @define_getters get_var_lobnds
    @define_getters get_var_upbnds
    @define_getters get_var_eqbnds
    @define_getters get_var_fxbnds
end

##################################################
## Fix bounds
##################################################
function KN_set_var_fxbnds(m::Model, nindex::Integer, xFxBnd::Cdouble)
    ret = @kn_ccall(set_var_fxbnd, Cint, (Ptr{Cvoid}, Cint, Cdouble),
                    m.env, nindex, xFxBnd)
    _checkraise(ret)
end

function KN_set_var_fxbnds(m::Model, xIndex::Vector{Cint}, xFxBnds::Vector{Cdouble})
    nvar = length(xIndex)
    @assert length(xFxBnds) == nvar
    ret = @kn_ccall(set_var_fxbnds, Cint,
                    (Ptr{Cvoid}, Cint, Ptr{Cint}, Ptr{Cdouble}),
                    m.env, nvar, xIndex, xFxBnds)
    _checkraise(ret)
end

function KN_set_var_fxbnds(m::Model, xFxBnds::Vector{Cdouble})
    ret = @kn_ccall(set_var_fxbnds_all, Cint, (Ptr{Cvoid}, Ptr{Cdouble}),
                    m.env, xFxBnds)
    _checkraise(ret)
end

##################################################
## Variables types
##################################################

"""
Set variable types (e.g. KN_VARTYPE_CONTINUOUS, KN_VARTYPE_BINARY,
KN_VARTYPE_INTEGER). If not set, variables are assumed to be continuous.
"""
function KN_set_var_types(m::Model, valindex::Vector{Cint}, xTypes::Vector{Cdouble})
    nvar = length(valindex)
    @assert nvar == length(xTypes)
    ret = @kn_ccall(set_var_types, Cint,
                    (Ptr{Cvoid}, Cint, Ptr{Cint}, Ptr{Cdouble}),
                    m.env, nvar, valindex, xTypes)
    _checkraise(ret)
end

function KN_set_var_types(m::Model, xTypes::Vector{Cint})
    ret = @kn_ccall(set_var_types_all, Cint, (Ptr{Cvoid}, Ptr{Cint}),
                    m.env, xTypes)
    _checkraise(ret)
end

function KN_set_var_type(m::Model, indexVar::Integer, xType::Integer)
    ret = @kn_ccall(set_var_type, Cint, (Ptr{Cvoid}, Cint, Cint),
                    m.env, indexVar, xType)
    _checkraise(ret)
end

##################################################
## Variables properties
##################################################

"""
Specify some properties of the variables.  Currently
this API routine is only used to mark variables as linear,
but other variable properties will be added in the future.
Note: use bit-wise specification of the features:
bit value   meaning
  0     1   KN_VAR_LINEAR
default = 0 (variables are assumed to be nonlinear)

If a variable only appears linearly in the model, it can be very
helpful to mark this by enabling bit 0. This information can then
be used by Knitro to perform more extensive preprocessing. If a
variable appears nonlinearly in any constraint or the objective (or
if the user does not know) then it should not be marked as linear.
Variables are assumed to be nonlinear variables by default.
Knitro makes a local copy of all inputs, so the application may
free memory after the call.
"""
function KN_set_var_properties(m::Model, valindex::Vector{Cint}, xProperties::Vector{Cint})
    nvar = length(valindex)
    @assert nvar == length(xProperties)
    ret = @kn_ccall(set_var_properties, Cint,
                    (Ptr{Cvoid}, Cint, Ptr{Cint}, Ptr{Cint}),
                    m.env, nvar, valindex, xProperties)
    _checkraise(ret)
end

function KN_set_var_properties(m::Model, xProperties::Vector{Cint})
    ret = @kn_ccall(set_var_properties_all, Cint, (Ptr{Cvoid}, Ptr{Cint}),
                    m.env, xProperties)
    _checkraise(ret)
end

function KN_set_var_property(m::Model, indexVar::Integer, xProperty::Integer)
    ret = @kn_ccall(set_var_property, Cint, (Ptr{Cvoid}, Cint, Cint),
                    m.env, indexVar, xProperty)
    _checkraise(ret)
end


##################################################
## Honor bounds
##################################################
"""
This API function can be used to identify which variables
should satisfy their variable bounds throughout the optimization
process (KN_HONORBNDS_ALWAYS).  The user option KN_PARAM_HONORBNDS
can be used to set ALL variables to honor their bounds.  This
routine takes precedence over the setting of KN_PARAM_HONORBNDS
and is used to customize the settings for individual variables.
Knitro makes a local copy of all inputs, so the application may
free memory after the call.
"""
function KN_set_var_honorbnds(m::Model, nindex::Integer, xHonorBound::Cint)
    ret = @kn_ccall(set_var_honorbnd, Cint,
                    (Ptr{Cvoid}, Cint, Cint),
                    m.env, nindex, xHonorBound)
    _checkraise(ret)
end

function KN_set_var_honorbnds(m::Model, valindex::Vector{Cint}, xHonorBound::Vector{Cint})
    nvar = length(valindex)
    @assert length(xHonorBound) == nvar
    ret = @kn_ccall(set_var_honorbnds, Cint,
                    (Ptr{Cvoid}, Cint, Ptr{Cint}, Ptr{Cint}),
                    m.env, nvar, valindex, xHonorBound)
    _checkraise(ret)
end

function KN_set_var_honorbnds(m::Model, xHonorBound::Vector{Cint})
    ret = @kn_ccall(set_var_honorbnds_all, Cint, (Ptr{Cvoid}, Ptr{Cint}),
                    m.env, xHonorBound)
    _checkraise(ret)
end

##################################################
## Naming variables
##################################################
"""
Set names for model components passed in by the user/modeling
language so that Knitro can internally print out these names.
Knitro makes a local copy of all inputs, so the application may
free memory after the call.
"""
function KN_set_var_names(m::Model, nindex::Integer, name::String)
    ret = @kn_ccall(set_var_name, Cint,
                    (Ptr{Cvoid}, Cint, Ptr{Cchar}),
                    m.env, nindex, name)
    _checkraise(ret)
end

function KN_set_var_names(m::Model, varIndex::Vector{Cint}, names::Vector{String})
    nvar = length(varIndex)
    ret = @kn_ccall(set_var_names, Cint,
                    (Ptr{Cvoid}, Cint, Ptr{Cint}, Ptr{Ptr{Char}}),
                    m.env, nvar, varIndex, names)
    _checkraise(ret)
end

function KN_set_var_names(m::Model, names::Vector{String})
    ret = @kn_ccall(set_var_names_all, Cint, (Ptr{Cvoid}, Ptr{Ptr{Cchar}}),
                    m.env, names)
    _checkraise(ret)
end

# Getters
if KNITRO_VERSION >= v"12.0"
    function KN_get_var_names(m::Model, max_length=1024)
        return String[KN_get_var_names(m, Cint(id-1), max_length) for id in 1:KN_get_number_vars(m)]
    end

    function KN_get_var_names(m::Model, index::Vector{Cint}, max_length=1024)
        return String[KN_get_var_names(m, id, max_length) for id in index]
    end

    function KN_get_var_names(m::Model, index::Cint, max_length=1024)
        rawname = zeros(Cchar, max_length)
        ret = @kn_ccall(get_var_name, Cint,
                        (Ptr{Cvoid}, Cint, Cint, Ptr{Cchar}),
                        m.env, index, max_length, rawname)
        _checkraise(ret)
        name = String(strip(String(convert(Vector{UInt8}, rawname)), '\0'))
        return name
    end
end

##################################################
## Initial values
##################################################
# primal values
"""
Set initial values for primal variables.  If not set, variables
may be initialized as 0 or initialized by Knitro based on some
initialization strategy (perhaps determined by a user option).
"""
function KN_set_var_primal_init_values(m::Model, xinitval::Vector{Cdouble})
    ret = @kn_ccall(set_var_primal_init_values_all, Cint,
                    (Ptr{Cvoid}, Ptr{Cdouble}),
                    m.env, xinitval)
    _checkraise(ret)
end

function KN_set_var_primal_init_values(m::Model, indx::Integer, xinitval::Cdouble)
    ret = @kn_ccall(set_var_primal_init_value, Cint,
                    (Ptr{Cvoid}, Cint, Cdouble), m.env, indx, xinitval)
    _checkraise(ret)
end

# dual values
function KN_set_var_dual_init_values(m::Model, xinitval::Vector{Cdouble})
    ret = @kn_ccall(set_var_dual_init_values_all, Cint,
                    (Ptr{Cvoid}, Ptr{Cdouble}),
                    m.env, xinitval)
    _checkraise(ret)
end

function KN_set_var_dual_init_values(m::Model, indx::Integer, xinitval::Cdouble)
    ret = @kn_ccall(set_var_dual_init_value, Cint,
                    (Ptr{Cvoid}, Cint, Cdouble), m.env, indx, xinitval)
    _checkraise(ret)
end


##################################################
## Scalings
##################################################
"""
Set an array of variable scaling and centering values to
perform a linear scaling
  x[i] = xScaleFactors[i] * xScaled[i] + xScaleCenters[i]
for each variable. These scaling factors should try to
represent the "typical" values of the "x" variables so that the
scaled variables ("xScaled") used internally by Knitro are close
to one.  The values for xScaleFactors should be positive.
If a non-positive value is specified, that variable will not
be scaled.
"""
function KN_set_var_scalings(m::Model, nindex::Integer,
                             xScaleFactors::Cdouble, xScaleCenters::Cdouble)
    ret = @kn_ccall(set_var_scaling, Cint,
                    (Ptr{Cvoid}, Cint, Cdouble, Cdouble),
                    m.env, nindex, xScaleFactors, xScaleCenters)
    _checkraise(ret)
end
KN_set_var_scalings(m::Model, nindex::Integer, xScaleFactors::Cdouble) =
    KN_set_var_scalings(m, nindex, xScaleFactors, 0.)


function KN_set_var_scalings(m::Model, valindex::Vector{Cint},
                             xScaleFactors::Vector{Cdouble}, xScaleCenters::Vector{Cdouble})
    nvar = length(valindex)
    @assert nvar = length(xScaleFactors) == length(xScaleCenters)
    ret = @kn_ccall(set_var_scalings, Cint,
                    (Ptr{Cvoid}, Cint, Ptr{Cint}, Ptr{Cdouble}, Ptr{Cdouble}),
                    m.env, nvar, valindex, xScaleFactors, xScaleCenters)
    _checkraise(ret)
end
KN_set_var_scalings(m::Model, xIndex::Vector{Cint}, xScaleFactors::Vector{Cdouble}) =
    KN_set_var_scalings(m, xIndex, xScaleFactors, zeros(Cdouble, length(xScaleFactors)))

function KN_set_var_scalings(m::Model,
                             xScaleFactors::Vector{Cdouble}, xScaleCenters::Vector{Cdouble})
    @assert length(xScaleFactors) == length(xScaleCenters)
    ret = @kn_ccall(set_var_scalings_all, Cint, (Ptr{Cvoid}, Ptr{Cdouble}, Ptr{Cdouble}),
                    m.env, xScaleFactors, xScaleCenters)
    _checkraise(ret)
end
KN_set_var_scalings(m::Model, xScaleFactors::Vector{Cdouble}) =
    KN_set_var_scalings(m, xScaleFactors, zeros(Cdouble, length(xScaleFactors)))


##################################################
## Feasibility tolerance
##################################################
"""
Set custom absolute feasibility tolerances to use for the
termination tests.
The user options KN_PARAM_FEASTOL/KN_PARAM_FEASTOLABS define
a single tolerance that is applied equally to every constraint
and variable.  This API function allows the user to specify
separate feasibility termination tolerances for each constraint
and variable.  Values specified through this function will override
the value determined by KN_PARAM_FEASTOL/KN_PARAM_FEASTOLABS. The
tolerances should be positive values.  If a non-positive value is
specified, that constraint or variable will use the standard tolerances
based on  KN_PARAM_FEASTOL/KN_PARAM_FEASTOLABS.
The variables are considered to be satisfied when
    x[i] - xUpBnds[i] <= xFeasTols[i]  for all i=1..n, and
    xLoBnds[i] - x[i] <= xFeasTols[i]  for all i=1..n
The regular constraints are considered to be satisfied when
    c[i] - cUpBnds[i] <= cFeasTols[i]  for all i=1..m, and
    cLoBnds[i] - c[i] <= cFeasTols[i]  for all i=1..m
The complementarity constraints are considered to be satisfied when
    min(x1_i, x2_i) <= ccFeasTols[i]  for all i=1..ncc,
where x1 and x2 are the arrays of complementary pairs.
Knitro makes a local copy of all inputs, so the application
may free memory after the call.
"""
function KN_set_var_feastols(m::Model, nindex::Integer, xFeasTol::Cdouble)
    ret = @kn_ccall(set_var_feastol, Cint, (Ptr{Cvoid}, Cint, Cdouble),
                    m.env, nindex, xFeasTol)
    _checkraise(ret)
end

function KN_set_var_feastols(m::Model, xIndex::Vector{Cint}, xFeasTols::Vector{Cdouble})
    nvar = length(xIndex)
    @assert length(xFeasTols) == nvar
    ret = @kn_ccall(set_var_feastols, Cint,
                    (Ptr{Cvoid}, Cint, Ptr{Cint}, Ptr{Cdouble}),
                    m.env, nvar, xIndex, xFeasTols)
    _checkraise(ret)
end

function KN_set_var_feastols(m::Model, xFeasTols::Vector{Cdouble})
    ret = @kn_ccall(set_var_feastols_all, Cint, (Ptr{Cvoid}, Ptr{Cdouble}),
                    m.env, xFeasTols)
    _checkraise(ret)
end
