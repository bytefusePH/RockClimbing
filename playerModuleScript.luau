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
playerModule.handsOffset = CFrame.new(0, 0.05, 0)
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
function playerModule.ChangeHandVariant(hand: table, right: boolean, variant: string, stationary: boolean)
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
function playerModule.FindHand(right: boolean)
	local origin = playerModule.VRModel:WaitForChild(playerModule.IsRight(right) .. "Origin")
	local handVariantsFolder = origin:WaitForChild("HandVariants")
	local handTable = {model = origin, 
		isClimbing = false, 
		isRight = right, 
		climbingOn = nil, 
		grabOffset = nil, 
		initialGrabPosition = nil, 
		currentVariant = "Idle",
		handModel = handVariantsFolder:FindFirstChild(playerModule.IsRight(right) .. "HandIdle"),
	}
	for _, variant in handVariantsFolder:GetChildren() do
		if variant:IsA("Part") or variant:IsA("MeshPart") then
			if variant.Name ~= playerModule.IsRight(right) .. "Hand" .. handTable.currentVariant then
				variant.Transparency = 1
			end
		end
	end
	return handTable
end
function playerModule.OnCharacterAdded(newCharacter: Model)
	local humanoid = newCharacter:WaitForChild("Humanoid")
	playerModule.dummyCharacter = dummyCharacterFolder:WaitForChild(newCharacter.Name)
	playerModule.VRModel = playerModule.dummyCharacter:WaitForChild("VRModel")
	if playerModule.VRModel then
		playerModule.rightHand = playerModule.FindHand(true)
		playerModule.leftHand = playerModule.FindHand(false)
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
-- function playerModule.TurnCamera(right: boolean)
-- 	if (right == true and 360 + playerModule.cameraRotation or 360 - playerModule.cameraRotation) > playerModule.rotationSensitivity then
-- 		playerModule.cameraRotation -= right == true and playerModule.rotationSensitivity or -playerModule.rotationSensitivity
-- 	else
-- 		playerModule.cameraRotation = 0
-- 	end
-- end
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
return playerModule