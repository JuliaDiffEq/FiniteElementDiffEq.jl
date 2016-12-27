######
##FEM Stochastic Poisson Method Tests
######
using FiniteElementDiffEq

prob = prob_poisson_noisywave

sol = solve(prob)#,solver=:CG) #TODO Fix CG and switch back

TEST_PLOT && plot(sol,title=["True Deterministic Solution" "Stochastic Solution"],plot_analytic=true)
#This condition should be true with really high probability
var(sol.u) < 8e-4
