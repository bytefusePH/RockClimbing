local collectionService = game:GetService("CollectionService")
local userInputService = game:GetService("UserInputService")
local runService = game:GetService("RunService")
local vrService = game:GetService("VRService")
local replicatedStorage = game:GetService("ReplicatedStorage")
local players = game:GetService("Players")
local serverRemotes = replicatedStorage:WaitForChild("ServerRemotes")
local updatePlayerPositionsRemote = serverRemotes:WaitForChild("UpdatePlayerPositions")
local player = players.LocalPlayer
local camera = game.Workspace.Camera
local playerModule = require(player.PlayerScripts.playerModuleScript)
playerModule.InitializeModule(player)
local VRRenderStep = nil
local rightHandVariant = {}
local leftHandVariant = {}
local climbingHeartbeat = nil
local playerFolder = game.Workspace:WaitForChild("PlayerFolder")
local bodyVelocity = nil
local previousPositions = {cameraCFrame = CFrame.new(0, 0, 0), rightHandCFrame = CFrame.new(0, 0, 0), leftHandCFrame = CFrame.new(0, 0, 0), dummyCFrame = CFrame.new(0, 0, 0)}
local grabSound = game.ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Sounds"):WaitForChild("GrabSound")
local function SetInvisibility(part, invisible)
	part.Transparency = invisible == true and 1 or 0
	local isPermaInvisible = part:FindFirstChild("isPermaInvisible") or Instance.new("BoolValue")
	isPermaInvisible.Parent = part
	isPermaInvisible.Name = "isPermaInvisible"
	isPermaInvisible.Value = invisible
end
function SetCharacterInvisibility(boolean)
	if not playerModule.dummyCharacter then return end
	for _, part in playerModule.dummyCharacter:GetChildren() do
		if part ~= playerModule.dummyCharacter.PrimaryPart then
			if part:IsA("BasePart") then
				local isPermaInvisible = part:FindFirstChild("isPermaInvisible")
				if not isPermaInvisible or isPermaInvisible.Value == false then
					part.Transparency = boolean == true and 0.75 or 0
				end
			elseif part:IsA("Accessory") then
				local handle = part:FindFirstChild("Handle") or part:FindFirstChildOfClass("BasePart")
				if handle then
					local isPermaInvisible = handle:FindFirstChild("isPermaInvisible")
					if not isPermaInvisible or isPermaInvisible.Value == false then
						handle.Transparency = boolean == true and 0.75 or 0
					end
				end
			end
		end
	end
end
function UpdatePreviousPositions()
	previousPositions.cameraCFrame = camera:GetRenderCFrame()
	previousPositions.rightHandCFrame = playerModule.rightHand.model.CFrame
	previousPositions.leftHandCFrame = playerModule.leftHand.model.CFrame
	previousPositions.dummyCFrame = playerModule.dummyCharacter.PrimaryPart.CFrame
