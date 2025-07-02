# Copyright (c) 2016: Ng Yee Sian, Miles Lubin, other contributors
#
# Use of this source code is governed by an MIT-style license that can be found
# in the LICENSE.md file or at https://opensource.org/licenses/MIT.

module TestMOIWrapper

using Test

import KNITRO
import MathOptInterface as MOI

function runtests()
    for name in names(@__MODULE__; all=true)
        if startswith("$(name)", "test_")
            @testset "$(name)" begin
                getfield(@__MODULE__, name)()
            end
        end
    end
    return
end

function test_runtests()
    model = MOI.instantiate(KNITRO.Optimizer)
    config = MOI.Test.Config(
        atol=1e-3,
        rtol=1e-3,
        optimal_status=MOI.LOCALLY_SOLVED,
        infeasible_status=MOI.LOCALLY_INFEASIBLE,
        exclude=Any[MOI.VariableBasisStatus, MOI.ConstraintBasisStatus, MOI.ConstraintName],
    )
    MOI.Test.runtests(model, config; include=["test_basic_"])
    return
end

function test_MOI_Test_cached()
    second_order_exclude = [
        r"^test_conic_GeometricMeanCone_VectorAffineFunction$",
        r"^test_conic_GeometricMeanCone_VectorAffineFunction_2$",
        r"^test_conic_GeometricMeanCone_VectorOfVariables$",
        r"^test_conic_GeometricMeanCone_VectorOfVariables_2$",
        r"^test_conic_RotatedSecondOrderCone_INFEASIBLE_2$",
        r"^test_conic_RotatedSecondOrderCone_VectorAffineFunction$",
        r"^test_conic_RotatedSecondOrderCone_VectorOfVariables$",
        r"^test_conic_RotatedSecondOrderCone_out_of_order$",
        r"^test_conic_SecondOrderCone_Nonpositives$",
        r"^test_conic_SecondOrderCone_Nonnegatives$",
        r"^test_conic_SecondOrderCone_VectorAffineFunction$",
        r"^test_conic_SecondOrderCone_VectorOfVariables$",
        r"^test_conic_SecondOrderCone_out_of_order$",
        r"^test_constraint_PrimalStart_DualStart_SecondOrderCone$",
    ]
    model =
        MOI.instantiate(KNITRO.Optimizer; with_bridge_type=Float64, with_cache_type=Float64)
    MOI.set(model, MOI.Silent(), true)
    config = MOI.Test.Config(
        atol=1e-3,
        rtol=1e-3,
        optimal_status=MOI.LOCALLY_SOLVED,
        infeasible_status=MOI.LOCALLY_INFEASIBLE,
        exclude=Any[MOI.VariableBasisStatus, MOI.ConstraintBasisStatus],
    )
    MOI.Test.runtests(
        model,
        config;
        exclude=Union{String,Regex}[
            # This test seems to fail for some reason.
            # TODO(eminyouskn): Fix this.
            r"^test_linear_integer_solve_twice$",
            # TODO(odow): this test is flakey.
            r"^test_cpsat_ReifiedAllDifferent$",
            # TODO(odow): investigate issue with bridges
            r"^test_basic_VectorNonlinearFunction_GeometricMeanCone$",
            # Returns OTHER_ERROR, which is also reasonable.
            r"^test_conic_empty_matrix$",
            # Uses the ZerosBridge and ConstraintDual
            r"^test_conic_linear_VectorOfVariables_2$",
            # Returns ITERATION_LIMIT instead of DUAL_INFEASIBLE, which is okay.
            r"^test_linear_DUAL_INFEASIBLE$",
            # Incorrect ObjectiveBound with an LP, but that's understandable.
            r"^test_solve_ObjectiveBound_MAX_SENSE_LP$",
            # KNITRO doesn't support INFEASIBILITY_CERTIFICATE results.
            r"^test_solve_DualStatus_INFEASIBILITY_CERTIFICATE_$",
            # Cannot get ConstraintDualStart
            r"^test_model_ModelFilter_AbstractConstraintAttribute$",
            # ConstraintDual not supported for SecondOrderCone
            second_order_exclude...,
        ],
    )
    # Run the tests for second_order_exclude, this time excluding
    # `MOI.ConstraintDual` and `MOI.DualObjectiveValue`.
    push!(config.exclude, MOI.ConstraintDual)
    push!(config.exclude, MOI.DualObjectiveValue)
    MOI.Test.runtests(model, config; include=second_order_exclude)
    return
end

