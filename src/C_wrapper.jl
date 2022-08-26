# Copyright (c) 2016: Ng Yee Sian, Miles Lubin, other contributors
#
# Use of this source code is governed by an MIT-style license that can be found
# in the LICENSE.md file or at https://opensource.org/licenses/MIT.

"A macro to make calling KNITRO's KN_* C API a little cleaner"
macro kn_ccall(func, args...)
    f = Base.Meta.quot(Symbol("KN_$(func)"))
    args = [esc(a) for a in args]
    quote
        ccall(($f, libknitro), $(args...))
    end
end

macro kn_get_values(function_name, type)
    name_singular = "KN_" * string(function_name)
    name_plural = "KN_" * string(function_name) * "s"
    fname = Symbol(name_plural)
    fnameshort = Symbol(name_singular)
    # Names of C function in knitro.h
    c_fname = Symbol(name_singular)
    c_fnames = Symbol(name_plural)
    c_fnames_all = Symbol(name_plural * "_all")

    n = if occursin("var", name_singular)
        :(KN_get_number_vars(kc))
    elseif occursin("con", name_singular)
        :(KN_get_number_cons(kc))
    end

    quote
        function $(esc(fname))(kc::Model)
            result = zeros($type, $n)
            $c_fnames_all(kc, result)
            return result
        end
        function $(esc(fname))(kc::Model, index::Vector{Cint})
            result = zeros($type, length(index))
            $c_fnames(kc, length(index), index, result)
            return result
        end
        function $(esc(fname))(kc::Model, index::Integer)
            result = zeros($type, 1)
            $c_fname(kc, index, result)
            return result[1]
        end
        $(esc(fnameshort))(kc::Model, index::Integer) = $(esc(fname))(kc, index)
    end
end

macro kn_get_attribute(function_name, type)
    fname = Symbol("KN_" * string(function_name))
    quote
        function $(esc(fname))(m::Model)
            val = zeros($type, 1)
            ret = $fname(m, val)
            return val[1]
        end
    end
end

"Return the current KNITRO version."
function get_release()
    len = 15
    out = zeros(Cchar, len)
    KN_get_release(len, out)
    return String(strip(String(convert(Vector{UInt8}, out)), '\0'))
end

"Wrapper for KNITRO KN_context."
mutable struct Env
    ptr_env::Ptr{Cvoid}

    function Env()
        ptrptr_env = Ref{Ptr{Cvoid}}()
        res = KN_new(ptrptr_env)
        if res != 0
            error("Fail to retrieve a valid KNITRO KN_context. Error $res")
        end
        return new(ptrptr_env[])
    end

    Env(ptr::Ptr{Cvoid}) = new(ptr)
end

Base.unsafe_convert(::Type{Ptr{Cvoid}}, env::Env) = env.ptr_env::Ptr{Cvoid}

is_valid(env::Env) = env.ptr_env != C_NULL

"""
Free all memory and release any Knitro license acquired by calling KN_new.
"""
function free_env(env::Env)
    if env.ptr_env != C_NULL
        ptrptr_env = Ref{Ptr{Cvoid}}(env.ptr_env)
        KN_free(ptrptr_env)
        env.ptr_env = C_NULL
    end
    return
end

"""
Structure specifying the callback context.

Each evaluation callbacks (for objective, gradient or hessian)
is attached to a unique callback context.
"""
mutable struct CallbackContext
    context::Ptr{Cvoid}
    n::Int
    m::Int
    # Add a dictionnary to store user params.
    userparams::Any

    # Oracle's callbacks are context dependent, so store
    # them inside dedicated CallbackContext.
    eval_f::Function
    eval_g::Function
    eval_h::Function
    eval_rsd::Function
    eval_jac_rsd::Function

    function CallbackContext(ptr_cb::Ptr{Cvoid})
        return new(ptr_cb, 0, 0, nothing)
    end
end

Base.unsafe_convert(::Type{Ptr{Cvoid}}, cb::CallbackContext) = cb.context::Ptr{Cvoid}

