# Utils for MathOptInterface
#
##################################################
# Import legacy from LinQuadOptInterface to ease the integration
# of KNITRO quadratic and linear facilities.
"""
    canonical_quadratic_reduction(func::ScalarQuadraticFunction)

Reduce a ScalarQuadraticFunction into three arrays, returned in the following
order:
 1. a vector of quadratic row indices
 2. a vector of quadratic column indices
 3. a vector of quadratic coefficients

Warning: we assume in this function that all variables are correctly
ordered, that is no deletion or swap has occured.
"""
function canonical_quadratic_reduction(func::MOI.ScalarQuadraticFunction)
    quad_columns_1, quad_columns_2, quad_coefficients = (
        Int32[term.variable_index_1.value for term in func.quadratic_terms],
        Int32[term.variable_index_2.value for term in func.quadratic_terms],
        [term.coefficient for term in func.quadratic_terms]
    )
    # Take care of difference between MOI standards and KNITRO ones.
    for i in 1:length(quad_coefficients)
        if quad_columns_1[i] == quad_columns_2[i]
            quad_coefficients[i] *= .5
        end
    end
    # Take care that Julia is 1-indexed.
    quad_columns_1 .-= 1
    quad_columns_2 .-= 1
    return quad_columns_1, quad_columns_2, quad_coefficients
end

"""
    canonical_linear_reduction(func::Quad)

Reduce a ScalarQuadraticFunction into two arrays, returned in the following
order:
 1. a vector of linear column indices
 2. a vector of linear coefficients

Warning: we assume in this function that all variables are correctly
ordered, that is no deletion or swap has occured.
"""
function canonical_linear_reduction(func::MOI.ScalarQuadraticFunction)
    affine_columns = Int32[term.variable_index.value for term in func.affine_terms]
    affine_coefficients = [term.coefficient for term in func.affine_terms]
    affine_columns .-= 1
    return affine_columns, affine_coefficients
end
function canonical_linear_reduction(func::MOI.ScalarAffineFunction)
    affine_columns = Int32[term.variable_index.value for term in func.terms]
    affine_coefficients = [term.coefficient for term in func.terms]
    affine_columns .-= 1
    return affine_columns, affine_coefficients
end

function canonical_vector_affine_reduction(func::MOI.VectorAffineFunction)
    index_cols = Int32[]
    index_vars = Int32[]
    coefs = Float64[]

    for t in func.terms
        push!(index_cols, t.output_index)
        push!(index_vars, t.scalar_term.variable_index.value)
        push!(coefs, t.scalar_term.coefficient)
    end
    index_cols .-= 1
    index_vars .-= 1
    return index_cols, index_vars, coefs
end

# Convert Julia'Inf to KNITRO's Inf.
function check_value(val::Float64)
    if val > KN_INFINITY
        return KN_INFINITY
    elseif val < -KN_INFINITY
        return -KN_INFINITY
    end
    return val
end
