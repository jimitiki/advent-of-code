INPUT_MODE = { FULL = 0, FIRST_LINE = 1, LINES = 2 }

local solvers = {}
for y = 15, 99 do
    for d = 1, 25 do
        local year, day = string.format("%02d", y), string.format("%02d", d)
        local file_path = string.format("solvers/y%s/d%s", year, day)
        local success, result = pcall(require, file_path)
        if success then
            if not solvers[year] then solvers[year] = {} end
            solvers[year][day] = {
                input_path = string.format("../inputs/y%s/d%s.txt", year, day),
                input_mode = result.input_mode or INPUT_MODE.FULL,
                solve = result.solve_fn,
                test = result.test_fn,
            }
        end
    end
end

return solvers