mutable struct Model
    # KNITRO context environment.
    env::Env
    # Keep reference to callbacks for garbage collector.
    callbacks::Vector{CallbackContext}
    # Some structures for userParams
    puts_user::Any
    multistart_user::Any
    mip_user::Any
    newpoint_user::Any

    # Solution values.
    # Optimization status. Equal to 1 if problem is unsolved.
    status::Cint
    obj_val::Cdouble
    x::Vector{Cdouble}
    mult::Vector{Cdouble}

    # Special callbacks (undefined by default).
    # (this functions do not depend on callback environments)
    ms_process::Function
    newpt_callback::Function
    mip_callback::Function
    user_callback::Function
    ms_initpt_callback::Function
    puts_callback::Function

    # Constructor.
    function Model()
        model = new(
            Env(),
            CallbackContext[],
            nothing,
            nothing,
            nothing,
            nothing,
            1,
            Inf,
            Cdouble[],
            Cdouble[],
        )
        # Add a destructor to properly delete model.
        finalizer(KN_free, model)
        return model
    end
    # Instantiate a new Knitro instance in current environment `env`.
    function Model(env::Env)
        return new(
            env,
            CallbackContext[],
            nothing,
            nothing,
            nothing,
            nothing,
            1,
            Inf,
            Cdouble[],
            Cdouble[],
        )
    end
end

Base.unsafe_convert(::Type{Ptr{Cvoid}}, kn::Model) = kn.env.ptr_env::Ptr{Cvoid}

"Free solver object."
KN_free(m::Model) = free_env(m.env)

"Create solver object."
KN_new() = Model()

is_valid(m::Model) = is_valid(m.env)

has_callbacks(m::Model) = !isempty(m.callbacks)

register_callback(model::Model, cb::CallbackContext) = push!(model.callbacks, cb)

function Base.show(io::IO, m::Model)
    if is_valid(m)
        println(io, "$(get_release())")
        println(io, "-----------------------")
        println(io, "Problem Characteristics")
        println(io, "-----------------------")
        println(io, "Objective goal:  Minimize")
        println(io, "Objective type:  $(KN_get_obj_type(m))")
        println(
            io,
            "Number of variables:                             $(KN_get_number_vars(m))",
        )
        println(
            io,
            "Number of constraints:                           $(KN_get_number_cons(m))",
        )
        println(
            io,
            "Number of nonzeros in Jacobian:                  $(KN_get_jacobian_nnz(m))",
        )
        println(
            io,
            "Number of nonzeros in Hessian:                   $(KN_get_hessian_nnz(m))",
        )

    else
        println(io, "KNITRO Problem: NULL")
    end
    return
end

#=
    LM license manager
=#

"""
Type declaration for the Artelys License Manager context object.
Applications must not modify any part of the context.
"""
mutable struct LMcontext
    ptr_lmcontext::Ptr{Cvoid}
    # Keep a pointer to instantiated models in order to free
    # memory properly.
    linked_models::Vector{Model}

    function LMcontext()
        ptrref = Ref{Ptr{Cvoid}}()
        res = KN_checkout_license(ptrref)
        if res != 0
            error("KNITRO: Error checkout license")
        end
        lm = new(ptrref[], Model[])
        finalizer(KN_release_license, lm)
        return lm
    end
end

Base.unsafe_convert(::Type{Ptr{Cvoid}}, lm::LMcontext) = lm.ptr_lmcontext::Ptr{Cvoid}

function Env(lm::LMcontext)
    ptrptr_env = Ref{Ptr{Cvoid}}()
    res = KN_new_lm(lm, ptrptr_env)
    if res != 0
        error("Fail to retrieve a valid KNITRO KN_context. Error $res")
    end
    return Env(ptrptr_env[])
end

function attach!(lm::LMcontext, model::Model)
    push!(lm.linked_models, model)
    return
end

# create Model with license manager
function Model(lm::LMcontext)
    model = Model(Env(lm))
    attach!(lm, model)
    return model
end

KN_new_lm(lm::LMcontext) = Model(lm)

function KN_release_license(lm::LMcontext)
    # First, ensure that all linked models are properly freed
    # before releasing license manager!
    KN_free.(lm.linked_models)
    if lm.ptr_lmcontext != C_NULL
        refptr = Ref{Ptr{Cvoid}}(lm.ptr_lmcontext)
        KN_release_license(refptr)
        lm.ptr_lmcontext = C_NULL
    end
    return
end

#=
    VARIABLES
=#

function KN_add_var(m::Model)
    index = Ref{Cint}(0)
    KN_add_var(m, index)
    return index[]
