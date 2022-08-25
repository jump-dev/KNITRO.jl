
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

@testset "Instantiation Knitro C interface" begin
    # get KNITRO.KNITRO release version
    rel = KNITRO.get_release()
    @test isa(rel, String)

    @testset "Definition of model" begin
        m = KNITRO.Model()
        options = joinpath(dirname(@__FILE__), "..", "examples", "knitro.opt")
        KNITRO.KN_reset_params_to_defaults(m)

        KNITRO.KN_free(m)
        @test m.env.ptr_env == C_NULL
    end
end

# add generic callbacks for future tests

function evalAll(kc, cb, evalRequest, evalResult, userParams)
    x = evalRequest.x
    evalRequestCode = evalRequest.evalRequestCode

    if evalRequestCode == KNITRO.KN_RC_EVALFC
        # Evaluate nonlinear objective
        evalResult.obj[1] = x[1]^2 * x[3] + x[2]^3 * x[3]^2
    elseif evalRequestCode == KNITRO.KN_RC_EVALGA
        evalResult.objGrad[1] = 2 * x[1] * x[3]
        evalResult.objGrad[2] = 3 * x[2]^2 * x[3]^2
        evalResult.objGrad[3] = x[1]^2 + 2 * x[2]^3 * x[3]
    elseif evalRequestCode == KNITRO.KN_RC_EVALH
        evalResult.hess[1] = 2 * x[3]
        evalResult.hess[2] = 2 * x[1]
        evalResult.hess[3] = 6 * x[2] * x[3]^2
        evalResult.hess[4] = 6 * x[2]^2 * x[3]
        evalResult.hess[5] = 2 * x[2]^3
    elseif evalRequestCode == KNITRO.KN_RC_EVALHV
        vec = evalRequest.vec
        evalResult.hessVec[1] = (2 * x[3]) * vec[1] + (2 * x[1]) * vec[3]
        evalResult.hessVec[2] = (6 * x[2] * x[3]^2) * vec[2] + (6 * x[2]^2 * x[3]) * vec[3]
        evalResult.hessVec[3] =
            (2 * x[1]) * vec[1] + (6 * x[2]^2 * x[3]) * vec[2] + (2 * x[2]^3) * vec[3]

    elseif evalRequestCode == KNITRO.KN_RC_EVALH_NO_F
        evalResult.hess[1] = 0
        evalResult.hess[2] = 0
        evalResult.hess[3] = 0
        evalResult.hess[4] = 0
        evalResult.hess[5] = 0

    elseif evalRequestCode == KNITRO.KN_RC_EVALHV_NO_F
        vec = evalRequest.vec
        evalResult.hessVec[1] = 0
        evalResult.hessVec[2] = lambda_[4] * vec[3]
        evalResult.hessVec[3] = lambda_[4] * vec[2]

    else
        return KNITRO.KN_RC_CALLBACK_ERR
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

if KNITRO.KNITRO_VERSION >= v"12.0"
    @testset "Names getters" begin
        kc = KNITRO.KN_new()
        KNITRO.KN_add_vars(kc, 3)
        KNITRO.KN_add_cons(kc, 3)
        xnames = ["x1", "x2", "x3"]
        cnames = ["c1", "c2", "c3"]

        KNITRO.KN_set_var_names_all(kc, xnames)
        KNITRO.KN_set_con_names_all(kc, cnames)
        index = Cint(1)

        name = KNITRO.KN_get_var_names(kc, index)
        @test name == xnames[2]
        outnames = KNITRO.KN_get_var_names(kc, [index])
        @test outnames[1] == xnames[2]
        outnames = KNITRO.KN_get_var_names(kc)
        @test xnames == outnames

        name = KNITRO.KN_get_con_names(kc, index)
        @test name == cnames[2]
        outnames = KNITRO.KN_get_con_names(kc, [index])
        @test outnames[1] == cnames[2]
        outnames = KNITRO.KN_get_con_names(kc)
        @test cnames == outnames

        KNITRO.KN_free(kc)
    end
end
if KNITRO.KNITRO_VERSION >= v"12.1"
    @testset "MPS reader/writer" begin
        mps_name = joinpath(dirname(@__FILE__), "lp.mps")
        mps_name_out = joinpath(dirname(@__FILE__), "lp2.mps")
        open(mps_name, "w") do io
            return write(io, MPS_PROBLEM)
        end
        kc = KNITRO.KN_new()
        KNITRO.KN_load_mps_file(kc, mps_name)
        KNITRO.KN_set_param(kc, "outlev", 0)
        KNITRO.KN_write_mps_file(kc, mps_name_out)
        status = KNITRO.KN_solve(kc)
        obj = KNITRO.get_objective(kc)
        KNITRO.KN_free(kc)
        @test status == 0
        @test obj ≈ 250.0 / 3.0

        # Resolve with dumped MPS file
        kc = KNITRO.KN_new()
        KNITRO.KN_load_mps_file(kc, mps_name_out)
        KNITRO.KN_set_param(kc, "outlev", 0)
        status = KNITRO.KN_solve(kc)
        obj = KNITRO.get_objective(kc)
        KNITRO.KN_free(kc)
        @test status == 0
        @test obj ≈ 250.0 / 3.0
    end
