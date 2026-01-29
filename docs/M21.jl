# Model M21: Closed 2x2 Economy --  An Introduction to the Basics

using Pkg
Pkg.add("JuMP")
Pkg.add("Ipopt")
Pkg.add("MPSGE")
using JuMP, Ipopt, MPSGE

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

M21 = MPSGEModel()

@parameters(M21, begin
    TX, 0
    LENDOW, 1
end)

@sectors(M21, begin
    X
    Y
    W
end)

@commodities(M21, begin
    PX
    PY
    PW
    PL
    PK    
end)

@consumer(M21, CONS)

@production(M21, X, [s=1,t=0], begin
    @output(PX, 100, t)
    @input(PL, 25, s, taxes = [Tax(CONS, TX)])
    @input(PK, 75, s, taxes = [Tax(CONS, TX)])
end)  

@production(M21, Y, [s=1,t=0], begin
    @output(PY, 100, t)
    @input(PL, 75, s)
    @input(PK, 25, s)
end)

@production(M21, W, [s=1,t=0], begin
    @output(PW, 200, t)
    @input(PX, 100, s)
    @input(PY, 100, s)
end)

@demand(M21, CONS, begin
    @final_demand(PW, 200)
    @endowment(PK, 100)
    @endowment(PL, 100*LENDOW)
end)

fix(PW, 1)

solve!(M21, cumulative_iteration_limit=0)

#       Solve the counterfactuals

set_value!(TX, .5)
set_value!(LENDOW, 1)
solve!(M21)
change_TX = generate_report(M21)

set_value!(LENDOW, 2)
set_value!(TX, 0)
solve!(M21, cumulative_iternation_limit=1000)
change_LENDOW = generate_report(M21)