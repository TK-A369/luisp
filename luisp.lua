local luispModule = {}

local debugMode = false
local printErrors = false
local yieldMode = false

local luispVariables = {}

local function printTab(tab, depth)
	if depth == nil then depth = 0 end

	if type(tab) == "table" then
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

--http://lua-users.org/wiki/CopyTable
local function deepcopy(orig)
	local orig_type = type(orig)
	local copy
	if orig_type == 'table' then
		copy = {}
		for orig_key, orig_value in next, orig, nil do
			copy[deepcopy(orig_key)] = deepcopy(orig_value)
		end
		setmetatable(copy, deepcopy(getmetatable(orig)))
	else -- number, string, boolean, etc
		copy = orig
	end
	return copy
end

local function evalArgs(args, ret)
	local result = { type = "list", value = {} }
	for k, v in pairs(args.value) do
		if v.type == "list" then
			local res, err, errDetail = luispModule.exec(v, true)
			if err then
				return nil, err, errDetail
			end
			result.value[k] = res
		else
			result.value[k] = v
		end
	end
	if ret then
		return result
	else
		args = result
	end
end

local luispCoreFunctions = {
	{
		name = "+",
		callback = function(args)
			if debugMode then
				print("Summing args: ")
				printTab(args)
			end
			args = evalArgs(args, true)
			if debugMode then
				print("Summing args (after eval): ")
				printTab(args)
			end
			local sum = 0
			for k, v in pairs(args.value) do
				if debugMode then
					print("Summing")
					printTab(v)
					print("Type: " .. v.type)
				end
				if v.type == "atom" then
					if tonumber(v.value) == nil then
						return nil, "TypeError", "All arguments in + function should be number atoms or (callable) lists that return number atom"
					else
						sum = sum + v.value
					end
				else
					if debugMode then
						print("Stack: " .. debug.traceback())
					end
					return nil, "TypeError", "All arguments in + function should be atoms or (callable) lists that return atom"
				end
			end
			if debugMode then
				print("Summing result: " .. sum)
			end
			return { type = "atom", value = sum }
		end
	},
	{
		name = "-",
		callback = function(args)
			if debugMode then
				print("Subtracting")
				print("Subtracting args: ")
				printTab(args)
			end
			args = evalArgs(args, true)
			if debugMode then
				print("Subtracting args (after eval): ")
				printTab(args)
			end

			local sub = 0
			for k, v in pairs(args.value) do
				if k == 1 then
					if v.type == "atom" then
						sub = v.value
					else
						return nil, "TypeError", "All arguments in + function should be atoms or (callable) lists that return atom"
					end
				else
					if v.type == "atom" then
						sub = sub - v.value
					else
						return nil, "TypeError", "All arguments in + function should be atoms or (callable) lists that return atom"
					end
				end
			end
			return { type = "atom", value = sub }
		end
	},
	{
		name = "*",
		callback = function(args)
			if debugMode then
				print("Multiplication args: ")
				printTab(args)
			end
			args = evalArgs(args, true)
			if debugMode then
				print("Multiplication args (after eval): ")
				printTab(args)
			end
			local mult = 1
			for k, v in pairs(args.value) do
				if debugMode then
					print("Multiplication")
					printTab(v)
					print("Type: " .. v.type)
				end
				if v.type == "atom" then
					if tonumber(v.value) == nil then
						return nil, "TypeError", "All arguments in * function should be number atoms or (callable) lists that return number atom"
					else
						mult = mult * v.value
					end
				else
					if debugMode then
						print("Stack: " .. debug.traceback())
					end
					return nil, "TypeError", "All arguments in * function should be number atoms or (callable) lists that return number atom"
				end
			end
			if debugMode then
				print("Multiplication result: " .. mult)
			end
			return { type = "atom", value = mult }
		end
	},
	{
		name = "/",
		callback = function(args)
			if debugMode then
				print("Dividing")
				print("Dividing args: ")
				printTab(args)
			end
			args = evalArgs(args, true)
			if debugMode then
				print("Dividing args (after eval): ")
				printTab(args)
			end

			local div = 1
			for k, v in pairs(args.value) do
				if k == 1 then
					if v.type == "atom" then
						div = v.value
					else
						return nil, "TypeError", "All arguments in / function should be number atoms or (callable) lists that return number atom"
					end
				else
					if v.type == "atom" then
						div = div / v.value
					else
						return nil, "TypeError", "All arguments in / function should be number atoms or (callable) lists that return number atom"
					end
				end
			end
			return { type = "atom", value = div }
		end
	},
	{
		name = "^",
		callback = function(args)
			if debugMode then
				print("Exponentiation")
				print("Exponentiation args: ")
				printTab(args)
			end
			args = evalArgs(args, true)
			if debugMode then
				print("Exponentiation args (after eval): ")
				printTab(args)
			end

			if args.value[1].type == "atom" and args.value[2].type == "atom" and tonumber(args.value[1].value) ~= nil and tonumber(args.value[2].value) ~= nil then
				return { type = "atom", value = args.value[1].value ^ args.value[2].value }
			else
				return nil, "TypeError", "All arguments in ^ function should be number atoms or (callable) lists that return number atom"
			end
		end
	},
	{
		name = "==",
		callback = function(args)
			if debugMode then
				print("Check equality")
				print("Check equality args: ")
				printTab(args)
			end
			args = evalArgs(args, true)
			if debugMode then
				print("Check equality args (after eval): ")
				printTab(args)
			end

			if args.value[1].type == "atom" and args.value[2].type == "atom" and tonumber(args.value[1].value) ~= nil and tonumber(args.value[2].value) ~= nil then
				if tonumber(args.value[1].value) == tonumber(args.value[2].value) then
					return { type = "atom", value = true }
				else
					return { type = "atom", value = false }
				end
			else
				return nil, "TypeError", "All arguments in == function should be number atoms or (callable) lists that return number atom"
			end
		end
	},
	{
		name = ">",
		callback = function(args)
			if debugMode then
				print("Check equality")
				print("Check equality args: ")
				printTab(args)
			end
			args = evalArgs(args, true)
			if debugMode then
				print("Check equality args (after eval): ")
				printTab(args)
			end

			if args.value[1].type == "atom" and args.value[2].type == "atom" and tonumber(args.value[1].value) ~= nil and tonumber(args.value[2].value) ~= nil then
				if tonumber(args.value[1].value) > tonumber(args.value[2].value) then
					return { type = "atom", value = true }
				else
					return { type = "atom", value = false }
				end
			else
				return nil, "TypeError", "All arguments in > function should be number atoms or (callable) lists that return number atom"
			end
		end
	},
	{
		name = "<",
		callback = function(args)
			if debugMode then
				print("Check equality")
				print("Check equality args: ")
				printTab(args)
			end
			args = evalArgs(args, true)
			if debugMode then
				print("Check equality args (after eval): ")
				printTab(args)
			end

			if args.value[1].type == "atom" and args.value[2].type == "atom" and tonumber(args.value[1].value) ~= nil and tonumber(args.value[2].value) ~= nil then
				if tonumber(args.value[1].value) < tonumber(args.value[2].value) then
					return { type = "atom", value = true }
				else
					return { type = "atom", value = false }
				end
			else
				return nil, "TypeError", "All arguments in < function should be number atoms or (callable) lists that return number atom"
			end
		end
	},
	{
		name = "strconcat",
		callback = function(args)
			if debugMode then
				print("Concat")
				print("Concat args: ")
				printTab(args)
			end
			args = evalArgs(args, true)
			if debugMode then
				print("Concat args (after eval): ")
				printTab(args)
			end

			local result = ""

			for k, v in pairs(args.value) do
				if v.type == "atom" then
					result = result .. tostring(v.value)
				else
					return nil, "TypeError", "All arguments in strconcat function should be atoms or (callable) lists that return atom"
				end
			end

			return { type = "atom", value = result }
		end
	},
	{
		name = "list",
		callback = function(args)
			if debugMode then
				print("List args: ")
				printTab(args)
			end
			args = evalArgs(args, true)
			if debugMode then
				print("List args (after eval): ")
				printTab(args)
			end

			local result = { type = "quotelist", value = {} }
			for k, v in pairs(args.value) do
				if v.type == "atom" or v.type == "quotelist" then
					table.insert(result.value, v)
				end
			end
			return result
		end
	},
	{
		name = "set",
		callback = function(args)
			if debugMode then
				print("Set args: ")
				printTab(args)
			end
			args = evalArgs(args, true)
			if debugMode then
				print("Set args (after eval): ")
				printTab(args)
			end

			if args.value[1].type == "atom" then
				local copy = deepcopy(args.value[2])
				luispVariables[args.value[1].value] = copy
			else
				return nil, "TypeError", "Argument 1 should be atom"
			end

			if debugMode then
				print("Variable \"" .. args.value[1].value .. "\" after setting:")
				printTab(luispVariables[args.value[1].value])
			end
		end
	},
	{
		name = "if",
		callback = function(args)
			if debugMode then
				print("If args: ")
				printTab(args)
			end

			local evalRes, err, errDetail = evalArgs({ type = "list", value = { args.value[1] } }, true)
			if err or not evalRes then
				if debugMode then
					print("If error!")
				end
				return nil, err, errDetail
			end
			local arg1 = evalRes.value[1]
			if debugMode then
				print("Arg1 (after eval): ")
				printTab(arg1)
			end

			if arg1.type == "atom" then
				if tostring(arg1.value) == "0" or tostring(arg1.value) == "false" or tostring(arg1.value) == "" or tostring(arg1.value) == "nil" then
					--False
					if #(args.value) == 3 then
						if debugMode then
							print("Entering if's 2nd block")
						end
						local ret, err, errDetail = luispModule.exec(args.value[3], true)
						return ret, err, errDetail
					end
				else
					--True
					if debugMode then
						print("Entering if's 1st block")
					end
					local ret, err, errDetail = luispModule.exec(args.value[2], true)
					return ret, err, errDetail
				end
			else
				return nil, "TypeError", "Argument 1 should be atom or (callable) list that returns atom"
			end
		end
	},
	{
		name = "for",
		callback = function(args)
			if debugMode then
				print("for args: ")
				printTab(args)
			end

			local evalRes, err, errDetail = evalArgs({ type = "list", value = { args.value[1], args.value[2], args.value[3], args.value[4] } }, true)
			if err or not evalRes then
				if debugMode then
					print("for error!")
				end
				return nil, err, errDetail
			end
			if debugMode then
				print("for args 1-4 (after eval): ")
				printTab(evalRes)
			end

			local result = { type = "qoutelist", value = {} }

			if evalRes.value[1].type == "atom" and evalRes.value[2].type == "atom" and evalRes.value[3].type == "atom" and evalRes.value[4].type == "atom" then
				local forIterVar = evalRes.value[1].value
				local forStart = evalRes.value[2].value
				local forEnd = evalRes.value[3].value
				local forInc = evalRes.value[4].value

				if debugMode then
					print("IterVar: " .. forIterVar)
					print("Start: " .. forStart)
					print("End: " .. forEnd)
					print("Inc: " .. forInc)
				end

				for i = forStart, forEnd, forInc do
					if debugMode then
						print("for iteration " .. i)
					end
					luispModule.exec({ type = "list", value = { { type = "atom", value = "set" }, { type = "atom", value = forIterVar }, { type = "atom", value = i } } }, true)
					local res, err, errDetail = luispModule.exec(args.value[5])
					if err then
						return nil, err, errDetail
					end
					table.insert(result.value, res)
				end
			else
				return nil, "TypeError", "Arguments 1-4 should be atoms or (callable) lists that returns atom"
			end

			return result
		end
	},
	{
		name = "while",
		callback = function(args)
			if debugMode then
				print("while args: ")
				printTab(args)
			end

			local result = { type = "qoutelist", value = {} }

			while true do
				if debugMode then
					print("while iteration start")
				end
				local res1, err1, errDetail1 = evalArgs({ type = "list", value = { args.value[1] } }, true)
				if debugMode then
					print("while condition (after eval):")
					printTab(res1)
				end
				if err1 then
					if debugMode then
						print("Error in while loop condition")
					end
					return nil, err1, errDetail1
				end
				if res1 == nil or res1.value[1] == nil or res1.value[1].value == nil then
					if debugMode then
						print("Breaking from while loop 1")
					end
					break
				end
				if tostring(res1.value[1].value) == "0" or tostring(res1.value[1].value) == "false" or tostring(res1.value[1].value) == "" then
					if debugMode then
						print("Breaking from while loop 2")
					end
					break
				end
				if debugMode then
					print("while executing code")
				end
				local res2, err2, errDetail2 = luispModule.exec(args.value[2], true)
				if err2 then
					if debugMode then
						print("Error in while block")
					end
					return nil, err2, errDetail2
				end
				table.insert(result.value, res2)
			end

			return result
		end
	},
	{
		name = "random",
		callback = function(args)
			if debugMode then
				print("random args: ")
				printTab(args)
			end
			args = evalArgs(args, true)
			if debugMode then
				print("random args (after eval): ")
				printTab(args)
			end

			if args.value[1].type == "atom" and args.value[2].type == "atom" and tonumber(args.value[1].value) ~= nil and tonumber(args.value[2].value) ~= nil then
				return { type = "atom", value = math.random(args.value[1].value, args.value[2].value) }
			else
				return nil, "TypeError", "Arguments of function random should be atoms or (callable) lists that returns atom"
			end
		end
	},
}

