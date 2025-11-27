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
camera.CameraType = Enum.CameraType.Scriptable
camera.CFrame = CFrame.new(0, 20, 0)
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
function SetPartInvisibility(part, boolean)
	local isPermaInvisible = part:FindFirstChild("isPermaInvisible")
	if not isPermaInvisible or isPermaInvisible.Value == false then
		part.Transparency = boolean == true and 0.75 or 0
	end
end
function SetCharacterInvisibility(boolean)
	if not playerModule.dummyCharacter then return end
	for _, part in playerModule.dummyCharacter:GetChildren() do
		if part ~= playerModule.dummyCharacter.PrimaryPart then
			if part:IsA("BasePart") then
				SetPartInvisibility(part, boolean)
			elseif part:IsA("Accessory") then
				local handle = part:FindFirstChild("Handle") or part:FindFirstChildOfClass("BasePart")
				if handle then
					SetPartInvisibility(handle, boolean)
				end
			end
		end
	end
end
function UpdatePreviousPositions()
	previousPositions.cameraCFrame = camera:GetRenderCFrame()
	previousPositions.rightHandCFrame = playerModule.rightHand.origin.CFrame
	previousPositions.leftHandCFrame = playerModule.leftHand.origin.CFrame
	previousPositions.dummyCFrame = playerModule.dummyCharacter.PrimaryPart.CFrame
