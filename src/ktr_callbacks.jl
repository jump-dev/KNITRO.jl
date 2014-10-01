export
  set_func_callback,
  set_grad_callback,
  set_hess_callback

# /** Applications may define functions for evaluating problem elements
#  *  at a trial point.  The functions must match the prototype defined
#  *  below, and passed to KNITRO with the appropriate KTR_set_func_x call.
#  *  KNITRO may request four different types of evaluation information,
#  *  as specified in "evalRequestCode":
#  *    KTR_RC_EVALFC - return objective and constraint function values
#  *    KTR_RC_EVALGA - return first derivative values in "objGrad" and "jac"
#  *    KTR_RC_EVALH  - return second derivative values in "hessian"
#  *    KTR_RC_EVALH_NO_F  (this version exclude the objective term)
#  *    KTR_RC_EVALHV - return a Hessian-vector product in "hessVector"
#  *    KTR_RC_EVALHV_NO_F (this version exclude the objective term)
#  *
#  *  The argument "lambda" is not defined when requesting EVALFC or EVALGA.
#  *    Usually, applications define 3 callback functions, one for EVALFC,
#  *  one for EVALGA, and one for EVALH / EVALHV.  The last function
#  *  evaluates H or HV depending on the value of "evalRequestCode".
#  *    It is possible to combine EVALFC and EVALGA into a single function,
#  *  because "x" changes only for an EVALFC request.  This is advantageous
#  *  if the application evaluates functions and their derivatives at the same
#  *  time.  Pass the same callback function in KTR_set_func_callback
#  *  and KTR_set_grad_callback, have it populate "obj", "c", "objGrad",
#  *  and "jac" for an EVALFC request, and do nothing for an EVALGA request.
#  *    Do not combine EVALFC and EVALGA if hessopt = KTR_HESSOPT_FINITE_DIFF,
#  *  because the finite difference Hessian changes x and calls EVALGA without
#  *  calling EVALFC first.
#  *    It is not possible to combine EVALH / EVALHV because "lambda" changes
#  *  after the EVALFC call.
#  *
#  *  The "userParams" argument is an arbitrary pointer passed from the KNITRO
#  *  KTR_solve call to the callback.  It should be used to pass parameters
#  *  defined and controlled by the application, or left null if not used.
#  *  KNITRO does not modify or dereference the "userParams" pointer.
#  *
#  *  For simplicity, the following callback functions all use the same
#  *  "KTR_callback()" function prototype defined below.
#  *      
#  *      KTR_set_func_callback
#  *      KTR_set_grad_callback
#  *      KTR_set_hess_callback
#  *      KTR_set_newpoint_callback
#  *      KTR_set_ms_process_callback
#  *      KTR_set_mip_node_callback
#  *
#  *  Callbacks should return 0 if successful, a negative error code if not.
#  *  Possible unsuccessful (negative) error codes for the func/grad/hess
#  *  callback functions include:
#  *     
#  *      KTR_RC_CALLBACK_ERR       (for generic callback errors)
#  *      KTR_RC_EVAL_ERR           (for evaluation errors, e.g log(-1))
#  *
#  *  In addition, for the "func", "newpoint", "ms_process" and "mip_node"
#  *  callbacks, the user may set the following return code to force KNITRO
#  *  to terminate based on some user-defined condition.
#  *
#  *      KTR_RC_USER_TERMINATION   (to use a callback routine
#  *                                 for user specified termination)
#  */
# typedef int KTR_callback (const int             evalRequestCode,
#                           const int             n,
#                           const int             m,
#                           const int             nnzJ,
#                           const int             nnzH,
#                           const double * const  x,
#                           const double * const  lambda,
#                                 double * const  obj,
#                                 double * const  c,
#                                 double * const  objGrad,
#                                 double * const  jac,
#                                 double * const  hessian,
#                                 double * const  hessVector,
#                                 void   *        userParams);

callback_params = (Cint, Cint, Cint, Cint, Cint, Ptr{Cdouble},
                   Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cdouble},
                   Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cdouble},
                   Ptr{Cdouble}, Ptr{Void})

# /** Set the callback function that evaluates "obj" and "c" at x.
#  *  It may also evaluate "objGrad" and "jac" if EVALFC and EVALGA are
#  *  combined into a single call.
#  *  Do not modify "hessian" or "hessVector".
#  */
# int  KNITRO_API KTR_set_func_callback (KTR_context_ptr       kc,
#                                        KTR_callback * const  fnPtr);

function set_func_callback(kp::KnitroProblem, f::Function)
  cb = cfunction(f, Cint, callback_params)
  return_code = @ktr_ccall(set_func_callback, Int32, (Ptr{Void},
                           Ptr{Void}), kp.env, cb)
  if return_code != 0
    error("KNITRO: Error setting function callback")
  end
end

# /** Set the callback function that evaluates "objGrad" and "jac" at x.
#  *  It may do nothing if EVALFC and EVALGA are combined into a single call.
#  *  Do not modify "hessian" or "hessVector".
#  */
# int  KNITRO_API KTR_set_grad_callback (KTR_context_ptr       kc,
#                                        KTR_callback * const  fnPtr);

function set_grad_callback(kp::KnitroProblem, f::Function)
  cb = cfunction(f, Cint, callback_params)
  return_code = @ktr_ccall(set_grad_callback, Int32,(Ptr{Void},
                           Ptr{Void}), kp.env, cb)
  if return_code != 0
    error("KNITRO: Error setting gradient callback")
  end
