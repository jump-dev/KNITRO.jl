# MathOptInterface Variables

##################################################
## Getters
MOI.get(model::Optimizer, ::MOI.NumberOfVariables) = length(model.variable_info)

function MOI.get(model::Optimizer, ::MOI.ListOfVariableIndices)
    return [MOI.VariableIndex(i) for i in 1:length(model.variable_info)]
end

##################################################
## Bridges with KNITRO.
function MOI.add_variable(model::Optimizer)
    # If model has been optimized, KNITRO does not support adding
    # another variable.
    (model.number_solved >= 1) && throw(AddVariableError())
    push!(model.variable_info, VariableInfo())
    KN_add_var(model.inner)
    nvars = length(model.variable_info)
    # By default, initial value is set to 0.
    KN_set_var_primal_init_values(model.inner, nvars - 1, 0.)
    return MOI.VariableIndex(nvars)
end
function MOI.add_variables(model::Optimizer, n::Int)
    return [MOI.add_variable(model) for i in 1:n]
end

function check_inbounds(model::Optimizer, vi::MOI.VariableIndex)
    num_variables = length(model.variable_info)
    if !(1 <= vi.value <= num_variables)
        error("Invalid variable index $vi. ($num_variables variables in the model.)")
    end
    return
end

##################################################
## Check inbounds for safety.
function check_inbounds(model::Optimizer, var::MOI.SingleVariable)
    return check_inbounds(model, var.variable)
end

function check_inbounds(model::Optimizer, aff::MOI.ScalarAffineFunction)
    for term in aff.terms
        check_inbounds(model, term.variable)
    end
    return
end

function check_inbounds(model::Optimizer, quad::MOI.ScalarQuadraticFunction)
    for term in quad.affine_terms
        check_inbounds(model, term.variable)
    end
    for term in quad.quadratic_terms
        check_inbounds(model, term.variable_1)
        check_inbounds(model, term.variable_2)
    end
    return
end

function has_upper_bound(model::Optimizer, vi::MOI.VariableIndex)
    return model.variable_info[vi.value].has_upper_bound
end

function has_lower_bound(model::Optimizer, vi::MOI.VariableIndex)
    return model.variable_info[vi.value].has_lower_bound
end

function is_fixed(model::Optimizer, vi::MOI.VariableIndex)
    return model.variable_info[vi.value].is_fixed
end

##################################################
## PrimalStart
function MOI.supports(::Optimizer, ::MOI.VariablePrimalStart,
                      ::Type{MOI.VariableIndex})
    return true
end
function MOI.set(model::Optimizer, ::MOI.VariablePrimalStart,
                 vi::MOI.VariableIndex, value::Union{Real, Nothing})
    check_inbounds(model, vi)
    if isa(value, Real)
        KN_set_var_primal_init_values(model.inner, vi.value - 1, Cdouble(value))
    else
        # By default, initial value is set to 0.
        KN_set_var_primal_init_values(model.inner, vi.value - 1, 0.)
    end
    return
end

##################################################
## Naming
# WIP: this part aims at supporting JuMP directly, without caching optimizer.
MOI.supports(::Optimizer, ::MOI.VariableName, ::Type{MOI.VariableIndex}) = true
function MOI.set(model::Optimizer, ::MOI.VariableName, vi::MOI.VariableIndex, name::String)
    model.variable_info[vi.value].name = name
    return
end
function MOI.get(model::Optimizer, ::MOI.VariableName, vi::MOI.VariableIndex)
    return model.variable_info[vi.value].name
end
