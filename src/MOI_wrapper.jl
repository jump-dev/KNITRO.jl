# Copyright (c) 2016: Ng Yee Sian, Miles Lubin, other contributors
#
# Use of this source code is governed by an MIT-style license that can be found
# in the LICENSE.md file or at https://opensource.org/licenses/MIT.

import MathOptInterface

const MOI = MathOptInterface

include(joinpath("MOI_wrapper", "utils.jl"))

mutable struct VariableInfo
    has_lower_bound::Bool # Implies lower_bound == Inf
    has_upper_bound::Bool # Implies upper_bound == Inf
    is_fixed::Bool        # Implies lower_bound == upper_bound and !has_lower_bound and !has_upper_bound.
    name::String
end

VariableInfo() = VariableInfo(false, false, false, "")

struct EmptyNLPEvaluator <: MOI.AbstractNLPEvaluator end

MOI.features_available(::EmptyNLPEvaluator) = [:Grad, :Jac, :Hess]

MOI.initialize(::EmptyNLPEvaluator, features) = nothing

MOI.eval_objective(::EmptyNLPEvaluator, x) = NaN

MOI.eval_constraint(::EmptyNLPEvaluator, g, x) = nothing

MOI.eval_objective_gradient(::EmptyNLPEvaluator, g, x) = nothing

MOI.jacobian_structure(::EmptyNLPEvaluator) = Tuple{Int64,Int64}[]

MOI.hessian_lagrangian_structure(::EmptyNLPEvaluator) = Tuple{Int64,Int64}[]

MOI.eval_constraint_jacobian(::EmptyNLPEvaluator, J, x) = nothing

MOI.eval_hessian_lagrangian(::EmptyNLPEvaluator, H, x, σ, μ) = nothing

empty_nlp_data() = MOI.NLPBlockData([], EmptyNLPEvaluator(), false)

mutable struct ComplementarityCache
    n::Int
    index_comps_1::Vector{Cint}
    index_comps_2::Vector{Cint}
    cc_types::Vector{Cint}
    ComplementarityCache() = new(0, Cint[], Cint[], Cint[])
end

has_complementarity(cache::ComplementarityCache) = cache.n >= 1

function _add_complementarity_constraint!(
    cache::ComplementarityCache,
    index_vars_1::Vector{Cint},
    index_vars_2::Vector{Cint},
    cc_types::Vector{Int},
)
    if !(length(index_vars_1) == length(index_vars_2) == length(cc_types))
        error(
            "Arrays `index_vars_1`, `index_vars_2` and `cc_types` should" *
            " share the same length to specify a valid complementarity " *
            "constraint.",
        )
    end
    cache.n += 1
    append!(cache.index_comps_1, index_vars_1)
    append!(cache.index_comps_2, index_vars_2)
    append!(cache.cc_types, cc_types)
    return
end

mutable struct Optimizer <: MOI.AbstractOptimizer
    inner::Union{Model,Nothing}
    # We only keep in memory some information about variables
    # as we cannot delete variables, we do not have to store an index.
    variable_info::Vector{VariableInfo}
    # Get number of solve for restart.
    number_solved::Int
    # Specify if NLP is loaded inside KNITRO to avoid double definition.
    nlp_loaded::Bool
    nlp_data::MOI.NLPBlockData
    # Store index of nlp constraints.
    nlp_index_cons::Vector{Cint}
    # Store optimization sense.
    sense::MOI.OptimizationSense
    # Store the structure of the objective.
    objective::Union{
        MOI.VariableIndex,
        MOI.ScalarAffineFunction{Float64},
        MOI.ScalarQuadraticFunction{Float64},
        Nothing,
    }
    # Constraint counters.
    number_zeroone_constraints::Int
    number_integer_constraints::Int
    # Complementarity cache
    complementarity_cache::ComplementarityCache
    # Constraint mappings.
    constraint_mapping::Dict{MOI.ConstraintIndex,Union{Cint,Vector{Cint}}}
    license_manager::Union{LMcontext,Nothing}
    options::Dict{String,Any}
end

function set_options(model::Optimizer, options)
    for (name, value) in options
        MOI.set(model, MOI.RawOptimizerAttribute(string(name)), value)
    end
    return
