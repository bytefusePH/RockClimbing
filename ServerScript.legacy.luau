local players = game:GetService("Players")
local runService = game:GetService("RunService")
local replicatedStorage = game:GetService("ReplicatedStorage")
local serverRemotes = replicatedStorage:WaitForChild("ServerRemotes")
local VRModel = replicatedStorage:WaitForChild("VRModel")
local updatePlayerPositions = serverRemotes:WaitForChild("UpdatePlayerPositions")
local dummyCharacterFolder = game.Workspace:WaitForChild("PlayerFolder"):WaitForChild("DummyCharacters")
players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		local humanoid = character:WaitForChild("Humanoid") :: Humanoid
		local heightScale = humanoid:FindFirstChild("BodyHeightScale")
		local widthScale = humanoid:FindFirstChild("BodyWidthScale")
		local depthScale = humanoid:FindFirstChild("BodyDepthScale")
		if heightScale then
			heightScale.Value = 1.2
		end
		if widthScale then
			widthScale.Value = 0.7
		end
		if depthScale then
			depthScale.Value = 0.7
		end
		humanoid.HipHeight = 4.25
		humanoid.RequiresNeck = false
		character.Archivable = true
		character.PrimaryPart.CanCollide = false
		local clonedCharacter = character:Clone()
		clonedCharacter.Parent = game.Workspace.PlayerFolder.DummyCharacters
		clonedCharacter.PrimaryPart.Anchored = true
		clonedCharacter.PrimaryPart.CFrame = CFrame.new(0, 10, 0)
		clonedCharacter["Health"]:Destroy()
		clonedCharacter["VRLocalScript"]:Destroy()
		for _, part in clonedCharacter:GetChildren() do
			local loweredName = string.lower(part.Name)
			if part:IsA("MeshPart") or part:IsA("Part") then
				if string.find(loweredName, "hand") or string.find(loweredName, "arm") then
					part:Destroy()
				elseif string.find(loweredName, "foot") or string.find(loweredName, "leg") then
					part.Transparency = 1
				end
				if part then
					part.Massless = true
					part.CollisionGroup = "Dummy"
				end
			elseif part:IsA("Part") or part:IsA("MeshPart") then
				part.Massless = true
				part.CollisionGroup = "Dummy"
			elseif part:IsA("Accessory") and (part.AccessoryType == Enum.AccessoryType.Jacket) then
				local handle = part:FindFirstChildOfClass("Part") or part:FindFirstChildOfClass("MeshPart")
				if handle then handle:Destroy() end
			end
		end
		for _, part in character:GetChildren() do
			if (part:IsA("Part") or part:IsA("BasePart")) and part ~= character.PrimaryPart then
				part:Destroy()
			end
		end
		local clonedVRModel = VRModel:Clone()
		clonedVRModel.Parent = clonedCharacter
		character.Archivable = false
	end)
	player.CharacterRemoving:Connect(function(character)
		local dummyCharacter = dummyCharacterFolder:FindFirstChild(player.Name)
		dummyCharacter.Archivable = true
		if dummyCharacter then
			dummyCharacter:Destroy()
		end
	end)
end)
function UpdatePlayerVRPosition(player, listOfPositions, handVariants)
	local dummyCharacter = dummyCharacterFolder:FindFirstChild(player.Character.Name)
	if dummyCharacter then
		local vrModel = dummyCharacter:FindFirstChild("VRModel")
		if not vrModel then return end
		dummyCharacter.PrimaryPart.CFrame = listOfPositions.dummyCFrame
		local rightHand = vrModel["RightOrigin"]
		local leftHand = vrModel["LeftOrigin"]
		rightHand.CFrame = listOfPositions.rightHandCFrame
		leftHand.CFrame = listOfPositions.leftHandCFrame
		local neckMotor = dummyCharacter["Head"]["Neck"] :: Motor6D
		local cameraRotationX = listOfPositions.cameraCFrame:ToEulerAnglesXYZ()
		neckMotor.C0 = CFrame.new(neckMotor.C0.Position) * CFrame.Angles(cameraRotationX, 0, 0)
	end
end
updatePlayerPositions.OnServerEvent:Connect(function(player, listOfPositions, handVariants)
	UpdatePlayerVRPosition(player, listOfPositions, handVariants)
end)