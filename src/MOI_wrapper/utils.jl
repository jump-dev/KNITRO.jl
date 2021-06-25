# Utils for MathOptInterface
#
##################################################
# Import legacy from LinQuadOptInterface to ease the integration
# of KNITRO quadratic and linear facilities.
##################################################
# URL: https://github.com/JuliaOpt/LinQuadOptInterface.jl
#
# LICENSE:
# MIT License
# Copyright (c) 2017 Oscar Dowson, Joaquim Dias Garcia and contributors
##################################################

function reduce_duplicates!(rows::Vector{T}, cols::Vector{T}, vals::Vector{S}) where T where S
    @assert length(rows) == length(cols) == length(vals)
    for i in 1:length(rows)
        if rows[i] > cols[i]
            tmp = rows[i]
            rows[i] = cols[i]
            cols[i] = tmp
        end
    end
    return findnz(sparse(rows, cols, vals))
end

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
        Cint[term.variable_1.value for term in func.quadratic_terms],
        Cint[term.variable_2.value for term in func.quadratic_terms],
        Cdouble[term.coefficient for term in func.quadratic_terms]
    )
    # Take care of difference between MOI standards and KNITRO ones.
    for i in 1:length(quad_coefficients)
        @inbounds if quad_columns_1[i] == quad_columns_2[i]
            quad_coefficients[i] *= .5
        end
    end
    return reduce_duplicates!(quad_columns_1, quad_columns_2, quad_coefficients)
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
    affine_columns = Cint[term.variable.value - 1 for term in func.affine_terms]
    affine_coefficients = Cdouble[term.coefficient for term in func.affine_terms]
    return affine_columns, affine_coefficients
end
function canonical_linear_reduction(func::MOI.ScalarAffineFunction)
    affine_columns = Cint[term.variable.value - 1 for term in func.terms]
    affine_coefficients = Cdouble[term.coefficient for term in func.terms]
    return affine_columns, affine_coefficients
end

function canonical_vector_affine_reduction(func::MOI.VectorAffineFunction)
    index_cols = Cint[]
    index_vars = Cint[]
    coefs = Cdouble[]

    for t in func.terms
        push!(index_cols, t.output_index - 1)
        push!(index_vars, t.scalar_term.variable.value - 1)
        push!(coefs, t.scalar_term.coefficient)
    end
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