end

@testset "First problem" begin
    kc = KNITRO.KN_new()
    @test isa(kc, KNITRO.Model)
    # By default, kc does not have any callback
    @test !KNITRO.has_callbacks(kc)

    release = KNITRO.get_release()

    KNITRO.KN_reset_params_to_defaults(kc)

    options = joinpath(dirname(@__FILE__), "..", "examples", "test_knitro.opt")
    tuner1 = joinpath(dirname(@__FILE__), "..", "examples", "tuner-fixed.opt")
    tuner2 = joinpath(dirname(@__FILE__), "..", "examples", "tuner-explore.opt")
    KNITRO.KN_set_param(kc, "algorithm", 0)
    KNITRO.KN_set_param(kc, "cplexlibname", ".")
    KNITRO.KN_set_param(kc, "xtol", 1e-15)
    KNITRO.KN_set_param(kc, KNITRO.KN_PARAM_ALG, KNITRO.KN_ALG_BAR_DIRECT)
    KNITRO.KN_set_param(kc, KNITRO.KN_PARAM_CPLEXLIB, ".")
    KNITRO.KN_set_param(kc, KNITRO.KN_PARAM_XTOL, 1e-15)

    @test KNITRO.KN_get_int_param(kc, "algorithm") == KNITRO.KN_ALG_BAR_DIRECT
    @test KNITRO.KN_get_double_param(kc, "xtol") == 1e-15
    @test KNITRO.KN_get_int_param(kc, KNITRO.KN_PARAM_ALG) == KNITRO.KN_ALG_BAR_DIRECT
    @test KNITRO.KN_get_double_param(kc, KNITRO.KN_PARAM_XTOL) == 1e-15
    @test KNITRO.KN_get_param_name(kc, KNITRO.KN_PARAM_XTOL) == "xtol"

    @test KNITRO.KN_get_param_doc(kc, KNITRO.KN_PARAM_XTOL) ==
          "# Step size tolerance used for terminating the optimization.\n"
    @test KNITRO.KN_get_param_type(kc, KNITRO.KN_PARAM_XTOL) == KNITRO.KN_PARAMTYPE_FLOAT
    @test KNITRO.KN_get_num_param_values(kc, KNITRO.KN_PARAM_XTOL) == 0

    @test KNITRO.KN_get_param_value_doc(kc, KNITRO.KN_PARAM_GRADOPT, 1) == "exact"

    @test KNITRO.KN_get_param_id(kc, "xtol") == KNITRO.KN_PARAM_XTOL

    # START: Some specific parameter settings
    KNITRO.KN_set_param(kc, "hessopt", 1)
    KNITRO.KN_set_param(kc, "presolve", 0)
    KNITRO.KN_set_param(kc, "outlev", 0)
    # END:   Some specific parameter settings

    # Perform a derivative check.
    KNITRO.KN_set_param(kc, KNITRO.KN_PARAM_DERIVCHECK, KNITRO.KN_DERIVCHECK_ALL)

    function newpt_callback(kc, x, lambda_, user_data)
        a = KNITRO.KN_get_rel_feas_error(kc)
        b = KNITRO.KN_get_rel_opt_error(kc)
        return 0
    end

    # Define objective goal
    objGoal = KNITRO.KN_OBJGOAL_MAXIMIZE
    KNITRO.KN_set_obj_goal(kc, objGoal)

    # Add the variables and set their bounds.
    nV = 3
    KNITRO.KN_add_vars(kc, nV)
    KNITRO.KN_set_var_lobnds_all(kc, [0, 0.1, 0])
    KNITRO.KN_set_var_upbnds_all(kc, [0.0, 2, 2])
    # Define an initial point.
    KNITRO.KN_set_var_primal_init_values_all(kc, [1.0, 1, 1.5])
    KNITRO.KN_set_var_dual_init_values_all(kc, [1.0, 1, 1, 1])

    # Add the constraints and set their bounds.
    nC = 1
    KNITRO.KN_add_cons(kc, nC)
    KNITRO.KN_set_con_lobnds_all(kc, [0.1])
    KNITRO.KN_set_con_upbnds_all(kc, [2 * 2 * 0.99])

    # Test getters.
    if KNITRO.KNITRO_VERSION >= v"12.0"
        xindex = Cint[0, 1, 2]
        @test KNITRO.KN_get_var_lobnds(kc, xindex) == [0, 0.1, 0]
        @test KNITRO.KN_get_var_upbnds(kc, xindex) == [0.0, 2, 2]

        cindex = Cint[0]
        @test KNITRO.KN_get_con_lobnds(kc, cindex) == [0.1]
        @test KNITRO.KN_get_con_upbnds(kc, cindex) == [2 * 2 * 0.99]
    end

    # Load quadratic structure x1*x2 for the constraint.
    KNITRO.KN_add_con_quadratic_struct(kc, 0, 1, 2, 1.0)

    # Define callback functions.
    cb = KNITRO.KN_add_objective_callback(kc, evalAll)
    @test KNITRO.has_callbacks(kc)
    KNITRO.KN_set_cb_grad(kc, cb, evalAll)
    KNITRO.KN_set_cb_hess(
        kc,
        cb,
        5,
        evalAll,
        hessIndexVars1=Int32[0, 0, 1, 1, 2],
        hessIndexVars2=Int32[0, 2, 1, 2, 2],
    )

    KNITRO.KN_set_newpt_callback(kc, newpt_callback)

    # Add complementarity constraints.
    KNITRO.KN_set_compcons(kc, Int32[KNITRO.KN_CCTYPE_VARVAR], Int32[0], Int32[1])

    # Solve the problem.
    status = KNITRO.KN_solve(kc)
    @test status == 0

    # Restart using the previous solution.
    nStatus, objSol, x, lambda_ = KNITRO.KN_get_solution(kc)
    KNITRO.KN_set_var_primal_init_values_all(kc, x)
    KNITRO.KN_set_var_dual_init_values_all(kc, lambda_)
    status = KNITRO.KN_solve(kc)
    @test status == 0

    # Restart with new variable bounds
    KNITRO.KN_set_var_lobnds_all(kc, Float64[0.0, 0, 0])
    KNITRO.KN_set_var_upbnds_all(kc, Float64[2.0, 2, 2])
    status = KNITRO.KN_solve(kc)
    @test status == 0

    # Retrieve relevant solve information
    @test KNITRO.KN_get_number_FC_evals(kc) >= 1
    @test KNITRO.KN_get_number_GA_evals(kc) >= 1
    @test KNITRO.KN_get_number_H_evals(kc) >= 1
    @test KNITRO.KN_get_number_HV_evals(kc) == 0
    @test KNITRO.KN_get_number_iters(kc) >= 1
    @test KNITRO.KN_get_number_cg_iters(kc) >= 0
    @test KNITRO.KN_get_abs_feas_error(kc) < 1e-10
    @test KNITRO.KN_get_rel_feas_error(kc) < 1e-10
    @test KNITRO.KN_get_abs_opt_error(kc) < 1e-7
    @test KNITRO.KN_get_rel_opt_error(kc) < 1e-8
    @test KNITRO.KN_get_con_values(kc)[1] ≈ 3.96

    nStatus, objSol, x, lambda_ = KNITRO.KN_get_solution(kc)
    @test nStatus == 0
    @test x ≈ [0.0, 2.0, 1.98]

    @test objSol ≈ 31.363199 atol = 1e-5

    # Test getters for primal and dual variables
    if KNITRO.KNITRO_VERSION >= v"12.0"
        xopt = KNITRO.KN_get_var_primal_values(kc, Cint[0, 1, 2])
        @test xopt == x
        rc = KNITRO.KN_get_var_dual_values(kc, Cint[0, 1, 2])
        @test rc == lambda_[2:4]
        dual = KNITRO.KN_get_con_dual_values(kc, Cint[0])
        @test dual == [lambda_[1]]
    end

    KNITRO.KN_free(kc)