end

function Optimizer(; license_manager=nothing, options...)
    # Create KNITRO context.
    if isa(license_manager, LMcontext)
        kc = Model(license_manager)
    else
        kc = Model()
    end
    # Convert Symbol to String in options dictionnary.
    options_dict = Dict{String,Any}()
    for (name, value) in options
        options_dict[string(name)] = value
    end
    model = Optimizer(
        kc,
        [],
        0,
        false,
        empty_nlp_data(),
        Cint[],
        MOI.FEASIBILITY_SENSE,
        nothing,
        0,
        0,
        ComplementarityCache(),
        Dict{MOI.ConstraintIndex,Int}(),
        license_manager,
        Dict(),
    )

    set_options(model, options)
    return model
end

function Base.show(io::IO, model::Optimizer)
    println(io, "A MathOptInterface model with backend:")
    println(io, model.inner)
    return
end

MOI.supports_incremental_interface(model::Optimizer) = true

function MOI.copy_to(model::Optimizer, src::MOI.ModelLike)
    return MOI.Utilities.default_copy_to(model, src)
end

function free(model::Optimizer)
    if model.inner !== nothing
        KN_free(model.inner)
    end
    return
end

function MOI.empty!(model::Optimizer)
    free(model)
    if isa(model.license_manager, LMcontext)
        model.inner = Model(model.license_manager)
    else
        model.inner = Model()
    end
    empty!(model.variable_info)
    model.number_solved = 0
    model.nlp_data = empty_nlp_data()
    model.nlp_loaded = false
    model.nlp_index_cons = Cint[]
    model.sense = MOI.FEASIBILITY_SENSE
    model.objective = nothing
    model.number_zeroone_constraints = 0
    model.number_integer_constraints = 0
    model.complementarity_cache = ComplementarityCache()
    model.constraint_mapping = Dict()
    model.license_manager = model.license_manager
    set_options(model, model.options)
    return
end

function MOI.is_empty(model::Optimizer)
    return isempty(model.variable_info) &&
           model.nlp_data.evaluator isa EmptyNLPEvaluator &&
           model.sense == MOI.FEASIBILITY_SENSE &&
           model.number_solved == 0 &&
           isa(model.objective, Nothing) &&
           model.number_zeroone_constraints == 0 &&
           model.number_integer_constraints == 0 &&
           !has_complementarity(model.complementarity_cache) &&
           !model.nlp_loaded
end

number_constraints(model::Optimizer) = KN_get_number_cons(model.inner)

# MOI.SolverName

MOI.get(model::Optimizer, ::MOI.SolverName) = "Knitro"

# MOI.SolverVersion

MOI.get(::Optimizer, ::MOI.SolverVersion) = string(KNITRO_VERSION)

# MOI.Silent

MOI.supports(model::Optimizer, ::MOI.Silent) = true

function MOI.get(model::Optimizer, ::MOI.Silent)
    return KN_get_int_param(model.inner, "outlev") == 0
end

function MOI.set(model::Optimizer, ::MOI.Silent, value)
    # Default outlev is KN_OUTLEV_ITER_10.
    outlev = value ? KN_OUTLEV_NONE : KN_OUTLEV_ITER_10
    # Register change in outlev in options in case model is emptied.
    model.options["outlev"] = outlev
    # Set option in Knitro's model.
    # KN_set_param(model.inner, "outlev", outlev)
    KN_set_param(model.inner, KN_PARAM_OUTLEV, outlev)
    return
end

# MOI.TimeLimitSec

MOI.supports(model::Optimizer, ::MOI.TimeLimitSec) = true

function MOI.get(model::Optimizer, ::MOI.TimeLimitSec)
    ret = KN_get_double_param(model.inner, KN_PARAM_MAXTIMECPU)
    return ret == 1e8 ? nothing : ret
end

function MOI.set(model::Optimizer, ::MOI.TimeLimitSec, value)
    # By default, maxtime is set to 1e8 in Knitro.
    KN_set_param(model.inner, KN_PARAM_MAXTIMECPU, something(value, 1e8))
    return
end

# MOI.RawOptimizerAttribute

