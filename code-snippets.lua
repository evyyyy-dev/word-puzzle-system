-- ===================================== --
-- Hint-Driven Word Puzzle System (Snippet)
-- This snippet demonstrates the solution masking and the setup of a box.
-- =================================================================== --

-- Masks the solution with underscores by using string.rep.
-- If the solution has a whitespace, it splits up the solution into words and lengths, and then concatenates everything together.
-- @return strings: filteresdSolution, letterCount
function Solutions.FilterSolution(player, boxName)
	local solution: string = SolutionList.Boxes[boxName]
	if solution == nil then
		warn(string.format("[SolutionService] Solution for %s is nil!", boxName))
		return
	end

	if find(solution, " ") then
		local words = {}
		local lengths = {}

		for word in gmatch(solution, "%S+") do
			local wordLength = #word
			table.insert(words, string.rep(placeholderUnicode, #word))
			table.insert(lengths, string.format("(%d)", wordLength))
		end

		return table.concat(words, " "), table.concat(lengths, " ") -- Example output: ___ ____ (3) (4)
	end
	
	return rep("_", #solution), string.format("(%d)", #solution) -- Example output: ____ (4)
end

-- Sets up a puzzle box by getting the masked solution, cloning the GUI and connecting a listener event.
-- If the solution is correct, it plays effects and saves it inside of the datastore.  
function BoxInitializer.SetupPuzzleBox(box)
	if not box:IsDescendantOf(workspace) then
		return
	end

	local boxName = box.Name

	local filteredSolution, letterCount = getSolutionLength:InvokeServer(boxName)
	local hint = box:GetAttribute("Hint")

	if not filteredSolution then
		warn(`[BoxInitializer] Solution not found for {boxName}`)
		return
	end
	if not hint then
		warn(`[BoxInitializer] Hint attribute missing for box {boxName}`)
		return
	end

	BoxInitializer.SetupBoxGui(box, filteredSolution, letterCount, hint)

	local guiPrompt: TextBox = BoxInitializer.boxData[box].Prompt

	-- Used to avoid it being initialized twice (without this, the already saved ones get updated twice)
	if BoxInitializer.alreadySolved[boxName] then
		guiPrompt.Text = BoxInitializer.alreadySolved[boxName]
		PuzzleBoxHandler.SetBoxColors(guiPrompt, true)
	end

	guiPrompt:GetPropertyChangedSignal("Text"):Connect(function()
		local promptText = guiPrompt.Text
		local textLength = #promptText
		if textLength >= #filteredSolution then
			--Used to restrict player from typing extra characters after solve (for example, "helloasdasd" instead of "hello")
			local trucnatedText = string.sub(promptText, 1, #filteredSolution)

			local isCorrect = checkSolution:InvokeServer(boxName, promptText)
			if not isCorrect then return end

			PuzzleBoxHandler.OnBoxSolved(box)
			guiPrompt.Text = trucnatedText
		elseif textLength == 0 then 
			PuzzleBoxHandler.SetBoxColors(guiPrompt, false)
			requestUpdateSolvedBox:FireServer(boxName, nil)
		end
	end)
end
