const KN_var_type_map = Dict(
    KN_VARTYPE_CONTINUOUS => :Cont,
    KN_VARTYPE_INTEGER => :Int,
    KN_VARTYPE_BINARY => :Bin
)

const KN_rev_var_type_map = Dict(
    :Cont => KN_VARTYPE_CONTINUOUS,
    :Int => KN_VARTYPE_INTEGER,
    :Bin => KN_VARTYPE_BINARY
)

# This list was obtained through AWK with Knitro 11.1 with the following command:
# grep "#define" knitro.h | grep "KN_PARAM_" | awk '{ printf("\"%s\" => Int32(%s),\n",$2,$3) }'
# For versions up to 10.3, use the folowing command:
# grep "#define" knitro.h | grep "KTR_PARAM_" | awk '{ printf("\"%s\" => Int32(%s),\n",$2,$3) }'
const KN_paramName2Indx = Dict(
    "KN_PARAM_NEWPOINT" => Int32(1001),
    "KN_PARAM_HONORBNDS" => Int32(1002),
    "KN_PARAM_ALGORITHM" => Int32(1003),
    "KN_PARAM_ALG" => Int32(1003),
    "KN_PARAM_BAR_MURULE" => Int32(1004),
    "KN_PARAM_BAR_FEASIBLE" => Int32(1006),
    "KN_PARAM_GRADOPT" => Int32(1007),
    "KN_PARAM_HESSOPT" => Int32(1008),
    "KN_PARAM_BAR_INITPT" => Int32(1009),
    "KN_PARAM_ACT_LPSOLVER" => Int32(1012),
    "KN_PARAM_CG_MAXIT" => Int32(1013),
    "KN_PARAM_MAXIT" => Int32(1014),
    "KN_PARAM_OUTLEV" => Int32(1015),
    "KN_PARAM_OUTMODE" => Int32(1016),
    "KN_PARAM_SCALE" => Int32(1017),
    "KN_PARAM_SOC" => Int32(1019),
    "KN_PARAM_DELTA" => Int32(1020),
    "KN_PARAM_BAR_FEASMODETOL" => Int32(1021),
    "KN_PARAM_FEASTOL" => Int32(1022),
    "KN_PARAM_FEASTOLABS" => Int32(1023),
    "KN_PARAM_MAXTIMECPU" => Int32(1024),
    "KN_PARAM_BAR_INITMU" => Int32(1025),
    "KN_PARAM_OBJRANGE" => Int32(1026),
    "KN_PARAM_OPTTOL" => Int32(1027),
    "KN_PARAM_OPTTOLABS" => Int32(1028),
    "KN_PARAM_LINSOLVER_PIVOTTOL" => Int32(1029),
    "KN_PARAM_XTOL" => Int32(1030),
    "KN_PARAM_DEBUG" => Int32(1031),
    "KN_PARAM_MULTISTART" => Int32(1033),
    "KN_PARAM_MSENABLE" => Int32(1033),
    "KN_PARAM_MSMAXSOLVES" => Int32(1034),
    "KN_PARAM_MSMAXBNDRANGE" => Int32(1035),
    "KN_PARAM_MSMAXTIMECPU" => Int32(1036),
    "KN_PARAM_MSMAXTIMEREAL" => Int32(1037),
    "KN_PARAM_LMSIZE" => Int32(1038),
    "KN_PARAM_BAR_MAXCROSSIT" => Int32(1039),
    "KN_PARAM_MAXTIMEREAL" => Int32(1040),
    "KN_PARAM_CG_PRECOND" => Int32(1041),
    "KN_PARAM_BLASOPTION" => Int32(1042),
    "KN_PARAM_BAR_MAXREFACTOR" => Int32(1043),
    "KN_PARAM_LINESEARCH_MAXTRIALS" => Int32(1044),
    "KN_PARAM_BLASOPTIONLIB" => Int32(1045),
    "KN_PARAM_OUTAPPEND" => Int32(1046),
    "KN_PARAM_OUTDIR" => Int32(1047),
    "KN_PARAM_CPLEXLIB" => Int32(1048),
    "KN_PARAM_BAR_PENRULE" => Int32(1049),
    "KN_PARAM_BAR_PENCONS" => Int32(1050),
    "KN_PARAM_MSNUMTOSAVE" => Int32(1051),
    "KN_PARAM_MSSAVETOL" => Int32(1052),
    "KN_PARAM_PRESOLVEDEBUG" => Int32(1053),
    "KN_PARAM_MSTERMINATE" => Int32(1054),
    "KN_PARAM_MSSTARTPTRANGE" => Int32(1055),
    "KN_PARAM_INFEASTOL" => Int32(1056),
    "KN_PARAM_LINSOLVER" => Int32(1057),
    "KN_PARAM_BAR_DIRECTINTERVAL" => Int32(1058),
    "KN_PARAM_PRESOLVE" => Int32(1059),
    "KN_PARAM_PRESOLVE_TOL" => Int32(1060),
    "KN_PARAM_BAR_SWITCHRULE" => Int32(1061),
    "KN_PARAM_HESSIAN_NO_F" => Int32(1062),
    "KN_PARAM_MA_TERMINATE" => Int32(1063),
    "KN_PARAM_MA_MAXTIMECPU" => Int32(1064),
    "KN_PARAM_MA_MAXTIMEREAL" => Int32(1065),
    "KN_PARAM_MSSEED" => Int32(1066),
    "KN_PARAM_MA_OUTSUB" => Int32(1067),
    "KN_PARAM_MS_OUTSUB" => Int32(1068),
    "KN_PARAM_XPRESSLIB" => Int32(1069),
    "KN_PARAM_TUNER" => Int32(1070),
    "KN_PARAM_TUNER_OPTIONSFILE" => Int32(1071),
    "KN_PARAM_TUNER_MAXTIMECPU" => Int32(1072),
    "KN_PARAM_TUNER_MAXTIMEREAL" => Int32(1073),
    "KN_PARAM_TUNER_OUTSUB" => Int32(1074),
    "KN_PARAM_TUNER_TERMINATE" => Int32(1075),
    "KN_PARAM_LINSOLVER_OOC" => Int32(1076),
    "KN_PARAM_BAR_RELAXCONS" => Int32(1077),
    "KN_PARAM_MSDETERMINISTIC" => Int32(1078),
    "KN_PARAM_BAR_REFINEMENT" => Int32(1079),
    "KN_PARAM_DERIVCHECK" => Int32(1080),
    "KN_PARAM_DERIVCHECK_TYPE" => Int32(1081),
    "KN_PARAM_DERIVCHECK_TOL" => Int32(1082),
    "KN_PARAM_LINSOLVER_INEXACT" => Int32(1083),
    "KN_PARAM_LINSOLVER_INEXACTTOL" => Int32(1084),
    "KN_PARAM_MAXFEVALS" => Int32(1085),
    "KN_PARAM_FSTOPVAL" => Int32(1086),
    "KN_PARAM_DATACHECK" => Int32(1087),
    "KN_PARAM_DERIVCHECK_TERMINATE" => Int32(1088),
    "KN_PARAM_BAR_WATCHDOG" => Int32(1089),
    "KN_PARAM_FTOL" => Int32(1090),
    "KN_PARAM_FTOL_ITERS" => Int32(1091),
    "KN_PARAM_ACT_QPALG" => Int32(1092),
    "KN_PARAM_BAR_INITPI_MPEC" => Int32(1093),
    "KN_PARAM_XTOL_ITERS" => Int32(1094),
    "KN_PARAM_LINESEARCH" => Int32(1095),
    "KN_PARAM_OUT_CSVINFO" => Int32(1096),
    "KN_PARAM_INITPENALTY" => Int32(1097),
    "KN_PARAM_ACT_LPFEASTOL" => Int32(1098),
    "KN_PARAM_CG_STOPTOL" => Int32(1099),
    "KN_PARAM_RESTARTS" => Int32(1100),
    "KN_PARAM_RESTARTS_MAXIT" => Int32(1101),
    "KN_PARAM_BAR_SLACKBOUNDPUSH" => Int32(1102),
    "KN_PARAM_CG_PMEM" => Int32(1103),
    "KN_PARAM_BAR_SWITCHOBJ" => Int32(1104),
    "KN_PARAM_OUTNAME" => Int32(1105),
    "KN_PARAM_OUT_CSVNAME" => Int32(1106),
    "KN_PARAM_ACT_PARAMETRIC" => Int32(1107),
    "KN_PARAM_ACT_LPDUMPMPS" => Int32(1108),
    "KN_PARAM_ACT_LPALG" => Int32(1109),
    "KN_PARAM_ACT_LPPRESOLVE" => Int32(1110),
    "KN_PARAM_ACT_LPPENALTY" => Int32(1111),
    "KN_PARAM_BNDRANGE" => Int32(1112),
    "KN_PARAM_BAR_CONIC_ENABLE" => Int32(1113),
    "KN_PARAM_CONVEX" => Int32(1114),
    "KN_PARAM_OUT_HINTS" => Int32(1115),
    "KN_PARAM_EVAL_FCGA" => Int32(1116),
    "KN_PARAM_MIP_METHOD" => Int32(2001),
    "KN_PARAM_MIP_BRANCHRULE" => Int32(2002),
    "KN_PARAM_MIP_SELECTRULE" => Int32(2003),
    "KN_PARAM_MIP_INTGAPABS" => Int32(2004),
    "KN_PARAM_MIP_INTGAPREL" => Int32(2005),
    "KN_PARAM_MIP_MAXTIMECPU" => Int32(2006),
    "KN_PARAM_MIP_MAXTIMEREAL" => Int32(2007),
    "KN_PARAM_MIP_MAXSOLVES" => Int32(2008),
    "KN_PARAM_MIP_INTEGERTOL" => Int32(2009),
    "KN_PARAM_MIP_OUTLEVEL" => Int32(2010),
    "KN_PARAM_MIP_OUTINTERVAL" => Int32(2011),
    "KN_PARAM_MIP_OUTSUB" => Int32(2012),
    "KN_PARAM_MIP_DEBUG" => Int32(2013),
    "KN_PARAM_MIP_IMPLICATNS" => Int32(2014),
    "KN_PARAM_MIP_GUB_BRANCH" => Int32(2015),
    "KN_PARAM_MIP_KNAPSACK" => Int32(2016),
    "KN_PARAM_MIP_ROUNDING" => Int32(2017),
    "KN_PARAM_MIP_ROOTALG" => Int32(2018),
    "KN_PARAM_MIP_LPALG" => Int32(2019),
    "KN_PARAM_MIP_TERMINATE" => Int32(2020),
    "KN_PARAM_MIP_MAXNODES" => Int32(2021),
    "KN_PARAM_MIP_HEURISTIC" => Int32(2022),
    "KN_PARAM_MIP_HEUR_MAXIT" => Int32(2023),
    "KN_PARAM_MIP_HEUR_MAXTIMECPU" => Int32(2024),
    "KN_PARAM_MIP_HEUR_MAXTIMEREAL" => Int32(2025),
    "KN_PARAM_MIP_PSEUDOINIT" => Int32(2026),
    "KN_PARAM_MIP_STRONG_MAXIT" => Int32(2027),
    "KN_PARAM_MIP_STRONG_CANDLIM" => Int32(2028),
    "KN_PARAM_MIP_STRONG_LEVEL" => Int32(2029),
    "KN_PARAM_MIP_INTVAR_STRATEGY" => Int32(2030),
    "KN_PARAM_MIP_RELAXABLE" => Int32(2031),
    "KN_PARAM_MIP_NODEALG" => Int32(2032),
    "KN_PARAM_MIP_HEUR_TERMINATE" => Int32(2033),
    "KN_PARAM_MIP_SELECTDIR" => Int32(2034),
    "KN_PARAM_PAR_NUMTHREADS" => Int32(3001),
    "KN_PARAM_PAR_CONCURRENT_EVALS" => Int32(3002),
    "KN_PARAM_PAR_BLASNUMTHREADS" => Int32(3003),
    "KN_PARAM_PAR_LSNUMTHREADS" => Int32(3004),
    "KN_PARAM_PAR_MSNUMTHREADS" => Int32(3005),
)

