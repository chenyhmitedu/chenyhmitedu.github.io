# Model M29: Closed 2x2 Economy --  Stone Geary (LES) Preferences

using Pkg
Pkg.add("JuMP")
Pkg.add("Ipopt")
Pkg.add("MPSGE")
using JuMP, Ipopt, MPSGE

#=
The observed data is:

                  Production Sectors          Consumers
   Markets   |    X       Y        W    |       CONS
   ------------------------------------------------------
        PX   |  100             -100    |
        PY   |          100     -100    |
        PW   |                   200    |       -200
        PL   |  -40     -60             |        100
        PK   |  -60     -40             |        100
   ------------------------------------------------------

But calibrated to the model as:

                  Production Sectors          Consumers
   Markets   |    X       Y        W    |       CONS
   ------------------------------------------------------
        PX   |  100              -60    |        -40
        PY   |          100     -100    |
        PW   |                   160    |       -160
        PL   |  -40     -60             |        100
        PK   |  -60     -40             |        100
   ------------------------------------------------------
   =#

M29 = MPSGEModel()   

@parameters(M29, begin
    endow, 1
end)

@sectors(M29, begin
    X
    Y
    W
end)

@commodities(M29, begin
    PX
    PY
    PW
    PL
    PK
end)

@consumer(M29, CONS)

@production(M29, X, [s = 1, t = 0], begin
    @output(PX, 100, t)
    @input(PL, 40, s)
    @input(PK, 60, s)
end)

@production(M29, Y, [s = 1, t = 0], begin
    @output(PY, 100, t)
    @input(PL, 60, s)
    @input(PK, 40, s)
end)

@production(M29, W, [s = 1, t = 0], begin
    @output(PW, 160, t)
    @input(PX, 60, s)
    @input(PY, 100, s)
end)

@demand(M29, CONS, begin
    @final_demand(PW, 160)
    @endowment(PL, 100*endow)
    @endowment(PK, 100*endow)
    @endowment(PX, -40)
end)

fix(PW, 1)

set_value!(endow, 1)
solve!(M29, cumulative_iteration_limit = 0)
benchmark_calibration = generate_report(M29)


set_value!(endow, 2)
solve!(M29, cumulative_iteration_limit = 1000)
Double_endowment_simulation = generate_report(M29)