function MOI.supports(model::Optimizer, attr::MOI.RawOptimizerAttribute)
    if attr.name == "free"
        return true
    end
    return KN_get_param_id(model.inner, attr.name) > 0
end

function MOI.get(model::Optimizer, attr::MOI.RawOptimizerAttribute)
    if !MOI.supports(model, attr)
        throw(MOI.UnsupportedAttribute(attr))
    elseif !haskey(model.options, attr.name)
        throw(MOI.GetAttributeNotAllowed(attr))
    end
    return model.options[attr.name]
end

function MOI.set(model::Optimizer, attr::MOI.RawOptimizerAttribute, value)
    if attr.name == "option_file"
        KN_load_param_file(model.inner, value)
    elseif attr.name == "tuner_file"
        KN_load_tuner_file(model.inner, value)
    elseif attr.name == "free"
        free(model)
    elseif !MOI.supports(model, attr)
        throw(MOI.UnsupportedAttribute(attr))
    else
        KN_set_param(model.inner, attr.name, value)
    end
    model.options[attr.name] = value
    return
end

# MOI.optimize!

function _load_complementarity_constraint(model::Optimizer, cache::ComplementarityCache)
    return KN_set_compcons(
        model.inner,
        cache.cc_types,
        cache.index_comps_1,
        cache.index_comps_2,
    )
end