end

@testset "Second problem test" begin
    kc = KNITRO.KN_new()

    function prettyPrinting(str, userParams)
        s = "KNITRO-Julia: " * str * "\n"
        println(s)
        return length(s)
    end

    KNITRO.KN_set_puts_callback(kc, prettyPrinting)

    # START: Some specific parameter settings
    KNITRO.KN_set_param(kc, "outlev", 0)
    KNITRO.KN_set_param(kc, "presolve", 0)
    KNITRO.KN_set_param(kc, "ms_enable", 1)
    KNITRO.KN_set_param(kc, "ms_maxsolves", 5)
    KNITRO.KN_set_param(kc, "hessian_no_f", 1)
    KNITRO.KN_set_param(kc, "hessopt", KNITRO.KN_HESSOPT_PRODUCT)
    # END:   Some specific parameter settings

    # Define objective goal
    objGoal = KNITRO.KN_OBJGOAL_MAXIMIZE
    KNITRO.KN_set_obj_goal(kc, objGoal)

    # Add the variables and set their bounds.
    nV = 3
    KNITRO.KN_add_vars(kc, nV)
    KNITRO.KN_set_var_lobnds_all(kc, [0, 0.1, 0])
    KNITRO.KN_set_var_upbnds_all(kc, [0.0, 2, 2])

    # Define an initial point.
    KNITRO.KN_set_var_primal_init_values_all(kc, [1, 1, 1.5])
    KNITRO.KN_set_var_dual_init_values_all(kc, [1, 1, 1, 1.0])

    # Add the constraints and set their lower bounds.
    nC = 1
    KNITRO.KN_add_cons(kc, nC)
    KNITRO.KN_set_con_lobnds_all(kc, [0.1])
    KNITRO.KN_set_con_upbnds_all(kc, [2 * 2 * 0.99])

    # Load quadratic structure x1*x2 for the constraint.
    KNITRO.KN_add_con_quadratic_struct(kc, 0, 1, 2, 1.0)

    # Define callback functions.
    cb = KNITRO.KN_add_objective_callback(kc, evalAll)

    KNITRO.KN_set_cb_grad(kc, cb, evalAll)
    KNITRO.KN_set_cb_hess(kc, cb, KNITRO.KN_DENSE_ROWMAJOR, evalAll)

    KNITRO.KN_set_ms_process_callback(kc, callback("ms callback"))

    function ms_initpt_callbackFn(kc, nSolveNumber, x, lambda_, userParams)
        x[:] = [1, 1, 1.1 + 0.1 * nSolveNumber]
        lambda_[:] = [1.0, 1, 1, 1]
        return 0
    end

    # Set multistart initial point callback
    KNITRO.KN_set_ms_initpt_callback(kc, ms_initpt_callbackFn)

    # Add complementarity constraints.
    KNITRO.KN_set_compcons(kc, Int32[KNITRO.KN_CCTYPE_VARVAR], Int32[0], Int32[1])

    # Solve the problem.
    status = KNITRO.KN_solve(kc)

    @test status == 0
    nStatus, objSol, x, lambda_ = KNITRO.KN_get_solution(kc)
    @test nStatus == 0
    @test x ≈ [0.0, 2.0, 1.98] atol = 1e-5

    @test objSol ≈ 31.363199 atol = 1e-5

    KNITRO.KN_free(kc)