end

# /** Set the callback function that evaluates second derivatives at (x, lambda).
#  *  If "evalRequestCode" equals KTR_RC_EVALH, then the function must
#  *  return nonzeroes in "hessian".  If it equals KTR_RC_EVALHV, then the
#  *  function multiplies second derivatives by "hessVector" and returns the
#  *  product in "hessVector".
#  *  Do not modify "obj", "c", "objGrad", or "jac".
#  */
# int  KNITRO_API KTR_set_hess_callback (KTR_context_ptr       kc,
#                                        KTR_callback * const  fnPtr);

function set_hess_callback(kp::KnitroProblem, f::Function)
  cb = cfunction(f, Cint, callback_params)
  return_code = @ktr_ccall(set_hess_callback, Int32, (Ptr{Void},
                           Ptr{Void}), kp.env, cb)
  if return_code != 0
    error("KNITRO: Error setting hessian callback")
  end
end

# /** Set the callback function that is invoked after KNITRO computes a
#  *  new estimate of the solution point (i.e., after every major iteration).
#  *  The function should not modify any KNITRO arguments.
#  *  Argument "kc" is the context pointer for the current problem being
#  *  solved inside KNITRO (either the main single-solve problem, or a
#  *  subproblem when using multi-start, Tuner, etc.).
#  *  Arguments "x" and "lambda" contain the new point and values.
#  *  Arguments "obj" and "c" contain objective and constraint values at "x",
#  *  and "objGrad" and "jac" contain the objective gradient and constraint
#  *  Jacobian at "x".
#  */
# typedef int  KTR_newpt_callback (KTR_context_ptr           kc,
#                                      const int             n,
#                                      const int             m,
#                                      const int             nnzJ,
#                                      const double * const  x,
#                                      const double * const  lambda,
#                                      const double          obj,
#                                      const double * const  c,
#                                      const double * const  objGrad,
#                                      const double * const  jac,
#                                            void   *        userParams);
# int  KNITRO_API KTR_set_newpt_callback (KTR_context_ptr             kc,
#                                         KTR_newpt_callback * const  fnPtr);
# /** An older version of this callback maintained for backwards compatibility.
#  *  Please use the new version defined above. */    
# int  KNITRO_API KTR_set_newpoint_callback (KTR_context_ptr       kc,
#                                            KTR_callback * const  fnPtr);
    
# /** This callback function is for multistart (MS) problems only.
#  *  Set the callback function that is invoked after KNITRO finishes
#  *  processing a multistart solve.  The function should not modify any
#  *  KNITRO arguments.  Arguments "x" and "lambda" contain the solution from
#  *  the last solve. Arguments "obj" and "c" contain objective and constraint
#  *  values at "x".  First and second derivative arguments are not currently
#  *  defined and should not be examined. 
#  */
# int  KNITRO_API KTR_set_ms_process_callback (KTR_context_ptr       kc,
#                                              KTR_callback * const  fnPtr);
    
# /** This callback function is for mixed integer (MIP) problems only.
#  *  Set the callback function that is invoked after KNITRO finishes
#  *  processing a node on the branch-and-bound tree (i.e., after a relaxed
#  *  subproblem solve in the branch-and-bound procedure).
#  *  The function should not modify any KNITRO arguments.
#  *  Arguments "x" and "lambda" contain the solution from the node solve.
#  *  Arguments "obj" and "c" contain objective and constraint values at "x".
#  *  First and second derivative arguments are not currently defined and
#  *  should not be examined. 
#  */
# int  KNITRO_API KTR_set_mip_node_callback (KTR_context_ptr       kc,
#                                            KTR_callback * const  fnPtr);


# /** Type declaration for the callback that allows applications to 
#  *  specify an initial point before each local solve in the multistart
#  *  procedure.  On input, arguments "x" and "lambda" are the randomly
#  *  generated initial points determined by KNITRO, which can be overwritten
#  *  by the user.  The argument "nSolveNumber" is the number of the
#  *  multistart solve.  Return 0 if successful, a negative error code if not.
#  *  Use KTR_set_ms_initpt_callback to set this callback function.
#  */
# typedef int  KTR_ms_initpt_callback (const int             nSolveNumber,
#                                      const int             n,
#                                      const int             m,
#                                      const double * const  xLoBnds,
#                                      const double * const  xUpBnds,
#                                            double * const  x,
#                                            double * const  lambda,
#                                            void   * const  userParams);

# /** Return 0 if successful, a negative error code if not.
#  */
# int  KNITRO_API KTR_set_ms_initpt_callback (KTR_context_ptr                 kc,
#                                             KTR_ms_initpt_callback * const  fnPtr);

    
# /** Applications can set a "put string" callback function to handle output
#  *  generated by the KNITRO solver.  By default KNITRO prints to stdout
#  *  or a file named "knitro.log", as determined by KTR_PARAM_OUTMODE.
#  *  The KTR_puts function takes a "userParams" argument which is a
#  *  a pointer passed directly from KTR_solve.  Note that "userParams" will
#  *  be a NULL pointer until defined by an application call to KTR_new_puts
#  *  or KTR_solve. Return 0 if successful, a negative error code if not.
#  */    
# int  KNITRO_API KTR_set_puts_callback (KTR_context_ptr   kc,
#                                        KTR_puts * const  fnPtr);
