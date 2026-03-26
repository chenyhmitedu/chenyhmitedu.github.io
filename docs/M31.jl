# Model M31.GMS: Closed 2x2 Economy - Calibrating to a Existing Tax

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
        PL   |  -20     -60             |         80
        PK   |  -60     -40             |        100
        TAX  |  -20       0             |         20
   ------------------------------------------------------
=#

M31 = MPSGEModel()

@parameters(M31, begin
    TX,     0   # Proportional output tax on sector X
    TY,     0   # Proportional output tax on sector Y
    TLX,    1   # Ad-valorem tax on labor inputs to X
    TKX,    0   # Ad-valorem tax on capital inputs to X
end)

@sectors(M31, begin
    X
    Y
    W
end)

@commodities(M31, begin
    PX
    PY
    PW
    PL
    PK
end)

@consumer(M31, CONS)

@production(M31, X, [s = 1, t = 0], begin
    @output(PX, 100, t, taxes = [Tax(CONS, TX)])
    @input(PL, 20, s, taxes = [Tax(CONS, TLX)], reference_price = 2)
    @input(PK, 60, s, taxes = [Tax(CONS, TKX)])
end)

@production(M31, Y, [s = 1, t = 0], begin
    @output(PY, 100, t, taxes = [Tax(CONS, TY)])
    @input(PL, 60, s)
    @input(PK, 40, s)
end)

@production(M31, W, [s = 1, t = 0], begin
    @output(PW, 200, t)
    @input(PX, 100, s)
    @input(PY, 100, s)
end)

@demand(M31, CONS, begin
    @final_demand(PW, 200)
    @endowment(PL, 80)
    @endowment(PK, 100)
end)

fix(PW, 1)
set_value!(TLX, 1)
set_value!(TKX, 0)
set_value!(TX, 0)
solve!(M31, cumulative_iternation_limit = 0)
benchmark_calibration = generate_report(M31)
println(benchmark_calibration)

#       In the first counterfactual, we replace the tax on labor inputs
#       by a uniform tax on both factors:

set_value!(TLX, 0.25)
set_value!(TKX, 0.25)
solve!(M31, cumulative_iteration_limit = 1000)
uniform_tax = generate_report(M31)

#       Now demonstrate that a 25% tax on all inputs is equivalent to a
#       20% tax on the output (or all outputs if more than one)

set_value!(TLX, 0)
set_value!(TKX, 0)
set_value!(TX, 0.2)
solve!(M31, cumulative_iteration_limit = 1000)
output_tax = generate_report(M31)

#       Finally, demonstrate that a 20% tax on the X sector output is 
#       equivalent to a 25% subsidy on Y sector output (assumes that the
#       funds for the subsidy can be raised lump sum from the consumer!)

set_value!(TLX, 0)
set_value!(TKX, 0)
set_value!(TX, 0)
set_value!(TY, -0.25)
solve!(M31, cumulative_iteration_limit = 1000)
output_subsidy_on_Y = generate_report(M31)