end
local radiusParameters = OverlapParams.new()
radiusParameters.FilterType = Enum.RaycastFilterType.Include
radiusParameters.FilterDescendantsInstances = {game.Workspace:WaitForChild("Climbable"), game.Workspace:WaitForChild("Grabbable")}
-- radiusParameters.FilterType = Enum.RaycastFilterType.Exclude
-- radiusParameters.FilterDescendantsInstances = {game.Workspace:WaitForChild("Baseplate"), game.Workspace:WaitForChild("SpawnLocation"), player.Character}
-- local dummyCharacterFolder = game.Workspace:WaitForChild("PlayerFolder"):WaitForChild("DummyCharacters")
-- players.PlayerAdded:Connect(function(newPlayer)
-- 	newPlayer.CharacterAdded:Connect(function(newCharacter)
-- 		local dummyCharacter = dummyCharacterFolder:WaitForChild(newPlayer.Name)
-- 		local dummyIndex = table.find(radiusParameters.FilterDescendantsInstances, dummyCharacter)
-- 		local characterIndex = table.find(radiusParameters.FilterDescendantsInstances, newPlayer.Character)
-- 		table.insert(radiusParameters.FilterDescendantsInstances, dummyCharacter)
-- 		table.insert(radiusParameters.FilterDescendantsInstances, newPlayer.Character)
-- 	end)
-- 	newPlayer.CharacterRemoving:Connect(function(newCharacter)
-- 		local dummyCharacter = dummyCharacterFolder:FindFirstChild(newPlayer.Name)
-- 		local dummyIndex = table.find(radiusParameters.FilterDescendantsInstances, dummyCharacter)
-- 		local characterIndex = table.find(radiusParameters.FilterDescendantsInstances, newPlayer.Character)
-- 		if dummyIndex then
-- 			table.remove(radiusParameters.FilterDescendantsInstances, dummyIndex)
-- 		end
-- 		if characterIndex then
-- 			table.remove(radiusParameters.FilterDescendantsInstances, characterIndex)
-- 		end
-- 	end)
-- end)
local headAccessoryTypes = {[Enum.AccessoryType.Hair] = true, [Enum.AccessoryType.Hat] = true, [Enum.AccessoryType.Face] = true}
-- local playerModule.rightHand.prevCFrame = CFrame.new(0, 0, 0)
local rightHandVelocity = Vector3.new()
-- local playerModule.leftHand.prevCFrame = CFrame.new(0, 0, 0)
local leftHandVelocity = Vector3.new()
local lastVelocityUpdated = 0
local function OnCharacterAdded(newCharacter: Model)
	playerModule.OnCharacterAdded(newCharacter)
	local humanoidRootPart = newCharacter.PrimaryPart
	local humanoid = player.Character:WaitForChild("Humanoid") :: Humanoid
	local head = playerModule.dummyCharacter:WaitForChild("Head")
	local neck = head:WaitForChild("Neck")
	local headPosition = (head.Position.Y - playerModule.dummyCharacter.PrimaryPart.Position.Y)
	head.Transparency = 1
	local worldCFrame = CFrame.new(Vector3.new(game.Workspace.SpawnLocation.Position.X, headPosition, game.Workspace.SpawnLocation.Position.Z))
	humanoid:GetPropertyChangedSignal("FloorMaterial"):Connect(function()
		SetCharacterInvisibility(humanoid.FloorMaterial == Enum.Material.Air and climbingHeartbeat == nil)
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
		camera.CFrame = CFrame.new(newCharacter.PrimaryPart.Position + Vector3.new(0, headPosition, 0)) * CFrame.Angles(0, playerModule.cameraRotation, 0)
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
		if playerModule.rightHand and playerModule.rightHand.origin then
			--playerModule.rightHand.origin.CFrame = camera.CFrame * CFrame.new(rightHandTrack.Position * headPosition) * playerModule.handsOffset * CFrame.fromEulerAnglesXYZ(rightHandTrack:ToEulerAnglesXYZ())
			playerModule.rightHand.anchoredHand.CFrame = camera.CFrame * CFrame.new(rightHandTrack.Position * headPosition) * playerModule.handsOffset * CFrame.fromEulerAnglesXYZ(rightHandTrack:ToEulerAnglesXYZ())
			-- playerModule.rightHand.origin.CFrame = playerModule.AlignHandMovement(Enum.UserCFrame.RightHand, worldCenter, game.Workspace.CurrentCamera.HeadScale)
			if playerModule.rightHand.mesh and playerModule.rightHand.isClimbing == false then
				--playerModule.rightHand.mesh.CFrame = playerModule.rightHand.origin.CFrame * CFrame.Angles(0, -180, 0)
				playerModule.rightHand.mesh.CFrame = playerModule.rightHand.anchoredHand.CFrame * CFrame.Angles(math.rad(-15), math.rad(-205), 0)
			end
			if next(rightHandVariant) ~= nil then
				if rightHandVariant.origin.Anchored == false then
					rightHandVariant.origin.CFrame = playerModule.rightHand.origin.CFrame * rightHandVariant.offset
				end
			end
		end
		if playerModule.leftHand and playerModule.leftHand.origin then
			playerModule.leftHand.anchoredHand.CFrame = camera.CFrame * CFrame.new(leftHandTrack.Position * headPosition) * playerModule.leftHandOffset * CFrame.fromEulerAnglesXYZ(leftHandTrack:ToEulerAnglesXYZ())
			-- playerModule.leftHand.origin.CFrame = camera.CFrame:ToWorldSpace(leftHandTrack)
			-- playerModule.leftHand.origin.CFrame = playerModule.AlignHandMovement(Enum.UserCFrame.LeftHand, worldCenter, game.Workspace.currentCamera.HeadScale)
			if playerModule.leftHand.mesh and playerModule.leftHand.isClimbing == false then
				--playerModule.leftHand.mesh.CFrame = playerModule.leftHand.origin.CFrame * CFrame.Angles(0, 180, 0)
				playerModule.leftHand.mesh.CFrame = playerModule.leftHand.anchoredHand.CFrame * CFrame.Angles(math.rad(-15), math.rad(205), 0)
			end
			if next(leftHandVariant) ~= nil then
				if leftHandVariant.origin.Anchored == false then
					leftHandVariant.origin.CFrame = playerModule.leftHand.origin.CFrame * leftHandVariant.offset
				end
			end
		end
		-- if playerModule.VRVectorsChanged(previousPositions) == true then
		-- 	UpdatePreviousPositions()
		-- 	updatePlayerPositionsRemote:FireServer(previousPositions)
		-- end
		lastVelocityUpdated += dt
		if playerModule.rightHand and playerModule.rightHand.origin and playerModule.leftHand and playerModule.leftHand.origin then
			if playerModule.rightHand.prevCFrame ~= CFrame.new() and playerModule.leftHand.prevCFrame ~= CFrame.new() and dt > 0 then
				rightHandVelocity = (playerModule.rightHand.origin.CFrame.Position - playerModule.rightHand.prevCFrame.Position) / dt
				leftHandVelocity = (playerModule.leftHand.origin.CFrame.Position - playerModule.leftHand.prevCFrame.Position) / dt
				lastVelocityUpdated = 0
			end
			playerModule.rightHand.prevCFrame = playerModule.rightHand.origin.CFrame
			playerModule.leftHand.prevCFrame = playerModule.leftHand.origin.CFrame
		end
	end)
	bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.Parent = newCharacter.PrimaryPart
	bodyVelocity.MaxForce = Vector3.new(0, 0, 0)
	bodyVelocity.Velocity = Vector3.new(0, 0, 0)
	--UpdatePreviousPositions()
	humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
	for i, part in playerModule.dummyCharacter:GetChildren() do
		if part:IsA("Accessory") and headAccessoryTypes[part.AccessoryType] == true then
			part:Destroy()
		end
	end
