# Copyright (c) 2016: Ng Yee Sian, Miles Lubin, other contributors
#
# Use of this source code is governed by an MIT-style license that can be found
# in the LICENSE.md file or at https://opensource.org/licenses/MIT.

using KNITRO
using Test

const MPS_PROBLEM = """
                    NAME         lo1
                    OBJSENSE     MAX
                    ROWS
                     N  obj
                     E  c1
                     G  c2
                     L  c3
                    COLUMNS
                        x1        obj       3
                        x1        c1        3
                        x1        c2        2
                        x2        obj       1
                        x2        c1        1
                        x2        c2        1
                        x2        c3        2
                        x3        obj       5
                        x3        c1        2
                        x3        c2        3
                        x4        obj       1
                        x4        c2        1
                        x4        c3        3
                    RHS
                        rhs       c1        30
                        rhs       c2        15
                        rhs       c3        25
                    RANGES
                    BOUNDS
                     UP bound     x2        10
                    ENDATA
                    """

@testset "Definition of model" begin
    m = KN_new()
    options = joinpath(dirname(@__FILE__), "..", "examples", "knitro.opt")
    KN_reset_params_to_defaults(m)
    KN_free(m)
    @test m.env.ptr_env == C_NULL
end

# add generic callbacks for future tests

function evalAll(kc, cb, evalRequest, evalResult, userParams)
    x = evalRequest.x
    evalRequestCode = evalRequest.evalRequestCode
    if evalRequestCode == KN_RC_EVALFC
        # Evaluate nonlinear objective
        evalResult.obj[1] = x[1]^2 * x[3] + x[2]^3 * x[3]^2
    elseif evalRequestCode == KN_RC_EVALGA
        evalResult.objGrad[1] = 2 * x[1] * x[3]
        evalResult.objGrad[2] = 3 * x[2]^2 * x[3]^2
        evalResult.objGrad[3] = x[1]^2 + 2 * x[2]^3 * x[3]
    elseif evalRequestCode == KN_RC_EVALH
        evalResult.hess[1] = 2 * x[3]
        evalResult.hess[2] = 2 * x[1]
        evalResult.hess[3] = 6 * x[2] * x[3]^2
        evalResult.hess[4] = 6 * x[2]^2 * x[3]
        evalResult.hess[5] = 2 * x[2]^3
    elseif evalRequestCode == KN_RC_EVALHV
        vec = evalRequest.vec
        evalResult.hessVec[1] = (2 * x[3]) * vec[1] + (2 * x[1]) * vec[3]
        evalResult.hessVec[2] = (6 * x[2] * x[3]^2) * vec[2] + (6 * x[2]^2 * x[3]) * vec[3]
        evalResult.hessVec[3] =
            (2 * x[1]) * vec[1] + (6 * x[2]^2 * x[3]) * vec[2] + (2 * x[2]^3) * vec[3]
    elseif evalRequestCode == KN_RC_EVALH_NO_F
        evalResult.hess[1] = 0
        evalResult.hess[2] = 0
        evalResult.hess[3] = 0
        evalResult.hess[4] = 0
        evalResult.hess[5] = 0
    elseif evalRequestCode == KN_RC_EVALHV_NO_F
        vec = evalRequest.vec
        evalResult.hessVec[1] = 0
        evalResult.hessVec[2] = lambda_[4] * vec[3]
        evalResult.hessVec[3] = lambda_[4] * vec[2]
    else
        return KN_RC_CALLBACK_ERR
    end
    return 0
end

function callback(name)
    function callbackFn(kc, x, lambda_, userParams)
        println(name)
        return 0
    end
    return callbackFn
end

if KNITRO.knitro_version() >= v"12.1"
    @testset "MPS reader/writer" begin
        mps_name = joinpath(dirname(@__FILE__), "lp.mps")
        mps_name_out = joinpath(dirname(@__FILE__), "lp2.mps")
        open(mps_name, "w") do io
            return write(io, MPS_PROBLEM)
        end
        kc = KN_new()
        KN_load_mps_file(kc, mps_name)
        KN_set_int_param_by_name(kc, "outlev", 0)
        KN_write_mps_file(kc, mps_name_out)
        status = KN_solve(kc)
        obj = Ref{Cdouble}(0.0)
        KN_get_solution(kc, Ref{Cint}(), obj, C_NULL, C_NULL)
        KN_free(kc)
        @test status == 0
        @test isapprox(obj[], 250.0 / 3.0, rtol=1e-6)

        # Resolve with dumped MPS file
        kc = KN_new()
        KN_load_mps_file(kc, mps_name_out)
        KN_set_int_param_by_name(kc, "outlev", 0)
        status = KN_solve(kc)
        obj = Ref{Cdouble}(0.0)
        KN_get_solution(kc, Ref{Cint}(), obj, C_NULL, C_NULL)
        KN_free(kc)
        @test status == 0
        @test isapprox(obj[], 250.0 / 3.0, rtol=1e-6)
    end
end

