using Knitro

#    min  9 - 8x1 - 6x2 - 4x3
#         + 2(x1^2) + 2(x2^2) + (x3^2) + 2(x1*x2) + 2(x1*x3)
#    subject to  c[0]:  x1 + x2 + 2x3 <= 3
#                x1 >= 0
#                x2 >= 0
#                x3 >= 0
#    initpt (0.5, 0.5, 0.5)
#
#    Solution is x1=4/3, x2=7/9, x3=4/9, lambda=2/9  (f* = 1/9)
#
#  The problem comes from Hock and Schittkowski, HS35.

function evaluate_fc(evalRequestCode::Cint,
                     n::Cint,
                     m::Cint,
                     nnzJ::Cint,
                     nnzH::Cint,
                     x_::Ptr{Cdouble},
                     lambda_::Ptr{Cdouble},
                     obj_::Ptr{Cdouble},
                     c_::Ptr{Cdouble},
                     g_::Ptr{Cdouble},
                     J_::Ptr{Cdouble},
                     H_::Ptr{Cdouble},
                     HV_::Ptr{Cdouble},
                     userParams_::Ptr{Void})
  if evalRequestCode != KTR_RC_EVALFC
    return KTR_RC_CALLBACK_ERR
  end
  x = pointer_to_array(x_,n,false)::Vector{Float64}

  linear_terms = 9.0 - 8.0*x[1] - 6.0*x[2] - 4.0*x[3]
  quad_terms = 2.0*x[1]*x[1] + 2.0*x[2]*x[2] + x[3]*x[3]
  quad_terms2 = 2.0*x[1]*x[2] + 2.0*x[1]*x[3]
  obj_value = linear_terms + quad_terms + quad_terms2
  cons = x[1] + x[2] + 2.0 * x[3]

  unsafe_store!(obj_::Ptr{Cdouble}, obj_value::Cdouble)
  unsafe_store!(c_::Ptr{Cdouble}, cons::Cdouble, 1)

  int32(0)::Int32
end

function evaluate_ga(evalRequestCode::Cint,
                     n::Cint,
                     m::Cint,
                     nnzJ::Cint,
                     nnzH::Cint,
                     x_::Ptr{Cdouble},
                     lambda_::Ptr{Cdouble},
                     obj_::Ptr{Cdouble},
                     c_::Ptr{Cdouble},
                     g_::Ptr{Cdouble},
                     J_::Ptr{Cdouble},
                     H_::Ptr{Cdouble},
                     HV_::Ptr{Cdouble},
                     userParams_::Ptr{Void})
  if evalRequestCode != KTR_RC_EVALGA
    return KTR_RC_CALLBACK_ERR
  end
  x = pointer_to_array(x_,n,false)::Vector{Float64}

  g0 = -8.0 + 4.0*x[1] + 2.0*x[2] + 2.0*x[3]
  g1 = -6.0 + 2.0*x[1] + 4.0*x[2]
  g2 = -4.0 + 2.0*x[1] + 2.0*x[3]
  j0 = 1.0; j1 = 1.0; j2 = 2.0

  unsafe_store!(g_::Ptr{Cdouble}, g0::Cdouble, 1)
  unsafe_store!(g_::Ptr{Cdouble}, g1::Cdouble, 2)
  unsafe_store!(g_::Ptr{Cdouble}, g2::Cdouble, 3)
  unsafe_store!(J_::Ptr{Cdouble}, j0::Cdouble, 1)
  unsafe_store!(J_::Ptr{Cdouble}, j1::Cdouble, 2)
  unsafe_store!(J_::Ptr{Cdouble}, j2::Cdouble, 3)
  
  int32(0)::Int32
end