end
local rightHandPreviousCFrame = CFrame.new()
local leftHandPreviousCFrame = CFrame.new()
local rightHandLastUpdateTime = 0
local leftHandLastUpdateTime = 0
local rightHandVelocity = Vector3.new()
local leftHandVelocity = Vector3.new()
local function OnCharacterAdded(newCharacter: Model)
	local humanoidRootPart = newCharacter.PrimaryPart
	local humanoid = player.Character:WaitForChild("Humanoid") :: Humanoid
	local head = playerModule.dummyCharacter:WaitForChild("Head")
	local headPosition = (head.Position.Y - playerModule.dummyCharacter.PrimaryPart.Position.Y)
	humanoid:GetPropertyChangedSignal("FloorMaterial"):Connect(function()
		SetCharacterInvisibility(humanoid.FloorMaterial == Enum.Material.Air)
	end)
	local collidableHRP = Instance.new("Part")
	collidableHRP.Name = "CollidableHRP"
	collidableHRP.Parent = newCharacter.PrimaryPart
	collidableHRP.Size = Vector3.new(0.5, 0.5, 0.5)
	collidableHRP.Transparency = 1
	collidableHRP.CastShadow = false
	local HRPWeld = Instance.new("Weld")
	HRPWeld.Parent = newCharacter.PrimaryPart
	HRPWeld.C1 = CFrame.new(0, -headPosition, 0)
	HRPWeld.Part0 = newCharacter.PrimaryPart
	HRPWeld.Part1 = collidableHRP
	VRRenderStep = runService.RenderStepped:Connect(function(dt)
		if not HRPWeld.Part0 or not HRPWeld.Part1 then
			HRPWeld.Part0 = newCharacter.PrimaryPart
			HRPWeld.Part1 = collidableHRP
		end
		local cameraRenderCFrame = camera:GetRenderCFrame()
		local VRCameraPosition = cameraRenderCFrame.Position
		local _, cameraYaw = cameraRenderCFrame:ToOrientation()
		HRPWeld.C0 = HRPWeld.Part0.CFrame:ToObjectSpace(CFrame.new(
			cameraRenderCFrame.Position.X,
			playerModule.dummyCharacter.PrimaryPart.Position.Y,
			cameraRenderCFrame.Position.Z
			))
		playerModule.dummyCharacter.PrimaryPart.CFrame = CFrame.new(VRCameraPosition.X, VRCameraPosition.Y - headPosition, VRCameraPosition.Z) * CFrame.Angles(0, cameraYaw, 0) * CFrame.new(0, 0, 0.75)
		local rightHandTrack = vrService:GetUserCFrame(Enum.UserCFrame.RightHand)
		local leftHandTrack = vrService:GetUserCFrame(Enum.UserCFrame.LeftHand)
		if playerModule.VRModel and playerModule.VRModel.PrimaryPart then
			playerModule.VRModel.PrimaryPart.CFrame = camera.CFrame
		end
		if playerModule.rightHand and playerModule.rightHand.model then
			local currentRightHandCFrame = camera.CFrame * CFrame.new(rightHandTrack.Position * camera.HeadScale) * playerModule.handsOffset * CFrame.fromEulerAnglesXYZ(rightHandTrack:ToEulerAnglesXYZ())
			playerModule.rightHand.model.CFrame = camera.CFrame * CFrame.new(rightHandTrack.Position * camera.HeadScale) * playerModule.handsOffset * CFrame.fromEulerAnglesXYZ(rightHandTrack:ToEulerAnglesXYZ())
			local currentTime = os.clock()
			if rightHandLastUpdateTime ~= 0 and currentTime > rightHandLastUpdateTime then
				local deltaTime = currentTime - rightHandLastUpdateTime
				rightHandVelocity = (currentRightHandCFrame.Position - rightHandPreviousCFrame.Position) / deltaTime
			end
			rightHandPreviousCFrame = currentRightHandCFrame
			rightHandLastUpdateTime = currentTime
			if next(rightHandVariant) ~= nil then
				if rightHandVariant.model.Anchored == false then
					rightHandVariant.model.CFrame = playerModule.rightHand.model.CFrame * rightHandVariant.offset
				end
			end
		end
		if playerModule.leftHand and playerModule.leftHand.model then
			local currentLeftHandCFrame = camera.CFrame * CFrame.new(leftHandTrack.Position * camera.HeadScale) * playerModule.leftHandOffset * CFrame.fromEulerAnglesXYZ(leftHandTrack:ToEulerAnglesXYZ())
			playerModule.leftHand.model.CFrame = currentLeftHandCFrame
			local currentTime = os.clock()
			if leftHandLastUpdateTime ~= 0 and currentTime > leftHandLastUpdateTime then
				local deltaTime = currentTime - leftHandLastUpdateTime
				leftHandVelocity = (currentLeftHandCFrame.Position - leftHandPreviousCFrame.Position) / deltaTime
			end
			leftHandPreviousCFrame = currentLeftHandCFrame
			leftHandLastUpdateTime = currentTime
			if next(leftHandVariant) ~= nil then
				if leftHandVariant.model.Anchored == false then
					leftHandVariant.model.CFrame = playerModule.leftHand.model.CFrame * leftHandVariant.offset
				end
			end
		end
		if playerModule.VRVectorsChanged(previousPositions) == true then
			UpdatePreviousPositions()
			updatePlayerPositionsRemote:FireServer(previousPositions)
		end
	end)
	bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.Parent = newCharacter.PrimaryPart
	bodyVelocity.MaxForce = Vector3.new(0, 0, 0)
	bodyVelocity.Velocity = Vector3.new(0, 0, 0)
	UpdatePreviousPositions()
	humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
	task.wait(1)
	for _, part in playerModule.dummyCharacter:GetChildren() do
		local loweredName = string.lower(part.Name)
		if part:IsA("MeshPart") or part:IsA("Part") then
			if string.find(loweredName, "head") then
				part:Destroy()
			elseif string.find(loweredName, "foot") or string.find(loweredName, "leg") then
				SetInvisibility(part, true)
			end
		elseif part:IsA("Accessory") then
			if part.AccessoryType == Enum.AccessoryType.Hat or part.AccessoryType == Enum.AccessoryType.Face or part.AccessoryType == Enum.AccessoryType.Eyebrow or part.AccessoryType == Enum.AccessoryType.Eyelash or part.AccessoryType == Enum.AccessoryType.Hair then
				local handle = part:FindFirstChildOfClass("Part") or part:FindFirstChildOfClass("MeshPart")
				if handle then handle:Destroy() end
			end 
		end
	end
