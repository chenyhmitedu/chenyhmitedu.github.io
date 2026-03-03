# Model M33: Closed 2X2 Economy -- Equal Yield Tax Reform

using Pkg
Pkg.add("JuMP")
Pkg.add("Ipopt")
Pkg.add("MPSGE")
Pkg.add("DataFrames")
using JuMP, Ipopt, MPSGE, DataFrames

#=

                  Production Sectors                 Consumers
   Markets   |    A       B        W      TL   TK      CONS
   ----------------------------------------------------------
        PX   |  120             -120
        PY   |          120     -120           
        PW   |                   340                  -340
        PLS  |  -48     -72              120           
        PKS  |  -72     -48                      120   
        PL   |                  -100    -100           200
        PK   |                                  -100   100 
        TAX  |                           -20     -20    40 
   ---------------------------------------------------------

=#

# Number of TXL values in sensitivity analysis  
S = 5

M33 = MPSGEModel()

@parameters(M33, begin
    TXL, 0.2
end)

@sectors(M33, begin
    X
    Y
    W
    TL
    TK
end)

@commodities(M33, begin
    PX
    PY
    PL
    PK
    PLS
    PKS
    PW
end)

@consumer(M33, CONS)

@auxiliaries(M33, begin
    TXK
end)

set_start_value(PLS, 1.2)
set_start_value(PKS, 1.2)
set_start_value(TXK, 0.2)

@production(M33, X, [t = 0, s = 1], begin
    @output(PX, 120, t)
    @input(PLS, 40, s, reference_price = 1.2)
    @input(PKS, 60, s, reference_price = 1.2)
end)

@production(M33, Y, [t = 0, s = 1], begin
    @output(PY, 120, t)
    @input(PLS, 60, s, reference_price = 1.2)
    @input(PKS, 40, s, reference_price = 1.2)
end)

@production(M33, TL, [t = 0, s = 0], begin
    @output(PLS, 100, t, reference_price = 1.2)
    @input(PL, 100, s, taxes = [Tax(CONS, TXL)])
end)

@production(M33, TK, [t = 0, s = 0], begin
    @output(PKS, 100, t, reference_price = 1.2)
    @input(PK, 100, s, taxes = [Tax(CONS, TXK)])
end)

@production(M33, W, [t = 0, s = 0.7, a => s = 1], begin
    @output(PW, 340, t)
    @input(PX, 120, a)
    @input(PY, 120, a)
    @input(PL, 100, s)
end)

@demand(M33, CONS, begin
    @final_demand(PW, 340)
    @endowment(PL, 200)
    @endowment(PK, 100)
end)

@aux_constraint(M33, TXK, begin
    TXL*PL*TL*100 + TXK*PK*TK*100 - 40*(PX + PY)/2
end)
   
fix(PW, 1)

set_value!(TXL, 0.2)
solve!(M33, cumulative_iteration_limit = 0)
benchmark_calibration = generate_report(M33)

# Counterfactual simulation

simulation_results = Vector{DataFrame}(undef, S)

for i in 1:S
    set_value!(TXL, 0.25 - 0.05*i)
    solve!(M33, cumulative_iteration_limit = 1000)
    simulation_results[i] = generate_report(M33)
end

println(simulation_results)