function MOI.optimize!(model::Optimizer)
    KN_set_param(model.inner, "datacheck", 0)
    KN_set_param(model.inner, "hessian_no_f", 1)
    # Add complementarity structure if specified.
    if has_complementarity(model.complementarity_cache)
        _load_complementarity_constraint(model, model.complementarity_cache)
    end
    # Add NLP structure if specified.
    if !isa(model.nlp_data.evaluator, EmptyNLPEvaluator) && !model.nlp_loaded
        # Instantiate NLPEvaluator once and for all.
        features = MOI.features_available(model.nlp_data.evaluator)::Vector{Symbol}
        has_hessian = (:Hess in features)
        has_hessvec = (:HessVec in features)
        has_nlp_objective = model.nlp_data.has_objective
        num_nlp_constraints = length(model.nlp_data.constraint_bounds)
        has_nlp_constraints = (num_nlp_constraints > 0)
        # Build initial features for solver.
        init_feat = Symbol[]
        has_nlp_objective && push!(init_feat, :Grad)
        # Knitro could not mix Hessian callback with Hessian-vector callback.
        if has_hessian
            push!(init_feat, :Hess)
        elseif has_hessvec
            push!(init_feat, :HessVec)
        end
        if has_nlp_constraints
            push!(init_feat, :Jac)
        end
        MOI.initialize(model.nlp_data.evaluator, init_feat)
        # Load NLP structure inside Knitro.
        offset = number_constraints(model)
        load_nlp_constraints(model)
        num_cons = KN_get_number_cons(model.inner)
        # 1/ Definition of the callbacks
        # Objective callback (used both for objective and constraint evaluation).
        function eval_f_cb(kc, cb, evalRequest, evalResult, userParams)
            # Evaluate objective if specified in nlp_data.
            if has_nlp_objective
                evalResult.obj[1] =
                    MOI.eval_objective(model.nlp_data.evaluator, evalRequest.x)
            end
            # Evaluate nonlinear term in constraint.
            if has_nlp_constraints
                MOI.eval_constraint(model.nlp_data.evaluator, evalResult.c, evalRequest.x)
            end
            return 0
        end
        # Gradient and Jacobian callback.
        function eval_grad_cb(kc, cb, evalRequest, evalResult, userParams)
            # Evaluate non-linear term in objective gradient.
            if has_nlp_objective
                MOI.eval_objective_gradient(
                    model.nlp_data.evaluator,
                    evalResult.objGrad,
                    evalRequest.x,
                )
            end
            # Evaluate non linear part of jacobian.
            if has_nlp_constraints
                MOI.eval_constraint_jacobian(
                    model.nlp_data.evaluator,
                    evalResult.jac,
                    evalRequest.x,
                )
            end
            return 0
        end
        # 2/ Passing the callbacks to Knitro
        # 2.1/ Objective & constraints
        # Objective defined in NLP structure has precedence over model.objective.
        # If we have a NLP structure, we have three possible choices
        #   1. We have both a NLP objective and NLP constraints
        #   2. We have NLP constraints, with a linear or quadratic objective
        #   3. We have a NLP objective, without NLP constraints
        if has_nlp_constraints
            # Add only a callback for objective if no NLP constraint
            cb = KN_add_eval_callback(
                model.inner,
                has_nlp_objective,
                model.nlp_index_cons,
                eval_f_cb,
            )
        elseif has_nlp_objective
            cb = KN_add_objective_callback(model.inner, eval_f_cb)
        end
        # If a objective is specified in model.objective, load it.
        if !has_nlp_objective && !isnothing(model.objective)
            add_objective!(model, model.objective)
        end
        # 2.2/ Gradient & Jacobian
        nV = has_nlp_objective ? KN_DENSE : Cint(0)
        if !has_nlp_constraints
            KN_set_cb_grad(model.inner, cb, eval_grad_cb; nV=nV)
        else
            # Get jacobian structure.
            jacob_structure =
                MOI.jacobian_structure(model.nlp_data.evaluator)::Vector{Tuple{Int,Int}}
            # Take care to convert 1-indexing to 0-indexing!
            # KNITRO supports only Cint array for integer.
            jacIndexVars = Cint[j - 1 for (_, j) in jacob_structure]
            # NLP constraints are set after all other constraints
            # inside Knitro.
            jacIndexCons = Cint[i - 1 + offset for (i, _) in jacob_structure]
            KN_set_cb_grad(
                model.inner,
                cb,
                eval_grad_cb;
                nV=nV,
                jacIndexCons=jacIndexCons,
                jacIndexVars=jacIndexVars,
            )
        end
        # 2.3/ Hessian
        # By default, Hessian callback takes precedence over Hessvec callback.
        if has_hessian
            # Hessian callback.
            function eval_h_cb(kc, cb, evalRequest, evalResult, userParams)
                MOI.eval_hessian_lagrangian(
                    model.nlp_data.evaluator,
                    evalResult.hess,
                    evalRequest.x,
                    evalRequest.sigma,
                    view(evalRequest.lambda, offset+1:num_cons),
                )
                return 0
            end
            # Get hessian structure.
            hessian_structure = MOI.hessian_lagrangian_structure(
                model.nlp_data.evaluator,
            )::Vector{Tuple{Int,Int}}
            nnzH = length(hessian_structure)
            # Take care to convert 1-indexing to 0-indexing!
            # Knitro supports only Cint array for integer.
            hessIndexVars1 = Cint[i - 1 for (i, _) in hessian_structure]
            hessIndexVars2 = Cint[j - 1 for (_, j) in hessian_structure]

            KN_set_cb_hess(
                model.inner,
                cb,
                nnzH,
                eval_h_cb,
                hessIndexVars1=hessIndexVars1,
                hessIndexVars2=hessIndexVars2,
            )
        elseif has_hessvec
            function eval_hv_cb(kc, cb, evalRequest, evalResult, userParams)
                MOI.eval_hessian_lagrangian_product(
                    model.nlp_data.evaluator,
                    evalResult.hessVec,
                    evalRequest.x,
                    evalRequest.vec,
                    evalRequest.sigma,
                    view(evalRequest.lambda, offset+1:num_cons),
                )
                return 0
            end
            # Set callback
            # (no need to specify sparsity pattern for Hessian-vector product).
            KN_set_cb_hess(model.inner, cb, 0, eval_hv_cb)
            # Specify to Knitro that we are using Hessian-vector product.
            KN_set_param(model.inner, KN_PARAM_HESSOPT, KN_HESSOPT_PRODUCT)
        end
        model.nlp_loaded = true
    elseif !isa(model.objective, Nothing)
        add_objective!(model, model.objective)
    end
    KN_solve(model.inner)
    model.number_solved += 1
    return
end

include(joinpath("MOI_wrapper", "variables.jl"))
include(joinpath("MOI_wrapper", "constraints.jl"))
include(joinpath("MOI_wrapper", "objective.jl"))
include(joinpath("MOI_wrapper", "results.jl"))
include(joinpath("MOI_wrapper", "nlp.jl"))
include(joinpath("MOI_wrapper", "complementarity.jl"))
