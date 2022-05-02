local luisp = require("luisp")

luisp.debugModeOff()
luisp.printErrorsOn()
luisp.registerCoreFunctions()
luisp.registerIOFunctions()

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

luisp.registerFunctions({
	{
		name = "myfunc",
		callback = function(args)
			return { type = "atom", value = "Hello from my own function!" }
		end
	}
})

local code1 = [[
(print "Hello world!")
(print (+ 2 3))
(print (+ 1 2 3 4))
(print (+ 1 2 3 4 (+ 10 20)))
(print (- 10 7))
(print (+ (- 11 2) (- 23 12)))
(print (myfunc))
(print (list 2 3))
(set myvar1 7.5)
(set myvar2 (+ 2 3))
(set myvar3 (+ (myvar1) (myvar2)))
(print (myvar1))
(print (myvar2))
(print (myvar3))
]]

local code2 = [[
(set myvar1 '(1 2 3))
(print (myvar1))
]]

local code3 = [[
(set myvar1 7.5)
(print (myvar1))
(set myvar2 (+ 2 3))
(print (myvar2))
(set myvar3 (+ (myvar1) (myvar2)))
(print (myvar3))
(set myvar4 (- (myvar3) 2))
(print (myvar4))
(set myvar5 (- (myvar3) 0.5))
(print (myvar5))
(set myvar6 (- 21 1))
(print (myvar6))
]]

local code4 = [[
(print (+ 1 2 3))
(print (+ (+ 1 2) (+ 3 4)))
]]

local code5 = [[
(set myvar1 true)
(if (myvar1) ((print abc)(print "This is true!")) ((print def)(print "This is false!")))
]]

local parsedCode = luisp.parse(code5)

-- printTab(parsedCode)

-- print("\nExecuting: ")
local result, err, errDetail = luisp.exec(parsedCode)
if err then
	print("User error: ", err, errDetail)
end