function test_zero_one_with_no_bounds()
    model = MOI.instantiate(KNITRO.Optimizer)
    MOI.set(model, MOI.Silent(), true)
    x = MOI.add_variable(model)
    MOI.add_constraint(model, x, MOI.ZeroOne())
    MOI.set(model, MOI.ObjectiveSense(), MOI.MAX_SENSE)
    MOI.set(model, MOI.ObjectiveFunction{typeof(x)}(), x)
    MOI.optimize!(model)
    @test isapprox(MOI.get(model, MOI.VariablePrimal(), x), 1.0; atol=1e-6)
    return
end

function test_zero_one_with_bounds_after_add()
    model = MOI.instantiate(KNITRO.Optimizer)
    MOI.set(model, MOI.Silent(), true)
    x = MOI.add_variable(model)
    MOI.add_constraint(model, x, MOI.ZeroOne())
    MOI.add_constraint(model, x, MOI.GreaterThan(0.2))
    MOI.add_constraint(model, x, MOI.LessThan(0.5))
    MOI.set(model, MOI.ObjectiveSense(), MOI.MAX_SENSE)
    f = 2.0 * x
    MOI.set(model, MOI.ObjectiveFunction{typeof(f)}(), f)
    MOI.optimize!(model)
    @test MOI.get(model, MOI.TerminationStatus()) == MOI.LOCALLY_INFEASIBLE
    return
end

function test_zero_one_with_bounds_before_add()
    model = MOI.instantiate(KNITRO.Optimizer)
    MOI.set(model, MOI.Silent(), true)
    x = MOI.add_variable(model)
    MOI.add_constraint(model, x, MOI.GreaterThan(0.2))
    MOI.add_constraint(model, x, MOI.LessThan(0.5))
    MOI.add_constraint(model, x, MOI.ZeroOne())
    MOI.set(model, MOI.ObjectiveSense(), MOI.MAX_SENSE)
    f = 2.0 * x
    MOI.set(model, MOI.ObjectiveFunction{typeof(f)}(), f)
    MOI.optimize!(model)
    @test MOI.get(model, MOI.TerminationStatus()) == MOI.LOCALLY_INFEASIBLE
    return
end

function test_RawOptimizerAttribute()
    model = MOI.instantiate(KNITRO.Optimizer)
    attr = MOI.RawOptimizerAttribute("bad_attr")
    @test !MOI.supports(model, attr)
    @test_throws MOI.UnsupportedAttribute{typeof(attr)} MOI.get(model, attr)
    @test_throws MOI.UnsupportedAttribute{typeof(attr)} MOI.set(model, attr, 0)
    attr = MOI.RawOptimizerAttribute("maxtime_real")
    @test MOI.supports(model, attr)
    @test_throws MOI.GetAttributeNotAllowed{typeof(attr)} MOI.get(model, attr)
    MOI.set(model, attr, 10.0)
    @test MOI.get(model, attr) == 10.0
    return
end

# Issue #289
function test_get_nlp_block()
    model = MOI.instantiate(KNITRO.Optimizer)
    MOI.set(model, MOI.Silent(), true)
    x = MOI.add_variable(model)
    f = MOI.ScalarNonlinearFunction(:^, Any[x, 4])
    MOI.add_constraint(model, f, MOI.LessThan(1.0))
    MOI.optimize!(model)
    block = MOI.get(model, MOI.NLPBlock())
    @test block.evaluator isa MOI.Nonlinear.Evaluator
    return
end

function test_maxtime_cpu()
    model = KNITRO.Optimizer()
    if KNITRO.knitro_version() >= v"15.0"
        attr = MOI.RawOptimizerAttribute("maxtime")
    else
        attr = MOI.RawOptimizerAttribute("mip_maxtimecpu")
    end
    @test MOI.supports(model, attr)
    MOI.set(model, attr, 30)
    p = Ref{Cdouble}(0.0)
    if KNITRO.knitro_version() >= v"15.0"
        # 1163 is the parameter for max time in CPU seconds
        # Its name is KN_PARAM_MAXTIME. However, using this
        # name results in an error.
        # TODO(eminyouskn): Fix this.
        KNITRO.KN_get_double_param(model.inner, 1163, p)
    else
        KNITRO.KN_get_double_param(model.inner, KNITRO.KN_PARAM_MIP_MAXTIMECPU, p)
    end
    @test p[] == 30.0
    return
end

function test_outname()
    model = KNITRO.Optimizer()
    attr = MOI.RawOptimizerAttribute("outname")
    @test MOI.supports(model, attr)
    MOI.set(model, attr, "new_name.log")
    MOI.set(model, MOI.RawOptimizerAttribute("outmode"), 1)
    MOI.add_variable(model)
    MOI.optimize!(model)
    @test isfile("new_name.log")
    @test occursin("Artelys", read("new_name.log", String))
    rm("new_name.log")
    return
