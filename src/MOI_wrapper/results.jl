# MathOptInterface results
MOI.get(model::Optimizer, ::MOI.RawStatusString) = string(get_status(model.inner))

# Refer to KNITRO manual for solver status:
# https://www.artelys.com/tools/knitro_doc/3_referenceManual/returnCodes.html#returncodes
function MOI.get(model::Optimizer, ::MOI.TerminationStatus)
    if model.number_solved == 0
        return MOI.OPTIMIZE_NOT_CALLED
    end
    status = get_status(model.inner)
    if status == 0
        return MOI.LOCALLY_SOLVED
    elseif status == -100
        return MOI.ALMOST_OPTIMAL
    elseif -109 <= status <= -101
        return MOI.ALMOST_OPTIMAL
    elseif -209 <= status <= -200
        return MOI.LOCALLY_INFEASIBLE
    elseif status == -300
        return MOI.DUAL_INFEASIBLE
    elseif (status == -400) || (status == -410)
        return MOI.ITERATION_LIMIT
    elseif (status == -401) || (status == -411)
        return MOI.TIME_LIMIT
    elseif (status == -413) || (status == -412)
        return MOI.LOCALLY_INFEASIBLE
    elseif (-405 <= status <= -402) || (-415 <= status <= -414)
        return MOI.OTHER_LIMIT
    elseif (status == -406) || (status == -416)
        return MOI.NODE_LIMIT
    elseif -599 <= status <= -500
        return MOI.OTHER_ERROR
    elseif status == -503
        return MOI.MEMORY_LIMIT
    elseif status == -504
        return MOI.INTERRUPTED
    elseif (status == -505 ) || (status == -521)
        return MOI.INVALID_OPTION
    elseif (-514 <= status <= -506 ) || (-532 <= status <= -522)
        return MOI.INVALID_MODEL
    elseif (-525 <= status <= -522 )
        return MOI.NUMERICAL_ERROR
    elseif (status == -600) || (-520 <= status <= -515)
        return MOI.OTHER_ERROR
    else
        error("Unrecognized KNITRO status $status")
    end
end

# TODO
function MOI.get(model::Optimizer, ::MOI.ResultCount)
    return (model.number_solved >= 1) ? 1 : 0
end

function MOI.get(model::Optimizer, ::MOI.PrimalStatus)
    if model.number_solved == 0
        return MOI.NO_SOLUTION
    end
    status = get_status(model.inner)
    if status == 0
        return MOI.FEASIBLE_POINT
    elseif -109 <= status <= -100
        return MOI.FEASIBLE_POINT
    elseif -209 <= status <= -200
        return MOI.INFEASIBLE_POINT
    elseif status == -300
        return MOI.INFEASIBILITY_CERTIFICATE
    elseif -409 <= status <= -400
        return MOI.FEASIBLE_POINT
    elseif -419 <= status <= -410
        return MOI.INFEASIBLE_POINT
    elseif -599 <= status <= -500
        return MOI.UNKNOWN_RESULT_STATUS
    else
        return MOI.UNKNOWN_RESULT_STATUS
    end
end

function MOI.get(model::Optimizer, ::MOI.DualStatus)
    if model.number_solved == 0
        return MOI.NO_SOLUTION
    end
    status = get_status(model.inner)
    if status == 0
        return MOI.FEASIBLE_POINT
    elseif -109 <= status <= -100
        return MOI.FEASIBLE_POINT
    elseif -209 <= status <= -200
        return MOI.INFEASIBILITY_CERTIFICATE
    elseif status == -300
        return MOI.NO_SOLUTION
    elseif -409 <= status <= -400
        return MOI.FEASIBLE_POINT
    elseif -419 <= status <= -410
        return MOI.INFEASIBLE_POINT
    elseif -599 <= status <= -500
        return MOI.UNKNOWN_RESULT_STATUS
    else
        return MOI.UNKNOWN_RESULT_STATUS
    end
end

function MOI.get(model::Optimizer, ::S) where S <: MOI.ObjectiveValue
    if model.number_solved == 0
        error("ObjectiveValue not available.")
    end
    return get_objective(model.inner)
end

function MOI.get(model::Optimizer,
                 ::MOI.VariablePrimal, vi::MOI.VariableIndex)
    if model.number_solved == 0
        error("VariablePrimal not available.")
    end
    check_inbounds(model, vi)
    return get_solution(model.inner, vi.value)