const KNITRO_OPTIONS = String[
    "newpoint",                  # KTR_PARAM_NEWPOINT=               #
    "honorbnds",                 # KTR_PARAM_HONORBNDS            #
    "algorithm",                 # KTR_PARAM_ALGORITHM            #
    "bar_murule",                # KTR_PARAM_BAR_MURULE           #
    "bar_feasible",              # KTR_PARAM_BAR_FEASIBLE         #
    "gradopt",                   # KTR_PARAM_GRADOPT              #
    "hessopt",                   # KTR_PARAM_HESSOPT              #
    "bar_initpt",                # KTR_PARAM_BAR_INITPT           #
    "act_lpsolver",              # KTR_PARAM_ACT_LPSOLVER         #
    "cg_maxit",                  # KTR_PARAM_CG_MAXIT             #
    "maxit",                     # KTR_PARAM_MAXIT                #
    "outlev",                    # KTR_PARAM_OUTLEV               #
    "outmode",                   # KTR_PARAM_OUTMODE              #
    "scale",                     # KTR_PARAM_SCALE                #
    "soc",                       # KTR_PARAM_SOC                  #
    "delta",                     # KTR_PARAM_DELTA                #
    "bar_feasmodetol",           # KTR_PARAM_BAR_FEASMODETOL      #
    "feastol",                   # KTR_PARAM_FEASTOL              #
    "feastolabs",                # KTR_PARAM_FEASTOLABS           #
    "maxtimecpu",                # KTR_PARAM_MAXTIMECPU           #
    "bar_initmu",                # KTR_PARAM_BAR_INITMU           #
    "objrange",                  # KTR_PARAM_OBJRANGE             #
    "opttol",                    # KTR_PARAM_OPTTOL               #
    "opttolabs",                 # KTR_PARAM_OPTTOLABS            #
    "linsolver_pivottol",        # KTR_PARAM_LINSOLVER_PIVOTTOL   #
    "xtol",                      # KTR_PARAM_XTOL                 #
    "debug",                     # KTR_PARAM_DEBUG                #
    "ms_enable",                 # KTR_PARAM_MULTISTART           #
    "ms_maxsolves",              # KTR_PARAM_MSMAXSOLVES          #
    "ms_maxbndrange",            # KTR_PARAM_MSMAXBNDRANGE        #
    "ms_maxtime_cpu",            # KTR_PARAM_MSMAXTIMECPU         #
    "ms_maxtime_real",           # KTR_PARAM_MSMAXTIMEREAL        #
    "lmsize",                    # KTR_PARAM_LMSIZE               #
    "bar_maxcrossit",            # KTR_PARAM_BAR_MAXCROSSIT       #
    "maxtime_real",              # KTR_PARAM_MAXTIMEREAL          #
    "cg_precond",                # KTR_PARAM_CG_PRECOND           #
    "blasoption",                # KTR_PARAM_BLASOPTION           #
    "bar_maxrefactor",           # KTR_PARAM_BAR_MAXREFACTOR      #
    "linesearch_maxtrials",      # KTR_PARAM_LINESEARCH_MAXTRIALS #
    "blasoptionlib",             # KTR_PARAM_BLASOPTIONLIB        #
    "outappend",                 # KTR_PARAM_OUTAPPEND            #
    "outdir",                    # KTR_PARAM_OUTDIR               #
    "cplexlibname",              # KTR_PARAM_CPLEXLIB             #
    "bar_penaltyrule",           # KTR_PARAM_BAR_PENRULE          #
    "bar_penaltycons",           # KTR_PARAM_BAR_PENCONS          #
    "ms_num_to_save",            # KTR_PARAM_MSNUMTOSAVE          #
    "ms_savetol",                # KTR_PARAM_MSSAVETOL            #
    "ms_terminate",              # KTR_PARAM_MSTERMINATE          #
    "ms_startptrange",           # KTR_PARAM_MSSTARTPTRANGE       #
    "infeastol",                 # KTR_PARAM_INFEASTOL            #
    "linsolver",                 # KTR_PARAM_LINSOLVER            #
    "bar_directinterval",        # KTR_PARAM_BAR_DIRECTINTERVAL   #
    "presolve",                  # KTR_PARAM_PRESOLVE             #
    "presolve_tol",              # KTR_PARAM_PRESOLVE_TOL         #
    "bar_switchrule",            # KTR_PARAM_BAR_SWITCHRULE       #
    "hessian_no_f",              # KTR_PARAM_HESSIAN_NO_F         #
    "ma_terminate",              # KTR_PARAM_MA_TERMINATE         #
    "ma_maxtime_cpu",            # KTR_PARAM_MA_MAXTIMECPU        #
    "ma_maxtime_real",           # KTR_PARAM_MA_MAXTIMEREAL       #
    "ms_seed",                   # KTR_PARAM_MSSEED               #
    "ma_outsub",                 # KTR_PARAM_MA_OUTSUB            #
    "ms_outsub",                 # KTR_PARAM_MS_OUTSUB            #
    "xpresslibname",             # KTR_PARAM_XPRESSLIB            #
    "tuner",                     # KTR_PARAM_TUNER                #
    "tuner_optionsfile",         # KTR_PARAM_TUNER_OPTIONSFILE    #
    "tuner_maxtime_cpu",         # KTR_PARAM_TUNER_MAXTIMECPU     #
    "tuner_maxtime_real",        # KTR_PARAM_TUNER_MAXTIMEREAL    #
    "tuner_outsub",              # KTR_PARAM_TUNER_OUTSUB         #
    "tuner_terminate",           # KTR_PARAM_TUNER_TERMINATE      #
    "linsolver_ooc",             # KTR_PARAM_LINSOLVER_OOC        #
    "bar_relaxcons",             # KTR_PARAM_BAR_RELAXCONS        #
    "ms_deterministic",          # KTR_PARAM_MSDETERMINISTIC      #
    "bar_refinement",            # KTR_PARAM_BAR_REFINEMENT       #
    "derivcheck",                # KTR_PARAM_DERIVCHECK           #
    "derivcheck_type",           # KTR_PARAM_DERIVCHECK_TYPE      #
    "derivcheck_tol",            # KTR_PARAM_DERIVCHECK_TOL       #
    "maxfevals",                 # KTR_PARAM_MAXFEVALS            #
    "fstopval",                  # KTR_PARAM_FSTOPVAL             #
    "datacheck",                 # KTR_PARAM_DATACHECK            #
    "derivcheck_terminate",      # KTR_PARAM_DERIVCHECK_TERMINATE #
    "bar_watchdog",              # KTR_PARAM_BAR_WATCHDOG         #
    "ftol",                      # KTR_PARAM_FTOL                 #
    "ftol_iters",                # KTR_PARAM_FTOL_ITERS           #
    "act_qpalg",                 # KTR_PARAM_ACT_QPALG            #
    "bar_initpi_mpec",           # KTR_PARAM_BAR_INITPI_MPEC      #
    "xtol_iters",                # KTR_PARAM_XTOL_ITERS           #
    "linesearch",                # KTR_PARAM_LINESEARCH           #
    "out_csvinfo",               # KTR_PARAM_OUT_CSVINFO          #
    "initpenalty",               # KTR_PARAM_INITPENALTY          #
    "act_lpfeastol",             # KTR_PARAM_ACT_LPFEASTOL        #
    "cg_stoptol",                # KTR_PARAM_CG_STOPTOL           #
    "restarts",                  # KTR_PARAM_RESTARTS             #
    "restarts_maxit",            # KTR_PARAM_RESTARTS_MAXIT       #
    "bar_slackboundpush",        # KTR_PARAM_BAR_SLACKBOUNDPUSH   #
    "cg_pmem",                   # KTR_PARAM_CG_PMEM              #
    "bar_switchobj",             # KTR_PARAM_BAR_SWITCHOBJ        #
    "outname",                   # KTR_PARAM_OUTNAME              #
    "out_csvname",               # KTR_PARAM_OUT_CSVNAME          #
    "act_parametric",            # KTR_PARAM_ACT_PARAMETRIC       #
    "act_lpdumpmps",             # KTR_PARAM_ACT_LPDUMPMPS        #
    "act_lpalg",                 # KTR_PARAM_ACT_LPALG            #
    "act_lppresolve",            # KTR_PARAM_ACT_LPPRESOLVE       #
    "act_lppenalty",             # KTR_PARAM_ACT_LPPENALTY        #
    "bndrange",                  # KN_PARAM_BNDRANGE              #
    "bar_conic_enable",          # KN_PARAM_BAR_CONIC_ENABLE      #
    "convex",                    # KN_PARAM_CONVEX                #
    "out_hints",                 # KN_PARAM_OUT_HINTS             #
    "eval_fcga",                 # KN_PARAM_EVAL_FCGA             #
    "bar_maxcorrectors",         # KN_PARAM_BAR_MAXCORRECTORS     #
    "strat_warm_start",          # KN_PARAM_STRAT_WARM_START      #
    "findiff_terminate",         # KN_PARAM_FINDIFF_TERMINATE     #
    "cpuplatform",               # KN_PARAM_CPUPLATFORM           #
    "presolve_passes",           # KN_PARAM_PRESOLVE_PASSES       #
    "presolve_level",            # KN_PARAM_PRESOLVE_LEVEL        #
    "findiff_relstepsize",       # KN_PARAM_FINDIFF_RELSTEPSIZE   #
    "infeastol_iters",           # KN_PARAM_INFEASTOL_ITERS       #
    "mip_method",                # KTR_PARAM_MIP_METHOD           #
    "mip_branchrule",            # KTR_PARAM_MIP_BRANCHRULE       #
    "mip_selectrule",            # KTR_PARAM_MIP_SELECTRULE       #
    "mip_integral_gap_abs",      # KTR_PARAM_MIP_INTGAPABS        #
    "mip_integral_gap_rel",      # KTR_PARAM_MIP_INTGAPREL        #
    "mip_maxtimecpu",            # KTR_PARAM_MIP_MAXTIMECPU       #
    "mip_maxtimereal",           # KTR_PARAM_MIP_MAXTIMEREAL      #
    "mip_maxsolves",             # KTR_PARAM_MIP_MAXSOLVES        #
    "mip_integer_tol",           # KTR_PARAM_MIP_INTEGERTOL       #
    "mip_outlevel",              # KTR_PARAM_MIP_OUTLEVEL         #
    "mip_outinterval",           # KTR_PARAM_MIP_OUTINTERVAL      #
    "mip_outsub",                # KTR_PARAM_MIP_OUTSUB           #
    "mip_debug",                 # KTR_PARAM_MIP_DEBUG            #
    "mip_implications",          # KTR_PARAM_MIP_IMPLICATNS       #
    "mip_gub_branch",            # KTR_PARAM_MIP_GUB_BRANCH       #
    "mip_knapsack",              # KTR_PARAM_MIP_KNAPSACK         #
    "mip_rounding",              # KTR_PARAM_MIP_ROUNDING         #
    "mip_rootalg",               # KTR_PARAM_MIP_ROOTALG          #
    "mip_lpalg",                 # KTR_PARAM_MIP_LPALG            #
    "mip_terminate",             # KTR_PARAM_MIP_TERMINATE        #
    "mip_maxnodes",              # KTR_PARAM_MIP_MAXNODES         #
    "mip_heuristic",             # KTR_PARAM_MIP_HEURISTIC        #
    "mip_heuristic_maxit",       # KTR_PARAM_MIP_HEUR_MAXIT       #
    "mip_heuristic_maxtimecpu",  # KTR_PARAM_MIP_HEUR_MAXTIMECPU  #
    "mip_heuristic_maxtimereal", # KTR_PARAM_MIP_HEUR_MAXTIMEREAL #
    "mip_pseudoinit",            # KTR_PARAM_MIP_PSEUDOINIT       #
    "mip_strong_maxit",          # KTR_PARAM_MIP_STRONG_MAXIT     #
    "mip_strong_candlim",        # KTR_PARAM_MIP_STRONG_CANDLIM   #
    "mip_strong_level",          # KTR_PARAM_MIP_STRONG_LEVEL     #
    "mip_intvar_strategy",       # KTR_PARAM_MIP_INTVAR_STRATEGY  #
    "mip_relaxable",             # KTR_PARAM_MIP_RELAXABLE        #
    "mip_nodealg",               # KTR_PARAM_MIP_NODEALG          #
    "mip_heuristic_terminate",   # KTR_PARAM_MIP_HEUR_TERMINATE   #
    "mip_selectdir",             # KTR_PARAM_MIP_SELECTDIR        #
    "mip_cutfactor",             #  KTR_PARAM_MIP_CUTFACTOR       #
    "mip_zerohalf",              # KTR_PARAM_MIP_ZEROHALF         #
	"mip_mir",                   # KTR_PARAM_MIP_MIR              #
	"mip_clique",                # KTR_PARAM_MIP_CLIQUE           #
    "par_numthreads",            # KTR_PARAM_PAR_NUMTHREADS       #
    "par_concurrent_evals",      # KTR_PARAM_PAR_CONCURRENT_EVALS #
    "par_blasnumthreads",        # KTR_PARAM_PAR_BLASNUMTHREADS   #
    "par_lsnumthreads",          # KTR_PARAM_PAR_LSNUMTHREADS     #
    "par_msnumthreads",          # KTR_PARAM_PAR_MSNUMTHREADS     #
	"par_conicnumthreads"        # KTR_PARAM_PAR_CONICNUMTHREADS  # //FGN
]
