"""
`HeatProblem`

Wraps the data that define a 2D heat equation problem:

```math
u_t = Δu + f
```

with bounday conditions `gD` on the dirichlet boundary and gN on the neumann boundary.
Linearity is determined by whether the forcing function `f` is a function of two
variables `(t,x)` or three `(t,x,u)` (with `x=[:,1]` and `y=[:,2]`).

If they keyword `σ` is given, then this wraps the data that define a 2D stochastic heat equation

```math
u_t = Δu + f + σdW_t
```

### Constructors

* `HeatProblem(analytic,Du,f)`: Defines the dirichlet problem with solution `analytic`,
  solution gradient `Du = [u_x,u_y]`, and the forcing function `f`.

* `HeatProblem(u₀,f)`: Defines the problem with initial value `u₀` (as a function) and `f`.
  If your initial data is a vector, wrap it as `u₀(x) = vector`.

Note: If all functions are of `(t,x)`, then the program assumes it's linear. Write
your functions using the math to program syntrax translation: ``x`` `= x[:,1]` and ``y`` `= x[:,2]`.
Use `f=f(t,x,u)` and `σ=σ(t,x,u)` (if specified) for nonlinear problems
(with the boundary conditions still (t,x)). Systems of equations can be specified
with `u_i = u[:,i]` as the ith variable. See the example problems for more help.

### Keyword Arguments

* `gD` = dirichlet boundary function

* `gN` = neumann boundary function

* `σ` = The function which multiplies the noise dW. By default `σ=0`.

* `noisetype` = A string which specifies the type of noise to be generated. By default
  `noisetype=:White` for Gaussian Spacetime White Noise.

* `numvars` = Number of variables in the system. Automatically calculated from u₀ in most cases.

* `D` = Array which defines the diffusion coefficients. Default is `D=ones(1,numvars)`.
"""
type HeatProblem <: AbstractHeatProblem
  "u₀: Initial value function"
  u₀#::Function
  "Du: Function for the solution gradient [u_x,u_y]"
  Du::Function
  "f: Forcing function in heat equation"
  f::Function
  "gD: dirichlet boundary data"
  gD#::Function
  "gN: neumann boundary data"
  gN#::Function
  "analytic: Solution to the heat problem"
  analytic::Function
  "knownanalytic: Boolean which states whether the solution function is given"
  knownanalytic::Bool
  "islinear: Boolean which states whether the problem is linear or nonlinear"
  islinear::Bool
  numvars::Int
  σ::Function
  stochastic::Bool
  noisetype::Symbol
  D#AbstractArray
  function HeatProblem(analytic,Du,f;gN=nothing,σ=nothing,noisetype=:White,numvars=nothing,D=nothing)
    islinear = numparameters(f)==2
    knownanalytic = true
    u₀(x) = analytic(0,x)
    numvars = size(u₀([0 0
                       0 0
                       0 0]),2)
    gD = analytic
    if gN == nothing
      gN=(t,x)->zeros(size(x,1),numvars)
    end
    if σ==nothing
      stochastic=false
      σ=(t,x)->zeros(size(x,1),numvars)
    else
      stochastic=true
    end
    if D == nothing
      if numvars == 1
        D = 1.0
      else
        D = ones(1,numvars)
      end
    end
    return(new(u₀,Du,f,gD,gN,analytic,knownanalytic,islinear,numvars,σ,stochastic,noisetype,D))
  end
  function HeatProblem(u₀,f;gD=nothing,gN=nothing,σ=nothing,noisetype=:White,numvars=nothing,D=nothing)
    if σ==nothing
      stochastic=false
      σ=(t,x)->zeros(size(x,1))
    else
      stochastic=true
    end
    islinear = numparameters(f)==2
    knownanalytic = false
    if islinear
      if u₀==nothing
        u₀=(x)->zeros(size(x,1))
      end
      if gD == nothing
        gD=(t,x)->zeros(size(x,1))
      end
      if gN == nothing
        gN=(t,x)->zeros(size(x,1))
      end
      if D == nothing
        D = 1.0
      end
      numvars = 1
    end
    if !islinear #nonlinear
      if u₀==nothing && numvars == nothing
        warn("u₀ and numvars must be given. numvars assumed 1.")
        numvars = 1
        u₀=(x)->zeros(size(x,1),numvars)
        if gD == nothing
          gD=(t,x)->zeros(size(x,1),numvars)
        end
        if gN == nothing
          gN=(t,x)->zeros(size(x,1),numvars)
        end
        if D == nothing
          D = 1.0
        end
      elseif u₀==nothing #numvars!=nothing
        u₀=(x)->zeros(size(x,1),numvars) #Default to zero
        if gD == nothing
          gD=(t,x)->zeros(size(x,1),numvars)
        end
        if gN == nothing
          gN=(t,x)->zeros(size(x,1),numvars)
        end
        if D == nothing
          D = ones(1,numvars)
        end
      elseif numvars==nothing #If u₀ is given but numvars is not, we're still okay. Generate from size in function.
        numvars=0 #Placeholder, update gD and gN in solver
      end
    end
    return(new(u₀,(x)->0,f,gD,gN,(x)->0,knownanalytic,islinear,numvars,σ,stochastic,noisetype,D))
  end
