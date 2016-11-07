######
##FEM Poisson Nonlinear System Tests
######
using FiniteElementDiffEq

dx = 1//2^(1)
fem_mesh = notime_squaremesh([0 1 0 1],dx,:neumann)
prob = prob_poisson_birthdeathsystem

sol = solve(fem_mesh::FEMmesh,prob::PoissonProblem)

TEST_PLOT && plot(sol,plot_analytic=false,zlim=(0,2))

#Returns true if computed solution is homogenous near 2
bool1 = maximum(abs.(sol.u .- [2 1]))< 1e-8

### Harder system

prob = prob_poisson_birthdeathinteractingsystem

sol = solve(fem_mesh::FEMmesh,prob::PoissonProblem)

TEST_PLOT && plot(sol,plot_analytic=false,zlim=(0,2),cbar=false)

bool2 = maximum(abs.(sol.u .- [2 1]))< 1e-8

bool1 && bool2
