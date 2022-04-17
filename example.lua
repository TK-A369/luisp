local luisp = require("luisp")

luisp.debugModeOff()
luisp.registerCoreFunctions()

local function printTab(tab, depth)
	if depth == nil then depth = 0 end

	if type(tab) == "table" then
		-- for i = 1, depth do io.write("  ") end
		print("{")
		for k, v in pairs(tab) do
			for i = 1, (depth + 1) do io.write("  ") end
			io.write(k .. " = ")
			printTab(v, depth + 1)
		end
		for i = 1, depth do io.write("  ") end
		print("}")
	else
		print(tab)
	end
end

-- printTab({ "a", b = { 1, 2, 3 }, c = "some", d = { "one", "two", three = { 9, 10, 11 } } })

local code = [[
(print "Hello world!")
(print (+ 2 3))
(print (+ 1 2 3 4 (+ 10 20)))
(print (- 10 7))
(print (+ (- 11 2) (- 23 12)))
]]

local parsedCode = luisp.parse(code)

-- printTab(parsedCode)

-- print("\nExecuting: ")
local result, err, errDetail = luisp.exec(parsedCode)
if err then
	print("Error: ", err, errDetail)
end
