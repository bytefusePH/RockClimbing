local vrService = game:GetService("VRService")
local runService = game:GetService("RunService")
local players = game:GetService("Players")
local camera = game.Workspace.Camera
local dummyCharacterFolder = game.Workspace:WaitForChild("PlayerFolder"):WaitForChild("DummyCharacters")
local characterFinishedLoading = game.ReplicatedStorage:WaitForChild("ServerRemotes"):WaitForChild("CharacterFinishedLoading")
local playerModule = {}
playerModule.player = nil
playerModule.cameraOffset = CFrame.new(0, 0.25, 0)
--CFrame.new(0.1, -0.175, 0.025)
playerModule.handsOffset = CFrame.new(0, 0.2, 0)
local rotationX, rotationY, rotationZ = playerModule.handsOffset:ToEulerAnglesXYZ()
playerModule.leftHandOffset = CFrame.new(-playerModule.handsOffset.Position.X, playerModule.handsOffset.Position.Y, playerModule.handsOffset.Position.Z) * CFrame.Angles(rotationX, -rotationY, -rotationZ)
playerModule.VRModel = nil
playerModule.VRHead = nil
playerModule.rightHand = nil
playerModule.leftHand = nil
playerModule.rotationSensitivity = 45
playerModule.rotatingCamera = false
playerModule.cameraRotation = 0
playerModule.dummyCharacter = nil
playerModule.meshIds = {RightHand = {idle = "rbxassetid://87578832563922", closed = "rbxassetid://94555025070476"}, LeftHand = {idle = "rbxassetid://130045172590569", closed = "rbxassetid://127520433737371"}}
function playerModule.InitializeModule(player: Player)
	if playerModule.player then return end
	playerModule.player = player
end

function playerModule.IsClimbing()
	return (playerModule.rightHand.isClimbing == true or playerModule.leftHand.isClimbing == true)
end
function playerModule.IsRight(right)
	return right == true and "Right" or "Left"
end
function playerModule.FindHandVariant(handOrigin: Part, right: boolean, variant: string)
	local variant = handOrigin["HandVariants"]:FindFirstChild(playerModule.IsRight(right) .. "Hand" .. variant)
	if not variant then return nil end
	local offset = variant:FindFirstChild("Offset")
	return variant, offset ~= nil and CFrame.Angles(math.rad(offset.Value.X), math.rad(offset.Value.Y), math.rad(offset.Value.Z)) or CFrame.new(0, 0, 0)
end
function playerModule.ChangeHandVariant(hand, right: boolean, variant: string, stationary: boolean)
	local currentVariant = playerModule.FindHandVariant(hand.model, right, hand.currentVariant)
	local newVariant, newVariantOffset = playerModule.FindHandVariant(hand.model, right, variant)
	if not currentVariant or not newVariant then 
		newVariant = hand.model:WaitForChild("HandVariants"):FindFirstChild(playerModule.IsRight(right) .. "HandIdle")
		newVariantOffset = CFrame.new(0, 0, 0)
		variant = "Idle"
		newVariant = hand.model:WaitForChild("HandVariants"):FindFirstChild(playerModule.IsRight(right) .. "HandIdle")
	end
	if hand.currentVariant ~= variant then
		newVariant.CFrame = currentVariant.CFrame * newVariantOffset 
		currentVariant.Transparency = 1
		newVariant.Transparency = 0
		hand.currentVariant = variant
	end
	return {model = newVariant, offset = newVariantOffset}, currentVariant
