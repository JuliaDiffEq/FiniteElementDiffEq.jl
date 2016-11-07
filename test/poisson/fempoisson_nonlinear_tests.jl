######
##FEM Poisson Nonlinear Tests
######
using FiniteElementDiffEq

dx = 1//2^(3)
fem_mesh = notime_squaremesh([0 1 0 1],dx,:neumann)
prob = prob_poisson_birthdeath

sol = solve(fem_mesh::FEMmesh,prob::PoissonProblem)

TEST_PLOT && plot(sol,plot_analytic=false,zlim=(0,2))

#Returns true if computed solution is homogenous near 2
maximum(abs.(sol.u - 2))< 1e-9