end

doc"""
`PoissonProblem`

Wraps the data that define a 2D linear Poisson equation problem:

```math
-Δu = f
```

with bounday conditions `gD` on the dirichlet boundary and gN on the neumann boundary.
Linearity is determined by whether the forcing function `f` is a function of one
variable `(x)` or two `(u,x)` (with `x=[:,1]` and `y=[:,2]`).

If they keyword `σ` is given, then this wraps the data that define a 2D stochastic heat equation

```math
-Δu = f + σdW
```

### Constructors

`PoissonProblem(f,analytic,Du)`: Defines the dirichlet problem with analytical solution `analytic`, solution gradient `Du = [u_x,u_y]`,
and forcing function `f`

`PoissonProblem(u₀,f)`: Defines the problem with initial value `u₀` (as a function) and f.
If your initial data is a vector, wrap it as `u₀(x) = vector`.

Note: If all functions are of `(x)`, then the program assumes it's linear. Write
your functions using the math to program syntrax translation: ``x`` `= x[:,1]` and ``y`` `= x[:,2]`.
Use `f=f(u,x)` and `σ=σ(u,x)` (if specified) for nonlinear problems
(with the boundary conditions still (x)). Systems of equations can be specified
with `u_i = u[:,i]` as the ith variable. See the example problems for more help.

### Keyword Arguments

* `gD` = dirichlet boundary function

* `gN` = neumann boundary function

* `σ` = The function which multiplies the noise ``dW``. By default `σ=0`.

* `noisetype` = A string which specifies the type of noise to be generated. By default
  `noisetype=:White` for Gaussian Spacetime White Noise.

* `numvars` = The number of variables in the Poisson system. Automatically calculated in many cases.

* `D` = Vector of diffusion coefficients. Defaults is `D=ones(1,numvars)`.

"""
type PoissonProblem <: AbstractPoissonProblem
  "f: Forcing function in the Poisson problem"
  f#::Function
  "analytic: Solution to the Poisson problem"
  analytic::Function
  "Du: Gradient of the solution to the Poisson problem"
  Du::Function
  "gD: dirichlet Boundary Data"
  gD#::Nullable{Function}
  "gN: neumann Boundary Data"
  gN#::Nullable{Function}
  "knownanalytic: Boolean which states whether the solution function is given"
  knownanalytic::Bool
  "islinear: Boolean which states whether the problem is linear or nonlinear"
  islinear::Bool
  u₀::Function
  numvars::Int
  σ::Function
  stochastic::Bool
  noisetype::Symbol
  D#::AbstractArray
  function PoissonProblem(f,analytic,Du;gN=nothing,σ=nothing,u₀=nothing,noisetype=:White,numvars=nothing,D=nothing)
    gD = analytic
    numvars = size(analytic([0 0
                        0 0
                        0 0]),2)
    islinear = numparameters(f)==1
    if gN == nothing
      gN=(x)->zeros(size(x,1),numvars)
    end
    if u₀==nothing
      u₀=(x)->zeros(size(x,1),numvars)
    end
    if D == nothing
      if numvars == 1
        D = 1.0
      else
        D = ones(1,numvars)
      end
    end
    if σ==nothing
      stochastic=false
      σ=(x)->zeros(size(x,1),numvars)
    else
      stochastic=true
    end
    return(new(f,analytic,Du,analytic,gN,true,islinear,u₀,numvars,σ,stochastic,noisetype,D))
  end
  function PoissonProblem(f;gD=nothing,gN=nothing,u₀=nothing,σ=nothing,noisetype=:White,numvars=nothing,D=nothing)
    if σ==nothing
      stochastic=false
      σ=(x)->zeros(size(x,1))
    else
      stochastic = true
    end
    islinear = numparameters(f)==1
    if islinear && u₀==nothing
      u₀=(x)->zeros(size(x,1))
      if gD == nothing
        gD=(x)->zeros(size(x,1))
      end
      if gN == nothing
        gN=(x)->zeros(size(x,1))
      end
      if D == nothing
        D = 1.0
      end
      numvars = 1
    end
    if !islinear #nonlinear
      if u₀==nothing && numvars == nothing
        warn("u₀ and numvars must be given. numvars assumed 1.")
        numvars = 1
        u₀=(x)->zeros(size(x,1))
        if gD == nothing
          gD=(x)->zeros(size(x,1))
        end
        if gN == nothing
          gN=(x)->zeros(size(x,1))
        end
        if D == nothing
          D = 1.0
        end
      elseif u₀==nothing #numvars!=nothing
        u₀=(x)->zeros(size(x,1),numvars) #Default to zero
        if gD == nothing
          gD=(x)->zeros(size(x,1),numvars)
        end
        if gN == nothing
          gN=(x)->zeros(size(x,1),numvars)
        end
        if D == nothing
          D = ones(1,numvars)
        end
      elseif numvars==nothing #If u₀ is given but numvars is not, we're still okay. Generate from size in function.
        numvars=0 #Placeholder, update gD and gN in solver
      end
    end
    return(new(f,(x)->0,(x)->0,gD,gN,false,islinear,u₀,numvars,σ,stochastic,noisetype,D))
  end
end
