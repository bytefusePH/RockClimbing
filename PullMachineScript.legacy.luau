local runService = game:GetService("RunService")
local pullHandle = game.Workspace:WaitForChild("Grabbable"):WaitForChild("Handle")
local pullMachine = game.Workspace:WaitForChild("Props"):WaitForChild("Exercise"):WaitForChild("PullMachine")
local weightHolder = pullMachine:WaitForChild("Structure"):WaitForChild("WeightHolder")
local weightHolderRope = pullMachine:WaitForChild("Structure"):WaitForChild("WeightHolder"):WaitForChild("RopeConstraint")
local weightPart = pullMachine:WaitForChild("Weight")
local initialPosition = pullHandle.PrimaryPart.Position
local serverRemote = game.ReplicatedStorage:WaitForChild("ServerRemotes")
local grabObject = serverRemote:WaitForChild("GrabObject")
local updatePlayerPositions = serverRemote:WaitForChild("UpdatePlayerPositions")
local dummyCharacterFolder = game.Workspace:WaitForChild("PlayerFolder"):WaitForChild("DummyCharacters")
local pullMachineGrabbed = serverRemote:WaitForChild("PullMachineGrabbed")
local currentlyGrabbingPlayer = nil
local machineHeartbeat = nil
grabObject.OnServerEvent:Connect(function(player, right, action, part)
	--local vrModel = dummyCharacterFolder[player.Character.Name]["VRModel"]
	--local primaryWeld = action == "Grab" and vrModel[(right == true and "Right" or "Left") .. "Origin"]:WaitForChild("GrabWeld") :: Weld or nil
	--local secondaryWeld = vrModel[(right == true and "Left" or "Right") .. "Origin"]:FindFirstChild("GrabWeld") :: Weld
	if part ~= pullHandle.PrimaryPart then return end
	if action == "Grab" then
		currentlyGrabbingPlayer = player
		if not machineHeartbeat then
			machineHeartbeat = runService.Heartbeat:Connect(function(dt)
				local calculatedPosition = (pullHandle.PrimaryPart.Position - initialPosition).Magnitude
				weightHolderRope.Length	= 8.5 - calculatedPosition
			end)
		end
	else
		currentlyGrabbingPlayer = nil
		machineHeartbeat:Disconnect()
		weightHolderRope.Length = 8.5
	end
	weightPart:SetNetworkOwner(currentlyGrabbingPlayer)
	--if (primaryWeld and primaryWeld.Part1 == pullHandle.PrimaryPart) or (secondaryWeld and secondaryWeld.Part1 == pullHandle.PrimaryPart) then
	--	currentlyGrabbingPlayer = player
	--	machineHeartbeat = runService.Heartbeat:Connect(function()
	--		local calculatedPosition = (pullHandle.PrimaryPart.Position - initialPosition).Magnitude
	--		weightHolderRope.Length = 8.5 - calculatedPosition
	--	end)
	--else
	--	currentlyGrabbingPlayer = nil
	--	machineHeartbeat:Disconnect()
	--	weightHolderRope.Length = 8.5
	--end
	--weightPart:SetNetworkOwner(currentlyGrabbingPlayer)
end)
--updatePlayerPositions.OnServerEvent:Connect(function(player)
--	if currentlyGrabbingPlayer == player then
--		local calculatedPosition = (pullHandle.PrimaryPart.Position - initialPosition).Magnitude
--		weightHolderRope.Length = 8.5 - calculatedPosition
--	end
--end)