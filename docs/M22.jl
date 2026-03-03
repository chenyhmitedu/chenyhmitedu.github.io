# Model M22: Closed Economy 2X2 with Intermediate Inputs and Nesting

using Pkg
Pkg.add("JuMP")
Pkg.add("Ipopt")
Pkg.add("MPSGE")
using JuMP, Ipopt, MPSGE

#=
Production Sectors          Consumers
Markets  |    X       Y        W    |       CONS
------------------------------------------------------
    PX   |  120     -20     -100    |
    PY   |  -20     120     -100    |
    PW   |                   200    |       -200
    PL   |  -40     -60             |        100
    PK   |  -60     -40             |        100
 ------------------------------------------------------
=#

M22 = MPSGEModel()

@parameters(M22, begin
    TX, 0
end)

@sectors(M22, begin
    X
    Y
    W
end)

@commodities(M22, begin
    PX
    PY
    PW
    PL
    PK    
end)

@consumer(M22, CONS)

@production(M22, X, [s = 0.5, t = 0, va => s = 1], begin
    @output(PX, 120, t)
    @input(PY, 20, s)
    @input(PL, 40, va, taxes = [Tax(CONS, TX)])
    @input(PK, 60, va, taxes = [Tax(CONS, TX)])
end)  

@production(M22, Y, [s = 0.75, t = 0, va => s = 1], begin
    @output(PY, 120, t)
    @input(PX, 20, s)
    @input(PL, 60, va)
    @input(PK, 40, va)
end)

@production(M22, W, [s = 1,t = 0], begin
    @output(PW, 200, t)
    @input(PX, 100, s)
    @input(PY, 100, s)
end)

@demand(M22, CONS, begin
    @final_demand(PW, 200)
    @endowment(PK, 100)
    @endowment(PL, 100)
end)

fix(PW, 1)

set_value!(TX, 0)
solve!(M22, cumulative_iteration_limit=0)
benchmark_calibration = generate_report(M22)

#       Solve the counterfactuals

set_value!(TX, 1)

solve!(M22)
change_TX = generate_report(M22)