end

function KN_add_vars(m::Model, nvars::Int)
    indices = zeros(Cint, nvars)
    KN_add_vars(m, nvars, indices)
    return indices
end

@kn_get_values get_var_lobnd Cdouble
@kn_get_values get_var_upbnd Cdouble
@kn_get_values get_var_eqbnd Cdouble
@kn_get_values get_var_fxbnd Cdouble
@kn_get_values get_var_primal_value Cdouble
@kn_get_values get_var_dual_value Cdouble
@kn_get_values get_var_type Cint

#=
    OBJECTIVE
=#

function KN_add_obj_linear_struct(
    m::Model,
    objIndices::Vector{Cint},
    objCoefs::Vector{Cdouble},
)
    nnz = length(objIndices)
    @assert nnz == length(objCoefs)
    return KN_add_obj_linear_struct(m, nnz, objIndices, objCoefs)
end

function KN_add_obj_linear_struct(m::Model, objindex::Int, objCoefs::Cdouble)
    return KN_add_obj_linear_struct(m, Cint[objindex], [objCoefs])
end

function KN_add_obj_quadratic_struct(
    m::Model,
    indexVars1::Vector{Cint},
    indexVars2::Vector{Cint},
    coefs::Vector{Cdouble},
)
    nnz = length(indexVars1)
    @assert nnz == length(indexVars2) == length(coefs)
    return KN_add_obj_quadratic_struct(m, nnz, indexVars1, indexVars2, coefs)
end

#=
    CONSTRAINTS
=#

function KN_add_cons(m::Model, ncons::Integer)
    indices = zeros(Cint, ncons)
    KN_add_cons(m, ncons, indices)
    return indices
end

function KN_add_con(m::Model)
    index = Ref{Cint}(0)
    KN_add_con(m, index)
    return index[]
end

@kn_get_values get_con_lobnd Cdouble
@kn_get_values get_con_upbnd Cdouble
@kn_get_values get_con_eqbnd Cdouble
@kn_get_values get_con_dual_value Cdouble
@kn_get_values get_con_value Cdouble

function KN_add_con_linear_struct(
    m::Model,
    index_cons::Vector{Cint},
    index_vars::Vector{Cint},
    coefs::Vector{Cdouble},
)
    @assert length(index_cons) == length(index_vars) == length(coefs)
    return KN_add_con_linear_struct(m, length(index_cons), index_cons, index_vars, coefs)
end

function KN_add_con_linear_struct(
    m::Model,
    index_con::Integer,
    index_vars::Vector{Cint},
    coefs::Vector{Cdouble},
)
    @assert length(index_vars) == length(coefs)
    return KN_add_con_linear_struct_one(m, length(index_vars), index_con, index_vars, coefs)
end

function KN_add_con_linear_struct(
    m::Model,
    index_con::Integer,
    index_var::Integer,
    coef::Cdouble,
)
    return KN_add_con_linear_struct_one(m, 1, index_con, [index_var], [coef])
end

function KN_add_con_quadratic_struct(
    m::Model,
    index_cons::Vector{Cint},
    index_vars1::Vector{Cint},
    index_vars2::Vector{Cint},
    coefs::Vector{Cdouble},
)
    @assert length(index_cons) ==
            length(index_vars1) ==
            length(index_vars2) ==
            length(coefs)
    return KN_add_con_quadratic_struct(m, length(index_cons), index_cons, index_vars1, index_vars2, coefs)
end

function KN_add_con_quadratic_struct(
    m::Model,
    index_con::Integer,
    index_vars1::Vector{Cint},
    index_vars2::Vector{Cint},
    coefs::Vector{Cdouble},
)
    @assert length(index_vars1) == length(index_vars2) == length(coefs)
    return KN_add_con_quadratic_struct_one(
        m,
        length(index_vars1),
        index_con,
        index_vars1,
        index_vars2,
        coefs,
    )
end

function KN_add_con_quadratic_struct(
    m::Model,
    index_con::Integer,
    index_var1::Integer,
    index_var2::Integer,
    coef::Cdouble,
)
    return KN_add_con_quadratic_struct_one(
        m,
        1,
        index_con,
        Cint[index_var1],
        Cint[index_var2],
        [coef],
    )
end