@testset "First problem" begin
    kc = KN_new()
    @test isa(kc, KNITRO.Model)
    # By default, kc does not have any callback
    @test isempty(kc.callbacks)

    KN_reset_params_to_defaults(kc)

    options = joinpath(dirname(@__FILE__), "..", "examples", "test_knitro.opt")
    tuner1 = joinpath(dirname(@__FILE__), "..", "examples", "tuner-fixed.opt")
    tuner2 = joinpath(dirname(@__FILE__), "..", "examples", "tuner-explore.opt")
    if KNITRO.knitro_version() >= v"15.0"
        KN_set_int_param_by_name(kc, "nlp_algorithm", 0)
    else
        KN_set_int_param_by_name(kc, "algorithm", 0)
    end
    KN_set_char_param_by_name(kc, "cplexlibname", ".")
    KN_set_double_param_by_name(kc, "xtol", 1e-15)
    KN_set_int_param(kc, KN_PARAM_ALG, KN_ALG_BAR_DIRECT)
    KN_set_char_param(kc, KN_PARAM_CPLEXLIB, ".")
    KN_set_double_param(kc, KN_PARAM_XTOL, 1e-15)

    pCint = Ref{Cint}()
    if KNITRO.knitro_version() >= v"15.0"
        KN_get_int_param_by_name(kc, "nlp_algorithm", pCint)
    else
        KN_get_int_param_by_name(kc, "algorithm", pCint)
    end
    @test pCint[] == KN_ALG_BAR_DIRECT
    pCdouble = Ref{Cdouble}()
    KN_get_double_param_by_name(kc, "xtol", pCdouble)
    @test pCdouble[] == 1e-15
    KN_get_int_param(kc, KN_PARAM_ALG, pCint)
    @test pCint[] == KN_ALG_BAR_DIRECT
    KN_get_double_param(kc, KN_PARAM_XTOL, pCdouble)
    @test pCdouble[] == 1e-15
    tmp = Vector{Cchar}(undef, 1024)
    KN_get_param_name(kc, KN_PARAM_XTOL, tmp, 1024)
    _to_string(x) = GC.@preserve(x, unsafe_string(pointer(x)))
    @test _to_string(tmp) == "xtol"
    KN_get_param_doc(kc, KN_PARAM_XTOL, tmp, 1024)
    if KNITRO.knitro_version() >= v"15.0"
        @test _to_string(tmp) ==
              "Step size tolerance used for terminating the optimization.\n"
    else
        @test _to_string(tmp) ==
              "# Step size tolerance used for terminating the optimization.\n"
    end

    KN_get_param_type(kc, KN_PARAM_XTOL, pCint)
    @test pCint[] == KN_PARAMTYPE_FLOAT
    KN_get_num_param_values(kc, KN_PARAM_XTOL, pCint)
    @test pCint[] == 0
    KN_get_param_value_doc(kc, KN_PARAM_GRADOPT, 1, tmp, 1024)
    if KNITRO.knitro_version() >= v"15.0"
        @test _to_string(tmp) == "1 (exact): User supplies exact first derivatives"
    else
        @test _to_string(tmp) == "exact"
    end
    KN_get_param_id(kc, "xtol", pCint)
    @test pCint[] == KN_PARAM_XTOL

    # START: Some specific parameter settings
    KN_set_int_param_by_name(kc, "hessopt", 1)
    KN_set_int_param_by_name(kc, "presolve", 0)
    KN_set_int_param_by_name(kc, "outlev", 0)
    # END:   Some specific parameter settings

    # Perform a derivative check.
    KN_set_int_param(kc, KN_PARAM_DERIVCHECK, KN_DERIVCHECK_ALL)

    function newpt_callback(kc, x, lambda_, user_data)
        a = Ref{Cdouble}()
        KN_get_rel_feas_error(kc, a)
        KN_get_rel_opt_error(kc, a)
        return 0
    end

    # Define objective goal
    objGoal = KN_OBJGOAL_MAXIMIZE
    KN_set_obj_goal(kc, objGoal)

    # Add the variables and set their bounds.
    nV = 3
    KN_add_vars(kc, nV, zeros(Cint, nV))
    KN_set_var_lobnds_all(kc, [0, 0.1, 0])
    KN_set_var_upbnds_all(kc, [0.0, 2, 2])
    # Define an initial point.
    KN_set_var_primal_init_values_all(kc, [1.0, 1, 1.5])
    KN_set_var_dual_init_values_all(kc, [1.0, 1, 1, 1])

    # Add the constraints and set their bounds.
    nC = 1
    KN_add_cons(kc, nC, zeros(Cint, nC))
    KN_set_con_lobnds_all(kc, [0.1])
    KN_set_con_upbnds_all(kc, [2 * 2 * 0.99])

    # Test getters.
    if KNITRO.knitro_version() >= v"12.0"
        xindex = Cint[0, 1, 2]
        ret = zeros(Cdouble, 3)
        KN_get_var_lobnds(kc, 3, xindex, ret)
        @test ret == [0, 0.1, 0]
        KN_get_var_upbnds(kc, 3, xindex, ret)
        @test ret == [0.0, 2, 2]

        cindex = Cint[0]
        ret = zeros(Cdouble, 1)
        KN_get_con_lobnds(kc, 1, cindex, ret)
        @test ret == [0.1]
        KN_get_con_upbnds(kc, 1, cindex, ret)
        @test ret == [2 * 2 * 0.99]
    end

    # Load quadratic structure x1*x2 for the constraint.
    KN_add_con_quadratic_struct(kc, 1, Cint[0], Cint[1], Cint[2], [1.0])

    # Define callback functions.
    cb = KN_add_objective_callback(kc, evalAll)
    @test !isempty(kc.callbacks)
    KN_set_cb_grad(kc, cb, evalAll)
    KN_set_cb_hess(
        kc,
        cb,
        5,
        evalAll,
        hessIndexVars1=Int32[0, 0, 1, 1, 2],
        hessIndexVars2=Int32[0, 2, 1, 2, 2],
    )

    KN_set_newpt_callback(kc, newpt_callback)

    # Add complementarity constraints.
    KN_set_compcons(kc, 1, Int32[KN_CCTYPE_VARVAR], Int32[0], Int32[1])

    # Solve the problem.
    status = KN_solve(kc)
    @test status == 0

    # Restart using the previous solution.
    nStatus, objSol, x, lambda_ = KN_get_solution(kc)
    KN_set_var_primal_init_values_all(kc, x)
    KN_set_var_dual_init_values_all(kc, lambda_)
    status = KN_solve(kc)
    @test status == 0

    # Restart with new variable bounds
    KN_set_var_lobnds_all(kc, Float64[0.0, 0, 0])
    KN_set_var_upbnds_all(kc, Float64[2.0, 2, 2])

    # Set tolerances to 1e-10
    KN_set_double_param_by_name(kc, "feastol", 1e-10)
    KN_set_double_param_by_name(kc, "opttol", 1e-8)
    status = KN_solve(kc)
    @test status == 0

    # Retrieve relevant solve information
    pCint = Ref{Cint}(0)
    KN_get_number_FC_evals(kc, pCint)
    @test pCint[] >= 1
    KN_get_number_GA_evals(kc, pCint)
    @test pCint[] >= 1
    KN_get_number_H_evals(kc, pCint)
    @test pCint[] >= 1
    KN_get_number_HV_evals(kc, pCint)
    @test pCint[] == 0
    KN_get_number_iters(kc, pCint)
    @test pCint[] >= 1
    KN_get_number_cg_iters(kc, pCint)
    @test pCint[] >= 0
    pCdouble = Ref{Cdouble}()
    KN_get_abs_feas_error(kc, pCdouble)
    @test pCdouble[] < 1e-10
    KN_get_rel_feas_error(kc, pCdouble)
    @test pCdouble[] < 1e-10
    KN_get_abs_opt_error(kc, pCdouble)
    @test pCdouble[] < 1e-7
    KN_get_rel_opt_error(kc, pCdouble)
    @test pCdouble[] < 1e-8
    KN_get_con_value(kc, 0, pCdouble)
    @test pCdouble[] ≈ 3.96
    nStatus, objSol, x, lambda_ = KN_get_solution(kc)
    @test nStatus == 0
    @test x ≈ [0.0, 2.0, 1.98]

    @test objSol ≈ 31.363199 atol = 1e-5

    # Test getters for primal and dual variables
    if KNITRO.knitro_version() >= v"12.0"
        xopt = zeros(Cdouble, 3)
        KN_get_var_primal_values(kc, 3, Cint[0, 1, 2], xopt)
        @test xopt == x
        rc = zeros(Cdouble, 3)
        KN_get_var_dual_values(kc, 3, Cint[0, 1, 2], rc)
        @test rc == lambda_[2:4]
        dual = zeros(Cdouble, 1)
        KN_get_con_dual_values(kc, 1, Cint[0], dual)
        @test dual == [lambda_[1]]
    end

    KN_free(kc)
