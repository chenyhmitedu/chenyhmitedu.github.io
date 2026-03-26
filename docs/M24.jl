# Model M24: Closed Economy 2x2 with Specific Factors

using Pkg
Pkg.add("JuMP")
Pkg.add("Ipopt")
Pkg.add("MPSGE")
using JuMP, Ipopt, MPSGE

#=
Here is the initial data matrix for example M21 (also M1_MPS).  As noted
in the text description, it is technically useful to interpret a portion
of capital in each sector as sector specific.  Or it can in fact be a 
separate factor such as land or resources.

                  Production Sectors          Consumers
   Markets   |    X       Y        W    |       CONS
   ------------------------------------------------------
        PX   |  100             -100    |
        PY   |          100     -100    |
        PW   |                   200    |       -200
        PL   |  -25     -75             |        100
        PK   |  -75     -25             |        100
   ------------------------------------------------------

Designate part of the capital in each sector as fixed in that sector

                   Production Sectors          Consumers
    Markets   |    X       Y        W    |       CONS
    ------------------------------------------------------
         PX   |  100             -100    |
         PY   |          100     -100    |
         PW   |                   200    |       -200
         PL   |  -25     -75             |        100
         PK   |  -50     -15             |         65
         PKX  |  -25                     |         25
         PKY  |          -10             |         10
    ------------------------------------------------------
=#


M24 = MPSGEModel()

@parameters(M24, begin
    TX, 0
end)

@sectors(M24, begin
    X
    Y
    W
end)

@commodities(M24, begin
    PX
    PY
    PW
    PL
    PK
    PKX
    PKY
end)

@consumer(M24, CONS)

@production(M24, X, [s = 1, t = 0], begin
    @output(PX, 100, t)
    @input(PL, 25, s, taxes = [Tax(CONS, TX)])
    @input(PK, 50, s, taxes = [Tax(CONS, TX)])
    @input(PKX, 25, s, taxes = [Tax(CONS, TX)])
end)

@production(M24, Y, [s = 1, t = 0], begin
    @output(PY, 100, t)
    @input(PL, 75, s)
    @input(PK, 15, s)
    @input(PKY, 10, s)
end)

@production(M24, W, [s = 1, t = 0], begin
    @output(PW, 200, t)
    @input(PX, 100, s)
    @input(PY, 100, s)
end)

@demand(M24, CONS, begin
    @final_demand(PW, 200)
    @endowment(PL, 100)
    @endowment(PK, 65)
    @endowment(PKX, 25)
    @endowment(PKY, 10)
end)

fix(PW, 1)
set_value!(TX, 0)
solve!(M24, cumulative_iteration_limit = 0)

# Solve a counterfactual
set_value!(TX, 0.5)
solve!(M24, cumulative_iteration_limit = 1000)
homogeneous_input_tax_simulation = generate_report(M24)
println(homogeneous_input_tax_simulation)