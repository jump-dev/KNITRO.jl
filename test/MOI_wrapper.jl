module TestMOIWrapper

using Test
using KNITRO

const MOI = KNITRO.MOI

function runtests()
    for name in names(@__MODULE__; all = true)
        if startswith("$(name)", "test_")
            @testset "$(name)" begin
                getfield(@__MODULE__, name)()
            end
        end
    end
    return
end

const TEST_CONFIG = MOI.Test.Config(
    atol = 1e-4,
    rtol = 1e-4,
    optimal_status = MOI.LOCALLY_SOLVED,
    exclude = Any[
        MOI.ConstraintBasisStatus,
        MOI.DualObjectiveValue,
        MOI.ObjectiveBound,
        MOI.ListOfConstraintTypesPresent,
        MOI.ConstraintFunction,
        MOI.ObjectiveFunction,
    ]
)

const MOI_BASE_EXCLUDED = String[
    # KNITRO does not support problem's modification
    "test_modification",
    # KNITRO does not support delete
    "_delete_",
    # KNITRO returns LOCALLY_INFEASIBLE, not INFEASIBLE
    "INFEASIBLE",
    # MODEL
    "test_model_copy_to_", # TODO: No Exception thrown when we copy BadConstraintModel
    "test_model_ScalarFunctionConstantNotZero",  # RequirementUnmet: _supports(config, MOI.ConstraintFunction)
    # VARIABLE
    "test_variable_get_VariableIndex", # Knitro does not support get(::, ::MathOptInterface.VariableIndex, ::String)
    # SOLVE
    "test_solve_DualStatus_INFEASIBILITY_CERTIFICATE_",
    # CONSTRAINTS
    "test_constraint_ZeroOne", # Wrong solution returned
    "test_constraint_VectorAffineFunction_duplicate", # Knitro does not support get(::, ::MathOptInterface.VariableIndex, ::String)
    "test_constraint_PrimalStart_DualStart_SecondOrderCone", #TODO : bug in conic interface
    # LINEAR
    "test_linear_transform", # Knitro does not support model transform
    "test_linear_Semicontinuous_integration", # Wrong return status
    "test_linear_Semiinteger_integration", # Wrong return status
    # QUADRATIC
    "test_quadratic_Integer_SecondOrderCone", # MOI.get(model, MOI.TerminationStatus()) == MOI.OTHER_LIMIT
    # CONIC
    "test_conic", # TODO: solve issues with conic interface
]

function test_MOI_Test_cached()
    bridged = MOI.Bridges.full_bridge_optimizer(KNITRO.Optimizer(), Float64)
    model = MOI.Utilities.CachingOptimizer(
        MOI.Utilities.UniversalFallback(MOI.Utilities.Model{Float64}()),
        bridged,
    )
    MOI.set(model, MOI.Silent(), true)
    excluded = copy(MOI_BASE_EXCLUDED)
    append!(excluded, [
        "test_quadratic_nonhomogeneous", # Knitro diverges on second problem solved
    ])
    MOI.Test.runtests(
        model,
        TEST_CONFIG;
        exclude = excluded,
    )
end

function test_MOI_Test_bridged()
    model = MOI.Bridges.full_bridge_optimizer(
        KNITRO.Optimizer(),
        Float64,
    )
    MOI.set(model, MOI.Silent(), true)
    excluded = copy(MOI_BASE_EXCLUDED)
    append!(excluded, [
        "test_add_constrained_variables_vector", # Knitro does not support getting MOI.ConstraintSet
        "test_basic", # TODO: Need better support for names
        "test_model", # TODO: Need better support for names
        "test_objective_set_via_modify", # KNITRO does not support getting MOI.ListOfModelAttributesSet
        "test_objective_get_ObjectiveFunction_ScalarAffineFunction", # KNITRO does not support getting MOI.ObjectiveFunction
        "test_objective_ObjectiveFunction_VariableIndex", # KNITRO does not support getting MOI.ObjectiveFunctionType
        "test_quadratic_duplicate_terms", # Knitro does not support getting MOI.ObjectiveFunction / MOI.ConstraintFunction
        "test_quadratic_integration", # Knitro does not support getting ObjectiveFunction / MOI.ConstraintFunction
        "test_constraint_get_ConstraintIndex", # Knitro does not support get(::, ::MathOptInterface.VariableIndex, ::String)
    ])
    MOI.Test.runtests(
        model,
        TEST_CONFIG;
        exclude = excluded,
    )
    return
end

end

TestMOIWrapper.runtests()