end
local characterFinishedLoading = serverRemotes:WaitForChild("CharacterFinishedLoading")
characterFinishedLoading.OnClientEvent:Connect(function()
	OnCharacterAdded(player.Character)
end)
local preObjectsToFilter = {game.Workspace:WaitForChild("Baseplate"), game.Workspace:WaitForChild("SpawnLocation"), player.Character}
local previousMovementVector = Vector3.new(0, 0, 0)
local lastMovementUpdate = 0
local function PlayHandSound(parent)
	local grabSoundClone = grabSound:Clone()
	grabSoundClone.Parent = parent
	grabSoundClone:Play()
	return grabSoundClone
end
function AddHighlight(parent, adornee)
	local highlight = Instance.new("Highlight")
	highlight.Name = "HandHighlight"
	highlight.FillTransparency = 1
	highlight.OutlineColor = Color3.new(1, 1, 0)
	highlight.Parent = parent
	highlight.Adornee = adornee
	return highlight
end
function OnHandClimb(hand, part: Instance)
	if hand.currentVariant == "Closed" then
		--local variant = playerModule.FindHandVariant(hand.origin, hand.isRight, "Closed")
		--variant.CFrame = variant.CFrame * CFrame.Angles(0, math.rad(-180), 0)
		--variant.Anchored = true
	end
	AddHighlight(hand.origin, hand.mesh)
	PlayHandSound(hand.origin)
	local otherHand = hand.isRight and playerModule.leftHand or playerModule.rightHand
	local startingClimb = not playerModule.IsClimbing()
	-- local weld = hand.origin:FindFirstChildOfClass("Weld")
	-- if weld then
	-- 	weld.Part1.Anchored = true
	-- 	weld.Enabled = false
	-- end
	hand.initialGrabPosition = hand.origin.Position
	hand.initialPartPosition = part.Position
	hand.grabOffset = part.CFrame:ToObjectSpace(hand.prevCFrame).Position
	hand.isClimbing = true
	hand.climbingOn = part
	if otherHand.isClimbing then
		hand.initialGrabPosition = hand.origin.Position
		otherHand.initialGrabPosition = otherHand.origin.Position
	end
	hand.mesh.CFrame = hand.anchoredHand.CFrame * CFrame.Angles(math.rad(-15), math.rad(-180), 0)
	if not climbingHeartbeat then
		player.Character.PrimaryPart["CollidableHRP"].CanCollide = false
		SetCharacterInvisibility(true)
		bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
		climbingHeartbeat = runService.Heartbeat:Connect(function(dt)
			if not player.Character or not player.Character.PrimaryPart then
				if playerModule.leftHand.isClimbing == true then OnHandLetGo(playerModule.leftHand) end
				if playerModule.rightHand.isClimbing == true then OnHandLetGo(playerModule.rightHand) end
				return
			end
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
				-- leftHandVariant.origin.Position = targetPositionLeft
				-- rightHandVariant.origin.Position = targetPositionRight
				--playerModule.leftHand.mesh.CFrame = CFrame.new(targetPositionLeft) * playerModule.leftHand.mesh.CFrame.Rotation
				--playerModule.rightHand.mesh.CFrame = CFrame.new(targetPositionRight) * playerModule.rightHand.mesh.CFrame.Rotation
				movementVector = ((playerModule.leftHand.prevCFrame.Position - targetPositionLeft) + (playerModule.rightHand.prevCFrame.Position - targetPositionRight)) / 2 * 0.8
			elseif leftClimbing == true or rightClimbing == true then
				activeHand = isRight == true and playerModule.rightHand or playerModule.leftHand
				local handVariant = isRight == true and rightHandVariant or leftHandVariant
				local targetPosition = activeHand.climbingOn.CFrame:ToWorldSpace(CFrame.new(activeHand.grabOffset)).Position
				-- handVariant.origin.Position = targetPosition
				--activeHand.mesh.CFrame = handInitialCFrame
				movementVector = (activeHand.prevCFrame.Position - targetPosition) * 0.8
			else
				return
			end
			lastMovementUpdate -= dt
			if movementVector.Magnitude > 0.01 then
				player.Character.PrimaryPart.CFrame = player.Character.PrimaryPart.CFrame:Lerp(player.Character.PrimaryPart.CFrame - movementVector, 0.5)
				if lastMovementUpdate <= 0 then
					previousMovementVector = movementVector
					lastMovementUpdate = 0
				end
			end
		end)
	end