end
function MOI.get(model::Optimizer,
                 ::MOI.VariablePrimal, vi::Vector{MOI.VariableIndex})
    if model.number_solved == 0
        error("VariablePrimal not available.")
    end
    x = get_solution(model.inner)
    return [x[v.value] for v in vi]
end

macro checkcons(model, ci)
    quote
        if $(esc(model)).number_solved == 0
            error("Solve problem before accessing solution.")
        end
        if !(0 <= $(esc(ci)).value <= number_constraints($(esc(model))) - 1)
            error("Invalid constraint index ", $(esc(ci)).value)
        end
    end
end

##################################################
## ConstraintPrimal
function MOI.get(model::Optimizer, ::MOI.ConstraintPrimal,
                 ci::MOI.ConstraintIndex{S, T}) where {S <: SF, T <: SS}
    @checkcons(model, ci)
    g = KN_get_con_values(model.inner)
    index = model.constraint_mapping[ci] .+ 1
    return g[index]
end

function MOI.get(model::Optimizer, ::MOI.ConstraintPrimal,
                 ci::MOI.ConstraintIndex{S, T}) where {S <: VAF, T <: Union{MOI.Nonnegatives, MOI.Nonpositives}}
    @checkcons(model, ci)
    g = KN_get_con_values(model.inner)
    index = model.constraint_mapping[ci] .+ 1
    return g[index]
end

function MOI.get(model::Optimizer, ::MOI.ConstraintPrimal,
                 ci::MOI.ConstraintIndex{S, T}) where {S <: VOV, T <: Union{MOI.Nonnegatives, MOI.Nonpositives}}
    @checkcons(model, ci)
    x = get_solution(model.inner)
    index = model.constraint_mapping[ci] .+ 1
    return x[index]
end

function MOI.get(model::Optimizer, ::MOI.ConstraintPrimal,
                 ci::MOI.ConstraintIndex{S, T}) where {S <: Union{VAF, VOV}, T <: MOI.Zeros}
    @checkcons(model, ci)
    ncons = length(model.constraint_mapping[ci])
    return zeros(ncons)
end

function MOI.get(model::Optimizer, ::MOI.ConstraintPrimal,
                 ci::MOI.ConstraintIndex{S, T}) where {S <: Union{VAF, VOV}, T <: MOI.SecondOrderCone}
    @checkcons(model, ci)
    x = get_solution(model.inner)
    index = model.constraint_mapping[ci] .+ 1
    return x[index]
end

function MOI.get(model::Optimizer, ::MOI.ConstraintPrimal,
                 ci::MOI.ConstraintIndex{MOI.SingleVariable,
                                         MOI.LessThan{Float64}})
    if model.number_solved == 0
        error("ConstraintPrimal not available.")
    end
    g = KN_get_con_values(model.inner)

    allindex = Int[]
    for ci in cis
        append!(allindex, index + 1)
    end

    return g[allindex]
end

function MOI.get(model::Optimizer, ::MOI.ConstraintPrimal,
                 ci::MOI.ConstraintIndex{MOI.SingleVariable, <:LS})
    if model.number_solved == 0
        error("ConstraintPrimal not available.")
    end
    vi = MOI.VariableIndex(ci.value)
    check_inbounds(model, vi)
    return get_solution(model.inner, vi.value)
end

function MOI.get(model::Optimizer, ::MOI.ConstraintPrimal,
                 ci::Vector{MOI.ConstraintIndex{MOI.SingleVariable, <:LS}})
    if model.number_solved == 0
        error("ConstraintPrimal not available.")
    end
    x = get_solution(model.inner)
    return [x[c.value] for c in ci]
end

##################################################
## ConstraintDual
#
# KNITRO's dual sign depends on optimization sense.
sense_dual(model::Optimizer) = (model.sense == MOI.MAX_SENSE) ? 1. : -1.

function MOI.get(model::Optimizer, ::MOI.ConstraintDual,
                 ci::MOI.ConstraintIndex{S, T}) where {S <: SF, T <: SS}
    @checkcons(model, ci)

    index = model.constraint_mapping[ci] + 1
    lambda = get_dual(model.inner)
    return sense_dual(model) * lambda[index]
end

