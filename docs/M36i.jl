# Model M36: Closed 2x2 Economy --  Taxes and Classical Unemployment
using Pkg
Pkg.add("JuMP")
Pkg.add("Ipopt")
Pkg.add("MPSGE")
using JuMP, Ipopt, MPSGE

#=

               Production Sectors          Consumers

   Markets   |    X       Y        W    |       CONS
   ------------------------------------------------------
        PX   |  100             -100    |
        PY   |          100     -100    |
        PW   |                   200    |       -200
        PL   |  -20     -60             |        100*(1-U)
        PK   |  -60     -40             |        100
        TAX  |  -20       0             |         20
   ------------------------------------------------------

=#

# Define sectors, commodities and factors

X   = [:X]
Y   = [:Y]
XY  = X ∪ Y
W   = [:W]
C   = [:CONS]
L   = [:L]
K   = [:K]
F   = L ∪ K
S   = XY ∪ W
SF  = S ∪ F

# Define I/O parameters

out0 = Dict(i => 0 for i ∈ XY ∪ W)
in0  = Dict((i, j) => 0 for i ∈ XY ∪ W ∪ F, j ∈ XY ∪ W)
end0 = Dict((i, j) => 0 for i ∈ F, j ∈ C)

# Assign I/O parameters

out0[:X] = 100
out0[:Y] = 100
out0[:W] = 200
in0[:L, :X] = 20
in0[:K, :X] = 60
in0[:L, :Y] = 60
in0[:K, :Y] = 40
in0[:X, :W] = 100
in0[:Y, :W] = 100
end0[:L, :CONS] = 100
end0[:K, :CONS] = 100

M36 = MPSGEModel()

@parameters(M36, begin
    TO[XY], 0
    TX[F], 0
    U0, 0.2
end)

@sectors(M36, begin
    D[S]
end)

@commodities(M36, begin
    P[SF]
end)

@consumers(M36, begin
    CONS[C]
end)

@auxiliaries(M36, begin
    U
end)

set_start_value(U, 0.2)
set_value!(TX[:L], 1)

for i ∈ X
    @production(M36, D[i], [t = 0, s = 1], begin
        @output(P[i], out0[i], t, taxes = [Tax(CONS[:CONS], TO[i])])
        @input(P[:L], in0[:L, i], s, taxes = [Tax(CONS[:CONS], TX[:L])], reference_price = 2)
        @input(P[:K], in0[:K, i], s, taxes = [Tax(CONS[:CONS], TX[:K])])
end)
end

for i ∈ Y
    @production(M36, D[i], [t = 0, s = 1], begin
        @output(P[i], out0[i], t, taxes = [Tax(CONS[:CONS], TO[i])]) 
        [@input(P[f], in0[f, i], s) for f ∈ F]...   
    end)
end

for i ∈ W
    @production(M36, D[i], [t = 0, s = 1], begin
        @output(P[i], out0[i], t)
        [@input(P[j], in0[j, i], s) for j ∈ XY]...
    end)
end

for i ∈ C
    @demand(M36, CONS[i], begin
        [@final_demand(P[w], out0[w]) for w ∈ W]...
        @endowment(P[:L], 80/(1-U0))
        @endowment(P[:L], -80/(1-U0)*U)   
        @endowment(P[:K], 100)
    end)
end

@aux_constraint(M36, U, begin
    P[:L] - P[:W]
end)

fix(P[:W], 1)

solve!(M36, cumulative_iteration_limit = 0)
benchmark = generate_report(M36)
println(benchmark)

set_value!(TX[:L], 0.25)
set_value!(TX[:K], 0.25)

solve!(M36, cumulative_iteration_limit = 2000)
simulation_01 = generate_report(M36)
println(simulation_01)

fix(U, 0.2)

solve!(M36, cumulative_iteration_limit = 2000)
simulation_02 = generate_report(M36)
println(simulation_02)

