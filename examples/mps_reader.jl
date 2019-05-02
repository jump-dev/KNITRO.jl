#*******************************************************/
#* Copyright(c) 2019 by Artelys                        */
#* This source code is subject to the terms of the     */
#* MIT Expat License (see LICENSE.md)                  */
#*******************************************************/

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#  This example demonstrates how to load a MPS file with Knitro MPS
#  reader.
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


using KNITRO

# Absolute path to MPS file.
mps_file = joinpath(dirname(@__FILE__), "..", "examples", "lp.mps")

# Create a new Knitro solver instance.
kc = KNITRO.KN_new()

# Illustrate how to override default options by reading from
# the knitro.opt file.
options = joinpath(dirname(@__FILE__), "..", "examples", "knitro.opt")
KNITRO.KN_load_param_file(kc, options)

# Import MPS file inside Knitro.
err = KNITRO.KN_load_mps_file(kc, mps_file)

# Solve the problem.
# Return status codes are defined in "kn_defines.jl" and described
# in the Knitro manual.
nStatus = KNITRO.KN_solve(kc)

println("Knitro converged with final status = ", nStatus)

# An example of obtaining solution information.
nStatus, objSol, x, lambda_ =  KNITRO.KN_get_solution(kc)

# Delete the Knitro solver instance.
KNITRO.KN_free(kc)

@testset "Exemple lp1" begin
    @test nStatus == 0
    @test objSol ≈ 250 / 3 atol=1e-5
end