end

@testset "Third problem test" begin
    kc = KNITRO.KN_new()

    KNITRO.KN_set_param(kc, "outlev", 0)
    KNITRO.KN_set_param(kc, "presolve", KNITRO.KN_PRESOLVEDBG_NONE)

    # Define objective goal
    objGoal = KNITRO.KN_OBJGOAL_MAXIMIZE
    KNITRO.KN_set_obj_goal(kc, objGoal)

    # Add the variables and set their bounds.
    nV = 3
    KNITRO.KN_add_vars(kc, nV)
    KNITRO.KN_set_var_lobnds_all(kc, [0, 0.1, 0])
    KNITRO.KN_set_var_upbnds_all(kc, [0.0, 2, 2])

    # Define an initial point.
    KNITRO.KN_set_var_primal_init_values_all(kc, [1, 1, 1.5])
    KNITRO.KN_set_var_dual_init_values_all(kc, [1.0, 1, 1, 1])

    # Add the constraints and set their lower bounds.
    nC = 1
    KNITRO.KN_add_cons(kc, nC)
    KNITRO.KN_set_con_lobnds_all(kc, [0.1])
    KNITRO.KN_set_con_upbnds_all(kc, [2 * 2 * 0.99])

    # Load quadratic structure x1*x2 for the constraint.
    KNITRO.KN_add_con_quadratic_struct(kc, 0, 1, 2, 1.0)

    # Define callback functions.
    cb = KNITRO.KN_add_objective_callback(kc, evalAll)
    KNITRO.KN_set_cb_grad(kc, cb, evalAll)
    KNITRO.KN_set_cb_hess(kc, cb, KNITRO.KN_DENSE_ROWMAJOR, evalAll)

    KNITRO.KN_set_compcons(kc, Int32[KNITRO.KN_CCTYPE_VARVAR], Int32[0], Int32[1])

    KNITRO.KN_set_var_honorbnds_all(
        kc,
        [KNITRO.KN_HONORBNDS_ALWAYS, KNITRO.KN_HONORBNDS_INITPT, KNITRO.KN_HONORBNDS_NO],
    )

    KNITRO.KN_set_var_scalings(kc, 3, Int32[0, 1, 2], [1.0, 1.0, 1.0], zeros(3))
    KNITRO.KN_set_con_scalings_all(kc, [0.5])
    KNITRO.KN_set_compcon_scalings_all(kc, [2.0])
    KNITRO.KN_set_obj_scaling(kc, 10.0)

    status = KNITRO.KN_solve(kc)
    @test status == 0

    # Retrieve derivatives values
    objGrad = KNITRO.KN_get_objgrad_values(kc)
    jac = KNITRO.KN_get_jacobian_values(kc)
    hess = KNITRO.KN_get_hessian_values(kc)

    nStatus, objSol, x, lambda_ = KNITRO.KN_get_solution(kc)
    @test nStatus == 0
    @test x ≈ [0.0, 2.0, 1.98]
    @test objSol ≈ 31.363199 atol = 1e-5

    KNITRO.KN_free(kc)
end