end
OnCharacterAdded(player.Character)
player.CharacterAdded:Connect(function(character)
	OnCharacterAdded(character)
end)
local preObjectsToFilter = {game.Workspace:WaitForChild("Baseplate"), game.Workspace:WaitForChild("SpawnLocation"), player.Character}
function OnHandClimb(hand: table, part: Instance)
	if not player.Character or not player.Character.PrimaryPart then return end

	local climableFolder = part:FindFirstAncestor("Climable")
	local climable = part:FindFirstChild("Climable")
	if (climableFolder and climableFolder:IsA("Folder") and climableFolder.Name == "Climable") and (not climable or climable.Value == true) then
		if hand.currentVariant == "Closed" then
			local variant = playerModule.FindHandVariant(hand.model, hand.isRight, "Closed")
			variant.CFrame = variant.CFrame * CFrame.Angles(0, math.rad(-180), 0)
			variant.Anchored = true
			local handHighlight = Instance.new("Highlight")
			handHighlight.Name = "HandHighlight"
			handHighlight.FillTransparency = 1
			handHighlight.OutlineColor = Color3.new(1, 1, 0)
			handHighlight.Parent = variant
		end
		local grabSoundClone = grabSound:Clone()
		grabSoundClone.Parent = hand.model
		grabSoundClone:Play()
		local otherHand = hand.isRight and playerModule.leftHand or playerModule.rightHand
		local startingClimb = not playerModule.IsClimbing()
		local weld = hand.model:FindFirstChildOfClass("Weld")
		if weld then
			weld.Part1.Anchored = true
			weld.Enabled = false
		end
		hand.initialGrabPosition = hand.model.Position
		hand.initialPartPosition = part.Position
		hand.grabOffset = part.CFrame:ToObjectSpace(hand.model.CFrame).Position
		hand.isClimbing = true
		hand.climbingOn = part
		if otherHand.isClimbing then
			hand.initialGrabPosition = hand.model.Position
			otherHand.initialGrabPosition = otherHand.model.Position
		end
		if not climbingHeartbeat then
			player.Character.PrimaryPart["CollidableHRP"].CanCollide = false
			local radiusParameters = OverlapParams.new()
			local objectsToFilter = preObjectsToFilter
			for _, localPlayer in players:GetPlayers() do
				table.insert(objectsToFilter, localPlayer.Character)
				table.insert(objectsToFilter, playerFolder["DummyCharacters"]:FindFirstChild(localPlayer.Character.Name))
			end
			radiusParameters.FilterDescendantsInstances = objectsToFilter
			radiusParameters.FilterType = Enum.RaycastFilterType.Exclude
			local partsInRadius = game.Workspace:GetPartBoundsInRadius(playerModule.dummyCharacter.PrimaryPart.CFrame.Position, 10, radiusParameters)
			SetCharacterInvisibility(true)
			bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
			climbingHeartbeat = runService.Heartbeat:Connect(function(dt)
				if not player.Character or not player.Character.PrimaryPart then
					if playerModule.leftHand.isClimbing == true then OnHandLetGo(playerModule.leftHand) end
					if playerModule.rightHand.isClimbing == true then OnHandLetGo(playerModule.rightHand) end
					return
				end
				--if grabRenderStep ~= nil then grabRenderStep:Disconnect() end
				local leftClimbing = (playerModule.leftHand.isClimbing and playerModule.leftHand.climbingOn ~= nil)
				local rightClimbing = (playerModule.rightHand.isClimbing and playerModule.rightHand.climbingOn ~= nil)
				if (not playerModule.leftHand or not playerModule.rightHand) or (playerModule.leftHand.isClimbing == false and playerModule.rightHand.isClimbing == false) then
					if climbingHeartbeat then
						climbingHeartbeat:Disconnect()
						climbingHeartbeat = nil
					end
					return
				end
				local movementVector = Vector3.new(0, 0, 0)
				local activeHand = nil
				local isRight = (rightClimbing == true and leftClimbing == false)
				if leftClimbing == true and rightClimbing == true then
					local targetPositionLeft = playerModule.leftHand.climbingOn.CFrame:ToWorldSpace(CFrame.new(playerModule.leftHand.grabOffset)).Position
					local targetPositionRight = playerModule.rightHand.climbingOn.CFrame:ToWorldSpace(CFrame.new(playerModule.rightHand.grabOffset)).Position
					leftHandVariant.model.Position = targetPositionLeft
					rightHandVariant.model.Position = targetPositionRight
					movementVector = ((playerModule.leftHand.model.Position - targetPositionLeft) + (playerModule.rightHand.model.Position - targetPositionRight)) / 2 * 0.8
				elseif leftClimbing == true or rightClimbing == true then
					activeHand = isRight == true and playerModule.rightHand or playerModule.leftHand
					local handVariant = isRight == true and rightHandVariant or leftHandVariant
					local targetPosition = activeHand.climbingOn.CFrame:ToWorldSpace(CFrame.new(activeHand.grabOffset)).Position
					handVariant.model.Position = targetPosition
					movementVector = (activeHand.model.Position - targetPosition) * 0.8
				else
					return
				end
				if movementVector.Magnitude > 0.01 then
					player.Character.PrimaryPart.CFrame = player.Character.PrimaryPart.CFrame:Lerp(player.Character.PrimaryPart.CFrame - movementVector, 0.5)
				end
			end)
		end
	end