end
local grabRenderStep = nil
local letGoParams = OverlapParams.new()
letGoParams.FilterDescendantsInstances = {player.Character}
letGoParams.FilterType = Enum.RaycastFilterType.Exclude
function OnHandLetGo(hand)
	if not hand.isClimbing then return end
	local otherHand = hand.isRight and playerModule.leftHand or playerModule.rightHand
	local wasTwoHandClimbing = hand.isClimbing and otherHand.isClimbing
	hand.isClimbing = false
	hand.climbingOn = nil
	hand.initialGrabPosition = nil
	hand.initialPartPosition = nil
	local weld = hand.origin:FindFirstChildOfClass("Weld")
	--if weld then
	--	weld.Part1.Anchored = false
	--	weld.Part1.Parent = hand.origin["HandVariants"]
	--	weld.Enabled = true
	--end
	if hand.isClimbing == false and otherHand.isClimbing == false then
		if climbingHeartbeat then
			player.Character.PrimaryPart["CollidableHRP"].CanCollide = true
			climbingHeartbeat:Disconnect()
			climbingHeartbeat = nil
		end
		local partsInRadius = game.Workspace:GetPartBoundsInRadius(player.Character.PrimaryPart.Position, 5, radiusParameters)
		local groundObjectNear = false
		for _, part in partsInRadius do
			if part.Parent:IsA("Folder") == false and part.Parent.Name ~= "Climbable" then
				groundObjectNear = true
				break
			end
		end
		SetCharacterInvisibility(false)
		bodyVelocity.Velocity = Vector3.new(0, 0, 0)
		bodyVelocity.MaxForce = Vector3.new(0, 0, 0)
		player.Character.PrimaryPart:ApplyImpulse(-previousMovementVector * 250)
	end
