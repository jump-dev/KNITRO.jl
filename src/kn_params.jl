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
# grep "#define" knitro.h | grep "KN_PARAM_" | awk '{ printf("\"%s\" => Cint(%s),\n",$2,$3) }'
const KN_paramName2Indx = Dict(
    "KN_PARAM_NEWPOINT" => Cint(1001),
    "KN_PARAM_HONORBNDS" => Cint(1002),
    "KN_PARAM_ALGORITHM" => Cint(1003),
    "KN_PARAM_ALG" => Cint(1003),
    "KN_PARAM_BAR_MURULE" => Cint(1004),
    "KN_PARAM_BAR_FEASIBLE" => Cint(1006),
    "KN_PARAM_GRADOPT" => Cint(1007),
    "KN_PARAM_HESSOPT" => Cint(1008),
    "KN_PARAM_BAR_INITPT" => Cint(1009),
    "KN_PARAM_ACT_LPSOLVER" => Cint(1012),
    "KN_PARAM_CG_MAXIT" => Cint(1013),
    "KN_PARAM_MAXIT" => Cint(1014),
    "KN_PARAM_OUTLEV" => Cint(1015),
    "KN_PARAM_OUTMODE" => Cint(1016),
    "KN_PARAM_SCALE" => Cint(1017),
    "KN_PARAM_SOC" => Cint(1019),
    "KN_PARAM_DELTA" => Cint(1020),
    "KN_PARAM_BAR_FEASMODETOL" => Cint(1021),
    "KN_PARAM_FEASTOL" => Cint(1022),
    "KN_PARAM_FEASTOLABS" => Cint(1023),
    "KN_PARAM_MAXTIMECPU" => Cint(1024),
    "KN_PARAM_BAR_INITMU" => Cint(1025),
    "KN_PARAM_OBJRANGE" => Cint(1026),
    "KN_PARAM_OPTTOL" => Cint(1027),
    "KN_PARAM_OPTTOLABS" => Cint(1028),
    "KN_PARAM_LINSOLVER_PIVOTTOL" => Cint(1029),
    "KN_PARAM_XTOL" => Cint(1030),
    "KN_PARAM_DEBUG" => Cint(1031),
    "KN_PARAM_MULTISTART" => Cint(1033),
    "KN_PARAM_MSENABLE" => Cint(1033),
    "KN_PARAM_MSMAXSOLVES" => Cint(1034),
    "KN_PARAM_MSMAXBNDRANGE" => Cint(1035),
    "KN_PARAM_MSMAXTIMECPU" => Cint(1036),
    "KN_PARAM_MSMAXTIMEREAL" => Cint(1037),
    "KN_PARAM_LMSIZE" => Cint(1038),
    "KN_PARAM_BAR_MAXCROSSIT" => Cint(1039),
    "KN_PARAM_MAXTIMEREAL" => Cint(1040),
    "KN_PARAM_CG_PRECOND" => Cint(1041),
    "KN_PARAM_BLASOPTION" => Cint(1042),
    "KN_PARAM_BAR_MAXREFACTOR" => Cint(1043),
    "KN_PARAM_LINESEARCH_MAXTRIALS" => Cint(1044),
    "KN_PARAM_BLASOPTIONLIB" => Cint(1045),
    "KN_PARAM_OUTAPPEND" => Cint(1046),
    "KN_PARAM_OUTDIR" => Cint(1047),
    "KN_PARAM_CPLEXLIB" => Cint(1048),
    "KN_PARAM_BAR_PENRULE" => Cint(1049),
    "KN_PARAM_BAR_PENCONS" => Cint(1050),
    "KN_PARAM_MSNUMTOSAVE" => Cint(1051),
    "KN_PARAM_MSSAVETOL" => Cint(1052),
    "KN_PARAM_PRESOLVEDEBUG" => Cint(1053),
    "KN_PARAM_MSTERMINATE" => Cint(1054),
    "KN_PARAM_MSSTARTPTRANGE" => Cint(1055),
    "KN_PARAM_INFEASTOL" => Cint(1056),
    "KN_PARAM_LINSOLVER" => Cint(1057),
    "KN_PARAM_BAR_DIRECTINTERVAL" => Cint(1058),
    "KN_PARAM_PRESOLVE" => Cint(1059),
    "KN_PARAM_PRESOLVE_TOL" => Cint(1060),
    "KN_PARAM_BAR_SWITCHRULE" => Cint(1061),
    "KN_PARAM_HESSIAN_NO_F" => Cint(1062),
    "KN_PARAM_MA_TERMINATE" => Cint(1063),
    "KN_PARAM_MA_MAXTIMECPU" => Cint(1064),
    "KN_PARAM_MA_MAXTIMEREAL" => Cint(1065),
    "KN_PARAM_MSSEED" => Cint(1066),
    "KN_PARAM_MA_OUTSUB" => Cint(1067),
    "KN_PARAM_MS_OUTSUB" => Cint(1068),
    "KN_PARAM_XPRESSLIB" => Cint(1069),
    "KN_PARAM_TUNER" => Cint(1070),
    "KN_PARAM_TUNER_OPTIONSFILE" => Cint(1071),
    "KN_PARAM_TUNER_MAXTIMECPU" => Cint(1072),
    "KN_PARAM_TUNER_MAXTIMEREAL" => Cint(1073),
    "KN_PARAM_TUNER_OUTSUB" => Cint(1074),
    "KN_PARAM_TUNER_TERMINATE" => Cint(1075),
    "KN_PARAM_LINSOLVER_OOC" => Cint(1076),
    "KN_PARAM_BAR_RELAXCONS" => Cint(1077),
    "KN_PARAM_MSDETERMINISTIC" => Cint(1078),
    "KN_PARAM_BAR_REFINEMENT" => Cint(1079),
    "KN_PARAM_DERIVCHECK" => Cint(1080),
    "KN_PARAM_DERIVCHECK_TYPE" => Cint(1081),
    "KN_PARAM_DERIVCHECK_TOL" => Cint(1082),
    "KN_PARAM_LINSOLVER_INEXACT" => Cint(1083),
    "KN_PARAM_LINSOLVER_INEXACTTOL" => Cint(1084),
    "KN_PARAM_MAXFEVALS" => Cint(1085),
    "KN_PARAM_FSTOPVAL" => Cint(1086),
    "KN_PARAM_DATACHECK" => Cint(1087),
    "KN_PARAM_DERIVCHECK_TERMINATE" => Cint(1088),
    "KN_PARAM_BAR_WATCHDOG" => Cint(1089),
    "KN_PARAM_FTOL" => Cint(1090),
    "KN_PARAM_FTOL_ITERS" => Cint(1091),
    "KN_PARAM_ACT_QPALG" => Cint(1092),
    "KN_PARAM_BAR_INITPI_MPEC" => Cint(1093),
    "KN_PARAM_XTOL_ITERS" => Cint(1094),
    "KN_PARAM_LINESEARCH" => Cint(1095),
    "KN_PARAM_OUT_CSVINFO" => Cint(1096),
    "KN_PARAM_INITPENALTY" => Cint(1097),
    "KN_PARAM_ACT_LPFEASTOL" => Cint(1098),
    "KN_PARAM_CG_STOPTOL" => Cint(1099),
    "KN_PARAM_RESTARTS" => Cint(1100),
    "KN_PARAM_RESTARTS_MAXIT" => Cint(1101),
    "KN_PARAM_BAR_SLACKBOUNDPUSH" => Cint(1102),
    "KN_PARAM_CG_PMEM" => Cint(1103),
    "KN_PARAM_BAR_SWITCHOBJ" => Cint(1104),
    "KN_PARAM_OUTNAME" => Cint(1105),
    "KN_PARAM_OUT_CSVNAME" => Cint(1106),
    "KN_PARAM_ACT_PARAMETRIC" => Cint(1107),
    "KN_PARAM_ACT_LPDUMPMPS" => Cint(1108),
    "KN_PARAM_ACT_LPALG" => Cint(1109),
    "KN_PARAM_ACT_LPPRESOLVE" => Cint(1110),
    "KN_PARAM_ACT_LPPENALTY" => Cint(1111),
    "KN_PARAM_BNDRANGE" => Cint(1112),
    "KN_PARAM_BAR_CONIC_ENABLE" => Cint(1113),
    "KN_PARAM_CONVEX" => Cint(1114),
    "KN_PARAM_OUT_HINTS" => Cint(1115),
    "KN_PARAM_EVAL_FCGA" => Cint(1116),
    "KN_PARAM_BAR_MAXCORRECTORS" => Cint(1117),
    "KN_PARAM_STRAT_WARM_START" => Cint(1118),
    "KN_PARAM_FINDIFF_TERMINATE" => Cint(1119),
    "KN_PARAM_CPUPLATFORM" => Cint(1120),
    "KN_PARAM_PRESOLVE_PASSES" => Cint(1121),
    "KN_PARAM_PRESOLVE_LEVEL" => Cint(1122),
    "KN_PARAM_FINDIFF_RELSTEPSIZE" => Cint(1123),
    "KN_PARAM_INFEASTOL_ITERS" => Cint(1124),
    "KN_PARAM_PRESOLVEOP_TIGHTEN" => Cint(1125),
    "KN_PARAM_BAR_LINSYS" => Cint(1126),
    "KN_PARAM_PRESOLVE_INITPT" => Cint(1127),
    "KN_PARAM_ACT_QPPENALTY" => Cint(1128),
    "KN_PARAM_BAR_LINSYS_STORAGE" => Cint(1129),
    "KN_PARAM_LINSOLVER_MAXITREF" => Cint(1130),
    "KN_PARAM_BFGS_SCALING" => Cint(1131),
    "KN_PARAM_MIP_METHOD" => Cint(2001),
    "KN_PARAM_MIP_BRANCHRULE" => Cint(2002),
    "KN_PARAM_MIP_SELECTRULE" => Cint(2003),
    "KN_PARAM_MIP_INTGAPABS" => Cint(2004),
    "KN_PARAM_MIP_INTGAPREL" => Cint(2005),
    "KN_PARAM_MIP_MAXTIMECPU" => Cint(2006),
    "KN_PARAM_MIP_MAXTIMEREAL" => Cint(2007),
    "KN_PARAM_MIP_MAXSOLVES" => Cint(2008),
    "KN_PARAM_MIP_INTEGERTOL" => Cint(2009),
    "KN_PARAM_MIP_OUTLEVEL" => Cint(2010),
    "KN_PARAM_MIP_OUTINTERVAL" => Cint(2011),
    "KN_PARAM_MIP_OUTSUB" => Cint(2012),
    "KN_PARAM_MIP_DEBUG" => Cint(2013),
    "KN_PARAM_MIP_IMPLICATNS" => Cint(2014),
    "KN_PARAM_MIP_GUB_BRANCH" => Cint(2015),
    "KN_PARAM_MIP_KNAPSACK" => Cint(2016),
    "KN_PARAM_MIP_ROUNDING" => Cint(2017),
    "KN_PARAM_MIP_ROOTALG" => Cint(2018),
    "KN_PARAM_MIP_LPALG" => Cint(2019),
    "KN_PARAM_MIP_TERMINATE" => Cint(2020),
    "KN_PARAM_MIP_MAXNODES" => Cint(2021),
    "KN_PARAM_MIP_HEURISTIC" => Cint(2022),
    "KN_PARAM_MIP_HEUR_MAXIT" => Cint(2023),
    "KN_PARAM_MIP_HEUR_MAXTIMECPU" => Cint(2024),
    "KN_PARAM_MIP_HEUR_MAXTIMEREAL" => Cint(2025),
    "KN_PARAM_MIP_PSEUDOINIT" => Cint(2026),
    "KN_PARAM_MIP_STRONG_MAXIT" => Cint(2027),
    "KN_PARAM_MIP_STRONG_CANDLIM" => Cint(2028),
    "KN_PARAM_MIP_STRONG_LEVEL" => Cint(2029),
    "KN_PARAM_MIP_INTVAR_STRATEGY" => Cint(2030),
    "KN_PARAM_MIP_RELAXABLE" => Cint(2031),
    "KN_PARAM_MIP_NODEALG" => Cint(2032),
    "KN_PARAM_MIP_HEUR_TERMINATE" => Cint(2033),
    "KN_PARAM_MIP_SELECTDIR" => Cint(2034),
    "KN_PARAM_MIP_CUTFACTOR" => Cint(2035),
    "KN_PARAM_MIP_ZEROHALF" => Cint(2036),
    "KN_PARAM_MIP_MIR" => Cint(2037),
    "KN_PARAM_MIP_CLIQUE" => Cint(2038),
    "KN_PARAM_MIP_HEUR_STRATEGY" => Cint(2039),
    "KN_PARAM_MIP_HEUR_FEASPUMP" => Cint(2040),   
    "KN_PARAM_MIP_HEUR_MPEC" => Cint(2041), 
    "KN_PARAM_MIP_HEUR_DIVING" => Cint(2042),
    "KN_PARAM_MIP_CUTTINGPLANE" => Cint(2043),
    # Knitro 13.0
    "KN_PARAM_MS_ENABLE"            => Cint(1033),
    "KN_PARAM_MS_MAXSOLVES"         => Cint(1034),
    "KN_PARAM_MS_MAXBNDRANGE"       => Cint(1035),
    "KN_PARAM_MS_MAXTIMECPU"        => Cint(1036),
    "KN_PARAM_MS_MAXTIMEREAL"       => Cint(1037),
    "KN_PARAM_MS_NUMTOSAVE"         => Cint(1051),
    "KN_PARAM_MS_SAVETOL"           => Cint(1052),
    "KN_PARAM_MS_TERMINATE"         => Cint(1054),
    "KN_PARAM_MS_STARTPTRANGE"      => Cint(1055),
    "KN_PARAM_MS_SEED"              => Cint(1066),  
    "KN_PARAM_MS_DETERMINISTIC"     => Cint(1078),
    "KN_PARAM_BAR_INITSHIFTTOL"     => Cint(1132),
    "KN_PARAM_NUMTHREADS"           => Cint(1133),
    "KN_PARAM_CONCURRENT_EVALS"     => Cint(1134),
    "KN_PARAM_BLAS_NUMTHREADS"      => Cint(1135),
    "KN_PARAM_LINSOLVER_NUMTHREADS" => Cint(1136),
    "KN_PARAM_MS_NUMTHREADS"        => Cint(1137),
    "KN_PARAM_CONIC_NUMTHREADS"     => Cint(1138),
    "KN_PARAM_NCVX_QCQP_INIT"       => Cint(1139), 
    "KN_PARAM_MIP_OPTGAPABS"        => Cint(2004),
    "KN_PARAM_MIP_OPTGAPREL"        => Cint(2005), 
    "KN_PARAM_MIP_IMPLICATIONS"     => Cint(2014), 
    "KN_PARAM_MIP_CUTOFF"           => Cint(2044), #
    "KN_PARAM_MIP_HEUR_LNS"         => Cint(2045),
    "KN_PARAM_MIP_MULTISTART"       => Cint(2046),
    # DEPRECATED starting Knitro 13.0
    "KN_PARAM_PAR_NUMTHREADS"       => Cint(3001), # USE KN_PARAM_NUMTHREADS
    "KN_PARAM_PAR_CONCURRENT_EVALS" => Cint(3002), # USE KN_PARAM_CONCURRENT_EVALS
    "KN_PARAM_PAR_BLASNUMTHREADS"   => Cint(3003), # USE KN_PARAM_BLAS_NUMTHREADS
    "KN_PARAM_PAR_LSNUMTHREADS"     => Cint(3004), # USE KN_PARAM_LINSOLVER_NUMTHREADS
    "KN_PARAM_PAR_MSNUMTHREADS"     => Cint(3005), # USE KN_PARAM_MS_NUMTHREADS
    "KN_PARAM_PAR_CONICNUMTHREADS"  => Cint(3006), # USE KN_PARAM_CONIC_NUMTHREADS

)