end
local grabRenderStep = nil
local letGoParams = OverlapParams.new()
letGoParams.FilterDescendantsInstances = {player.Character}
letGoParams.FilterType = Enum.RaycastFilterType.Exclude
function OnHandLetGo(hand: table)
	if not hand.isClimbing then return end
	local otherHand = hand.isRight and playerModule.leftHand or playerModule.rightHand
	local wasTwoHandClimbing = hand.isClimbing and otherHand.isClimbing
	hand.isClimbing = false
	hand.climbingOn = nil
	hand.initialGrabPosition = nil
	hand.initialPartPosition = nil
	local weld = hand.model:FindFirstChildOfClass("Weld")
	if weld then
		weld.Part1.Anchored = false
		weld.Part1.Parent = hand.model["HandVariants"]
		weld.Enabled = true
	end
	if hand.isClimbing == false and otherHand.isClimbing == false then
		if climbingHeartbeat then
			player.Character.PrimaryPart["CollidableHRP"].CanCollide = true
			climbingHeartbeat:Disconnect()
			climbingHeartbeat = nil
		end
		local partsInRadius = game.Workspace:GetPartBoundsInRadius(player.Character.PrimaryPart.Position, 5, letGoParams)
		local groundObjectNear = false
		for _, part in partsInRadius do
			if part.Parent:IsA("Folder") == false and part.Parent.Name ~= "Climable" then
				groundObjectNear = true
				break
			end
		end
		SetCharacterInvisibility(false)
		bodyVelocity.Velocity = Vector3.new(0, 0, 0)
		bodyVelocity.MaxForce = Vector3.new(0, 0, 0)
	end