@testset "Fourth problem test" begin
    kc = KNITRO.KN_new()
    # START: Some specific parameter settings
    KNITRO.KN_set_param(kc, "presolve", 0)
    KNITRO.KN_set_param(kc, "outlev", 0)
    KNITRO.KN_set_param(kc, "gradopt", 2)
    KNITRO.KN_set_param(kc, "hessopt", 2)
    KNITRO.KN_set_param(kc, "mip_numthreads", 1)
    # END:   Some specific parameter settings
    function evalF_evalGA(kc, cb, evalRequest, evalResult, userParams)
        x = evalRequest.x
        evalRequestCode = evalRequest.evalRequestCode
        if evalRequestCode == KNITRO.KN_RC_EVALFC
            # Evaluate nonlinear objective
            evalResult.obj[1] = x[1]^2 * x[3] + x[2]^3 * x[3]^2
        elseif evalRequestCode == KNITRO.KN_RC_EVALGA
            evalResult.objGrad[1] = 2 * x[1] * x[3]
            evalResult.objGrad[2] = 3 * x[2]^2 * x[3]^2
            evalResult.objGrad[3] = x[1]^2 + 2 * x[2]^3 * x[3]
        else
            return KNITRO.KN_RC_CALLBACK_ERR
        end
        return 0
    end
    # Define objective goal
    objGoal = KNITRO.KN_OBJGOAL_MAXIMIZE
    KNITRO.KN_set_obj_goal(kc, objGoal)
    # Add the variables and set their bounds.
    nV = 3
    KNITRO.KN_add_vars(kc, nV)
    KNITRO.KN_set_var_lobnds_all(kc, [0.0, 0.1, 0.0])
    KNITRO.KN_set_var_upbnds_all(kc, [0.0, 2.0, 2.0])
    KNITRO.KN_set_var_types_all(
        kc,
        [
            KNITRO.KN_VARTYPE_CONTINUOUS,
            KNITRO.KN_VARTYPE_INTEGER,
            KNITRO.KN_VARTYPE_INTEGER,
        ],
    )
    # Define an initial point.
    KNITRO.KN_set_var_primal_init_values_all(kc, [1.0, 1.0, 1.5])
    KNITRO.KN_set_var_dual_init_values_all(kc, [1.0, 1.0, 1.0, 1.0])
    # Add the constraints and set their lower bounds.
    nC = 1
    KNITRO.KN_add_cons(kc, nC)
    KNITRO.KN_set_con_lobnds_all(kc, [0.1])
    KNITRO.KN_set_con_upbnds_all(kc, [2 * 2 * 0.99])
    # Load quadratic structure x1*x2 for the constraint.
    KNITRO.KN_add_con_quadratic_struct(kc, 0, 1, 2, 1.0)
    # Define callback functions.
    cb = KNITRO.KN_add_objective_callback(kc, evalF_evalGA)
    KNITRO.KN_set_cb_grad(kc, cb, evalF_evalGA)
    # Define complementarity constraints
    KNITRO.KN_set_compcons(kc, Int32[KNITRO.KN_CCTYPE_VARVAR], Int32[0], Int32[1])
    # Set MIP parameters
    KNITRO.KN_set_mip_branching_priorities_all(kc, Int32[0, 1, 2])
    # not compatible with MPEC constraint as a variable cannot be involved in
    # two different complementarity constraints.
    # KNITRO.KN_set_mip_intvar_strategies(kc, 2, KNITRO.KN_MIP_INTVAR_STRATEGY_MPEC)
    KNITRO.KN_set_mip_node_callback(kc, callback("mip_node"))
    # Set var, con and obj names
    KNITRO.KN_set_var_names_all(kc, ["myvar1", "myvar2", "myvar3"])
    KNITRO.KN_set_con_names_all(kc, ["mycon1"])
    KNITRO.KN_set_obj_name(kc, "myobj")
    # Set feasibility tolerances
    KNITRO.KN_set_var_feastols_all(kc, [0.1, 0.001, 0.1])
    KNITRO.KN_set_con_feastols_all(kc, [0.1])
    KNITRO.KN_set_compcon_feastols_all(kc, [0.1])
    # Set finite differences step size
    KNITRO.KN_set_cb_relstepsizes_all(kc, cb, [0.1, 0.001, 0.1])
    # Solve the problem.
    status = KNITRO.KN_solve(kc)
    # Test for return codes 0 for optimality, and KN_RC_MIP_EXH_FEAS for all
    # nodes explored, assumed optimal
    @test status == 0 || status == KNITRO.KN_RC_MIP_EXH_FEAS
    @test KNITRO.KN_get_mip_number_nodes(kc) >= 1
    @test KNITRO.KN_get_mip_number_solves(kc) >= 1
    @test KNITRO.KN_get_mip_relaxation_bnd(kc) ≈ 31.3632000015
    @test KNITRO.KN_get_mip_lastnode_obj(kc) ≈ 31.3632000015
    @test KNITRO.KN_get_con_values(kc)[1] == 4.0
    @test KNITRO.KN_get_mip_incumbent_obj(kc) ≈ 32.0
    @test KNITRO.KN_get_mip_incumbent_x(kc) == 0.0
    KNITRO.KN_free(kc)
end