const KNITRO_OPTIONS = String[
    "newpoint",                  # KN_PARAM_NEWPOINT=            #
    "honorbnds",                 # KN_PARAM_HONORBNDS            #
    "algorithm",                 # KN_PARAM_ALGORITHM            #
    "bar_murule",                # KN_PARAM_BAR_MURULE           #
    "bar_feasible",              # KN_PARAM_BAR_FEASIBLE         #
    "gradopt",                   # KN_PARAM_GRADOPT              #
    "hessopt",                   # KN_PARAM_HESSOPT              #
    "bar_initpt",                # KN_PARAM_BAR_INITPT           #
    "act_lpsolver",              # KN_PARAM_ACT_LPSOLVER         #
    "cg_maxit",                  # KN_PARAM_CG_MAXIT             #
    "maxit",                     # KN_PARAM_MAXIT                #
    "outlev",                    # KN_PARAM_OUTLEV               #
    "outmode",                   # KN_PARAM_OUTMODE              #
    "scale",                     # KN_PARAM_SCALE                #
    "soc",                       # KN_PARAM_SOC                  #
    "delta",                     # KN_PARAM_DELTA                #
    "bar_feasmodetol",           # KN_PARAM_BAR_FEASMODETOL      #
    "feastol",                   # KN_PARAM_FEASTOL              #
    "feastolabs",                # KN_PARAM_FEASTOLABS           #
    "maxtimecpu",                # KN_PARAM_MAXTIMECPU           #
    "bar_initmu",                # KN_PARAM_BAR_INITMU           #
    "objrange",                  # KN_PARAM_OBJRANGE             #
    "opttol",                    # KN_PARAM_OPTTOL               #
    "opttolabs",                 # KN_PARAM_OPTTOLABS            #
    "linsolver_pivottol",        # KN_PARAM_LINSOLVER_PIVOTTOL   #
    "xtol",                      # KN_PARAM_XTOL                 #
    "debug",                     # KN_PARAM_DEBUG                #
    "ms_enable",                 # KN_PARAM_MS_ENABLE            #
    "ms_maxsolves",              # KN_PARAM_MS_MAXSOLVES         #
    "ms_maxbndrange",            # KN_PARAM_MS_MAXBNDRANGE       #
    "ms_maxtime_cpu",            # KN_PARAM_MS_MAXTIMECPU        #
    "ms_maxtime_real",           # KN_PARAM_MS_MAXTIMEREAL       #
    "lmsize",                    # KN_PARAM_LMSIZE               #
    "bar_maxcrossit",            # KN_PARAM_BAR_MAXCROSSIT       #
    "maxtime_real",              # KN_PARAM_MAXTIMEREAL          #
    "cg_precond",                # KN_PARAM_CG_PRECOND           #
    "blasoption",                # KN_PARAM_BLASOPTION           #
    "bar_maxrefactor",           # KN_PARAM_BAR_MAXREFACTOR      #
    "linesearch_maxtrials",      # KN_PARAM_LINESEARCH_MAXTRIALS #
    "blasoptionlib",             # KN_PARAM_BLASOPTIONLIB        #
    "outappend",                 # KN_PARAM_OUTAPPEND            #
    "outdir",                    # KN_PARAM_OUTDIR               #
    "cplexlibname",              # KN_PARAM_CPLEXLIB             #
    "bar_penaltyrule",           # KN_PARAM_BAR_PENRULE          #
    "bar_penaltycons",           # KN_PARAM_BAR_PENCONS          #
    "ms_num_to_save",            # KN_PARAM_MS_NUMTOSAVE         #
    "ms_savetol",                # KN_PARAM_MS_SAVETOL           #
    "ms_terminate",              # KN_PARAM_MS_TERMINATE         #
    "ms_startptrange",           # KN_PARAM_MS_STARTPTRANGE      #
    "infeastol",                 # KN_PARAM_INFEASTOL            #
    "linsolver",                 # KN_PARAM_LINSOLVER            #
    "bar_directinterval",        # KN_PARAM_BAR_DIRECTINTERVAL   #
    "presolve",                  # KN_PARAM_PRESOLVE             #
    "presolve_tol",              # KN_PARAM_PRESOLVE_TOL         #
    "bar_switchrule",            # KN_PARAM_BAR_SWITCHRULE       #
    "hessian_no_f",              # KN_PARAM_HESSIAN_NO_F         #
    "ma_terminate",              # KN_PARAM_MA_TERMINATE         #
    "ma_maxtime_cpu",            # KN_PARAM_MA_MAXTIMECPU        #
    "ma_maxtime_real",           # KN_PARAM_MA_MAXTIMEREAL       #
    "ms_seed",                   # KN_PARAM_MS_SEED               #
    "ma_outsub",                 # KN_PARAM_MA_OUTSUB            #
    "ms_outsub",                 # KN_PARAM_MS_OUTSUB            #
    "xpresslibname",             # KN_PARAM_XPRESSLIB            #
    "tuner",                     # KN_PARAM_TUNER                #
    "tuner_optionsfile",         # KN_PARAM_TUNER_OPTIONSFILE    #
    "tuner_maxtime_cpu",         # KN_PARAM_TUNER_MAXTIMECPU     #
    "tuner_maxtime_real",        # KN_PARAM_TUNER_MAXTIMEREAL    #
    "tuner_outsub",              # KN_PARAM_TUNER_OUTSUB         #
    "tuner_terminate",           # KN_PARAM_TUNER_TERMINATE      #
    "linsolver_ooc",             # KN_PARAM_LINSOLVER_OOC        #
    "bar_relaxcons",             # KN_PARAM_BAR_RELAXCONS        #
    "ms_deterministic",          # KN_PARAM_MS_DETERMINISTIC     #
    "bar_refinement",            # KN_PARAM_BAR_REFINEMENT       #
    "derivcheck",                # KN_PARAM_DERIVCHECK           #
    "derivcheck_type",           # KN_PARAM_DERIVCHECK_TYPE      #
    "derivcheck_tol",            # KN_PARAM_DERIVCHECK_TOL       #
    "maxfevals",                 # KN_PARAM_MAXFEVALS            #
    "fstopval",                  # KN_PARAM_FSTOPVAL             #
    "datacheck",                 # KN_PARAM_DATACHECK            #
    "derivcheck_terminate",      # KN_PARAM_DERIVCHECK_TERMINATE #
    "bar_watchdog",              # KN_PARAM_BAR_WATCHDOG         #
    "ftol",                      # KN_PARAM_FTOL                 #
    "ftol_iters",                # KN_PARAM_FTOL_ITERS           #
    "act_qpalg",                 # KN_PARAM_ACT_QPALG            #
    "bar_initpi_mpec",           # KN_PARAM_BAR_INITPI_MPEC      #
    "xtol_iters",                # KN_PARAM_XTOL_ITERS           #
    "linesearch",                # KN_PARAM_LINESEARCH           #
    "out_csvinfo",               # KN_PARAM_OUT_CSVINFO          #
    "initpenalty",               # KN_PARAM_INITPENALTY          #
    "act_lpfeastol",             # KN_PARAM_ACT_LPFEASTOL        #
    "cg_stoptol",                # KN_PARAM_CG_STOPTOL           #
    "restarts",                  # KN_PARAM_RESTARTS             #
    "restarts_maxit",            # KN_PARAM_RESTARTS_MAXIT       #
    "bar_slackboundpush",        # KN_PARAM_BAR_SLACKBOUNDPUSH   #
    "cg_pmem",                   # KN_PARAM_CG_PMEM              #
    "bar_switchobj",             # KN_PARAM_BAR_SWITCHOBJ        #
    "outname",                   # KN_PARAM_OUTNAME              #
    "out_csvname",               # KN_PARAM_OUT_CSVNAME          #
    "act_parametric",            # KN_PARAM_ACT_PARAMETRIC       #
    "act_lpdumpmps",             # KN_PARAM_ACT_LPDUMPMPS        #
    "act_lpalg",                 # KN_PARAM_ACT_LPALG            #
    "act_lppresolve",            # KN_PARAM_ACT_LPPRESOLVE       #
    "act_lppenalty",             # KN_PARAM_ACT_LPPENALTY        #
    "bndrange",                  # KN_PARAM_BNDRANGE             #
    "bar_conic_enable",          # KN_PARAM_BAR_CONIC_ENABLE     #
    "convex",                    # KN_PARAM_CONVEX               #
    "out_hints",                 # KN_PARAM_OUT_HINTS            #
    "eval_fcga",                 # KN_PARAM_EVAL_FCGA            #
    "bar_maxcorrectors",         # KN_PARAM_BAR_MAXCORRECTORS    #
    "strat_warm_start",          # KN_PARAM_STRAT_WARM_START     #
    "findiff_terminate",         # KN_PARAM_FINDIFF_TERMINATE    #
    "cpuplatform",               # KN_PARAM_CPUPLATFORM          #
    "presolve_passes",           # KN_PARAM_PRESOLVE_PASSES      #
    "presolve_level",            # KN_PARAM_PRESOLVE_LEVEL       #
    "findiff_relstepsize",       # KN_PARAM_FINDIFF_RELSTEPSIZE  #
    "infeastol_iters",           # KN_PARAM_INFEASTOL_ITERS      #
    "mip_method",                # KN_PARAM_MIP_METHOD           #
    "mip_branchrule",            # KN_PARAM_MIP_BRANCHRULE       #
    "mip_selectrule",            # KN_PARAM_MIP_SELECTRULE       #
    "mip_integral_gap_abs",      # KN_PARAM_MIP_INTGAPABS        #
    "mip_integral_gap_rel",      # KN_PARAM_MIP_INTGAPREL        #
    "mip_maxtimecpu",            # KN_PARAM_MIP_MAXTIMECPU       #
    "mip_maxtimereal",           # KN_PARAM_MIP_MAXTIMEREAL      #
    "mip_maxsolves",             # KN_PARAM_MIP_MAXSOLVES        #
    "mip_integer_tol",           # KN_PARAM_MIP_INTEGERTOL       #
    "mip_outlevel",              # KN_PARAM_MIP_OUTLEVEL         #
    "mip_outinterval",           # KN_PARAM_MIP_OUTINTERVAL      #
    "mip_outsub",                # KN_PARAM_MIP_OUTSUB           #
    "mip_debug",                 # KN_PARAM_MIP_DEBUG            #
    "mip_implications",          # KN_PARAM_MIP_IMPLICATIONS     #
    "mip_gub_branch",            # KN_PARAM_MIP_GUB_BRANCH       #
    "mip_knapsack",              # KN_PARAM_MIP_KNAPSACK         #
    "mip_rounding",              # KN_PARAM_MIP_ROUNDING         #
    "mip_rootalg",               # KN_PARAM_MIP_ROOTALG          #
    "mip_lpalg",                 # KN_PARAM_MIP_LPALG            #
    "mip_terminate",             # KN_PARAM_MIP_TERMINATE        #
    "mip_maxnodes",              # KN_PARAM_MIP_MAXNODES         #
    "mip_heuristic",             # KN_PARAM_MIP_HEURISTIC        #
    "mip_heuristic_maxit",       # KN_PARAM_MIP_HEUR_MAXIT       #
    "mip_heuristic_maxtimecpu",  # KN_PARAM_MIP_HEUR_MAXTIMECPU  #
    "mip_heuristic_maxtimereal", # KN_PARAM_MIP_HEUR_MAXTIMEREAL #
    "mip_pseudoinit",            # KN_PARAM_MIP_PSEUDOINIT       #
    "mip_strong_maxit",          # KN_PARAM_MIP_STRONG_MAXIT     #
    "mip_strong_candlim",        # KN_PARAM_MIP_STRONG_CANDLIM   #
    "mip_strong_level",          # KN_PARAM_MIP_STRONG_LEVEL     #
    "mip_intvar_strategy",       # KN_PARAM_MIP_INTVAR_STRATEGY  #
    "mip_relaxable",             # KN_PARAM_MIP_RELAXABLE        #
    "mip_nodealg",               # KN_PARAM_MIP_NODEALG          #
    "mip_heuristic_terminate",   # KN_PARAM_MIP_HEUR_TERMINATE   #
    "mip_selectdir",             # KN_PARAM_MIP_SELECTDIR        #
    "mip_cutfactor",             # KN_PARAM_MIP_CUTFACTOR        #
    "mip_zerohalf",              # KN_PARAM_MIP_ZEROHALF         #
    "mip_mir",                   # KN_PARAM_MIP_MIR              #
    "mip_clique",                # KN_PARAM_MIP_CLIQUE           #
    "mip_heuristic_strategy",    # KN_PARAM_MIP_HEUR_STRATEGY    #
    "mip_heuristic_feaspump",    # KN_PARAM_MIP_HEUR_FEASPUMP    #
    "mip_heuristic_mpec",        # KN_PARAM_MIP_HEUR_MPEC        #
    "mip_heuristic_diving",      # KN_PARAM_MIP_HEUR_DIVING      #
    "mip_cutting_plane",         # KN_PARAM_MIP_CUTTINGPLANE     #
    "par_numthreads",            # KN_PARAM_PAR_NUMTHREADS (Knitro < 13.0) KN_PARAM_NUMTHREADS (Knitro >= 13.0)             #
    "par_concurrent_evals",      # KN_PARAM_PAR_CONCURRENT_EVALS (Knitro < 13.0) KN_PARAM_CONCURRENT_EVALS (Knitro >= 13.0) #
    "par_blasnumthreads",        # KN_PARAM_PAR_BLASNUMTHREADS (Knitro < 13.0) KN_PARAM_BLAS_NUMTHREADS (Knitro >= 13.0)    #
    "par_lsnumthreads",          # KN_PARAM_PAR_LSNUMTHREADS (Knitro < 13.0) KN_PARAM_LINSOLVER_NUMTHREADS (Knitro >= 13.0) #
    "par_msnumthreads",          # KN_PARAM_PAR_MSNUMTHREADS (Knitro < 13.0) KN_PARAM_MS_NUMTHREADS (Knitro >= 13.0)        #
    "par_conicnumthreads",       # KN_PARAM_PAR_CONICNUMTHREADS (Knitro < 13.0) KN_PARAM_CONIC_NUMTHREADS (Knitro >= 13.0)  #
    "findiff_relstepsize",       # KN_PARAM_FINDIFF_RELSTEPSIZE  #
    "infeastol_iters",           # KN_PARAM_INFEASTOL_ITERS      #
    "presolveop_tighten",        # KN_PARAM_PRESOLVEOP_TIGHTEN   #
    "pre_redundancylevel",       # KN_CNT_REDUNDANCY_DETECTION   #
    "pre_improvecoefficients",   # KN_IMPROVE_COEFFICIENTS       #
    "bar_linsys",                # KN_PARAM_BAR_LINSYS           #
    "presolve_initpt",           # KN_PARAM_PRESOLVE_INITPT      #
    "act_qppenalty",             # KN_PARAM_ACT_QPPENALTY        #
    "bar_linsys_storage",        # KN_PARAM_BAR_LINSYS_STORAGE   #
    "linsolver_maxitref",        # KN_PARAM_LINSOLVER_MAXITREF   #
    "bfgs_scaling",              # KN_PARAM_BFGS_SCALING         #
    "option_file",
    "tuner_file",
    "bar_initshiftol",          # KN_PARAM_BAR_INITSHIFTTOL      #
    "ncvx_qcqp_init",           # KN_PARAM_NCVX_QCQP_INIT        #
    "mip_opt_gap_abs",          # KN_PARAM_MIP_OPTGAPABS         #
    "mip_opt_gap_rel",          # KN_PARAM_MIP_OPTGAPREL         #
    "mip_cutoff",               # KN_PARAM_MIP_CUTOFF            #
    "mip_heuristic_lns",        # KN_PARAM_MIP_HEUR_LNS          #
    "mip_multistart",           # KN_PARAM_MIP_MULTISTART        #
]
