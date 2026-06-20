#!/usr/bin/env lua
Solvers = require("solvers")

local function get_solver()
    local y, d = arg[1], arg[2]
    if not y then
        io.stdout:write("Missing year arg\n")
        return nil
    end
    if not d then
        io.stdout:write("Missing day arg\n")
        return nil
    end
    local yrs = Solvers[y]
    if not yrs then
        io.stdout:write("No solutions for year ", y, "\n")
        return nil
    end
    local solver = yrs[d]
    if not solver then
        io.stdout:write("No solution for year ", y, " day ", d, "\n")
    end
    return solver
end

local function answer_to_string(answer)
    if answer then
        return tostring(answer)
    else
        return "No solution"
    end
end

local solver = get_solver()
if not solver then return end

local input_file = io.open(solver.input_path)
if not input_file then
    io.stdout:write("File \"", solver.input_path, "\" does not exist\n")
    return
end

local input
if solver.input_mode == INPUT_MODE.FULL then
    input = input_file:read("*a")
elseif solver.input_mode == INPUT_MODE.FIRST_LINE then
    input = input_file:read()
elseif solver.input_mode == INPUT_MODE.LINES then
    input = {}
    local i = 1
    for line in input_file:lines() do
        input[i] = line
        i = i + 1
    end
end
input_file:close()

local p1, p2 = solver.solve(input)
io.stdout:write("Part 1: ", answer_to_string(p1), "\nPart 2: ", answer_to_string(p2), "\n")
io.stdout:flush()
