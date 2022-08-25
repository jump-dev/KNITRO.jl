# Copyright (c) 2016: Ng Yee Sian, Miles Lubin, other contributors
#
# Use of this source code is governed by an MIT-style license that can be found
# in the LICENSE.md file or at https://opensource.org/licenses/MIT.

function MOI.supports_constraint(
    ::Optimizer,
    ::Type{MOI.VectorOfVariables},
    ::Type{MOI.Complements},
)
    return true
end

# Complementarity constraints (x_1 complements x_2), with x_1 and x_2
# being two variables of the problem.
function MOI.add_constraint(
    model::Optimizer,
    func::MOI.VectorOfVariables,
    set::MOI.Complements,
)
    if model.number_solved >= 1
        throw(
            MOI.AddConstraintNotAllowed{typeof(func),typeof(set)}(
                "Constraints cannot be added after a call to optimize!.",
            ),
        )
    end
    indv = Cint[v.value - 1 for v in func.variables]
    # Number of complementarity in Knitro is half the dimension of the MOI set
    n_comp = div(set.dimension, 2)
    # Currently, only complementarity constraints between two variables
    # are supported.
    comp_type = fill(KN_CCTYPE_VARVAR, n_comp)
    # Number of complementarity constraint previously added
    n_comp_cons = model.complementarity_cache.n
    _add_complementarity_constraint!(
        model.complementarity_cache,
        indv[1:n_comp],
        indv[n_comp+1:end],
        comp_type,
    )
    return MOI.ConstraintIndex{typeof(func),typeof(set)}(n_comp_cons)
end
