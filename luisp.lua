local luispModule = {}

function luispModule.parse(code)
	print("Parsing...")
	print(code)

	local parsedCode = {}
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
					currentList = currentList[#currentList]
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
					table.insert(parsedCode, { type = "list", value = {} })
				else
					local currentList = parsedCode
					for i = 1, parserState.indentLvl do
						if i == 1 then
							currentList = currentList[#currentList]
						else
							currentList = currentList.value[#currentList.value]
						end
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
						if i == 1 then
							currentList = currentList[#currentList]
						else
							currentList = currentList.value[#currentList.value]
						end
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
					if i == 1 then
						currentList = currentList[#currentList]
					else
						currentList = currentList.value[#currentList.value]
					end
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

return luispModule
