local luispModule = {}

local debugMode = false
local printErrors = false

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

local luispCoreFunctions = {
	{
		name = "print",
		callback = function(args)
			if args.value[1].type == "atom" then
				-- print("Printing atom: " .. args[1].value)
				print(args.value[1].value)
			elseif args.value[1].type == "quotelist" then
				for k, v in ipairs(args.value[1].value) do
					local res, err, errDetail = luispModule.exec({ type = "list", value = { { type = "atom", value = "print" }, v } })
					if err then
						if printErrors then
							print("Error: ", err, errDetail)
						end
						return nil, err, errDetail
					end
				end
			elseif args.value[1].type == "list" then
				-- print("Printing list:")
				-- printTab(args[1])
				local res, err, errDetail = luispModule.exec(args.value[1])
				if err then
					if printErrors then
						print("Error: ", err, errDetail)
					end
					return nil, err, errDetail
				else
					-- print(res.value)
					res, err, errDetail = luispModule.exec({ type = "list", value = { { type = "atom", value = "print" }, res } })
					if err then
						if printErrors then
							print("Error: ", err, errDetail)
						end
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
					sum = sum + luispModule.exec(v).value
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
						sub = luispModule.exec(v).value
					end
				else
					if v.type == "atom" then
						sub = sub - v.value
					elseif v.type == "list" then
						sub = sub - luispModule.exec(v).value
					end
				end
			end
			return { type = "atom", value = sub }
		end
	},
	{
		name = "list",
		callback = function(args)
			-- print("Subtracting")
			local result = { type = "quotelist", value = {} }
			for k, v in pairs(args.value) do
				if v.type == "atom" then
					table.insert(result.value, v)
				elseif v.type == "list" then
					local res, err, errDetail = luispModule.exec(v)
					if err then
						if printErrors then
							print("Error: ", err, errDetail)
						end
						return nil, err, errDetail
					else
						print(res.value)
					end
				end
			end
			return result
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

function luispModule.exec(parsedCode)
	local returnVal = nil

	if parsedCode.value[1].type == "list" then
		--This is list of lists
		for k, v in ipairs(parsedCode.value) do
			if v.type == "list" then
				local func = nil
				for k2, v2 in pairs(luispFunctions) do
					if v2.name == v.value[1].value then
						func = v2
						break
					end
				end
				if func then
					local args = { type = "list", value = {} }
					for i = 1, ((#v.value) - 1) do
						table.insert(args.value, v.value[i + 1])
					end
					local _returnVal, err, errDetail = func.callback(args)
					returnVal = _returnVal
					if err then
						print("Error:", err, errDetail)
					end
				else
					if printErrors then
						print("Error:", "FunctionNotDefinedError", "Function \"" .. v.value[1].value .. "\" not found!")
					end
					return nil, "FunctionNotDefinedError", "Function \"" .. v.value[1].value .. "\" not found!"
				end
			end
		end
	else
		--This is list of atoms
		local func = nil
		for k, v in ipairs(luispFunctions) do
			if v.name == parsedCode.value[1].value then
				func = v
				break
			end
		end
		if func then
			local args = { type = "list", value = {} }
			for i = 1, ((#parsedCode.value) - 1) do
				table.insert(args.value, parsedCode.value[i + 1])
			end
			-- print("Args:")
			-- printTab(args)
			returnVal = func.callback(args)
		else
			if printErrors then
				print("Error:", "FunctionNotDefinedError", "Function \"" .. tostring(parsedCode.value[1].value) .. "\" not found!")
			end
			return nil, "FunctionNotDefinedError", "Function \"" .. tostring(parsedCode.value[1].value) .. "\" not found!"
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
