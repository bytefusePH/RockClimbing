local players = game:GetService("Players")
local runService = game:GetService("RunService")
local replicatedStorage = game:GetService("ReplicatedStorage")
local serverRemotes = replicatedStorage:WaitForChild("ServerRemotes")
local VRCharacter = replicatedStorage:WaitForChild("VRCharacter")
local updatePlayerPositions = serverRemotes:WaitForChild("UpdatePlayerPositions")
local dummyCharacterFolder = game.Workspace:WaitForChild("PlayerFolder"):WaitForChild("DummyCharacters")
local characterFinishedLoading = serverRemotes:WaitForChild("CharacterFinishedLoading")
function CreateServerHand(player, hand)
	local serverHand = Instance.new("Part")
	serverHand.Size = Vector3.new(5, 5, 5)
	serverHand.Anchored = false
	serverHand.CanCollide = false
	serverHand.Name = "ServerHand"
	serverHand.Parent = hand
	local newAttachment = Instance.new("Attachment")
	newAttachment.Parent = serverHand
	local handAttachment = Instance.new("Attachment")
	handAttachment.Parent = hand
	local alignPosition = Instance.new("AlignPosition")
	alignPosition.Attachment0 = newAttachment
	alignPosition.Attachment1 = handAttachment
	alignPosition.RigidityEnabled = true
	alignPosition.Parent = hand
	Instance.new("Highlight", serverHand)
	serverHand.CFrame = hand.CFrame
	return serverHand
end
players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		local playerDescription = players:GetHumanoidDescriptionFromUserId(player.UserId)
		local humanoid = character:WaitForChild("Humanoid") :: Humanoid
		local humanoidDescription = humanoid:GetAppliedDescription()
		humanoidDescription.Torso = playerDescription.Torso
		humanoidDescription.Head = playerDescription.Head
		humanoidDescription.HeadColor = playerDescription.HeadColor
		humanoidDescription.TorsoColor = playerDescription.TorsoColor
		humanoidDescription.GraphicTShirt = playerDescription.GraphicTShirt
		humanoidDescription.Shirt = playerDescription.Shirt
		local humanoidAccessories = playerDescription:GetAccessories(true)
		humanoidDescription:SetAccessories(humanoidAccessories, true)
		local dummyCharacter = VRCharacter:Clone()
		dummyCharacter.Parent = dummyCharacterFolder
		dummyCharacter.Name = player.Name
		dummyCharacter["Humanoid"]:ApplyDescription(humanoidDescription)
		characterFinishedLoading:FireClient(player)
		for i, child in dummyCharacter:GetChildren() do
			if child:IsA("BasePart") and child ~= dummyCharacter.PrimaryPart then
				child.CollisionGroup = "Dummy"
			end
		end
		local vrModel = dummyCharacter:WaitForChild("VRModel")
		local leftOrigin = vrModel:WaitForChild("LeftOrigin")
		local rightOrigin = vrModel:WaitForChild("RightOrigin")
		local leftHandMesh = leftOrigin:WaitForChild("LeftHandMesh")
		local rightHandMesh = rightOrigin:WaitForChild("RightHandMesh")
		--leftOrigin:SetNetworkOwner(player)
		--rightOrigin:SetNetworkOwner(player)
		--leftHandMesh:SetNetworkOwner(player)
		--rightHandMesh:SetNetworkOwner(player)
		for i, child in vrModel:GetDescendants() do
			if child:IsA("BasePart") then
				local canSet = child:CanSetNetworkOwnership()
				if canSet == true then
					child:SetNetworkOwner(player)
				end
			end
		end
	end)
	player.CharacterRemoving:Connect(function(character)
		local dummyCharacter = dummyCharacterFolder:FindFirstChild(player.Name)
		if dummyCharacter then
			dummyCharacter:Destroy()
		end
	end)
end)
local lastUpdateTime = {}
local minUpdateInterval = 1/15
function UpdatePlayerVRPosition(player, listOfPositions, handVariants)
	local dummyCharacter = dummyCharacterFolder:FindFirstChild(player.Name)
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
-- updatePlayerPositions.OnServerEvent:Connect(function(player, listOfPositions, handVariants)
-- 	local currentTime = os.clock()
-- 	if lastUpdateTime[player.UserId] and (currentTime - lastUpdateTime[player.UserId] < minUpdateInterval) then
--         warn("Player " .. player.Name .. " is spamming UpdatePlayerPositions remote!")
--         return
--     end
-- 	lastUpdateTime[player.UserId] = currentTime
-- 	UpdatePlayerVRPosition(player, listOfPositions, handVariants)
-- end)