end
local grabObjectRemote = serverRemotes:WaitForChild("GrabObject")
local mouse = player:GetMouse()
userInputService.InputBegan:Connect(function(input, gameProcessedEvent)
	if gameProcessedEvent == true then return end
	local isHand, isRight = playerModule.IsHandInput(input)
	if isHand then
		local hand = isRight and playerModule.rightHand or playerModule.leftHand
		if not hand or not hand.model then warn("Hand model not ready") return end
		grabObjectRemote:FireServer(isRight, "Grab")
		if hand.isRight == true then
			rightHandVariant = playerModule.ChangeHandVariant(hand, hand.isRight, "Closed")
			if rightHandVariant.model then
				rightHandVariant.model.Anchored = false
			end
		else
			leftHandVariant = playerModule.ChangeHandVariant(hand, hand.isRight, "Closed")
			if leftHandVariant.model then
				leftHandVariant.model.Anchored = false
			end
		end
		local params = OverlapParams.new()
		params.FilterDescendantsInstances = {player.Character, playerModule.dummyCharacter}
		params.FilterType = Enum.RaycastFilterType.Exclude
		local partsInRadius = game.Workspace:GetPartBoundsInRadius(hand.model.Position, 0.2, params)
		for _, part in partsInRadius do
			if part:IsA("BasePart") then
				OnHandClimb(hand, part)
				if hand.isClimbing then
					break
				end
			end
		end
	end
end)
local rotatingCameraHeartbeat = nil
userInputService.InputEnded:Connect(function(input, gameProcessedEvent)
	local isHand, isRight = playerModule.IsHandInput(input)
	if isHand == true then
		local hand = isRight == true and playerModule.rightHand or playerModule.leftHand
		if hand then
			OnHandLetGo(hand)
			if hand.model:FindFirstChild("GrabWeldConstraint") then
				grabObjectRemote:FireServer(isRight, "Release")
			end
			if hand.currentVariant == "Idle" then return end
			local _, prevVariant = playerModule.ChangeHandVariant(hand, isRight, "Idle")
			local handHighlight = prevVariant:FindFirstChild("HandHighlight")
			if handHighlight then
				handHighlight:Destroy()
			end
			prevVariant.Anchored = true
			if isRight == true then				
				rightHandVariant = {}
			else
				leftHandVariant = {}
			end
		end
	end
	-- if input.KeyCode == Enum.KeyCode.Thumbstick2 then
	-- 	playerModule.rotatingCamera = false
	-- 	if rotatingCameraHeartbeat then
	-- 		rotatingCameraHeartbeat:Disconnect()
	-- 	end
	-- end
end)
-- userInputService.InputChanged:Connect(function(input, gameProcessedEvent)
-- 	if gameProcessedEvent == true then return end
-- 	if input.KeyCode == Enum.KeyCode.Thumbstick2 then
-- 		if playerModule.rotatingCamera == true or input.Position.X == 0 then return end
-- 		if rotatingCameraHeartbeat then
-- 			rotatingCameraHeartbeat:Disconnect()
-- 		end
-- 		print(input.Position.X)
-- 		local right = (input.Position.X > 0)
-- 		playerModule.TurnCamera(right)
-- 		player.Character.PrimaryPart.CFrame = CFrame.new(camera.CFrame.Position.X, player.Character.PrimaryPart.Position.Y, camera.CFrame.Position.Z)
-- 		playerModule.rotatingCamera = true
-- 		local holdTime = 0
-- 		local currentTime = 0
-- 		rotatingCameraHeartbeat = runService.Heartbeat:Connect(function(dt)
-- 			if holdTime >= 0.25 then
-- 				if currentTime < 1 then
-- 					currentTime += dt
-- 				else
-- 					playerModule.TurnCamera(right)
-- 					player.Character.PrimaryPart.CFrame = CFrame.new(camera.CFrame.Position.X, player.Character.PrimaryPart.Position.Y, camera.CFrame.Position.Z)
-- 					currentTime = 0
-- 				end
-- 			else
-- 				holdTime += dt
-- 			end
-- 		end)
-- 	end
-- end)