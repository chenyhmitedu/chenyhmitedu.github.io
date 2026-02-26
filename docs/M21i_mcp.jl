# Model M21_MCP: two goods, two factors, one household

using Pkg
Pkg.add("JuMP")                             # Julia for Mathematical Programming
Pkg.add("Complementarity")                  # A package for modeling complementarity constraints and problems especially MCPs
Pkg.add("PATHSolver")                       # A solver interface for the PATH algorithm designed to solve MCPs
using JuMP, Complementarity, PATHSolver

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
shr0    = Dict((row, col) => 0.0 for row ∈ F ∪ S, col ∈ S)

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

shr0[:L, :X]    = in0[:L, :X] / out0[:X] 
shr0[:K, :X]    = in0[:K, :X] / out0[:X] 
shr0[:L, :Y]    = in0[:L, :Y] / out0[:Y] 
shr0[:K, :Y]    = in0[:K, :Y] / out0[:Y] 
shr0[:X, :W]    = in0[:X, :W] / out0[:W] 
shr0[:Y, :W]    = in0[:Y, :W] / out0[:W] 
shr0[:L, :W]    = 0
shr0[:K, :W]    = 0

TO      = Dict(i => 0.0 for i ∈ I)
GE      = Dict(i => 1.0 for i ∈ F)      

function solve_M21_MCP(; T::Dict{Symbol, Float64}, G::Dict{Symbol, Float64})
    M21 = MCPModel()
    
    # Define variables via JuMP macro

    @variables(M21, begin
        D[I] >= 0
        P[A] >= 0
        CONS >= 0   
    end)

    # Define mapping (residual function)
   
    @mapping(M21, PRF[i ∈ I], out0[i] * prod(P[f]^shr0[f, i] for f ∈ F ∪ S)*(1+T[i]) - out0[i] * P[i])
    @mapping(M21, MKT_S[i ∈ S], out0[i] * D[i] - in0[i, :W] * D[:W] * prod(P[i]^shr0[i, :W] for i ∈ S) / P[i])
    @mapping(M21, MKT_W[i ∈ W], out0[i] * D[i] - CONS / P[i])
    @mapping(M21, MKT_F[f ∈ F], end0[f] * G[f] - sum(in0[f, i] * D[i] * prod(P[h]^shr0[h, i] for h ∈ F) / P[f] for i ∈ S))
    @mapping(M21, I_CONS, CONS - sum(end0[f]*G[f]*P[f] for f ∈ F) - sum(T[i]*out0[i]*D[i] *prod(P[f]^shr0[f, i] for f ∈ F) for i ∈ S))

    # Add complementarity constraints

    @complementarity(M21, PRF[I], D[I])
    @complementarity(M21, MKT_S[S], P[S])
    @complementarity(M21, MKT_W[W], P[W])
    @complementarity(M21, MKT_F[F], P[F])
    @complementarity(M21, I_CONS, CONS)

    # Fix numeraire: P[:W] = 1 (replace MKT_W ⟂ P[:W])

    fix(P[:W], 1.0; force = true)

    # Provide reasonable start values (helps PATH avoid the trivial corner)

    for v in (D[:X], D[:Y], D[:W], P[:X], P[:Y], P[:W], P[:L], P[:K])
        set_start_value(v, 1.0)
    end
    set_start_value(CONS, 200)

    # Solve

    status = solveMCP(M21)

    results = Dict(
        "status" => status,
        "X" => result_value(D[:X]),
        "Y" => result_value(D[:Y]),
        "W" => result_value(D[:W]),
        "PX" => result_value(P[:X]),
        "PY" => result_value(P[:Y]),
        "PW" => result_value(P[:W]),
        "PL" => result_value(P[:L]),
        "PK" => result_value(P[:K]),
        "CONS" => result_value(CONS)
    )
    return results
end

# Benchmark

TO[:X] = 0.0
GE[:L] = 1.0
benchmark = solve_M21_MCP(T=TO, G=GE)
println("=== Benchmark ===")
for (k, v) in benchmark
    println(rpad(k, 8), ": ", v)
end

# Counterfactual: Simulation01

TO[:X] = 0.5
GE[:L] = 1.0
simulation01 = solve_M21_MCP(T=TO, G=GE)
println("=== Simulation 01: TX = 0.5 ===")
for (k, v) in simulation01
    println(rpad(k, 8), ": ", v)            # The total width of k and space before : is 8 characters
end

# Counterfactual: Simulation02

TO[:X] = 0.0
GE[:L] = 2.0
simulation02 = solve_M21_MCP(T=TO, G=GE)
println("=== Simulation 02: LENDOW = 2 ===")
for (k, v) in simulation02
    println(rpad(k, 8), ": ", v)
end