local luispIOFunctions = {
	{
		name = "print",
		callback = function(args)
			if debugMode then
				print("Print args:")
				printTab(args)
			end
			if #(args.value) ~= 1 then
				return nil, "ArgsError", "Function print must have exactly 1 argument"
			end
			args = evalArgs(args, true)
			if debugMode then
				print("Print args (after eval):")
				printTab(args)
			end
			if args.value[1].type == "atom" then
				if debugMode then
					print("Printing atom: " .. args.value[1].value)
				end
				print(args.value[1].value)
			elseif args.value[1].type == "quotelist" then
				for k, v in ipairs(args.value[1].value) do
					local res, err, errDetail = luispModule.exec({ type = "list", value = { { type = "atom", value = "print" }, v } }, true)
					if err then
						return nil, "" .. err, errDetail
					end
				end
			end
			return nil
		end
	},
	{
		name = "readline",
		callback = function(args)
			local retVal = io.read()
			return { type = "atom", value = retVal }
		end
	},
}

local luispFunctions = {}

function luispModule.parse(code)
	if debugMode then
		print("Parsing...")
		print(code)
	end

	local parsedCode = { type = "list", value = {} }
	local parserState = {
		indentLvl = 0,
		inString = false,
		stringBuf = "",
		lastChar = ""
	}

	for c in code:gmatch(".") do
		if parserState.inString then
			if c == "\"" and parserState.lastChar ~= "\\" then
				--Leaving string atom
				parserState.inString = false
				local currentList = parsedCode
				for i = 1, parserState.indentLvl do
					currentList = currentList.value[#currentList.value]
				end
				table.insert(currentList.value, { type = "atom", value = parserState.stringBuf })
				if debugMode then print("Leaving string atom: \"" .. parserState.stringBuf .. "\"") end
				parserState.stringBuf = ""
			elseif c == "\\" then
			elseif parserState.lastChar == "\\" then
				if c == "n" then
					parserState.stringBuf = parserState.stringBuf .. "\n"
				elseif c == "t" then
					parserState.stringBuf = parserState.stringBuf .. "\t"
				elseif c == "\"" then
					parserState.stringBuf = parserState.stringBuf .. "\""
				elseif c == "\'" then
					parserState.stringBuf = parserState.stringBuf .. "\'"
				end
			else
				parserState.stringBuf = parserState.stringBuf .. c
			end
		else
			if c == "(" then
				--Entering list
				local listtype = "list"
				if parserState.lastChar == "\'" then listtype = "quotelist" end
				if parserState.indentLvl == 0 then
					table.insert(parsedCode.value, { type = listtype, value = {} })
				else
					local currentList = parsedCode
					for i = 1, parserState.indentLvl do
						currentList = currentList.value[#currentList.value]
					end
					table.insert(currentList.value, { type = listtype, value = {} })
				end
				parserState.indentLvl = parserState.indentLvl + 1
				parserState.stringBuf = ""
				if debugMode then print("Entering list") end
			elseif c == ")" then
				--Leaving list
				if parserState.stringBuf ~= "" then
					local currentList = parsedCode
					for i = 1, parserState.indentLvl do
						currentList = currentList.value[#currentList.value]
					end
					table.insert(currentList.value, { type = "atom", value = parserState.stringBuf })
					if debugMode then print("Leaving atom: \"" .. parserState.stringBuf .. "\"") end
					parserState.stringBuf = ""
				end
				parserState.indentLvl = parserState.indentLvl - 1
				if debugMode then print("Leaving list") end
			elseif c == "\"" then
				--Entering string atom
				parserState.inString = true
				parserState.stringBuf = ""
				if debugMode then print("Entering string atom") end
			elseif c == " " and parserState.stringBuf ~= "" then
				--Leaving atom
				local currentList = parsedCode
				for i = 1, parserState.indentLvl do
					currentList = currentList.value[#currentList.value]
				end
				table.insert(currentList.value, { type = "atom", value = parserState.stringBuf })
				if debugMode then print("Leaving atom: \"" .. parserState.stringBuf .. "\"") end
				parserState.stringBuf = ""
			elseif c == "\n" or c == "\t" then
				--White character
			elseif c == "\'" then
				--Quote sign
			else
				--Atom content
				parserState.stringBuf = parserState.stringBuf .. c
			end
		end
		parserState.lastChar = c
	end

	return parsedCode
end

function luispModule.exec(parsedCode, child)
	if not child then child = false end

	local returnVal = nil

	if parsedCode.value[1].type == "list" then
		--This is list of lists
		for k, v in ipairs(parsedCode.value) do
			if v.type == "list" then
				local varFunc = nil
				for k2, v2 in pairs(luispFunctions) do
					if v2.name == v.value[1].value then
						varFunc = v2
						break
					end
				end
				if varFunc then
					local args = { type = "list", value = {} }
					for i = 1, ((#(v.value)) - 1) do
						table.insert(args.value, v.value[i + 1])
					end
					if debugMode then
						print("Call args:")
						printTab(args)
					end
					local _returnVal, err, errDetail = varFunc.callback(args)
					returnVal = _returnVal
					if err then
						if not child and printErrors then
							print("Error:", err, errDetail)
							if debugMode then
								print("Instruction number: " .. k)
								print("Stack: " .. debug.traceback())
							end
						end
						return nil, err, errDetail
					end
				else
					if luispVariables[v.value[1].value] then
						returnVal = luispVariables[v.value[1].value]
					else
						if printErrors and not child then
							print("Error:", "VariableFunctionNotDefinedError", "Variable nor function \"" .. tostring(v.value[1].value) .. "\" not found!")
							if debugMode then
								print("Stack: " .. debug.traceback())
							end
						end
						return nil, "VariableFunctionNotDefinedError", "Variable nor function \"" .. tostring(v.value[1].value) .. "\" not found!"
					end
				end
			end

			if yieldMode then
				coroutine.yield()
			end
		end
	else
		--This is list of atoms
		local varFunc = nil
		for k, v in ipairs(luispFunctions) do
			if v.name == parsedCode.value[1].value then
				varFunc = v
				break
			end
		end
		if varFunc then
			local args = { type = "list", value = {} }
			for i = 1, ((#(parsedCode.value)) - 1) do
				table.insert(args.value, parsedCode.value[i + 1])
			end
			if debugMode then
				print("Call args:")
				printTab(args)
			end
			local _returnVal, err, errDetail = varFunc.callback(args)
			returnVal = _returnVal
			if err then
				if not child then
					print("Error:", err, errDetail)
					if debugMode then
						print("Stack: " .. debug.traceback())
					end
				end
				return nil, err, errDetail
			end
		else
			if luispVariables[parsedCode.value[1].value] then
				returnVal = luispVariables[parsedCode.value[1].value]
			else
				if printErrors and not child then
					print("Error:", "VariableFunctionNotDefinedError", "Variable nor function \"" .. tostring(parsedCode.value[1].value) .. "\" not found!")
					if debugMode then
						print("Stack: " .. debug.traceback())
					end
				end
				return nil, "VariableFunctionNotDefinedError", "Variable nor function \"" .. tostring(parsedCode.value[1].value) .. "\" not found!"
			end
		end

		if yieldMode then
			coroutine.yield()
		end
	end

	return returnVal
end

function luispModule.debugModeOn()
	debugMode = true
end

function luispModule.debugModeOff()
	debugMode = false
end

function luispModule.printErrorsOn()
	printErrors = true
end

function luispModule.printErrorsOff()
	printErrors = false
end

function luispModule.yieldModeOn()
	yieldMode = true
end

function luispModule.yieldModeOff()
	yieldMode = false
end

function luispModule.registerCoreFunctions()
	for k, v in pairs(luispCoreFunctions) do
		table.insert(luispFunctions, v)
	end
end

function luispModule.registerIOFunctions()
	for k, v in pairs(luispIOFunctions) do
		table.insert(luispFunctions, v)
	end
end

function luispModule.registerFunction(func)
	table.insert(luispFunctions, func)
end

function luispModule.registerFunctions(funcs)
	for k, v in pairs(funcs) do
		table.insert(luispFunctions, v)
	end
end

return luispModule
