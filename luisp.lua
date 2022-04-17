local luispModule = {}

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

local luispFunctions = {
	{
		name = "print",
		callback = function(args)
			if args[1].type == "atom" then
				-- print("Printing atom: " .. args[1].value)
				print(args[1].value)
			else
				-- print("Printing list:")
				-- printTab(args[1])
				print(luispModule.exec(args[1]).value)
			end
		end
	},
	{
		name = "+",
		callback = function(args)
			-- print("Summing args: ")
			-- printTab(args)
			local sum = 0
			for k, v in pairs(args.value) do
				-- print("Summing " .. v.value)
				if v.type == "atom" then
					sum = sum + v.value
				else
					sum = sum + luispModule.exec(v).value
				end
			end
			return { type = "atom", value = sum }
		end
	},
}

function luispModule.parse(code)
	print("Parsing...")
	print(code)

	local parsedCode = { type = "list", value = {} }
	local parserState = {
		indentLvl = 0,
		inString = false,
		stringBuf = ""
	}

	for c in code:gmatch(".") do
		if parserState.inString then
			if c == "\"" or c == "\'" then
				--Leaving string atom
				parserState.inString = false
				local currentList = parsedCode
				for i = 1, parserState.indentLvl do
					-- currentList = currentList[#currentList]
					currentList = currentList.value[#currentList.value]
				end
				table.insert(currentList.value, { type = "atom", value = parserState.stringBuf })
				print("Leaving string atom: \"" .. parserState.stringBuf .. "\"")
				parserState.stringBuf = ""
			else
				parserState.stringBuf = parserState.stringBuf .. c
			end
		else
			if c == "(" then
				--Entering list
				if parserState.indentLvl == 0 then
					table.insert(parsedCode.value, { type = "list", value = {} })
				else
					local currentList = parsedCode
					for i = 1, parserState.indentLvl do
						-- if i == 1 then
						-- 	currentList = currentList[#currentList]
						-- else
						currentList = currentList.value[#currentList.value]
						-- end
					end
					table.insert(currentList.value, { type = "list", value = {} })
				end
				parserState.indentLvl = parserState.indentLvl + 1
				print("Entering list")
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
					print("Leaving atom: \"" .. parserState.stringBuf .. "\"")
					parserState.stringBuf = ""
				end
				parserState.indentLvl = parserState.indentLvl - 1
				print("Leaving list")
			elseif c == "\"" or c == "\'" then
				--Entering string atom
				parserState.inString = true
				parserState.stringBuf = ""
				print("Entering string atom")
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
				print("Leaving atom: \"" .. parserState.stringBuf .. "\"")
				parserState.stringBuf = ""
			elseif c == "\n" or c == "\t" then
				--White character
			else
				--Atom content
				parserState.stringBuf = parserState.stringBuf .. c
			end
		end
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
					local args = table.pack(table.unpack(v.value, 2))
					returnVal = func.callback(args)
				end
			end
		end
	else
		--This is list of atoms
		local func = nil
		for k, v in pairs(luispFunctions) do
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
		end
	end

	-- for k, v in ipairs(parsedCode.value) do
	-- 	if v.type == "list" then
	-- 		local func = nil
	-- 		for k2, v2 in pairs(luispFunctions) do
	-- 			if v2.name == v.value[1].value then
	-- 				func = v2
	-- 				break
	-- 			end
	-- 		end
	-- 		if func then
	-- 			local args = table.pack(table.unpack(v.value, 2))
	-- 			returnVal = func.callback(args)
	-- 		end
	-- 	else
	-- 		local func = nil
	-- 		for k2, v2 in pairs(luispFunctions) do
	-- 			if v2.name == v.value then
	-- 				func = v2
	-- 				break
	-- 			end
	-- 		end
	-- 		if func then
	-- 			local args = table.pack(table.unpack(v.value, 2))
	-- 			returnVal = func.callback(args)
	-- 		end
	-- 	end
	-- end

	return returnVal
end

return luispModule
