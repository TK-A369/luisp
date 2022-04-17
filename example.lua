local luisp = require("luisp")

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
]]

local parsedCode = luisp.parse(code)

printTab(parsedCode)