end

@testset "Second problem test" begin
    kc = KN_new()

    function pretty_printer(contents::String, ::Any)
        print("[KNITRO.jl] $contents")
        return 12 + length(contents)
    end

    KN_set_puts_callback(kc, pretty_printer)

    # START: Some specific parameter settings
    # KN_set_int_param_by_name(kc, "outlev", 0)
    KN_set_int_param_by_name(kc, "presolve", 0)
    KN_set_int_param_by_name(kc, "ms_enable", 1)
    KN_set_int_param_by_name(kc, "ms_maxsolves", 5)
    KN_set_int_param_by_name(kc, "hessian_no_f", 1)
    KN_set_int_param_by_name(kc, "hessopt", KN_HESSOPT_PRODUCT)
    # END:   Some specific parameter settings

    # Define objective goal
    objGoal = KN_OBJGOAL_MAXIMIZE
    KN_set_obj_goal(kc, objGoal)

    # Add the variables and set their bounds.
    nV = 3
    KN_add_vars(kc, nV, zeros(Cint, nV))
    KN_set_var_lobnds_all(kc, [0, 0.1, 0])
    KN_set_var_upbnds_all(kc, [0.0, 2, 2])

    # Define an initial point.
    KN_set_var_primal_init_values_all(kc, [1, 1, 1.5])
    KN_set_var_dual_init_values_all(kc, [1, 1, 1, 1.0])

    # Add the constraints and set their lower bounds.
    nC = 1
    KN_add_cons(kc, nC, zeros(Cint, nC))
    KN_set_con_lobnds_all(kc, [0.1])
    KN_set_con_upbnds_all(kc, [2 * 2 * 0.99])

    # Load quadratic structure x1*x2 for the constraint.
    KN_add_con_quadratic_struct(kc, 1, Cint[0], Cint[1], Cint[2], [1.0])

    # Define callback functions.
    cb = KN_add_objective_callback(kc, evalAll)

    KN_set_cb_grad(kc, cb, evalAll)
    KN_set_cb_hess(kc, cb, KN_DENSE_ROWMAJOR, evalAll)

    KN_set_ms_process_callback(kc, callback("ms callback"))

    function ms_initpt_callbackFn(kc, nSolveNumber, x, lambda_, userParams)
        x[:] = [1, 1, 1.1 + 0.1 * nSolveNumber]
        lambda_[:] = [1.0, 1, 1, 1]
        return 0
    end

    # Set multistart initial point callback
    KN_set_ms_initpt_callback(kc, ms_initpt_callbackFn)

    # Add complementarity constraints.
    KN_set_compcons(kc, 1, Int32[KN_CCTYPE_VARVAR], Int32[0], Int32[1])

    # Solve the problem.
    status = KN_solve(kc)

    @test status == 0
    nStatus, objSol, x, lambda_ = KN_get_solution(kc)
    @test nStatus == 0
    @test x ≈ [0.0, 2.0, 1.98] atol = 1e-5

    @test objSol ≈ 31.363199 atol = 1e-5

    KN_free(kc)
