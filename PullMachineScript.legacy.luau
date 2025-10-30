local pullHandle = game.Workspace:WaitForChild("Grabbable"):WaitForChild("Handle")
local pullMachine = game.Workspace:WaitForChild("Props"):WaitForChild("Exercise"):WaitForChild("PullMachine")
local weightHolderRope = pullMachine:WaitForChild("Structure"):WaitForChild("WeightHolder"):WaitForChild("RopeConstraint")
local weightPart = pullMachine:WaitForChild("Weight")
local initialPosition = pullHandle.PrimaryPart.Position
local serverRemtoes = game.ReplicatedStorage:WaitForChild("ServerRemotes")
local grabObject = serverRemtoes:WaitForChild("GrabObject")
local updatePlayerPositions = serverRemtoes:WaitForChild("UpdatePlayerPositions")
local dummyCharacterFolder = game.Workspace:WaitForChild("PlayerFolder"):WaitForChild("DummyCharacters")
local currentlyGrabbingPlayer = nil
grabObject.OnServerEvent:Connect(function(player, right, action, part)
	local vrModel = dummyCharacterFolder[player.Character.Name]["VRModel"]
	local primaryWeld = action == "Grab" and vrModel[(right == true and "Right" or "Left") .. "Origin"]:WaitForChild("GrabWeld") :: Weld or nil
	local secondaryWeld = vrModel[(right == true and "Left" or "Right") .. "Origin"]:FindFirstChild("GrabWeld") :: Weld
	if (primaryWeld and primaryWeld.Part1 == pullHandle.PrimaryPart) or (secondaryWeld and secondaryWeld.Part1 == pullHandle.PrimaryPart) then
		currentlyGrabbingPlayer = player
	else
		currentlyGrabbingPlayer = nil
		weightHolderRope.Length = 8.5
	end
	weightPart:SetNetworkOwner(currentlyGrabbingPlayer)
end)
updatePlayerPositions.OnServerEvent:Connect(function(player)
	if currentlyGrabbingPlayer == player then
		local calculatedPosition = (pullHandle.PrimaryPart.Position - initialPosition).Magnitude
		weightHolderRope.Length = 8.5 - calculatedPosition
	end
end)