local luisp = require("luisp")

luisp.debugModeOff()
luisp.printErrorsOn()
luisp.yieldModeOn()
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

local clock = os.clock
local function sleep(n) -- seconds
	local t0 = clock()
	while clock() - t0 <= n do end
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
(set myvar1 (readline))
(if (myvar1) ((print abc)(print "This is true!")) ((print def)(print "This is false!")))
]]

local code6 = [[
(print 1)
(print 2)
(print 3)
(print 4)
(print 5)
]]

local code7 = [[
(for i 1 10 1 (
	(print (i))
	(print (+ (i) 10))
	(print (* (i) 10))
	(print (/ (i) 10))
	(print (* 10 (/ (i) 10)))
	(print (/ (* (i) 10) 10))
	(print (^ (i) 2))
	(print (^ 2 (i)))
	(print (random 1 (i)))
	(print "")
))
]]

local code8 = [[
(print "abc")
(print "Some text: \"Hello world!\"")
(print "\ta\n\tb\n\tc")
]]

local code9 = [[
(while ((set someRandomNumber (random 0 100)) (someRandomNumber)) (
	(print "Test")
	(print (someRandomNumber))
	(print "")
))
]]

local code10 = [[
(print "Welcome to Guess The Number game!")
(print "Try to guess random number, using least possible number of attempts.")
(print "Enter minimum:")
(set minNum (readline))
(print "Enter maximum:")
(set maxNum (readline))
(set cont true)
(set tryCounter 0)
(set num (random (minNum) (maxNum)))
(while (cont) (
	(print "Try to guess number:")
	(set currTry (readline))
	(set tryCounter (+ (tryCounter) 1))
	(if (== (currTry) (num)) (
		(print "Congratulations! You won!")
		(print (strconcat "Attempts count: " (tryCounter)))
		(set cont false)
	) (
		(if (> (currTry) (num)) (
			(print "Too big!")
		) (
			(print "Too small!")
		))
	))
))
]]

local parsedCode = luisp.parse(code10)

-- printTab(parsedCode)

-- print("\nExecuting: ")
local execCo = coroutine.create(function()
	local result, err, errDetail = luisp.exec(parsedCode)
	if err then
		print("User error: ", err, errDetail)
	end
end)

while true do
	if coroutine.status(execCo) == "suspended" then
		-- print("Resuming!")
		coroutine.resume(execCo)
	else
		-- print("End!")
		break
	end
	-- print("Tick!")
	sleep(0.01)
end