end

@testset "Third problem test" begin
    kc = KN_new()

    KN_set_int_param_by_name(kc, "outlev", 0)
    KN_set_int_param_by_name(kc, "presolve", KN_PRESOLVEDBG_NONE)

    # Define objective goal
    objGoal = KN_OBJGOAL_MAXIMIZE
    KN_set_obj_goal(kc, objGoal)

    # Add the variables and set their bounds.
    nV = 3
    KN_add_vars(kc, nV, zeros(Cint, nV))
    KN_set_var_lobnds_all(kc, [0, 0.1, 0])
    KN_set_var_upbnds_all(kc, [0.0, 2, 2])

    # Define an initial point.
    KN_set_var_primal_init_values_all(kc, [1, 1, 1.5])
    KN_set_var_dual_init_values_all(kc, [1.0, 1, 1, 1])

    # Add the constraints and set their lower bounds.
    nC = 1
    KN_add_cons(kc, nC, zeros(Cint, nC))
    KN_set_con_lobnds_all(kc, [0.1])
    KN_set_con_upbnds_all(kc, [2 * 2 * 0.99])

    # Load quadratic structure x1*x2 for the constraint.
    KN_add_con_quadratic_struct(kc, 1, Cint[0], Cint[1], Cint[2], [1.0])

    # Define callback functions.
    cb = KN_add_objective_callback(kc, evalAll)
    KN_set_cb_grad(kc, cb, evalAll)
    KN_set_cb_hess(kc, cb, KN_DENSE_ROWMAJOR, evalAll)

    KN_set_compcons(kc, 1, Int32[KN_CCTYPE_VARVAR], Int32[0], Int32[1])

    KN_set_var_honorbnds_all(
        kc,
        [KN_HONORBNDS_ALWAYS, KN_HONORBNDS_INITPT, KN_HONORBNDS_NO],
    )

    KN_set_var_scalings(kc, 3, Int32[0, 1, 2], [1.0, 1.0, 1.0], zeros(3))
    KN_set_con_scalings_all(kc, [0.5])
    KN_set_compcon_scalings_all(kc, [2.0])
    KN_set_obj_scaling(kc, 10.0)
    status = KN_solve(kc)
    @test status == 0
    nStatus, objSol, x, lambda_ = KN_get_solution(kc)
    @test nStatus == 0
    @test x ≈ [0.0, 2.0, 1.98]
    @test objSol ≈ 31.363199 atol = 1e-5
    KN_free(kc)
end

@testset "Fourth problem test" begin
    kc = KN_new()
    # START: Some specific parameter settings
    KN_set_int_param_by_name(kc, "presolve", 0)
    KN_set_int_param_by_name(kc, "outlev", 0)
    KN_set_int_param_by_name(kc, "gradopt", 2)
    KN_set_int_param_by_name(kc, "hessopt", 2)
    KN_set_int_param_by_name(kc, "mip_numthreads", 1)
    # END:   Some specific parameter settings
    function evalF_evalGA(kc, cb, evalRequest, evalResult, userParams)
        x = evalRequest.x
        evalRequestCode = evalRequest.evalRequestCode
        if evalRequestCode == KN_RC_EVALFC
            # Evaluate nonlinear objective
            evalResult.obj[1] = x[1]^2 * x[3] + x[2]^3 * x[3]^2
        elseif evalRequestCode == KN_RC_EVALGA
            evalResult.objGrad[1] = 2 * x[1] * x[3]
            evalResult.objGrad[2] = 3 * x[2]^2 * x[3]^2
            evalResult.objGrad[3] = x[1]^2 + 2 * x[2]^3 * x[3]
        else
            return KN_RC_CALLBACK_ERR
        end
        return 0
    end
    # Define objective goal
    objGoal = KN_OBJGOAL_MAXIMIZE
    KN_set_obj_goal(kc, objGoal)
    # Add the variables and set their bounds.
    nV = 3
    KN_add_vars(kc, nV, zeros(Cint, nV))
    KN_set_var_lobnds_all(kc, [0.0, 0.1, 0.0])
    KN_set_var_upbnds_all(kc, [0.0, 2.0, 2.0])
    KN_set_var_types_all(
        kc,
        [KN_VARTYPE_CONTINUOUS, KN_VARTYPE_INTEGER, KN_VARTYPE_INTEGER],
    )
    # Define an initial point.
    KN_set_var_primal_init_values_all(kc, [1.0, 1.0, 1.5])
    KN_set_var_dual_init_values_all(kc, [1.0, 1.0, 1.0, 1.0])
    # Add the constraints and set their lower bounds.
    nC = 1
    KN_add_cons(kc, nC, zeros(Cint, nC))
    KN_set_con_lobnds_all(kc, [0.1])
    KN_set_con_upbnds_all(kc, [2 * 2 * 0.99])
    # Load quadratic structure x1*x2 for the constraint.
    KN_add_con_quadratic_struct(kc, 1, Cint[0], Cint[1], Cint[2], [1.0])
    # Define callback functions.
    cb = KN_add_objective_callback(kc, evalF_evalGA)
    KN_set_cb_grad(kc, cb, evalF_evalGA)
    # Define complementarity constraints
    KN_set_compcons(kc, 1, Int32[KN_CCTYPE_VARVAR], Int32[0], Int32[1])
    # Set MIP parameters
    KN_set_mip_branching_priorities_all(kc, Int32[0, 1, 2])
    # not compatible with MPEC constraint as a variable cannot be involved in
    # two different complementarity constraints.
    # KN_set_mip_intvar_strategies(kc, 2, KN_MIP_INTVAR_STRATEGY_MPEC)
    KN_set_mip_node_callback(kc, callback("mip_node"))
    # Set var, con and obj names
    KN_set_var_names_all(kc, ["myvar1", "myvar2", "myvar3"])
    KN_set_con_names_all(kc, ["mycon1"])
    KN_set_obj_name(kc, "myobj")
    # Set feasibility tolerances
    KN_set_var_feastols_all(kc, [0.1, 0.001, 0.1])
    KN_set_con_feastols_all(kc, [1e-4])
    KN_set_compcon_feastols_all(kc, [0.1])
    # Set finite differences step size
    KN_set_cb_relstepsizes_all(kc, cb, [0.1, 0.001, 0.1])
    # Solve the problem.
    status = KN_solve(kc)
    # Test for return codes 0 for optimality, and KN_RC_MIP_EXH_FEAS for all
    # nodes explored, assumed optimal
    @test status == 0 || status == KN_RC_MIP_EXH_FEAS
    pCdouble = Ref{Cdouble}()
    KN_get_con_value(kc, 0, pCdouble)
    @test 0.1 - 1e-4 <= pCdouble[] <= 2 * 2 * 0.99 + 1e-4
    x_val = zeros(3)
    KN_get_mip_incumbent_x(kc, x_val)
    obj_val = x_val[1]^2 * x_val[3] + x_val[2]^3 * x_val[3]^2
    KN_get_mip_incumbent_obj(kc, pCdouble)
    @test pCdouble[] ≈ obj_val
    KN_free(kc)