end

function test_objective_sense()
    model = KNITRO.Optimizer()
    @test MOI.supports(model, MOI.ObjectiveSense())
    for sense in (MOI.MIN_SENSE, MOI.MAX_SENSE)
        MOI.set(model, MOI.ObjectiveSense(), sense)
        @test MOI.get(model, MOI.ObjectiveSense()) == sense
    end
    return
end

function test_get_objective_function()
    model = KNITRO.Optimizer()
    x = MOI.add_variable(model)
    MOI.set(model, MOI.ObjectiveSense(), MOI.MIN_SENSE)
    for f in (
        x,
        1.0 * x + 2.0,
        1.0 * x * x + 2.0 * x + 3.0,
        MOI.ScalarNonlinearFunction(:log, Any[x]),
    )
        MOI.set(model, MOI.ObjectiveFunction{typeof(f)}(), f)
        @test isapprox(MOI.get(model, MOI.ObjectiveFunction{typeof(f)}()), f)
    end
    return
end

function test_status_to_primal_status_code()
    ext = Base.get_extension(KNITRO, :KNITROMathOptInterfaceExt)
    for (status, code) in [
        0 => MOI.FEASIBLE_POINT,
        -100 => MOI.FEASIBLE_POINT,
        -199 => MOI.FEASIBLE_POINT,
        -200 => MOI.INFEASIBLE_POINT,
        -299 => MOI.INFEASIBLE_POINT,
        -300 => MOI.UNKNOWN_RESULT_STATUS,
        -301 => MOI.UNKNOWN_RESULT_STATUS,
        -399 => MOI.UNKNOWN_RESULT_STATUS,
        -400 => MOI.FEASIBLE_POINT,
        -409 => MOI.FEASIBLE_POINT,
        -410 => MOI.UNKNOWN_RESULT_STATUS,
        -499 => MOI.UNKNOWN_RESULT_STATUS,
        -500 => MOI.UNKNOWN_RESULT_STATUS,
        -599 => MOI.UNKNOWN_RESULT_STATUS,
    ]
        @test ext._status_to_primal_status_code(status) == code
    end
    for status in [1, 100, 200, 300, 400]
        @test_throws AssertionError ext._status_to_primal_status_code(status)
    end
    return
end

function test_status_to_dual_status_code()
    ext = Base.get_extension(KNITRO, :KNITROMathOptInterfaceExt)
    for (status, code) in [
        0 => MOI.FEASIBLE_POINT,
        -100 => MOI.FEASIBLE_POINT,
        -199 => MOI.FEASIBLE_POINT,
        -200 => MOI.UNKNOWN_RESULT_STATUS,
        -299 => MOI.UNKNOWN_RESULT_STATUS,
        -300 => MOI.UNKNOWN_RESULT_STATUS,
        -301 => MOI.UNKNOWN_RESULT_STATUS,
        -399 => MOI.UNKNOWN_RESULT_STATUS,
        -400 => MOI.UNKNOWN_RESULT_STATUS,
        -409 => MOI.UNKNOWN_RESULT_STATUS,
        -410 => MOI.UNKNOWN_RESULT_STATUS,
        -499 => MOI.UNKNOWN_RESULT_STATUS,
        -500 => MOI.UNKNOWN_RESULT_STATUS,
        -599 => MOI.UNKNOWN_RESULT_STATUS,
    ]
        @test ext._status_to_dual_status_code(status) == code
    end
    for status in [1, 100, 200, 300, 400]
        @test_throws AssertionError ext._status_to_dual_status_code(status)
    end
    return
end

function test_NLPBlockDual_error()
    model = KNITRO.Optimizer()
    @test_throws(
        MOI.ResultIndexBoundsError(MOI.NLPBlockDual(), 0),
        MOI.get(model, MOI.NLPBlockDual()),
    )
    return
end

function test_NodeCount()
    model = KNITRO.Optimizer()
    @test MOI.get(model, MOI.NodeCount()) === Int64(0)
    return
end

function test_BarrierIterations()
    model = KNITRO.Optimizer()
    @test MOI.get(model, MOI.BarrierIterations()) === Int64(0)
    return
end

function test_RelativeGap()
    model = KNITRO.Optimizer()
    @test MOI.get(model, MOI.RelativeGap()) === 0.0
    return
end

function test_NumberOfVariales()
    model = KNITRO.Optimizer()
    @test MOI.get(model, MOI.NumberOfVariables()) == 0
    x = MOI.add_variable(model)
    @test MOI.get(model, MOI.NumberOfVariables()) == 1
    y = MOI.add_variables(model, 2)
    @test MOI.get(model, MOI.NumberOfVariables()) == 3
    return
