# Copyright (c) 2016: Ng Yee Sian, Miles Lubin, other contributors
#
# Use of this source code is governed by an MIT-style license that can be found
# in the LICENSE.md file or at https://opensource.org/licenses/MIT.

MOI.get(model::Optimizer, ::MOI.RawStatusString) = string(get_status(model.inner))

const KN_TO_MOI_RETURN_STATUS = Dict{Int,MOI.TerminationStatusCode}(
    0 => MOI.LOCALLY_SOLVED,
    -100 => MOI.ALMOST_OPTIMAL,
    -101 => MOI.SLOW_PROGRESS,
    -102 => MOI.SLOW_PROGRESS,
    -103 => MOI.SLOW_PROGRESS,
    -200 => MOI.LOCALLY_INFEASIBLE,
    -201 => MOI.LOCALLY_INFEASIBLE,
    -202 => MOI.LOCALLY_INFEASIBLE,
    -203 => MOI.LOCALLY_INFEASIBLE,
    -204 => MOI.LOCALLY_INFEASIBLE,
    -205 => MOI.LOCALLY_INFEASIBLE,
    -300 => MOI.DUAL_INFEASIBLE,
    -301 => MOI.DUAL_INFEASIBLE,
    -400 => MOI.ITERATION_LIMIT,
    -401 => MOI.TIME_LIMIT,
    -402 => MOI.OTHER_LIMIT,
    -403 => MOI.OTHER_LIMIT,
    -404 => MOI.OTHER_LIMIT,
    -405 => MOI.OTHER_LIMIT,
    -406 => MOI.NODE_LIMIT,
    -410 => MOI.ITERATION_LIMIT,
    -411 => MOI.TIME_LIMIT,
    -412 => MOI.INFEASIBLE,
    -413 => MOI.INFEASIBLE,
    -414 => MOI.OTHER_LIMIT,
    -415 => MOI.OTHER_LIMIT,
    -416 => MOI.NODE_LIMIT,
    -500 => MOI.INVALID_MODEL,
    -501 => MOI.NUMERICAL_ERROR,
    -502 => MOI.INVALID_MODEL,
    -503 => MOI.MEMORY_LIMIT,
    -504 => MOI.INTERRUPTED,
    -505 => MOI.OTHER_ERROR,
    -506 => MOI.OTHER_ERROR,
    -507 => MOI.OTHER_ERROR,
    -508 => MOI.OTHER_ERROR,
    -509 => MOI.OTHER_ERROR,
    -510 => MOI.OTHER_ERROR,
    -511 => MOI.OTHER_ERROR,
    -512 => MOI.OTHER_ERROR,
    -513 => MOI.OTHER_ERROR,
    -514 => MOI.OTHER_ERROR,
    -515 => MOI.OTHER_ERROR,
    -516 => MOI.OTHER_ERROR,
    -517 => MOI.OTHER_ERROR,
    -518 => MOI.OTHER_ERROR,
    -519 => MOI.OTHER_ERROR,
    -519 => MOI.OTHER_ERROR,
    -520 => MOI.OTHER_ERROR,
    -521 => MOI.OTHER_ERROR,
    -522 => MOI.OTHER_ERROR,
    -523 => MOI.OTHER_ERROR,
    -524 => MOI.OTHER_ERROR,
    -525 => MOI.OTHER_ERROR,
    -526 => MOI.OTHER_ERROR,
    -527 => MOI.OTHER_ERROR,
    -528 => MOI.OTHER_ERROR,
    -529 => MOI.OTHER_ERROR,
    -530 => MOI.OTHER_ERROR,
    -531 => MOI.OTHER_ERROR,
    -532 => MOI.OTHER_ERROR,
    -600 => MOI.OTHER_ERROR,
)

# Refer to KNITRO manual for solver status:
# https://www.artelys.com/tools/knitro_doc/3_referenceManual/returnCodes.html#returncodes
function MOI.get(model::Optimizer, ::MOI.TerminationStatus)
    if model.number_solved == 0
        return MOI.OPTIMIZE_NOT_CALLED
    end
    status = get_status(model.inner)
    if haskey(KN_TO_MOI_RETURN_STATUS, status)
        return KN_TO_MOI_RETURN_STATUS[status]
    end
    return MOI.OTHER_ERROR
