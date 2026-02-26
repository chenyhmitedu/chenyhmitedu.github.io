# Model M21: Closed 2x2 Economy --  An Introduction to the Basics

using Pkg
Pkg.add("JuMP")
Pkg.add("MPSGE")            # Will automatically install PATHSolver since PATHSolver is a dependency of MPSGE
using JuMP, MPSGE

#= 
Production Sectors          Consumers
Markets  |    X       Y        W    |       CONS
------------------------------------------------------
    PX   |  100             -100    |
    PY   |          100     -100    |
    PW   |                   200    |       -200
    PL   |  -25     -75             |        100
    PK   |  -75     -25             |        100
------------------------------------------------------
=#

# Define sectors and factors

S = [:X, :Y]
W = [:W]
F = [:L, :K]
I = S ∪ W
A = I ∪ F

# Data

out0    = Dict(row => 0 for row ∈ I)
in0     = Dict((row, col) => 0 for row ∈ F ∪ S, col ∈ S)
end0    = Dict(row => 0 for row ∈ F) 

out0[:X]        = 100
out0[:Y]        = 100
out0[:W]        = 200

in0[:L, :X]     = 25
in0[:K, :X]     = 75
in0[:L, :Y]     = 75
in0[:K, :Y]     = 25
in0[:X, :W]     = 100
in0[:Y, :W]     = 100
end0[:L]        = 100
end0[:K]        = 100

M21 = MPSGEModel()

@parameters(M21, begin
    TO[S], 0               # Tax rate on X sector's inputs
    GE[F], 1               # Scale factor for labor endowment
end)

@sectors(M21, begin
    D[I]
end)

@commodities(M21, begin
    P[A]   
end)

@consumer(M21, CONS)

for i ∈ S
    @production(M21, D[i], [s=1,t=0], begin
        @output(P[i], out0[i], t)
        [@input(P[f], in0[f, i], s, taxes = [Tax(CONS, TO[i])]) for f ∈ F]
    end)  
end

for i ∈ W
    @production(M21, D[i], [s=1,t=0], begin
        @output(P[i], out0[i], t)
        [@input(P[j], in0[j, i], s) for j ∈ S]
    end)
end

@demand(M21, CONS, begin
    [@final_demand(P[i], out0[i]) for i ∈ W]
    [@endowment(P[f], end0[f]*GE[f]) for f ∈ F]
end)

fix(P[:W], 1)

solve!(M21, cumulative_iteration_limit=0)

#       Solve the counterfactuals

set_value!(TO[:X], .5)
set_value!(GE[:L], 1)
solve!(M21)
change_TX = generate_report(M21)

set_value!(GE[:L], 2)
set_value!(TO[:X], 0)
solve!(M21, cumulative_iternation_limit=1000)
change_LENDOW = generate_report(M21)