@testset "Fifth problem test" begin
    # Test in this environment the setting of user params
    myParams = "stringUserParam"
    kc = KNITRO.KN_new()

    KNITRO.KN_set_param(kc, "outlev", 0)
    KNITRO.KN_set_param(kc, "gradopt", 1)

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
    KNITRO.KN_add_vars(kc, nV)
    KNITRO.KN_set_var_lobnds_all(kc, [-1.0, -1.0])
    KNITRO.KN_set_var_upbnds_all(kc, [1.0, 1.0])
    KNITRO.KN_set_var_primal_init_values_all(kc, [1.0, 5.0])

    # Add the residuals
    KNITRO.KN_add_rsds(kc, 6)

    # Define callbacks
    cb = KNITRO.KN_add_lsq_eval_callback(kc, evalR)
    nnzJ = 12
    KNITRO.KN_set_cb_rsd_jac(
        kc,
        cb,
        nnzJ,
        evalJ,
        jacIndexRsds=Int32[0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5],
        jacIndexVars=Int32[0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1],
    )
    KNITRO.KN_set_cb_user_params(kc, cb, myParams)

    # Solve the problem.
    status = KNITRO.KN_solve(kc)
    @test status == 0

    jac = KNITRO.KN_get_rsd_jacobian_values(kc)

    nStatus, objSol, x, lambda_ = KNITRO.KN_get_solution(kc)
    @test nStatus == 0

    @test objSol ≈ 21.5848 atol = 1e-3
    @test x ≈ [1.0, 1.0] atol = 1e-5

    KNITRO.KN_free(kc)
end

@testset "User callback test (issue #110)" begin
    kc = KNITRO.KN_new()

    KNITRO.KN_set_param(kc, "outlev", 0)
    # Define objective goal
    objGoal = KNITRO.KN_OBJGOAL_MAXIMIZE
    KNITRO.KN_set_obj_goal(kc, objGoal)

    # Add the variables and set their bounds.
    nV = 3
    KNITRO.KN_add_vars(kc, nV)
    KNITRO.KN_set_var_lobnds_all(kc, [0, 0.1, 0])
    KNITRO.KN_set_var_upbnds_all(kc, [0.0, 2, 2])

    # Define an initial point.
    KNITRO.KN_set_var_primal_init_values_all(kc, [1, 1, 1.5])
    KNITRO.KN_set_var_dual_init_values_all(kc, [1.0, 1, 1, 1])

    # Add the constraints and set their lower bounds.
    nC = 1
    KNITRO.KN_add_cons(kc, nC)
    KNITRO.KN_set_con_lobnds_all(kc, [0.1])
    KNITRO.KN_set_con_upbnds_all(kc, [2 * 2 * 0.99])

    # Load quadratic structure x1*x2 for the constraint.
    KNITRO.KN_add_con_quadratic_struct(kc, 0, 1, 2, 1.0)

    # Define callback functions.
    cb = KNITRO.KN_add_eval_callback_all(kc, evalAll)
    KNITRO.KN_set_cb_grad(kc, cb, evalAll)
    KNITRO.KN_set_cb_hess(kc, cb, KNITRO.KN_DENSE_ROWMAJOR, evalAll)

    KNITRO.KN_set_compcons(kc, Int32[KNITRO.KN_CCTYPE_VARVAR], Int32[0], Int32[1])

    function newpt_callback(kc, x, lambda_, user_data)
        if KNITRO.KN_get_number_iters(kc) > 1
            return KNITRO.KN_RC_USER_TERMINATION
        end
        return 0
    end

    KNITRO.KN_set_newpt_callback(kc, newpt_callback)

    status = KNITRO.KN_solve(kc)
    @test status == KNITRO.KN_RC_USER_TERMINATION

    nStatus, objSol, x, lambda_ = KNITRO.KN_get_solution(kc)
    @test nStatus == KNITRO.KN_RC_USER_TERMINATION
    @test KNITRO.KN_get_number_iters(kc) == 2

    KNITRO.KN_free(kc)
end

@testset "Handling exception in callbacks" begin
    function eval_kn(kc, cb, evalRequest, evalResult, userParams)
        # Generate exception in callback
        throw(LoadError)
        return 0
    end

    kc = KNITRO.KN_new()
    KNITRO.KN_set_param(kc, "outlev", 0)
    KNITRO.KN_add_vars(kc, 1)
    KNITRO.KN_set_var_primal_init_values_all(kc, [0.0])
    cb = KNITRO.KN_add_objective_callback(kc, eval_kn)
    nstatus = KNITRO.KN_solve(kc)
    @test nstatus == KNITRO.KN_RC_CALLBACK_ERR
    KNITRO.KN_free(kc)
end

@testset "Knitro evaluation exception" begin
    function eval_kn(kc, cb, evalRequest, evalResult, userParams)
        x = evalRequest.x
        evalResult.obj[1] = sqrt(x[1])
        return 0
    end

    kc = KNITRO.KN_new()
    KNITRO.KN_set_param(kc, "outlev", 0)
    KNITRO.KN_add_vars(kc, 1)
    # Start from a non-evaluable point
    KNITRO.KN_set_var_primal_init_values_all(kc, [-1.0])
    cb = KNITRO.KN_add_objective_callback(kc, eval_kn)
    nstatus = KNITRO.KN_solve(kc)
    nStatus, objSol, x, lambda_ = KNITRO.KN_get_solution(kc)
    @test x ≈ [0.0] atol = 1e-5
    KNITRO.KN_free(kc)
