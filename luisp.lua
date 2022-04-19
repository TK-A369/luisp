local luispModule = {}

local debugMode = false
local printErrors = false

local luispVariables = {}

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

--http://lua-users.org/wiki/CopyTable
local function deepcopy(orig, copies)
	copies = copies or {}
	local orig_type = type(orig)
	local copy
	if orig_type == 'table' then
		if copies[orig] then
			copy = copies[orig]
		else
			copy = {}
			copies[orig] = copy
			for orig_key, orig_value in next, orig, nil do
				copy[deepcopy(orig_key, copies)] = deepcopy(orig_value, copies)
			end
			setmetatable(copy, deepcopy(getmetatable(orig), copies))
		end
	else -- number, string, boolean, etc
		copy = orig
	end
	return copy
end

local luispCoreFunctions = {
	{
		name = "print",
		callback = function(args)
			if args.value[1].type == "atom" then
				-- print("Printing atom: " .. args[1].value)
				print(args.value[1].value)
			elseif args.value[1].type == "quotelist" then
				for k, v in ipairs(args.value[1].value) do
					local res, err, errDetail = luispModule.exec({ type = "list", value = { { type = "atom", value = "print" }, v } }, true)
					if err then
						-- if printErrors then
						-- 	print("Error: ", err, errDetail)
						-- end
						return nil, err, errDetail
					end
				end
			elseif args.value[1].type == "list" then
				-- print("Printing list:")
				-- printTab(args[1])
				local res, err, errDetail = luispModule.exec(args.value[1], true)
				if err then
					-- if printErrors then
					-- 	print("Error: ", err, errDetail)
					-- end
					return nil, err, errDetail
				else
					-- print(res.value)
					res, err, errDetail = luispModule.exec({ type = "list", value = { { type = "atom", value = "print" }, res } }, true)
					if err then
						-- if printErrors then
						-- 	print("Error: ", err, errDetail)
						-- end
						return nil, err, errDetail
					end
				end
			end
			return nil
		end
	},
	{
		name = "+",
		callback = function(args)
			-- print("Summing args: ")
			-- printTab(args)
			local sum = 0
			for k, v in pairs(args.value) do
				-- print("Summing")
				-- printTab(v)
				if v.type == "atom" then
					sum = sum + v.value
				else
					sum = sum + luispModule.exec(v, true).value
				end
			end
			return { type = "atom", value = sum }
		end
	},
	{
		name = "-",
		callback = function(args)
			-- print("Subtracting")
			local sub = 0
			for k, v in pairs(args.value) do
				if k == 1 then
					if v.type == "atom" then
						sub = v.value
					elseif v.type == "list" then
						sub = luispModule.exec(v, true).value
					end
				else
					if v.type == "atom" then
						sub = sub - v.value
					elseif v.type == "list" then
						sub = sub - luispModule.exec(v, true).value
					end
				end
			end
			return { type = "atom", value = sub }
		end
	},
	{
		name = "list",
		callback = function(args)
			local result = { type = "quotelist", value = {} }
			for k, v in pairs(args.value) do
				if v.type == "atom" then
					table.insert(result.value, v)
				elseif v.type == "list" then
					local res, err, errDetail = luispModule.exec(v, true)
					if err then
						-- if printErrors then
						-- 	print("Error: ", err, errDetail)
						-- end
						return nil, err, errDetail
					else
						print(res.value)
					end
				end
			end
			return result
		end
	},
	{
		name = "set",
		callback = function(args)
			if args.value[1].type == "atom" then
				if args.value[2].type == "list" then
					local res, err, errDetail = luispModule.exec(args.value[2], true)
					if err then
						return nil, err, errDetail
					else
						luispVariables[args.value[1].value] = res
					end
				else
					local copy = deepcopy(args.value[2])
					luispVariables[args.value[1].value] = copy
				end
			else
				return nil, "TypeError", "Argument 1 should be atom"
			end
			print("Variable after setting:")
			printTab(luispVariables[args.value[1].value])
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
			if c == "\"" then
				--Leaving string atom
				parserState.inString = false
				local currentList = parsedCode
				for i = 1, parserState.indentLvl do
					-- currentList = currentList[#currentList]
					currentList = currentList.value[#currentList.value]
				end
				table.insert(currentList.value, { type = "atom", value = parserState.stringBuf })
				if debugMode then print("Leaving string atom: \"" .. parserState.stringBuf .. "\"") end
				parserState.stringBuf = ""
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
						-- if i == 1 then
						-- 	currentList = currentList[#currentList]
						-- else
						currentList = currentList.value[#currentList.value]
						-- end
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
						-- if i == 1 then
						-- 	currentList = currentList[#currentList]
						-- else
						currentList = currentList.value[#currentList.value]
						-- end
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
					-- if i == 1 then
					-- 	currentList = currentList[#currentList]
					-- else
					currentList = currentList.value[#currentList.value]
					-- end
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
					for i = 1, ((#v.value) - 1) do
						table.insert(args.value, v.value[i + 1])
					end
					local _returnVal, err, errDetail = varFunc.callback(args)
					returnVal = _returnVal
					if err and not child then
						print("Error:", err, errDetail)
					end
				else
					if luispVariables[v.value[1].value] then
						returnVal = luispVariables[v.value[1].value]
					else
						if printErrors and not child then
							print("Error:", "VariableFunctionNotDefinedError", "Variable nor function \"" .. tostring(v.value[1].value) .. "\" not found!")
						end
						return nil, "VariableFunctionNotDefinedError", "Variable nor function \"" .. tostring(v.value[1].value) .. "\" not found!"
					end
				end
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
			for i = 1, ((#parsedCode.value) - 1) do
				table.insert(args.value, parsedCode.value[i + 1])
			end
			-- print("Args:")
			-- printTab(args)
			returnVal = varFunc.callback(args)
		else
			if luispVariables[parsedCode.value[1].value] then
				returnVal = luispVariables[parsedCode.value[1].value]
			else
				if printErrors and not child then
					print("Error:", "VariableFunctionNotDefinedError", "Variable nor function \"" .. tostring(parsedCode.value[1].value) .. "\" not found!")
				end
				return nil, "VariableFunctionNotDefinedError", "Variable nor function \"" .. tostring(parsedCode.value[1].value) .. "\" not found!"
			end
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

function luispModule.registerCoreFunctions()
	for k, v in pairs(luispCoreFunctions) do
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
