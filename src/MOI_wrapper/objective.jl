# Copyright (c) 2016: Ng Yee Sian, Miles Lubin, other contributors
#
# Use of this source code is governed by an MIT-style license that can be found
# in the LICENSE.md file or at https://opensource.org/licenses/MIT.

function MOI.supports(
    ::Optimizer,
    ::MOI.ObjectiveFunction{
        <:Union{
            MOI.VariableIndex,
            MOI.ScalarAffineFunction{Float64},
            MOI.ScalarQuadraticFunction{Float64},
        },
    },
)
    return true
end

MOI.supports(::Optimizer, ::MOI.ObjectiveSense) = true

MOI.get(model::Optimizer, ::MOI.ObjectiveSense) = model.sense

function MOI.set(model::Optimizer, ::MOI.ObjectiveSense, sense::MOI.OptimizationSense)
    if model.number_solved >= 1
        throw(UpdateObjectiveError())
    end
    model.sense = sense
    if model.sense == MOI.MAX_SENSE
        KN_set_obj_goal(model.inner, KN_OBJGOAL_MAXIMIZE)
    elseif model.sense == MOI.MIN_SENSE
        KN_set_obj_goal(model.inner, KN_OBJGOAL_MINIMIZE)
    end
    return
end

##################################################
# Delete model.objective to avoid duplicate in memory
# between MOI and Knitro.
reset_objective!(model::Optimizer) = (model.objective = nothing)

# Objective definition.
function add_objective!(model::Optimizer, objective::MOI.ScalarQuadraticFunction)
    # We parse the expression passed in arguments.
    qobjindex1, qobjindex2, qcoefs = canonical_quadratic_reduction(objective)
    # Take care that Knitro is 0-indexed!
    qobjindex1 .-= 1
    qobjindex2 .-= 1
    lobjindex, lcoefs = canonical_linear_reduction(objective)
    # We load the objective inside KNITRO.
    KN_add_obj_quadratic_struct(model.inner, qobjindex1, qobjindex2, qcoefs)
    KN_add_obj_linear_struct(model.inner, lobjindex, lcoefs)
    KN_add_obj_constant(model.inner, objective.constant)
    reset_objective!(model)
    return
end

function add_objective!(model::Optimizer, objective::MOI.ScalarAffineFunction)
    # We parse the expression passed in arguments.
    lobjindex, lcoefs = canonical_linear_reduction(objective)
    # We load the objective inside KNITRO.
    KN_add_obj_linear_struct(model.inner, lobjindex, lcoefs)
    KN_add_obj_constant(model.inner, objective.constant)
    reset_objective!(model)
    return
end

function add_objective!(model::Optimizer, var::MOI.VariableIndex)
    # We load the objective inside KNITRO.
    KN_add_obj_linear_struct(model.inner, var.value - 1, 1.0)
    reset_objective!(model)
    return
end

function MOI.set(
    model::Optimizer,
    ::MOI.ObjectiveFunction,
    func::Union{MOI.VariableIndex,MOI.ScalarAffineFunction,MOI.ScalarQuadraticFunction},
)
    if model.number_solved >= 1
        throw(UpdateObjectiveError())
    end
    if !isa(model.nlp_data.evaluator, EmptyNLPEvaluator) && model.nlp_data.has_objective
        @warn("Objective is already specified in NLPBlockData.")
        return
    end
    check_inbounds(model, func)
    model.objective = func
    return
end