end

@testset "Fifth problem test" begin
    # Test in this environment the setting of user params
    myParams = "stringUserParam"
    kc = KN_new()

    KN_set_int_param_by_name(kc, "outlev", 0)
    KN_set_int_param_by_name(kc, "gradopt", 1)

    function evalR(kc, cb, evalRequest, evalResult, userParams)
        x = evalRequest.x
        # Each time we call this callback, the userParams should
        # be as specified.
        @test userParams == myParams
        evalResult.rsd[1] = x[1] * 1.309^x[2] - 2.138
        evalResult.rsd[2] = x[1] * 1.471^x[2] - 3.421
        evalResult.rsd[3] = x[1] * 1.49^x[2] - 3.597
        evalResult.rsd[4] = x[1] * 1.565^x[2] - 4.34
        evalResult.rsd[5] = x[1] * 1.611^x[2] - 4.882
        evalResult.rsd[6] = x[1] * 1.68^x[2] - 5.66
        return 0
    end

    function evalJ(kc, cb, evalRequest, evalResult, userParams)
        x = evalRequest.x
        # Each time we call this callback, the userParams should
        # be as specified.
        @test userParams == myParams
        evalResult.rsdJac[1] = 1.309^x[2]
        evalResult.rsdJac[2] = x[1] * log(1.309) * 1.309^x[2]
        evalResult.rsdJac[3] = 1.471^x[2]
        evalResult.rsdJac[4] = x[1] * log(1.471) * 1.471^x[2]
        evalResult.rsdJac[5] = 1.49^x[2]
        evalResult.rsdJac[6] = x[1] * log(1.49) * 1.49^x[2]
        evalResult.rsdJac[7] = 1.565^x[2]
        evalResult.rsdJac[8] = x[1] * log(1.565) * 1.565^x[2]
        evalResult.rsdJac[9] = 1.611^x[2]
        evalResult.rsdJac[10] = x[1] * log(1.611) * 1.611^x[2]
        evalResult.rsdJac[11] = 1.68^x[2]
        evalResult.rsdJac[12] = x[1] * log(1.68) * 1.68^x[2]
        return 0
    end

    # Add the variables and set their bounds.
    nV = 2
    KN_add_vars(kc, nV, zeros(Cint, nV))
    KN_set_var_lobnds_all(kc, [-1.0, -1.0])
    KN_set_var_upbnds_all(kc, [1.0, 1.0])
    KN_set_var_primal_init_values_all(kc, [1.0, 5.0])

    # Add the residuals
    KN_add_rsds(kc, 6, zeros(Cint, 6))

    # Define callbacks
    cb = KN_add_lsq_eval_callback(kc, evalR)
    nnzJ = 12
    KN_set_cb_rsd_jac(
        kc,
        cb,
        nnzJ,
        evalJ;
        jacIndexRsds=Int32[0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5],
        jacIndexVars=Int32[0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1],
    )
    KN_set_cb_user_params(kc, cb, myParams)
    status = KN_solve(kc)
    @test status == 0
    nStatus, objSol, x, lambda_ = KN_get_solution(kc)
    @test nStatus == 0
    @test objSol ≈ 21.5848 atol = 1e-3
    @test x ≈ [1.0, 1.0] atol = 1e-5
    KN_free(kc)
end