end
--function playerModule.FindHand(right: boolean)
--	local rightString = playerModule.IsRight(right)
--	local origin = playerModule.VRModel:WaitForChild(playerModule.IsRight(right) .. "Origin")
--	local handVariantsFolder = origin:WaitForChild("HandVariants")
--	local handTable = {model = origin, 
--		isClimbing = false, 
--		isRight = right, 
--		mesh = origin[rightString .. "HandMesh"],
--		climbingOn = nil, 
--		grabOffset = nil, 
--		initialGrabPosition = nil, 
--		currentVariant = "Idle",
--		handModel = handVariantsFolder:FindFirstChild(playerModule.IsRight(right) .. "HandIdle"),
--		grabbingOn = nil,
--		prevCFrame = origin.CFrame,
--	}
--	return handTable
--end
function playerModule.OnCharacterAdded(newCharacter: Model)
	local humanoid = newCharacter:WaitForChild("Humanoid")
	playerModule.dummyCharacter = dummyCharacterFolder:WaitForChild(newCharacter.Name)
	playerModule.VRModel = playerModule.dummyCharacter:WaitForChild("VRModel")
	if playerModule.VRModel then
		playerModule.rightHand = playerModule.FindHandNew(true)
		playerModule.leftHand = playerModule.FindHandNew(false)
		coroutine.wrap(function()
			task.wait(1)
			playerModule.rightHand.origin.CFrame = playerModule.dummyCharacter.PrimaryPart.CFrame
			playerModule.leftHand.origin.CFrame = playerModule.dummyCharacter.PrimaryPart.CFrame
		end)()
	end
end
function playerModule.IsHandInput(input: Enum)
	if input.UserInputType == Enum.UserInputType.Gamepad1 or input.UserInputType == Enum.UserInputType.Gamepad2 then
		if input.KeyCode == Enum.KeyCode.ButtonR1 or input.KeyCode == Enum.KeyCode.ButtonL1 then
			return true, (input.KeyCode == Enum.KeyCode.ButtonR2 or input.KeyCode == Enum.KeyCode.ButtonR1)
		end
	end
	return false
end
function playerModule.TurnCamera(right: boolean)
	if (right == true and 360 + playerModule.cameraRotation or 360 - playerModule.cameraRotation) > playerModule.rotationSensitivity then
		playerModule.cameraRotation -= right == true and playerModule.rotationSensitivity or -playerModule.rotationSensitivity
	else
		playerModule.cameraRotation = 0
	end
end
playerModule.raycastParams = RaycastParams.new()
playerModule.raycastParams.FilterType = Enum.RaycastFilterType.Exclude
playerModule.raycastParams.FilterDescendantsInstances = {playerModule.dummyCharacter, game.Workspace:WaitForChild("SpawnLocation")}
function FindRotationDifference(prevCFrame: CFrame, newCFrame: CFrame)
	local prevLook = prevCFrame.LookVector
	local newLook = newCFrame.LookVector
	local dotProduct = prevLook:Dot(newLook)
	local angleRad = math.acos(math.clamp(dotProduct, -1, 1))
	local angleDeg = math.deg(angleRad)
	return angleDeg
end
function playerModule.VectorsChanged(prevCFrame: CFrame, newCFrame: CFrame)
	local positionDifference = (prevCFrame.Position - newCFrame.Position).Magnitude
	local rotationDifference = FindRotationDifference(prevCFrame, newCFrame)
	if rotationDifference > 25 or positionDifference > 5 then
		return true
	else
		return false
	end
end
function playerModule.VRVectorsChanged(listOfPositions)
	local cameraChanged = playerModule.VectorsChanged(listOfPositions.cameraCFrame, camera:GetRenderCFrame())
	local rightHandChanged = playerModule.VectorsChanged(listOfPositions.rightHandCFrame, playerModule.rightHand.model.CFrame)
	local leftHandChanged = playerModule.VectorsChanged(listOfPositions.leftHandCFrame, playerModule.leftHand.model.CFrame)
	if cameraChanged == true or rightHandChanged == true or leftHandChanged == true then
		return true
	end
end
function playerModule.CalculateHandMovement(vrDevice, worldCFrame, headScale)
	local vrDeviceCFrame = vrService:GetUserCFrame(vrDevice)
	local vrDeviceRotation = vrDeviceCFrame - vrDeviceCFrame.Position
	local vrDeviceScaledCFrame = CFrame.new(vrDeviceCFrame.Position * headScale) * vrDeviceRotation
	local vrDeviceWorldCFrame = worldCFrame:ToWorldSpace(vrDeviceScaledCFrame)
	return vrDeviceWorldCFrame