function evaluate_hess(evalRequestCode::Cint,
                       n::Cint,
                       m::Cint,
                       nnzJ::Cint,
                       nnzH::Cint,
                       x_::Ptr{Cdouble},
                       lambda_::Ptr{Cdouble},
                       obj_::Ptr{Cdouble},
                       c_::Ptr{Cdouble},
                       g_::Ptr{Cdouble},
                       J_::Ptr{Cdouble},
                       H_::Ptr{Cdouble},
                       HV_::Ptr{Cdouble},
                       userParams_::Ptr{Void})
  if evalRequestCode == KTR_RC_EVALH
    unsafe_store!(H_::Ptr{Cdouble}, 4.0::Cdouble, 1)
    unsafe_store!(H_::Ptr{Cdouble}, 2.0::Cdouble, 2)
    unsafe_store!(H_::Ptr{Cdouble}, 2.0::Cdouble, 3)
    unsafe_store!(H_::Ptr{Cdouble}, 4.0::Cdouble, 4)
    unsafe_store!(H_::Ptr{Cdouble}, 2.0::Cdouble, 5)
    return int32(0)::Int32
  elseif evalRequestCode == KTR_RC_EVALH_NO_F
    unsafe_store!(H_::Ptr{Cdouble}, 0.0::Cdouble, 1)
    unsafe_store!(H_::Ptr{Cdouble}, 0.0::Cdouble, 2)
    unsafe_store!(H_::Ptr{Cdouble}, 0.0::Cdouble, 3)
    unsafe_store!(H_::Ptr{Cdouble}, 0.0::Cdouble, 4)
    unsafe_store!(H_::Ptr{Cdouble}, 0.0::Cdouble, 5)
    return int32(0)::Int32
  elseif evalRequestCode == KTR_RC_EVALHV
    HV = pointer_to_array(HV_,3,false)::Vector{Float64}
    hv0 = 4.0*HV[1] + 2.0*HV[2] + 2.0*HV[3]
    hv1 = 2.0*HV[1] + 4.0*HV[2]
    hv2 = 2.0*HV[1] + 2.0*HV[3]
    unsafe_store!(HV_::Ptr{Cdouble}, hv0::Cdouble, 1)
    unsafe_store!(HV_::Ptr{Cdouble}, hv1::Cdouble, 2)
    unsafe_store!(HV_::Ptr{Cdouble}, hv2::Cdouble, 3)
    return int32(0)::Int32
  elseif evalRequestCode == KTR_RC_EVALHV_NO_F
    unsafe_store!(HV_::Ptr{Cdouble}, 0.0::Cdouble, 1)
    unsafe_store!(HV_::Ptr{Cdouble}, 0.0::Cdouble, 2)
    unsafe_store!(HV_::Ptr{Cdouble}, 0.0::Cdouble, 3)
    return int32(0)::Int32
  else
    return KTR_RC_CALLBACK_ERR
  end
end

objGoal = KTR_OBJGOAL_MINIMIZE
objType = KTR_OBJTYPE_QUADRATIC

n = 3
x_L = zeros(n)
x_U = [KTR_INFBOUND,KTR_INFBOUND,KTR_INFBOUND]

m = 1
c_Type = [KTR_CONTYPE_LINEAR]
c_L = [-KTR_INFBOUND]
c_U = [3.0]

jac_con = Int32[0,0,0]
jac_var = Int32[0,1,2]
hess_row = Int32[0,0,0,1,2]
hess_col = Int32[0,1,2,1,2]

x0 = [0.5,0.5,0.5]
lambda0 = zeros(n+m)

kc = newcontext()
loadparamfile(kc,"knitro.opt")
ret = initialize_problem(kc, objGoal, objType,
                         x_L, x_U,
                         c_Type, c_L, c_U,
                         jac_var, jac_con,
                         hess_row, hess_col,
                         initial_x=x0,
                         initial_lambda=lambda0)

set_func_callback(kc,evaluate_fc)
set_grad_callback(kc,evaluate_ga)
set_hess_callback(kc,evaluate_hess)

x       = [0.5,0.5,0.5]
lambda  = zeros(m + n)
obj     = [0.0]
nStatus = solve_problem(kc, x, lambda, int32(0), obj)
print(nStatus)