@testset "User callback test (issue #110)" begin
    kc = KN_new()

    KN_set_int_param_by_name(kc, "outlev", 0)
    # Define objective goal
    objGoal = KN_OBJGOAL_MAXIMIZE
    KN_set_obj_goal(kc, objGoal)

    # Add the variables and set their bounds.
    nV = 3
    KN_add_vars(kc, nV, zeros(Cint, nV))
    KN_set_var_lobnds_all(kc, [0, 0.1, 0])
    KN_set_var_upbnds_all(kc, [0.0, 2, 2])

    # Define an initial point.
    KN_set_var_primal_init_values_all(kc, [1, 1, 1.5])
    KN_set_var_dual_init_values_all(kc, [1.0, 1, 1, 1])

    # Add the constraints and set their lower bounds.
    nC = 1
    KN_add_cons(kc, nC, zeros(Cint, nC))
    KN_set_con_lobnds_all(kc, [0.1])
    KN_set_con_upbnds_all(kc, [2 * 2 * 0.99])

    # Load quadratic structure x1*x2 for the constraint.
    KN_add_con_quadratic_struct(kc, 1, Cint[0], Cint[1], Cint[2], [1.0])

    # Define callback functions.
    cb = KN_add_eval_callback_all(kc, evalAll)
    KN_set_cb_grad(kc, cb, evalAll)
    KN_set_cb_hess(kc, cb, KN_DENSE_ROWMAJOR, evalAll)

    KN_set_compcons(kc, 1, Int32[KN_CCTYPE_VARVAR], Int32[0], Int32[1])

    function newpt_callback(kc, x, lambda_, user_data)
        pCint = Ref{Cint}()
        KN_get_number_iters(kc, pCint)
        if pCint[] > 1
            return KN_RC_USER_TERMINATION
        end
        return 0
    end

    KN_set_newpt_callback(kc, newpt_callback)

    status = KN_solve(kc)
    @test status == KN_RC_USER_TERMINATION

    nStatus, objSol, x, lambda_ = KN_get_solution(kc)
    @test nStatus == KN_RC_USER_TERMINATION
    pCint = Ref{Cint}()
    KN_get_number_iters(kc, pCint)
    @test pCint[] == 2

    KN_free(kc)
end

@testset "Handling exception in callbacks" begin
    function eval_kn(kc, cb, evalRequest, evalResult, userParams)
        # Generate exception in callback
        throw(LoadError)
        return 0
    end

    kc = KN_new()
    KN_set_int_param_by_name(kc, "outlev", 0)
    KN_add_vars(kc, 1, zeros(Cint, 1))
    KN_set_var_primal_init_values_all(kc, [0.0])
    cb = KN_add_objective_callback(kc, eval_kn)
    nstatus = KN_solve(kc)
    @test nstatus == KN_RC_CALLBACK_ERR
    KN_free(kc)
end

@testset "Knitro evaluation exception" begin
    function eval_kn(kc, cb, evalRequest, evalResult, userParams)
        x = evalRequest.x
        evalResult.obj[1] = sqrt(x[1])
        return 0
    end

    kc = KN_new()
    KN_set_int_param_by_name(kc, "outlev", 0)
    KN_add_vars(kc, 1, zeros(Cint, 1))
    # Start from a non-evaluable point
    KN_set_var_primal_init_values_all(kc, [-1.0])
    cb = KN_add_objective_callback(kc, eval_kn)
    nstatus = KN_solve(kc)
    nStatus, objSol, x, lambda_ = KN_get_solution(kc)
    @test x ≈ [0.0] atol = 1e-5
    KN_free(kc)
end

@testset "Knitro violation information" begin
    if KNITRO.knitro_version() < v"12.4"
        return 0
    end
    #*------------------------------------------------------------------*
    #*     FUNCTION callbackEvalFC                                      *
    #*------------------------------------------------------------------*
    # The signature of this function matches KN_eval_callback in knitro.h.
    # Only "obj" and "c" are set in the KN_eval_result structure.
    function callbackEvalFC(kc, cb, evalRequest, evalResult, userParams)
        x = evalRequest.x

        # Evaluate nonlinear term in objective
        evalResult.obj[1] = x[1] * x[2] * x[3] * x[4]

        # Evaluate nonlinear terms in constraints
        evalResult.c[1] = x[1] * x[1] * x[1]
        evalResult.c[2] = x[1] * x[1] * x[4]

        return 0
    end

    #*------------------------------------------------------------------*
    #*     main                                                         *
    #*------------------------------------------------------------------*

    # Create a new Knitro solver instance.
    kc = KN_new()
    KN_set_int_param_by_name(kc, "outlev", 0)
    xIndices = zeros(Cint, 4)
    KN_add_vars(kc, 4, xIndices)
    for x in xIndices
        KN_set_var_primal_init_value(kc, x, 0.8)
    end

    # Add the constraints and set the rhs and coefficients
    KN_add_cons(kc, 3, zeros(Cint, 3))
    KN_set_con_eqbnds_all(kc, [1.0, 0.0, 0.0])

    # Coefficients for 2 linear terms
    lconIndexCons = Int32[1, 2]
    lconIndexVars = Int32[2, 1]
    lconCoefs = [-1.0, -1.0]
    KN_add_con_linear_struct(kc, 2, lconIndexCons, lconIndexVars, lconCoefs)

    # Coefficients for 2 quadratic terms

    # 1st term:  x1^2 term in c0
    # 2nd term:  x3^2 term in c2
    qconIndexCons = Int32[0, 2]
    qconIndexVars1 = Int32[1, 3]
    qconIndexVars2 = Int32[1, 3]
    qconCoefs = [1.0, 1.0]

    KN_add_con_quadratic_struct(
        kc,
        2,
        qconIndexCons,
        qconIndexVars1,
        qconIndexVars2,
        qconCoefs,
    )

    # Add callback to evaluate nonlinear(non-quadratic) terms in the model:
    #    x0*x1*x2*x3  in the objective
    #    x0^3         in first constraint c0
    #    x0^2*x3      in second constraint c1
    cb = KN_add_eval_callback(kc, true, Int32[0, 1], callbackEvalFC)

    # Set minimize or maximize(if not set, assumed minimize)
    KN_set_obj_goal(kc, KN_OBJGOAL_MAXIMIZE)

    # Solve the problem.
    #
    # Return status codes are defined in "knitro.h" and described
    # in the Knitro manual.
    nStatus = KN_solve(kc)
    # An example of obtaining solution information.
    nStatus, objSol, x, lambda_ = KN_get_solution(kc)
    varbndInfeas, varintInfeas, varviols = zeros(Cint, 4), zeros(Cint, 4), zeros(Cdouble, 4)
    KN_get_var_viols(kc, 4, Cint[0, 1, 2, 3], varbndInfeas, varintInfeas, varviols)
    coninfeas, conviols = zeros(Cint, 3), zeros(Cdouble, 3)
    KN_get_con_viols(kc, 3, Cint[0, 1, 2], coninfeas, conviols)
    @testset "Example HS40 nlp1noderivs" begin
        @test varbndInfeas == [0, 0, 0, 0]
        @test varintInfeas == [0, 0, 0, 0]
        @test varviols ≈ [0.0, 0.0, 0.0, 0.0] atol = 1e-6
        @test coninfeas == [0, 0, 0]
        @test conviols ≈ [0.0, 0.0, 0.0] atol = 1e-6
        pCdouble = Ref{Cdouble}()
        KN_get_abs_feas_error(kc, pCdouble)
        @test pCdouble[] == max(conviols...)
    end

    # Delete the Knitro solver instance.
    KN_free(kc)