end

function test_RawOptimizerParameter_free()
    model = KNITRO.Optimizer()
    @test MOI.supports(model, MOI.RawOptimizerAttribute("free"))
    @test model.inner.env.ptr_env != C_NULL
    MOI.set(model, MOI.RawOptimizerAttribute("free"), true)
    @test model.inner.env.ptr_env == C_NULL
    return
end

function test_RawOptimizerParameter_option_file()
    model = KNITRO.Optimizer()
    @test MOI.supports(model, MOI.RawOptimizerAttribute("option_file"))
    dir = mktempdir()
    filename = joinpath(dir, "option_file")
    write(filename, "outlev 1")
    MOI.set(model, MOI.RawOptimizerAttribute("option_file"), filename)
    valueP = Ref{Cint}()
    KNITRO.KN_get_int_param(model.inner, KNITRO.KN_PARAM_OUTLEV, valueP)
    @test valueP[] == 1
    return
end

function test_RawOptimizerParameter_tuner_file()
    model = KNITRO.Optimizer()
    @test MOI.supports(model, MOI.RawOptimizerAttribute("tuner_file"))
    dir = mktempdir()
    filename = joinpath(dir, "tuner_file")
    if KNITRO.knitro_version() >= v"15.0"
        write(filename, "nlp_algorithm")
    else
        write(filename, "algorithm")
    end
    MOI.set(model, MOI.RawOptimizerAttribute("tuner_file"), filename)
    return
end

function test_VariableName()
    model = KNITRO.Optimizer()
    x = MOI.add_variable(model)
    @test MOI.supports(model, MOI.VariableName(), MOI.VariableIndex)
    @test MOI.get(model, MOI.VariableName(), x) == ""
    MOI.set(model, MOI.VariableName(), x, "x")
    @test MOI.get(model, MOI.VariableName(), x) == "x"
    return
end

function test_ConstraintDualStart()
    model = KNITRO.Optimizer()
    x = MOI.add_variable(model)
    for f in (x, 1.0 * x, 1.0 * x * x)
        c = MOI.add_constraint(model, f, MOI.LessThan(1.0))
        @test MOI.supports(model, MOI.ConstraintDualStart(), typeof(c))
        # Just test that this doesn't error.
        MOI.set(model, MOI.ConstraintDualStart(), c, nothing)
        MOI.set(model, MOI.ConstraintDualStart(), c, 1.0)
    end
    return
end

function test_error_kwargs()
    @test_throws(
        ErrorException(
            "Unsupported keyword arguments passed to `Optimizer`. Set attributes instead",
        ),
        KNITRO.Optimizer(; outlev=1),
    )
    return
end

function test_lm_context()
    lm = KNITRO.LMcontext()
    @test isempty(lm.linked_models)
    model = KNITRO.Optimizer(; license_manager=lm)
    @test length(lm.linked_models) == 1
    @test model.inner in lm.linked_models
    MOI.empty!(model)
    @test length(lm.linked_models) == 2
    @test model.inner in lm.linked_models
    return
end

function test_zero_one_with_bounds_after_add()
    model = KNITRO.Optimizer()
    MOI.set(model, MOI.Silent(), true)
    x = MOI.add_variable(model)
    MOI.add_constraint(model, x, MOI.ZeroOne())
    MOI.add_constraint(model, x, MOI.GreaterThan(0.2))
    MOI.add_constraint(model, x, MOI.LessThan(0.5))
    MOI.set(model, MOI.ObjectiveSense(), MOI.MAX_SENSE)
    f = 2.0 * x
    MOI.set(model, MOI.ObjectiveFunction{typeof(f)}(), f)
    MOI.optimize!(model)
    @test MOI.get(model, MOI.TerminationStatus()) == MOI.LOCALLY_INFEASIBLE
    return
end

function test_zero_one_with_bounds_before_add()
    model = KNITRO.Optimizer()
    MOI.set(model, MOI.Silent(), true)
    x = MOI.add_variable(model)
    MOI.add_constraint(model, x, MOI.GreaterThan(0.2))
    MOI.add_constraint(model, x, MOI.LessThan(0.5))
    MOI.add_constraint(model, x, MOI.ZeroOne())
    MOI.set(model, MOI.ObjectiveSense(), MOI.MAX_SENSE)
    f = 2.0 * x
    MOI.set(model, MOI.ObjectiveFunction{typeof(f)}(), f)
    MOI.optimize!(model)
    @test MOI.get(model, MOI.TerminationStatus()) == MOI.LOCALLY_INFEASIBLE
    return
end

end

TestMOIWrapper.runtests()
