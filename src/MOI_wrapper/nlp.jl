# Copyright (c) 2016: Ng Yee Sian, Miles Lubin, other contributors
#
# Use of this source code is governed by an MIT-style license that can be found
# in the LICENSE.md file or at https://opensource.org/licenses/MIT.

MOI.supports(::Optimizer, ::MOI.NLPBlock) = true

function MOI.set(model::Optimizer, ::MOI.NLPBlock, nlp_data::MOI.NLPBlockData)
    model.nlp_data = nlp_data
    return
end

# Keep loading of NLP constraints apart to load all NLP model all in once
# inside Knitro.
function load_nlp_constraints(model::Optimizer)
    num_nlp_constraints = length(model.nlp_data.constraint_bounds)
    if num_nlp_constraints == 0
        return
    end
    num_cons = KN_add_cons(model.inner, num_nlp_constraints)
    for (ib, pair) in enumerate(model.nlp_data.constraint_bounds)
        if pair.upper == pair.lower
            KN_set_con_eqbnd(model.inner, num_cons[ib], pair.upper)
        else
            KN_set_con_upbnd(model.inner, num_cons[ib], check_value(pair.upper))
            KN_set_con_lobnd(model.inner, num_cons[ib], check_value(pair.lower))
        end
    end
    model.nlp_index_cons = num_cons
    return
end

MOI.supports(::Optimizer, ::MOI.NLPBlockDualStart) = true

# TODO: FIXME
function MOI.set(model::Optimizer, ::MOI.NLPBlockDualStart, values)
    # @assert length(values) == length(model.nlp_index_cons)
    KN_set_con_dual_init_values(model.inner, Cint[0], values)
    return
end
