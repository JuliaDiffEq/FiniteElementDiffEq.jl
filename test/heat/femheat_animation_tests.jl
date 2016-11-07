#######
##FEM Heat Animation Test
#######

#Generates an animation for a solution of the heat equation
#Uses Plots.jl, requires matplotlib >=1.5
using FiniteElementDiffEq, DiffEqProblemLibrary#, Plots, ImageMagick
T = 2
dx = 1//2^(3)
dt = 1//2^(9)
fem_mesh = parabolic_squaremesh([0 1 0 1],dx,dt,T,:dirichlet)
prob = prob_femheat_moving

sol = solve(fem_mesh::FEMmesh,prob::HeatProblem,alg=:Euler,save_timeseries=true)
println("Generating Animation")
TEST_PLOT && animate(sol::FEMSolution,"test_animation.gif";zlims=(0,.1),cbar=false)

## Should have moved off the frame.
maximum(sol.u) .< 1e-6
