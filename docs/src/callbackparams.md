The following internal documentation is meant for advanced users.

### Typical Callbacks
For simplicity, the following callback functions (defined in `ktr_callbacks.jl`)

- `set_func_callback`
- `set_grad_callback`
- `set_hess_callback`
- `set_newpoint_callback` (not yet available)
- `set_ms_process_callback` (not yet available)
- `set_mip_node_callback`

all use the same `KTR_callback()` function prototype defined below.

```
typedef int KTR_callback (const int             evalRequestCode,
                          const int             n,
                          const int             m,
                          const int             nnzJ,
                          const int             nnzH,
                          const double * const  x,
                          const double * const  lambda,
                                double * const  obj,
                                double * const  c,
                                double * const  objGrad,
                                double * const  jac,
                                double * const  hessian,
                                double * const  hessVector,
                                void   *        userParams);
```

### New Point Callbacks
Type declaration for the callback function that is invoked after Artelys Knitro computes a new estimate of the solution point (i.e., after every major iteration).

The function should not modify any Artelys Knitro arguments.
- `kc` is the context pointer for the current problem being solved inside Artelys Knitro (either the main single-solve problem, or a subproblem when using multi-start, Tuner, etc.).
- `x` and `lambda` contain the new point and values.
- `obj` and `c` contain objective and constraint values at `x`, and
- `objGrad` and `jac` contain the objective gradient and constraint Jacobian at `x`.
 
```
typedef int  KTR_newpt_callback (KTR_context_ptr           kc,
                                 const int             n,
                                 const int             m,
                                 const int             nnzJ,
                                 const double * const  x,
                                 const double * const  lambda,
                                 const double          obj,
                                 const double * const  c,
                                 const double * const  objGrad,
                                 const double * const  jac,
                                       void   *        userParams);
```

### Multi-Start Initial Point Callback
Type declaration for the callback that allows applications to specify an initial point before each local solve in the multistart procedure.  On input, arguments "x" and "lambda" are the randomly generated initial points determined by Artelys Knitro, which can be overwritten by the user.  

The argument `nSolveNumber` is the number of the multistart solve.  Return 0 if successful, a negative error code if not. Use `set_ms_initpt_callback` to set this callback function.

```
typedef int  KTR_ms_initpt_callback (const int             nSolveNumber,
                                     const int             n,
                                     const int             m,
                                     const double * const  xLoBnds,
                                     const double * const  xUpBnds,
                                           double * const  x,
                                           double * const  lambda,
                                           void   * const  userParams);
```

### Put String Callback
Type declaration for the callback that allows applications to handle output. The function should return the number of characters that were printed.

```
typedef int  KTR_puts (const char * const  str,
                             void * const  userParams);
```