end

@testset "Knitro violation information" begin
    if KNITRO.KNITRO_VERSION < v"12.4"
        return 0
    end
    #*------------------------------------------------------------------*
    #*     FUNCTION callbackEvalFC                                      *
    #*------------------------------------------------------------------*
    # The signature of this function matches KNITRO.KN_eval_callback in knitro.h.
    # Only "obj" and "c" are set in the KNITRO.KN_eval_result structure.
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
    kc = KNITRO.KN_new()
    KNITRO.KN_set_param(kc, "outlev", 0)
    xIndices = KNITRO.KN_add_vars(kc, 4)
    for x in xIndices
        KNITRO.KN_set_var_primal_init_value(kc, x, 0.8)
    end

    # Add the constraints and set the rhs and coefficients
    KNITRO.KN_add_cons(kc, 3)
    KNITRO.KN_set_con_eqbnds_all(kc, [1.0, 0.0, 0.0])

    # Coefficients for 2 linear terms
    lconIndexCons = Int32[1, 2]
    lconIndexVars = Int32[2, 1]
    lconCoefs = [-1.0, -1.0]
    KNITRO.KN_add_con_linear_struct(kc, lconIndexCons, lconIndexVars, lconCoefs)

    # Coefficients for 2 quadratic terms

    # 1st term:  x1^2 term in c0
    # 2nd term:  x3^2 term in c2
    qconIndexCons = Int32[0, 2]
    qconIndexVars1 = Int32[1, 3]
    qconIndexVars2 = Int32[1, 3]
    qconCoefs = [1.0, 1.0]

    KNITRO.KN_add_con_quadratic_struct(
        kc,
        qconIndexCons,
        qconIndexVars1,
        qconIndexVars2,
        qconCoefs,
    )

    # Add callback to evaluate nonlinear(non-quadratic) terms in the model:
    #    x0*x1*x2*x3  in the objective
    #    x0^3         in first constraint c0
    #    x0^2*x3      in second constraint c1
    cb = KNITRO.KN_add_eval_callback(kc, true, Int32[0, 1], callbackEvalFC)

    # Set minimize or maximize(if not set, assumed minimize)
    KNITRO.KN_set_obj_goal(kc, KNITRO.KN_OBJGOAL_MAXIMIZE)

    # Solve the problem.
    #
    # Return status codes are defined in "knitro.h" and described
    # in the Knitro manual.
    nStatus = KNITRO.KN_solve(kc)
    # An example of obtaining solution information.
    nStatus, objSol, x, lambda_ = KNITRO.KN_get_solution(kc)
    varbndInfeas, varintInfeas, varviols = KNITRO.KN_get_var_viols(kc, Cint[0, 1, 2, 3])

    coninfeas, conviols = KNITRO.KN_get_con_viols(kc, Cint[0, 1, 2])

    KNITRO.KN_get_presolve_error(kc)
    @testset "Example HS40 nlp1noderivs" begin
        @test varbndInfeas == [0, 0, 0, 0]
        @test varintInfeas == [0, 0, 0, 0]
        @test varviols ≈ [0.0, 0.0, 0.0, 0.0] atol = 1e-6
        @test coninfeas == [0, 0, 0]
        @test conviols ≈ [0.0, 0.0, 0.0] atol = 1e-6
        @test KNITRO.KN_get_abs_feas_error(kc) == max(conviols...)
    end

    # Delete the Knitro solver instance.
    KNITRO.KN_free(kc)
end