end

function MOI.get(model::Optimizer, ::MOI.ResultCount)
    return model.number_solved >= 1 ? 1 : 0
end

function MOI.get(model::Optimizer, status::MOI.PrimalStatus)
    if model.number_solved == 0 || status.result_index != 1
        return MOI.NO_SOLUTION
    end
    status = get_status(model.inner)
    if status == 0
        return MOI.FEASIBLE_POINT
    elseif -109 <= status <= -100
        return MOI.FEASIBLE_POINT
    elseif -209 <= status <= -200
        return MOI.INFEASIBLE_POINT
        # TODO(odow): we don't support returning certificates yet
        # elseif status == -300
        #     return MOI.INFEASIBILITY_CERTIFICATE
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

function MOI.get(model::Optimizer, status::MOI.DualStatus)
    if model.number_solved == 0 || status.result_index != 1
        return MOI.NO_SOLUTION
    end
    status = get_status(model.inner)
    if status == 0
        return MOI.FEASIBLE_POINT
    elseif -109 <= status <= -100
        return MOI.FEASIBLE_POINT
        # elseif -209 <= status <= -200
        #     return MOI.INFEASIBILITY_CERTIFICATE
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

function MOI.get(model::Optimizer, obj::MOI.ObjectiveValue)
    if model.number_solved == 0
        error("ObjectiveValue not available.")
    elseif obj.result_index != 1
        throw(MOI.ResultIndexBoundsError{MOI.ObjectiveValue}(obj, 1))
    end
    return get_objective(model.inner)
end

function MOI.get(model::Optimizer, v::MOI.VariablePrimal, vi::MOI.VariableIndex)
    if model.number_solved == 0
        error("VariablePrimal not available.")
    elseif v.result_index > 1
        throw(MOI.ResultIndexBoundsError{MOI.VariablePrimal}(v, 1))
    end
    check_inbounds(model, vi)
    return get_solution(model.inner, vi.value)
end

function checkcons(model, ci, cp)
    if model.number_solved == 0
        error("Solve problem before accessing solution.")
    elseif cp.result_index > 1
        throw(MOI.ResultIndexBoundsError{typeof(cp)}(cp, 1))
    elseif !(0 <= ci.value <= number_constraints(model) - 1)
        error("Invalid constraint index ", ci.value)
    end
    return
end

function MOI.get(
    model::Optimizer,
    cp::MOI.ConstraintPrimal,
    ci::MOI.ConstraintIndex{S,T},
) where {
    S<:Union{MOI.ScalarAffineFunction{Float64},MOI.ScalarQuadraticFunction{Float64}},
    T<:Union{
        MOI.EqualTo{Float64},
        MOI.GreaterThan{Float64},
        MOI.LessThan{Float64},
        MOI.Interval{Float64},
    },
}
    checkcons(model, ci, cp)
    g = KN_get_con_values(model.inner)
    return g[model.constraint_mapping[ci].+1]
end

# function MOI.get(
#     model::Optimizer,
#     cp::MOI.ConstraintPrimal,
#     ci::MOI.ConstraintIndex{S,MOI.SecondOrderCone},
# ) where {S<:Union{MOI.VectorAffineFunction{Float64},MOI.VectorOfVariables}}
#     return # Not supported
# end

function MOI.get(
    model::Optimizer,
    cp::MOI.ConstraintPrimal,
    ci::MOI.ConstraintIndex{
        MOI.VariableIndex,
        <:Union{MOI.EqualTo{Float64},MOI.GreaterThan{Float64},MOI.LessThan{Float64}},
    },
)
    if model.number_solved == 0
        error("ConstraintPrimal not available.")
    elseif cp.result_index != 1
        throw(MOI.ResultIndexBoundsError{MOI.ConstraintPrimal}(cp, 1))
    end
    vi = MOI.VariableIndex(ci.value)
    check_inbounds(model, vi)
    return get_solution(model.inner, vi.value)