end
local grabObjectRemote = serverRemotes:WaitForChild("GrabObject")
local mouse = player:GetMouse()
userInputService.InputBegan:Connect(function(input, gameProcessedEvent)
	if gameProcessedEvent == true then return end
	local isHand, isRight = playerModule.IsHandInput(input)
	if isHand then
		local hand = isRight == true and playerModule.rightHand or playerModule.leftHand
		local otherHand = isRight == true and playerModule.leftHand or playerModule.rightHand
		if not hand or not hand.origin then warn("Hand model not ready") return end
		playerModule.ChangeHandMesh(hand, "Closed")
		if hand.isRight == true then
			-- rightHandVariant = playerModule.ChangeHandVariant(hand, hand.isRight, "Closed")
			-- if rightHandVariant.origin then
			-- 	rightHandVariant.origin.Anchored = false
			-- end
		else
			-- leftHandVariant = playerModule.ChangeHandVariant(hand, hand.isRight, "Closed")
			-- if leftHandVariant.origin then
			-- 	leftHandVariant.origin.Anchored = false
			-- end
		end
		local partsInRadius = game.Workspace:GetPartBoundsInRadius(isRight == true and playerModule.rightHand.prevCFrame.Position or playerModule.leftHand.prevCFrame.Position, 0.4, radiusParameters)
		for _, part in partsInRadius do
			if part:IsA("BasePart") then
				local parentedFolder = part:FindFirstAncestor("Climbable") or part:FindFirstAncestor("Grabbable")
				if parentedFolder then
					if parentedFolder.Name == "Climbable" then
						local climbable = part:FindFirstChild("Climbable")
						if (parentedFolder and parentedFolder:IsA("Folder") and parentedFolder.Name == "Climbable") and (not climbable or climbable.Value == true) then
							OnHandClimb(hand, part)
							if hand.isClimbing then
								break
							end
						end
					elseif parentedFolder.Name == "Grabbable" then
						hand.grabbingOn = part
						grabObjectRemote:FireServer(isRight, "Grab", part, otherHand.grabbingOn)
						local weldConstraint = Instance.new("WeldConstraint")
						weldConstraint.Part0 = hand.origin
						weldConstraint.Part1 = part
						weldConstraint.Parent = hand.origin
						hand.grabLastPosition = hand.grabbingOn.Position
						runService:BindToRenderStep("VelocityCalculate" .. (isRight == true and "Right" or "Left"), Enum.RenderPriority.Input.Value, function(dt)
							if not hand.grabbingOn.Position then return end
							hand.grabVelocity = (hand.grabbingOn.Position - hand.grabLastPosition) / dt
							hand.grabLastPosition = hand.grabbingOn.Position
						end)
						PlayHandSound(hand.origin)
						AddHighlight(hand.origin, hand.mesh)
						break
					end
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
		local otherHand = isRight == true and playerModule.leftHand or playerModule.rightHand
		if hand then
			local highlight = hand.origin:FindFirstChild("HandHighlight")
			if highlight then highlight:Destroy() end
			playerModule.ChangeHandMesh(hand, "Idle")
			OnHandLetGo(hand)
			if hand.grabbingOn then
				local grabWeldConstraint = hand.origin:FindFirstChild("WeldConstraint")
				if grabWeldConstraint then grabWeldConstraint:Destroy() end
				local grabbedPart = hand.grabbingOn
				hand.grabbingOn.Velocity = hand.grabVelocity
				hand.grabVelocity = nil
				runService:UnbindFromRenderStep("VelocityCalculate" .. (isRight == true and "Right" or "Left"))
				hand.grabbingOn = nil
				grabObjectRemote:FireServer(isRight, (otherHand.grabbingOn == nil or (otherHand.grabbingOn ~= grabbedPart and otherHand.grabbingOn.Parent ~= grabbedPart.Parent)) and "Release" or "LetGo", grabbedPart, otherHand.grabbingOn)
			end
			--if hand.currentVariant == "Idle" then return end
			-- local _, prevVariant = playerModule.ChangeHandVariant(hand, isRight, "Idle")
			--local handHighlight = prevVariant:FindFirstChild("HandHighlight")
			--if handHighlight then
			--	handHighlight:Destroy()
			--end
			--prevVariant.Anchored = true
			--if isRight == true then				
			--	rightHandVariant = {}
			--else
			--	leftHandVariant = {}
			--end
		end
	end
	if input.KeyCode == Enum.KeyCode.Thumbstick2 then
		playerModule.rotatingCamera = false
		if rotatingCameraHeartbeat then
			rotatingCameraHeartbeat:Disconnect()
		end
	end
end)
 userInputService.InputChanged:Connect(function(input, gameProcessedEvent)
 	if gameProcessedEvent == true then return end
 	if input.KeyCode == Enum.KeyCode.Thumbstick2 then
 		if playerModule.rotatingCamera == true or input.Position.X == 0 then return end
 		if rotatingCameraHeartbeat then
 			rotatingCameraHeartbeat:Disconnect()
 		end
 		local right = (input.Position.X > 0)
 		playerModule.TurnCamera(right)
 		player.Character.PrimaryPart.CFrame = CFrame.new(camera.CFrame.Position.X, player.Character.PrimaryPart.Position.Y, camera.CFrame.Position.Z)
 		playerModule.rotatingCamera = true
 		local holdTime = 0
 		local currentTime = 0
 		rotatingCameraHeartbeat = runService.Heartbeat:Connect(function(dt)
 			if holdTime >= 0.25 then
 				if currentTime < 1 then
 					currentTime += dt
 				else
 					playerModule.TurnCamera(right)
 					player.Character.PrimaryPart.CFrame = CFrame.new(camera.CFrame.Position.X, player.Character.PrimaryPart.Position.Y, camera.CFrame.Position.Z)
 					currentTime = 0
 				end
 			else
 				holdTime += dt
 			end
 		end)
 	end
 end)