@testset "Knitro structural manipulation" begin
    if KNITRO.KNITRO_VERSION < v"12.4"
        return 0
    end
    #*------------------------------------------------------------------*
    #*     FUNCTION callbackEvalFC                                      *
    #*------------------------------------------------------------------*
    # The signature of this function matches KNITRO.KN_eval_callback in knitro.h.
    # Only "obj" and "c" are set in the KNITRO.KN_eval_result structure.
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
    # The signature of this function matches KNITRO.KN_eval_callback in knitro.h.
    # Only "objGrad" and "jac" are set in the KNITRO.KN_eval_result structure.
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
    # The signature of this function matches KNITRO.KN_eval_callback in knitro.h.
    # Only "hess" or "hessVec" are set in the KNITRO.KN_eval_result structure.
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
    kc = KNITRO.KN_new()
    KNITRO.KN_set_param(kc, "outlev", 0)

    # Initialize Knitro with the problem definition.

    # Add the variables and specify initial values for them.
    # Note: any unset lower bounds are assumed to be
    # unbounded below and any unset upper bounds are
    # assumed to be unbounded above.
    xIndices = KNITRO.KN_add_vars(kc, 4)
    for x in xIndices
        KNITRO.KN_set_var_primal_init_value(kc, x, 0.8)
    end

    # Add the constraints and set the rhs and coefficients
    KNITRO.KN_add_cons(kc, 3)
    KNITRO.KN_set_con_eqbnds_all(kc, [1.0, 0.0, 0.0])

    # Coefficients for 2 linear terms
    lconIndexCons = Int32[1, 2]
    lconIndexVars = Int32[2, 1]
    lconCoefs = [-1.0, -1.0]
    KNITRO.KN_add_con_linear_struct(kc, lconIndexCons, lconIndexVars, lconCoefs)

    # Coefficients for 2 quadratic terms

    # 1st term:  x1^2 term in c0
    # 2nd term:  x3^2 term in c2
    qconIndexCons = Int32[0, 2]
    qconIndexVars1 = Int32[1, 3]
    qconIndexVars2 = Int32[1, 3]
    qconCoefs = [1.0, 1.0]

    KNITRO.KN_add_con_quadratic_struct(
        kc,
        qconIndexCons,
        qconIndexVars1,
        qconIndexVars2,
        qconCoefs,
    )

    # Add callback to evaluate nonlinear(non-quadratic) terms in the model:
    #    x0*x1*x2*x3  in the objective
    #    x0^3         in first constraint c0
    #    x0^2*x3      in second constraint c1
    cb = KNITRO.KN_add_eval_callback(kc, true, Int32[0, 1], callbackEvalFC)

    # Set obj. gradient and nonlinear jac provided through callbacks.
    # Mark objective gradient as dense, and provide non-zero sparsity
    # structure for constraint Jacobian terms.
    cbjacIndexCons = Int32[0, 1, 1]
    cbjacIndexVars = Int32[0, 0, 3]
    KNITRO.KN_set_cb_grad(
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
    KNITRO.KN_set_cb_hess(
        kc,
        cb,
        length(cbhessIndexVars1),
        callbackEvalH,
        hessIndexVars1=cbhessIndexVars1,
        hessIndexVars2=cbhessIndexVars2,
    )

    # Set minimize or maximize(if not set, assumed minimize)
    KNITRO.KN_set_obj_goal(kc, KNITRO.KN_OBJGOAL_MAXIMIZE)

    # Solve the initial problem.
    #
    # Return status codes are defined in "knitro.h" and described
    # in the Knitro manual.
    nStatus = KNITRO.KN_solve(kc)

    # An example of obtaining solution information.
    nStatus_origin, objSol_origin, x_origin, lambda_origin = KNITRO.KN_get_solution(kc)

    # =============== MODIFY PROBLEM AND RE-SOLVE ===========
    # Add 0.5x3 linear term to c2
    KNITRO.KN_add_con_linear_struct(kc, 2, 3, 0.5)
    # Change -x2 to 5x2 in c1
    KNITRO.KN_chg_con_linear_term(kc, 1, 2, 5.0)
    # Now add a new linear constraint x1 + 2x2 + x3 <= 2.5 (c3) and re-solve
    c3 = KNITRO.KN_add_con(kc)
    KNITRO.KN_set_con_upbnd(kc, c3, 2.5)
    KNITRO.KN_add_con_linear_struct(kc, c3, Int32[1, 2, 3], [1.0, 2.0, 1.0])

    # Add a constant to the objective
    KNITRO.KN_add_obj_constant(kc, 100.0)

    # Tell Knitro to try a "warm-start" since it is starting from the solution
    # of the previous solve, which may be a good initial point for the solution
    # of the slightly modified problem.
    KNITRO.KN_set_param(
        kc,
        KNITRO.KN_PARAM_STRAT_WARM_START,
        KNITRO.KN_STRAT_WARM_START_YES,
    )

    nStatus = KNITRO.KN_solve(kc)
    nStatus, objSol, x, lambda_ = KNITRO.KN_get_solution(kc)

    # =============== MODIFY PROBLEM BACK TO THE ORIGINAL ONE AND RE-SOLVE AGAIN ===========
    # Remove 0.5x3 from c2
    KNITRO.KN_del_con_linear_term(kc, 2, 3)
    # Change 5x2 back to -x2 in c1
    KNITRO.KN_chg_con_linear_term(kc, 1, 2, -1.0)
    # Remove new constraint c3
    KNITRO.KN_del_con_linear_struct_one(kc, 3, c3, Int32[1, 2, 3])
    # Remove the constant in the objective
    KNITRO.KN_del_obj_constant(kc)

    nStatus = KNITRO.KN_solve(kc)
    nStatus, objSol, x, lambda_ = KNITRO.KN_get_solution(kc)

    # Test that the solution is the same than the original problem
    @testset begin
        @test nStatus == nStatus_origin
        @test objSol ≈ objSol_origin atol = 1e-6
        @test x ≈ x_origin atol = 1e-6
        @test lambda_[1:length(lambda_origin)] ≈ lambda_origin atol = 1e-1
    end

    # Delete the Knitro solver instance.
    KNITRO.KN_free(kc)
end