end

function MOI.get(
    model::Optimizer,
    cp::MOI.ConstraintPrimal,
    ci::Vector{
        MOI.ConstraintIndex{
            MOI.VariableIndex,
            <:Union{MOI.EqualTo{Float64},MOI.GreaterThan{Float64},MOI.LessThan{Float64}},
        },
    },
)
    if model.number_solved == 0
        error("ConstraintPrimal not available.")
    elseif cp.result_index > 1
        throw(MOI.ResultIndexBoundsError{MOI.ConstraintPrimal}(cp, 1))
    end
    x = get_solution(model.inner)
    return [x[c.value] for c in ci]
end

# KNITRO's dual sign depends on optimization sense.
sense_dual(model::Optimizer) = model.sense == MOI.MAX_SENSE ? 1.0 : -1.0

function MOI.get(
    model::Optimizer,
    cd::MOI.ConstraintDual,
    ci::MOI.ConstraintIndex{S,T},
) where {
    S<:Union{MOI.ScalarAffineFunction{Float64},MOI.ScalarQuadraticFunction{Float64}},
    T<:Union{
        MOI.EqualTo{Float64},
        MOI.GreaterThan{Float64},
        MOI.LessThan{Float64},
        MOI.Interval{Float64},
    },
}
    checkcons(model, ci, cd)
    index = model.constraint_mapping[ci] + 1
    lambda = get_dual(model.inner)
    return sense_dual(model) * lambda[index]
end

# function MOI.get(
#     model::Optimizer,
#     cd::MOI.ConstraintDual,
#     ci::MOI.ConstraintIndex{S,MOI.SecondOrderCone},
# ) where {S<:Union{MOI.VectorAffineFunction{Float64},MOI.VectorOfVariables}}
#     return  # Not supported.
# end

function _reduced_cost(
    model,
    attr::MOI.ConstraintDual,
    ci::MOI.ConstraintIndex{MOI.VariableIndex,S},
) where {S}
    if model.number_solved == 0
        error("ConstraintDual not available.")
    elseif attr.result_index != 1
        throw(MOI.ResultIndexBoundsError{MOI.ConstraintDual}(attr, 1))
    end
    vi = MOI.VariableIndex(ci.value)
    check_inbounds(model, vi)
    offset = number_constraints(model)
    return sense_dual(model) * get_dual(model.inner, vi.value + offset)
end

function MOI.get(
    model::Optimizer,
    attr::MOI.ConstraintDual,
    ci::MOI.ConstraintIndex{MOI.VariableIndex,MOI.LessThan{Float64}},
)
    return min(0.0, _reduced_cost(model, attr, ci))
end

function MOI.get(
    model::Optimizer,
    attr::MOI.ConstraintDual,
    ci::MOI.ConstraintIndex{MOI.VariableIndex,MOI.GreaterThan{Float64}},
)
    return max(0.0, _reduced_cost(model, attr, ci))
end

function MOI.get(
    model::Optimizer,
    attr::MOI.ConstraintDual,
    ci::MOI.ConstraintIndex{MOI.VariableIndex,S},
) where {S<:Union{MOI.EqualTo{Float64},MOI.Interval{Float64}}}
    return _reduced_cost(model, attr, ci)
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

if KNITRO_VERSION >= v"12.0"
    MOI.get(model::Optimizer, ::MOI.SolveTimeSec) = KN_get_solve_time_cpu(model.inner)
end

MOI.get(model::Optimizer, ::MOI.NodeCount) = KN_get_mip_number_nodes(model.inner)

MOI.get(model::Optimizer, ::MOI.BarrierIterations) = KN_get_number_iters(model.inner)

MOI.get(model::Optimizer, ::MOI.RelativeGap) = KN_get_mip_rel_gap(model.inner)

MOI.get(model::Optimizer, ::MOI.ObjectiveBound) = KN_get_mip_relaxation_bnd(model.inner)