function KN_set_compcons(
    m::Model,
    ccTypes::Vector{Cint},
    indexComps1::Vector{Cint},
    indexComps2::Vector{Cint},
)
    # get number of constraints
    nnc = length(ccTypes)
    @assert nnc == length(indexComps1) == length(indexComps2)
    return KN_set_compcons(m, nnc, ccTypes, indexComps1, indexComps2)
end

#=
    RESIDUALS
=#

function KN_add_rsds(m::Model, ncons::Integer)
    indices = zeros(Cint, ncons)
    KN_add_rsds(m, ncons, indices)
    return indices
end

function KN_add_rsd(m::Model)
    index = Cint[0]
    KN_add_rsd(m, index)
    return index
end

function KN_add_rsd_linear_struct(
    m::Model,
    indexRsds::Vector{Cint},
    indexVars::Vector{Cint},
    coefs::Vector{Cdouble},
)
    nnz = length(indexRsds)
    @assert nnz == length(indexVars) == length(coefs)
    return KN_add_rsd_linear_struct(m, nnz, indexRsds, indexVars, coefs)
end

function KN_add_rsd_linear_struct(
    m::Model,
    indexRsd::Integer,
    indexVar::Vector{Cint},
    coefs::Vector{Cdouble},
)
    nnz = length(indexVar)
    @assert nnz == length(coefs)
    return KN_add_rsd_linear_struct_one(m, nnz, indexRsd, indexVar, coefs)
end

#=
    SOLVE
=#

function KN_solve(m::Model)
    # Check sanity. If model has Julia callbacks, we need to ensure
    # that Knitro is not multithreaded. Otherwise, the code will segfault
    # as we have trouble calling Julia code from multithreaded C
    # code. See issue #93 on https://github.com/jump-dev/KNITRO.jl.
    if has_callbacks(m)
        if KNITRO_VERSION >= v"13.0"
            KN_set_param(m, KN_PARAM_MS_NUMTHREADS, 1)
            KN_set_param(m, KN_PARAM_NUMTHREADS, 1)
            KN_set_param(m, KN_PARAM_MIP_NUMTHREADS, 1)
        else
            KN_set_param(m, "par_numthreads", 1)
            KN_set_param(m, "par_msnumthreads", 1)
        end
    end
    # For KN_solve, we do not return an error if ret is different of 0.
    m.status = KN_solve(m.env)
    return m.status
end

#=
    GETTERS
=#

function KN_get_solution(m::Model)
    # we first check that the model is well defined to avoid segfault
    @assert m.env != C_NULL
    nx = KN_get_number_vars(m)
    nc = KN_get_number_cons(m)

    x = zeros(Cdouble, nx)
    lambda = zeros(Cdouble, nx + nc)
    status, obj = Ref{Cint}(0), Ref{Cdouble}(0.0)
    KN_get_solution(m, status, obj, x, lambda)
    # Keep solution in cache.
    m.status = status[]
    m.x = x
    m.mult = lambda
    m.obj_val = obj[]
    return status[], obj[], x, lambda
end

# some wrapper functions for MOI
function get_status(m::Model)
    @assert m.env != C_NULL
    if m.status != 1
        return m.status
    end
    status, obj = Ref{Cint}(0), Ref{Cdouble}(0.0)
    KN_get_solution(m, status, obj, C_NULL, C_NULL)
    # Keep status in cache.
    m.status = status[]
    return status[]
end

function get_objective(m::Model)
    @assert m.env != C_NULL
    if isfinite(m.obj_val)
        return m.obj_val
    end
    status, obj = Ref{Cint}(0), Ref{Cdouble}(0.0)
    KN_get_solution(m, status, obj, C_NULL, C_NULL)
    # Keep objective value in cache.
    m.obj_val = obj[]
    return obj[]
end

function get_solution(m::Model)
    # We first check that the model is well defined to avoid segfault.
    @assert m.env != C_NULL
    if !isempty(m.x)
        return m.x
    end
    nx = KN_get_number_vars(m)
    x = zeros(Cdouble, nx)
    status, obj = Ref{Cint}(0), Ref{Cdouble}(0.0)
    KN_get_solution(m, status, obj, x, C_NULL)
    # Keep solution in cache.
    m.x = x
    return x
end
get_solution(m::Model, ix::Int) = isempty(m.x) ? get_solution(m)[ix] : m.x[ix]