end
function playerModule.FindHandNew(right: boolean)
	local rightString = playerModule.IsRight(right)
	local handOrigin = playerModule.VRModel:WaitForChild(playerModule.IsRight(right) .. "Origin")
	local handVariantsFolder = handOrigin:WaitForChild("HandVariants")
	local handTable = {origin = handOrigin, 
		isClimbing = false, 
		isRight = right, 
		climbingOn = nil, 
		grabOffset = nil, 
		initialGrabPosition = nil, 
		currentVariant = "Idle",
		--model = handVariantsFolder:FindFirstChild(playerModule.IsRight(right) .. "HandIdle"),
		grabbingOn = nil,
		prevCFrame = handOrigin.CFrame,
		anchoredHand = playerModule.CreateDummyHands(playerModule.VRModel, handOrigin["Attachment"])
	}
	playerModule.ChangeHandMesh(handTable, "Idle")
	return handTable
end
local handsFolder = game.ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Hands")
function playerModule.ChangeHandMesh(hand, variant: string)
	local rightString = hand.isRight == true and "Right" or "Left"
	local handVariantsFolder = hand.origin["HandVariants"]
	local newMesh = handVariantsFolder[rightString .. "Hand" .. variant]
	newMesh.Transparency = 0
	newMesh.Anchored = true
	for i, child in handVariantsFolder:GetChildren() do
		if child ~= newMesh	then
			child.Transparency = 1
			child.Anchored = true
		end
	end
	hand.mesh = newMesh
	return newMesh
end
function playerModule.AttachParts(parent, originalAttachment, otherAttachment)
	local alignPosition = Instance.new("AlignPosition")
	alignPosition.Attachment0 = originalAttachment
	alignPosition.Attachment1 = otherAttachment
	alignPosition.RigidityEnabled = true
	--alignPosition.MaxForce = 200
	--alignPosition.Responsiveness = 200
	alignPosition.Parent = parent
	local alignOrientation = Instance.new("AlignOrientation")
	alignOrientation.Attachment0 = originalAttachment
	alignOrientation.Attachment1 = otherAttachment
	alignOrientation.RigidityEnabled = true
	--alignOrientation.MaxAngularVelocity = math.huge
	--alignOrientation.MaxTorque = math.huge
	--alignOrientation.Responsiveness = math.huge
	alignOrientation.Parent = parent
end
function playerModule.CreateDummyHands(dummyParent, attachment)
	local anchoredHand = Instance.new("Part")
	anchoredHand.Size = Vector3.new(5, 5, 5)
	anchoredHand.Anchored = true
	anchoredHand.CanCollide = false
	anchoredHand.Name = "AnchoredHand"
	anchoredHand.Transparency = 1
	anchoredHand.Parent = dummyParent
	local newAttachment = Instance.new("Attachment")
	newAttachment.Parent = anchoredHand
	playerModule.AttachParts(dummyParent, attachment, newAttachment)
	--local alignPosition = Instance.new("AlignPosition")
	--alignPosition.Attachment0 = attachment
	--alignPosition.Attachment1 = newAttachment
	--alignPosition.RigidityEnabled = true
	--alignPosition.Parent = anchoredHand
	--local alignOrientation = Instance.new("AlignOrientation")
	--alignOrientation.Attachment0 = attachment
	--alignOrientation.Attachment1 = newAttachment
	--alignOrientation.RigidityEnabled = false
	--alignOrientation.MaxAngularVelocity = 200
	--alignOrientation.MaxTorque = 200
	--alignOrientation.Responsiveness = 200
	--alignOrientation.Parent = anchoredHand
	anchoredHand.Position = Vector3.new(0, 0, 0)
	return anchoredHand
end
return playerModule