function MOI.get(model::Optimizer, ::MOI.ConstraintDual,
                 ci::MOI.ConstraintIndex{S, T}) where {S <: VAF, T <: VLS}
    @checkcons(model, ci)
    index = model.constraint_mapping[ci] .+ 1
    lambda = get_dual(model.inner)
    return sense_dual(model) * lambda[index]
end

function MOI.get(model::Optimizer, ::MOI.ConstraintDual,
                 ci::MOI.ConstraintIndex{S, T}) where {S <: VOV, T <: VLS}
    offset = number_constraints(model)
    index = model.constraint_mapping[ci] .+ 1 .+ offset
    lambda = get_dual(model.inner)
    return sense_dual(model) * lambda[index]
end

###
# Get constraint of a SOC constraint.
#
# Use the following mathematical property.  Let
#
#   ||u_i || <= t_i      with dual constraint    || z_i || <= w_i
#
# At optimality, we have
#
#   w_i * u_i  = - t_i z_i
#
###
function MOI.get(model::Optimizer, ::MOI.ConstraintDual,
                 ci::MOI.ConstraintIndex{S, T}) where {S <: Union{VAF, VOV}, T <: MOI.SecondOrderCone}
    @checkcons(model, ci)
    index_var = model.constraint_mapping[ci] .+ 1
    index_con = ci.value
    x =  get_solution(model.inner)[index_var]
    # By construction.
    t_i = x[1]
    u_i = x[2:end]
    w_i = get_dual(model.inner)[index_con]

    dual = [-w_i; 1/t_i * w_i * u_i]

    return dual
end

## Reduced costs.
function MOI.get(model::Optimizer, ::MOI.ConstraintDual,
                 ci::MOI.ConstraintIndex{MOI.SingleVariable, MOI.LessThan{Float64}})
    if model.number_solved == 0
        error("ConstraintDual not available.")
    end
    vi = MOI.VariableIndex(ci.value)
    check_inbounds(model, vi)

    # Constraints' duals are before reduced costs in KNITRO.
    offset = number_constraints(model)
    lambda = sense_dual(model) * get_dual(model.inner, vi.value + offset)
    if lambda < 0
        return lambda
    else
        return 0
    end
end

function MOI.get(model::Optimizer, ::MOI.ConstraintDual,
                 ci::MOI.ConstraintIndex{MOI.SingleVariable, MOI.GreaterThan{Float64}})
    if model.number_solved == 0
        error("ConstraintDual not available.")
    end
    vi = MOI.VariableIndex(ci.value)
    check_inbounds(model, vi)

    # Constraints' duals are before reduced costs in KNITRO.
    offset = number_constraints(model)
    lambda = sense_dual(model) * get_dual(model.inner, vi.value + offset)
    if lambda > 0
        return lambda
    else
        return 0
    end
end

function MOI.get(model::Optimizer, ::MOI.ConstraintDual,
                 ci::MOI.ConstraintIndex{MOI.SingleVariable, MOI.EqualTo{Float64}})
    if model.number_solved == 0
        error("ConstraintDual not available.")
    end
    vi = MOI.VariableIndex(ci.value)
    check_inbounds(model, vi)

    # Constraints' duals are before reduced costs in KNITRO.
    offset = number_constraints(model)
    lambda = get_dual(model.inner, vi.value + offset)
    return sense_dual(model) * lambda
end

function MOI.get(model::Optimizer, ::MOI.NLPBlockDual)
    if model.number_solved == 0
        error("NLPBlockDual not available.")
    end
    # Get first index corresponding to a non-linear constraint:
    lambda = get_dual(model.inner)
    # FIXME: Assume that lambda has same sense as for linear
    # and quadratic constraint, but this is not tested inside MOI.
    return sense_dual(model) .* [lambda[i+1] for i in model.nlp_index_cons]
end

###
if KNITRO_VERSION >= v"12.0"
    MOI.get(model::Optimizer, ::MOI.SolveTimeSec) = KN_get_solve_time_cpu(model.inner)
end
# Additional getters
MOI.get(model::Optimizer, ::MOI.NodeCount) = KN_get_mip_number_nodes(model.inner)
MOI.get(model::Optimizer, ::MOI.BarrierIterations) = KN_get_number_iters(model.inner)
MOI.get(model::Optimizer, ::MOI.RelativeGap) = KN_get_mip_rel_gap(model.inner)
MOI.get(model::Optimizer, ::MOI.ObjectiveBound) = KN_get_mip_relaxation_bnd(model.inner)