function get_dual(m::Model)
    # we first check that the model is well defined to avoid segfault
    @assert m.env != C_NULL
    if !isempty(m.mult)
        return m.mult
    end
    nx = KN_get_number_vars(m)
    nc = KN_get_number_cons(m)
    lambda = zeros(Cdouble, nx + nc)
    status, obj = Ref{Cint}(0), Ref{Cdouble}(0.0)
    KN_get_solution(m, status, obj, C_NULL, lambda)
    # Keep multipliers in cache.
    m.mult = lambda
    return lambda
end

get_dual(m::Model, ix::Int) = isempty(m.mult) ? get_dual(m)[ix] : m.mult[ix]

function KN_get_objgrad_values(m::Model)
    nnz = KN_get_objgrad_nnz(m)
    indexVars = zeros(Cint, nnz)
    objGrad = zeros(Cdouble, nnz)
    KN_get_objgrad_values(m, indexVars, objGrad)
    return indexVars, objGrad
end

function KN_get_jacobian_values(m::Model)
    nnz = KN_get_jacobian_nnz(m)
    jacvars = zeros(Cint, nnz)
    jaccons = zeros(Cint, nnz)
    jaccoef = zeros(Cdouble, nnz)
    KN_get_jacobian_values(m, jacvars, jaccons, jaccoef)
    return jacvars, jaccons, jaccoef
end

function KN_get_rsd_jacobian_values(m::Model)
    nnz = KN_get_rsd_jacobian_nnz(m)
    jacvars = zeros(Cint, nnz)
    jaccons = zeros(Cint, nnz)
    jaccoef = zeros(Cdouble, nnz)
    KN_get_rsd_jacobian_values(m, jacvars, jaccons, jaccoef)
    return jacvars, jaccons, jaccoef
end

function KN_get_hessian_values(m::Model)
    nnz = KN_get_hessian_nnz(m)
    indexVars1 = zeros(Cint, nnz)
    indexVars2 = zeros(Cint, nnz)
    hess = zeros(Cdouble, nnz)
    KN_get_hessian_values(m, indexVars1, indexVars2, hess)
    return indexVars1, indexVars2, hess
end

function KN_get_var_viols(kc::Model, index::Vector{Cint})
    bndInfeas = zeros(Cint, length(index))
    intInfeas = zeros(Cint, length(index))
    viols = zeros(Cdouble, length(index))
    KN_get_var_viols(kc, length(index), index, bndInfeas, intInfeas, viols)
    return bndInfeas, intInfeas, viols
end

function KN_get_con_viols(kc::Model, index::Vector{Cint})
    infeas = zeros(Cint, length(index))
    viols = zeros(Cdouble, length(index))
    KN_get_con_viols(kc, length(index), index, infeas, viols)
    return infeas, viols
end

function KN_get_presolve_error(m::Model)
    @assert m.env != C_NULL
    component, index, error = Ref{Cint}(0), Ref{Cint}(0), Ref{Cint}(0)
    viol = Ref{Cdouble}(0.0)
    KN_get_presolve_error(m, component, index, error, viol)
    return Bool(component[]), Int64(index[]), Int64(error[]), viol[]
end

@kn_get_attribute get_number_vars Cint
@kn_get_attribute get_number_cons Cint
@kn_get_attribute get_obj_value Cdouble
@kn_get_attribute get_obj_type Cint

@kn_get_attribute get_number_iters Cint
@kn_get_attribute get_number_cg_iters Cint
@kn_get_attribute get_abs_feas_error Cdouble
@kn_get_attribute get_rel_feas_error Cdouble
@kn_get_attribute get_abs_opt_error Cdouble
@kn_get_attribute get_rel_opt_error Cdouble
@kn_get_attribute get_objgrad_nnz Cint
@kn_get_attribute get_jacobian_nnz KNLONG
@kn_get_attribute get_rsd_jacobian_nnz KNLONG
@kn_get_attribute get_hessian_nnz KNLONG
@kn_get_attribute get_solve_time_cpu Cdouble
@kn_get_attribute get_solve_time_real Cdouble

@kn_get_attribute get_mip_number_nodes Cint
@kn_get_attribute get_mip_number_solves Cint
@kn_get_attribute get_mip_abs_gap Cdouble
@kn_get_attribute get_mip_rel_gap Cdouble
@kn_get_attribute get_mip_incumbent_obj Cdouble
@kn_get_attribute get_mip_relaxation_bnd Cdouble
@kn_get_attribute get_mip_lastnode_obj Cdouble