local grabRenderStep = nil
grabObjectRemote.OnClientEvent:Connect(function(right, action, part)
	local hand = right == true and playerModule.rightHand or playerModule.leftHand
	local grabPoint = hand.origin["GrabPoint"]
	grabRenderStep = runService.Heartbeat:Connect(function()
		grabPoint.CFrame = hand.origin.CFrame
	end)
end)
-- grabObjectRemote.OnClientEvent:Connect(function(right, action, part)
-- 	local primaryString = right == true and "Right" or "Left"
-- 	local otherString = right == true and "Left" or "Right"
-- 	local primaryHand = right == true and playerModule.rightHand or playerModule.leftHand
-- 	if action == "Grab" then
-- 		local weld = part:WaitForChild(player.Name .. primaryString .. "Weld")
-- 		local initialRotation = weld.C0.Rotation
-- 		local initialMiddlePosition = (playerModule.rightHand.model.Position + playerModule.leftHand.model.Position) / 2
-- 		local partCFrame = CFrame.new(initialMiddlePosition):ToObjectSpace(CFrame.new(part.Position))
-- 		grabRenderStep = runService.Heartbeat:Connect(function(dt)
-- 			local middlePosition = (playerModule.rightHand.model.Position + playerModule.leftHand.model.Position) / 2
-- 			local offsetMiddlePosition = primaryHand.model.CFrame:VectorToObjectSpace(middlePosition - primaryHand.model.Position)
-- 			weld.C0 = CFrame.new(-offsetMiddlePosition - partCFrame.Position) * initialRotation
-- 		end)
-- 	end
-- end)
-- grabObjectRemote.OnClientEvent:Connect(function(right, action, part)
-- 	local hand = right == true and playerModule.rightHand or playerModule.leftHand
-- 	local otherHand = right == true and playerModule.leftHand or playerModule.rightHand
-- 	if action == "Grab" then
-- 		if grabRenderStep then
-- 			grabRenderStep:Disconnect()
-- 			grabRenderStep = nil
-- 		end
-- 		local grabWeld = hand.model:WaitForChild("GrabWeld")
-- 		local otherGrabWeld = otherHand.model:FindFirstChild("GrabWeld")
-- 		local partInitialCFrame = part.CFrame
-- 		local handInitialCFrame = hand.model.CFrame
-- 		local middlePosition = (playerModule.rightHand.model.Position + playerModule.leftHand.model.Position) / 2
-- 		local partMiddleCFrame = CFrame.new(middlePosition):ToObjectSpace(part.CFrame)
-- 		grabRenderStep = runService.Heartbeat:Connect(function(dt)
-- 			middlePosition = (playerModule.rightHand.model.Position + playerModule.leftHand.model.Position) / 2
-- 			grabWeld.C0 = hand.model.CFrame:ToObjectSpace(CFrame.new(middlePosition + partMiddleCFrame.Position)) * part.CFrame.Rotation
-- 			grabWeld.C0 = hand.model.CFrame:ToObjectSpace(CFrame.new(middlePosition))
-- 		end)
-- 	elseif action == "Release" then
-- 		if grabRenderStep then
-- 			grabRenderStep:Disconnect()
-- 			grabRenderStep = nil
-- 		end
-- 	end
-- end)