end

@testset "Knitro structural manipulation" begin
    if KNITRO.knitro_version() < v"12.4"
        return 0
    end
    #*------------------------------------------------------------------*
    #*     FUNCTION callbackEvalFC                                      *
    #*------------------------------------------------------------------*
    # The signature of this function matches KN_eval_callback in knitro.h.
    # Only "obj" and "c" are set in the KN_eval_result structure.
    function callbackEvalFC(kc, cb, evalRequest, evalResult, userParams)
        x = evalRequest.x

        # Evaluate nonlinear term in objective
        evalResult.obj[1] = x[1] * x[2] * x[3] * x[4]

        # Evaluate nonlinear terms in constraints
        evalResult.c[1] = x[1] * x[1] * x[1]
        evalResult.c[2] = x[1] * x[1] * x[4]

        return 0
    end

    #*------------------------------------------------------------------*
    #*     FUNCTION callbackEvalGA                                      *
    #*------------------------------------------------------------------*
    # The signature of this function matches KN_eval_callback in knitro.h.
    # Only "objGrad" and "jac" are set in the KN_eval_result structure.
    function callbackEvalGA(kc, cb, evalRequest, evalResult, userParams)
        x = evalRequest.x

        # Evaluate nonlinear term in objective gradient
        evalResult.objGrad[1] = x[2] * x[3] * x[4]
        evalResult.objGrad[2] = x[1] * x[3] * x[4]
        evalResult.objGrad[3] = x[1] * x[2] * x[4]
        evalResult.objGrad[4] = x[1] * x[2] * x[3]

        # Evaluate nonlinear terms in constraint gradients(Jacobian)
        evalResult.jac[1] = 3.0 * x[1] * x[1] # derivative of x0^3 term  wrt x0
        evalResult.jac[2] = 2.0 * x[1] * x[4] # derivative of x0^2 * x3 term  wrt x0
        evalResult.jac[3] = x[1] * x[1]       # derivative of x0^2 * x3 terms wrt x3

        return 0
    end

    #*------------------------------------------------------------------*
    #*     FUNCTION callbackEvalH                                       *
    #*------------------------------------------------------------------*
    # The signature of this function matches KN_eval_callback in knitro.h.
    # Only "hess" or "hessVec" are set in the KN_eval_result structure.
    function callbackEvalH(kc, cb, evalRequest, evalResult, userParams)
        x = evalRequest.x
        lambda_ = evalRequest.lambda
        # Scale objective component of hessian by sigma
        sigma = evalRequest.sigma

        # Evaluate nonlinear term in the Hessian of the Lagrangian.
        # Note: If sigma=0, some computations can be avoided.
        if sigma > 0.0 # Evaluate the full Hessian of the Lagrangian
            evalResult.hess[1] = lambda_[1] * 6.0 * x[1] + lambda_[2] * 2.0 * x[4]
            evalResult.hess[2] = sigma * x[3] * x[4]
            evalResult.hess[3] = sigma * x[2] * x[4]
            evalResult.hess[4] = sigma * x[2] * x[3] + lambda_[2] * 2.0 * x[1]
            evalResult.hess[5] = sigma * x[1] * x[4]
            evalResult.hess[6] = sigma * x[1] * x[3]
            evalResult.hess[7] = sigma * x[1] * x[2]
        else # sigma=0, do not include objective component
            evalResult.hess[1] = lambda_[1] * 6.0 * x[1] + lambda_[2] * 2.0 * x[4]
            evalResult.hess[2] = 0.0
            evalResult.hess[3] = 0.0
            evalResult.hess[4] = lambda_[2] * 2.0 * x[1]
            evalResult.hess[5] = 0.0
            evalResult.hess[6] = 0.0
            evalResult.hess[7] = 0.0
        end

        return 0
    end

    #*------------------------------------------------------------------*
    #*     main                                                         *
    #*------------------------------------------------------------------*

    # Create a new Knitro solver instance.
    kc = KN_new()
    KN_set_int_param_by_name(kc, "outlev", 0)

    # Initialize Knitro with the problem definition.

    # Add the variables and specify initial values for them.
    # Note: any unset lower bounds are assumed to be
    # unbounded below and any unset upper bounds are
    # assumed to be unbounded above.
    xIndices = zeros(Cint, 4)
    KN_add_vars(kc, 4, xIndices)
    for x in xIndices
        KN_set_var_primal_init_value(kc, x, 0.8)
    end

    # x2 >= 0. This constraint is added to avoid symmetric solutions.
    KN_set_var_lobnd(kc, 2, 0.0)

    # Add the constraints and set the rhs and coefficients
    KN_add_cons(kc, 3, zeros(Cint, 3))
    KN_set_con_eqbnds_all(kc, [1.0, 0.0, 0.0])

    # Coefficients for 2 linear terms
    lconIndexCons = Int32[1, 2]
    lconIndexVars = Int32[2, 1]
    lconCoefs = [-1.0, -1.0]
    KN_add_con_linear_struct(kc, 2, lconIndexCons, lconIndexVars, lconCoefs)

    # Coefficients for 2 quadratic terms

    # 1st term:  x1^2 term in c0
    # 2nd term:  x3^2 term in c2
    qconIndexCons = Int32[0, 2]
    qconIndexVars1 = Int32[1, 3]
    qconIndexVars2 = Int32[1, 3]
    qconCoefs = [1.0, 1.0]

    KN_add_con_quadratic_struct(
        kc,
        2,
        qconIndexCons,
        qconIndexVars1,
        qconIndexVars2,
        qconCoefs,
    )

    # Add callback to evaluate nonlinear(non-quadratic) terms in the model:
    #    x0*x1*x2*x3  in the objective
    #    x0^3         in first constraint c0
    #    x0^2*x3      in second constraint c1
    cb = KN_add_eval_callback(kc, true, Int32[0, 1], callbackEvalFC)

    # Set obj. gradient and nonlinear jac provided through callbacks.
    # Mark objective gradient as dense, and provide non-zero sparsity
    # structure for constraint Jacobian terms.
    cbjacIndexCons = Int32[0, 1, 1]
    cbjacIndexVars = Int32[0, 0, 3]
    KN_set_cb_grad(
        kc,
        cb,
        callbackEvalGA,
        jacIndexCons=cbjacIndexCons,
        jacIndexVars=cbjacIndexVars,
    )

    # Set nonlinear Hessian provided through callbacks. Since the
    # Hessian is symmetric, only the upper triangle is provided.
    # The upper triangular Hessian for nonlinear callback structure is:
    #    # lambda0*6*x0 + lambda1*2*x3     x2*x3    x1*x3    x1*x2 + lambda1*2*x0
    #              0                    0      x0*x3         x0*x2
    #                                            0           x0*x1
    #                                                         0
    #(7 nonzero elements)
    cbhessIndexVars1 = Int32[0, 0, 0, 0, 1, 1, 2]
    cbhessIndexVars2 = Int32[0, 1, 2, 3, 2, 3, 3]
    KN_set_cb_hess(
        kc,
        cb,
        length(cbhessIndexVars1),
        callbackEvalH,
        hessIndexVars1=cbhessIndexVars1,
        hessIndexVars2=cbhessIndexVars2,
    )

    # Set minimize or maximize(if not set, assumed minimize)
    KN_set_obj_goal(kc, KN_OBJGOAL_MAXIMIZE)

    # Solve the initial problem.
    #
    # Return status codes are defined in "knitro.h" and described
    # in the Knitro manual.
    nStatus = KN_solve(kc)

    # An example of obtaining solution information.
    nStatus_origin, objSol_origin, x_origin, lambda_origin = KN_get_solution(kc)

    # =============== MODIFY PROBLEM AND RE-SOLVE ===========
    # Add 0.5x3 linear term to c2
    KN_add_con_linear_struct(kc, 1, Cint[2], Cint[3], [0.5])
    # Change -x2 to 5x2 in c1
    KN_chg_con_linear_term(kc, 1, 2, 5.0)
    # Now add a new linear constraint x1 + 2x2 + x3 <= 2.5 (c3) and re-solve
    pc3 = Ref{Cint}()
    KN_add_con(kc, pc3)
    c3 = pc3[]
    KN_set_con_upbnd(kc, c3, 2.5)
    KN_add_con_linear_struct_one(kc, 3, c3, Int32[1, 2, 3], [1.0, 2.0, 1.0])

    # Add a constant to the objective
    KN_add_obj_constant(kc, 100.0)

    # Tell Knitro to try a "warm-start" since it is starting from the solution
    # of the previous solve, which may be a good initial point for the solution
    # of the slightly modified problem.
    KN_set_int_param(kc, KN_PARAM_STRAT_WARM_START, KN_STRAT_WARM_START_YES)

    nStatus = KN_solve(kc)
    nStatus, objSol, x, lambda_ = KN_get_solution(kc)

    # =============== MODIFY PROBLEM BACK TO THE ORIGINAL ONE AND RE-SOLVE AGAIN ===========
    # Remove 0.5x3 from c2
    KN_del_con_linear_term(kc, 2, 3)
    # Change 5x2 back to -x2 in c1
    KN_chg_con_linear_term(kc, 1, 2, -1.0)
    # Remove new constraint c3
    KN_del_con_linear_struct_one(kc, 3, c3, Int32[1, 2, 3])
    # Remove the constant in the objective
    KN_del_obj_constant(kc)

    nStatus = KN_solve(kc)
    nStatus, objSol, x, lambda_ = KN_get_solution(kc)

    # Test that the solution is the same than the original problem
    @testset begin
        @test nStatus == nStatus_origin
        @test objSol ≈ objSol_origin atol = 1e-6
        @test x ≈ x_origin atol = 1e-6
        @test lambda_[1:length(lambda_origin)] ≈ lambda_origin atol = 1e-1
    end

    # Delete the Knitro solver instance.
    KN_free(kc)
end

@testset "show" begin
    model = KN_new()
    @test occursin("Problem Characteristics", sprint(show, model))
    KN_free(model)
    @test sprint(show, model) == "KNITRO Problem: NULL\n"
end