#=
PARAMS
=#

function KN_set_param(m::Model, id::Integer, value::Integer)
    return KN_set_int_param(m, id, value)
end

function KN_set_param(m::Model, param::AbstractString, value::Integer)
    return KN_set_int_param_by_name(m, param, value)
end

function KN_set_param(m::Model, id::Integer, value::Cdouble)
    return KN_set_double_param(m, id, value)
end

function KN_set_param(m::Model, param::AbstractString, value::Cdouble)
    return KN_set_double_param_by_name(m, param, value)
end

function KN_set_param(m::Model, id::Integer, value::AbstractString)
    return KN_set_char_param(m, id, value)
end

function KN_set_param(m::Model, param::AbstractString, value::AbstractString)
    return KN_set_char_param_by_name(m, param, value)
end

function KN_get_int_param(m::Model, id::Integer)
    res = Ref{Cint}(0)
    KN_get_int_param(m, id, res)
    return res[]
end
function KN_get_int_param(m::Model, param::AbstractString)
    res = Ref{Cint}(0)
    KN_get_int_param_by_name(m, param, res)
    return res[]
end

function KN_get_double_param(m::Model, id::Integer)
    res = Ref{Cdouble}(0.0)
    KN_get_double_param(m, id, res)
    return res[]
end
function KN_get_double_param(m::Model, param::AbstractString)
    res = Ref{Cdouble}(0.0)
    KN_get_double_param_by_name(m, param, res)
    return res[]
end

function KN_get_param_name(m::Model, id::Integer)
    output_size = 128
    res = Vector{Cchar}(undef, output_size)
    KN_get_param_name(m, id, res, output_size)
    GC.@preserve res begin
        return unsafe_string(pointer(res))
    end
end

function KN_get_param_doc(m::Model, id::Integer)
    output_size = 128
    res = Vector{Cchar}(undef, output_size)
    KN_get_param_doc(m, id, res, output_size)
    GC.@preserve res begin
        return unsafe_string(pointer(res))
    end
end

function KN_get_param_type(m::Model, id::Integer)
    res = Ref{Cint}(0)
    KN_get_param_type(m, id, res)
    return res[]
end

function KN_get_num_param_values(m::Model, id::Integer)
    res = Ref{Cint}(0)
    KN_get_num_param_values(m, id, res)
    return res[]
end

function KN_get_param_value_doc(m::Model, id::Integer, value_id::Integer)
    output_size = 128
    res = Vector{Cchar}(undef, output_size)
    KN_get_param_value_doc(m, id, value_id, res, output_size)
    GC.@preserve res begin
        return unsafe_string(pointer(res))
    end
end

function KN_get_param_id(m::Model, name::AbstractString)
    res = Ref{Cint}(0)
    KN_get_param_id(m, name, res)
    return res[]
end

#=
    NAMES
=#

function KN_get_var_names(m::Model, max_length=1024)
    return String[
        KN_get_var_names(m, Cint(id - 1), max_length) for id in 1:KN_get_number_vars(m)
    ]
end

function KN_get_var_names(m::Model, index::Vector{Cint}, max_length=1024)
    return String[KN_get_var_names(m, id, max_length) for id in index]
end

function KN_get_var_names(m::Model, index::Cint, max_length=1024)
    rawname = Vector{Cchar}(undef, max_length)
    KN_get_var_name(m, index, max_length, rawname)
    GC.@preserve rawname begin
        return unsafe_string(pointer(rawname))
    end
end

function KN_get_con_names(m::Model, max_length=1024)
    return String[
        KN_get_con_names(m, Cint(id - 1), max_length) for id in 1:KN_get_number_cons(m)
    ]
end

function KN_get_con_names(m::Model, index::Vector{Cint}, max_length=1024)
    return String[KN_get_con_names(m, id, max_length) for id in index]
end

function KN_get_con_names(m::Model, index::Cint, max_length=1024)
    rawname = Vector{Cchar}(undef, max_length)
    KN_get_con_name(m, index, max_length, rawname)
    GC.@preserve rawname begin
        return unsafe_string(pointer(rawname))
    end
end
