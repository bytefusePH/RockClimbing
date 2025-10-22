local replicatedStorage = game:GetService("ReplicatedStorage")
local serverRemotes = replicatedStorage:WaitForChild("ServerRemotes")
local players = game:GetService("Players")
local GrabObject = serverRemotes:WaitForChild("GrabObject") :: RemoteEvent
local dummyCharacterFolder = game.Workspace:WaitForChild("PlayerFolder"):WaitForChild("DummyCharacters")
local grabbableFolder = game.Workspace:WaitForChild("Grabbable")
local respawningObjects = {}
local initialStats = {}
for i, child in pairs(grabbableFolder:GetDescendants()) do
	if child:IsA("BasePart") then
		initialStats[child] = {position = child.CFrame, collision = child.CanCollide}
	end
end
GrabObject.OnServerEvent:Connect(function(player: Player, right: boolean, action: string, velocity: Vector3?)
	local dummyCharacter = dummyCharacterFolder:FindFirstChild(player.Name) :: Model
	if not dummyCharacter then return end
	local handName = (right == true and "Right" or "Left") .. "Origin"
	local otherHandName = (right == false and "Right" or "Left") .. "Origin"
	local VRModel = dummyCharacter:FindFirstChild("VRModel")
	if not VRModel then return end
	local handOrigin = VRModel:FindFirstChild(handName)
	local otherHandOrigin = VRModel:FindFirstChild(otherHandName)
	if not handOrigin and not otherHandOrigin then return end
	if action == "Grab" then
		local params = OverlapParams.new()
	 	params.FilterDescendantsInstances = {player.Character, dummyCharacter}
	 	params.FilterType = Enum.RaycastFilterType.Exclude
	 	local partsInRadius = game.Workspace:GetPartBoundsInRadius(handOrigin.Position, 0.2, params)
	 	for i, part in partsInRadius do
			local grabbableFolder = part:FindFirstAncestor("Grabbable")
	 		if grabbableFolder and grabbableFolder:IsA("Folder") and grabbableFolder.Name == "Grabbable" then
				local otherGrabWeldConstraint = otherHandOrigin:FindFirstChild("GrabWeldConstraint") :: WeldConstraint
				if not otherGrabWeldConstraint or part ~= otherGrabWeldConstraint.Part1 then
					local grabWeldConstraint = Instance.new("WeldConstraint")
					grabWeldConstraint.Name = "GrabWeldConstraint"
					grabWeldConstraint.Part0 = handOrigin
					grabWeldConstraint.Parent = handOrigin
					grabWeldConstraint.Part1 = part
					local model = part:FindFirstAncestorOfClass("Model")
					if model then
						for i, modelPart in pairs(model:GetDescendants()) do
							if modelPart:IsA("BasePart") then
								modelPart.Anchored = false
								modelPart.CanCollide = false
							end
						end
					end
					break
				end
	 		end
	 	end
	elseif action == "Release" then
		local grabWeldConstraint = handOrigin:FindFirstChild("GrabWeldConstraint") :: WeldConstraint
		if grabWeldConstraint then
			local grabbedPart = grabWeldConstraint.Part1
			local model = grabbedPart:FindFirstAncestorOfClass("Model")
			if model then
				for i, modelPart in pairs(model:GetDescendants()) do
					if modelPart:IsA("BasePart") then
						modelPart.CanCollide = true
					end
				end
			end
			grabWeldConstraint:Destroy()
			if velocity and grabbedPart and grabbedPart:IsA("BasePart") then
				grabbedPart.Velocity = velocity * 2.5
			end
			local grabbedPartIndex = table.find(respawningObjects, grabbedPart)
			if not grabbedPartIndex then
				coroutine.wrap(function()
					table.insert(respawningObjects, grabbedPart)
					task.wait(10)
					if grabbedPart and grabbedPart:IsA("BasePart") then
						grabbedPart.CFrame = initialStats[grabbedPart].position
						if model then
							for i, modelPart in pairs(model:GetDescendants()) do
								if modelPart:IsA("BasePart") then
									modelPart.CanCollide = initialStats[grabbedPart].collision
									modelPart.Anchored = true
								end
							end
						end
						table.remove(respawningObjects, grabbedPartIndex)
					end
				end)()
			end
		end
	end
end)