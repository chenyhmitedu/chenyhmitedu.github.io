# Model M21_MCP: two goods, two factors, one household

using Pkg
Pkg.add("JuMP")
Pkg.add("Complementarity")
Pkg.add("PATHSolver")
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

function solve_M21_MCP(; TX = 0, LENDOW = 1.0)
    M21 = MCPModel()
    
    # Define variables via JuMP macro
    @variable(M21, X >= 0)              # Activity level for sector X
    @variable(M21, Y >= 0)              # Activity level for sector Y
    @variable(M21, W >= 0)              # Activity level for sector W
    @variable(M21, PX >= 0)             # Price index for commodity X
    @variable(M21, PY >= 0)             # Price index for commodity Y
    @variable(M21, PL >= 0)             # Price index for primary factor L
    @variable(M21, PK >= 0)             # Price index for primary factor K
    @variable(M21, PW >= 0)             # Price index for welfare (expenditure function)
    @variable(M21, CONS >= 0)           # Income of the representative consumer

    # Declare parameters
    #TX      = 0
    #LENDOW  = 1

    # Define mapping (residual function)
    @mapping(M21, PRF_X, 100 * PL^0.25 * PK^0.75 * (1+TX) - 100*PX)
    @mapping(M21, PRF_Y, 100 * PL^0.75 * PK^0.25 - 100*PY)
    @mapping(M21, PRF_W, 200 * PX^0.50 * PY^0.50 - 200*PW)
    @mapping(M21, MKT_X, 100 * X - 100 * W * PX^0.5 * PY^0.5 / PX)
    @mapping(M21, MKT_Y, 100 * Y - 100 * W * PX^0.5 * PY^0.5 / PY)
    @mapping(M21, MKT_W, 200 * W - CONS / PW)
    @mapping(M21, MKT_L, 100 * LENDOW - 25 * X * PL^0.25 * PK^0.75 / PL - 75 * Y * PL^0.75 * PK^0.25 / PL)
    @mapping(M21, MKT_K, 100 - 75 * X * PL^0.25 * PK^0.75 / PK - 25 * Y * PL^0.75 * PK^0.25 / PK)
    @mapping(M21, I_CONS, CONS - 100*LENDOW*PL - 100*PK - TX*100*X*PL^0.25*PK^0.75)

    # Add complementarity constraints
    @complementarity(M21, PRF_X, X)
    @complementarity(M21, PRF_Y, Y)
    @complementarity(M21, PRF_W, W)
    @complementarity(M21, MKT_X, PX)
    @complementarity(M21, MKT_Y, PY)
    @complementarity(M21, MKT_W, PW)
    @complementarity(M21, MKT_L, PL)
    @complementarity(M21, MKT_K, PK)
    @complementarity(M21, I_CONS, CONS)

    # Fix numeraire: PW = 1 (replace MKT_W ⟂ PW)
    fix(PW, 1.0; force = true)

    # Provide reasonable start values (helps PATH avoid the trivial corner)
    for v in (X, Y, W, PX, PY, PW, PL, PK)
        set_start_value(v, 1.0)
    end
    set_start_value(CONS, 200)

    # Solve
    status = solveMCP(M21)

    results = Dict(
        "status" => status,
        "X" => result_value(X),
        "Y" => result_value(Y),
        "W" => result_value(W),
        "PX" => result_value(PX),
        "PY" => result_value(PY),
        "PW" => result_value(PW),
        "PL" => result_value(PL),
        "PK" => result_value(PK),
        "CONS" => result_value(CONS)
    )
    return results
end

# Benchmark
benchmark = solve_M21_MCP(TX = 0)
println("=== Benchmark ===")
for (k, v) in benchmark
    println(rpad(k, 8), ": ", v)
end

# Counterfactual: Simulation01
simulation01 = solve_M21_MCP(TX = 0.5)
println("=== Simulation 01: TX = 0.5 ===")
for (k, v) in simulation01
    println(rpad(k, 8), ": ", v)
end

# Counterfactual: Simulation02
simulation02 = solve_M21_MCP(LENDOW = 2)
println("=== Simulation 02: LENDOW = 2 ===")
for (k, v) in simulation02
    println(rpad(k, 8), ": ", v)
end