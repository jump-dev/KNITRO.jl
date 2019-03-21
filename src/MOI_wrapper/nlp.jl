# MathOptInterface NLP

MOI.supports(::Optimizer, ::MOI.NLPBlock) = true

function MOI.set(model::Optimizer, ::MOI.NLPBlock, nlp_data::MOI.NLPBlockData)
    model.nlp_data = nlp_data
end

# Keep loading of NLP constraints apart to load all NLP model all in once
# inside Knitro.
function load_nlp_constraints(model::Optimizer)
    num_nlp_constraints = length(model.nlp_data.constraint_bounds)

    # We need to load the NLP constraints inside Knitro.
    if num_nlp_constraints > 0
        num_cons = KN_add_cons(model.inner, num_nlp_constraints)

        for (ib, pair) in enumerate(model.nlp_data.constraint_bounds)
            if pair.upper == pair.lower
                KN_set_con_eqbnd(model.inner, num_cons[ib], pair.upper)
            else
                ub = check_value(pair.upper)
                lb = check_value(pair.lower)
                KN_set_con_upbnd(model.inner, num_cons[ib], ub)
                KN_set_con_lobnd(model.inner, num_cons[ib], lb)
            end
        end
        # Add constraint to index.
        model.nlp_index_cons = num_cons
    end
    return
end
