local replicatedStorage = game:GetService("ReplicatedStorage")
local serverRemotes = replicatedStorage:WaitForChild("ServerRemotes")
local runService = game:GetService("RunService")
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
local playerHeartbeats = {}
GrabObject.OnServerEvent:Connect(function(player: Player, right: boolean, action: string, part: BasePart?, clientHandCFrame: CFrame?, clientPartCFrame: CFrame?, velocityDirection: Vector3?)
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
	 	local grabWeld = Instance.new("Weld")
		grabWeld.Name = "GrabWeld"
		grabWeld.Part0 = handOrigin
		grabWeld.Part1 = part
		grabWeld.C0 = clientHandCFrame:Inverse() * clientPartCFrame
		grabWeld.Parent = handOrigin
		local model = part:FindFirstAncestorOfClass("Model")
		if model then
			for i, modelPart in pairs(model:GetDescendants()) do
				if modelPart:IsA("BasePart") then
					modelPart.Anchored = false
					modelPart.CanCollide = false
				end
			end
		end
		respawningObjects[model] = {time = 10, grabbed = true}
	elseif action == "Release" then
		local grabWeld = handOrigin:FindFirstChild("GrabWeld") :: Weld
		local otherGrabWeld = otherHandOrigin:FindFirstChild("GrabWeld") :: Weld
		local grabbedPart = grabWeld.Part1
		local model = grabbedPart:FindFirstAncestorOfClass("Model")
		grabWeld:Destroy()
		if grabWeld then 
			if not otherGrabWeld or otherGrabWeld.Part1:FindFirstAncestorOfClass("Model") ~= model then
				for i, modelPart in pairs(model:GetDescendants()) do
					if modelPart:IsA("BasePart") then
						modelPart.CanCollide = true
					end
				end
				grabbedPart:ApplyImpulse(velocityDirection * 5)
				coroutine.wrap(function()
					respawningObjects[model] = {time = 10, grabbed = false}
					while respawningObjects[model] do
						if respawningObjects[model].grabbed == true then
							break
						end
						if respawningObjects[model].time > 0 then
							task.wait(1)
							respawningObjects[model].time = respawningObjects[model].time - 1
						else
							if model then
								for i, modelPart in pairs(model:GetChildren()) do
									if modelPart:IsA("BasePart") then
										modelPart.CanCollide = true
										modelPart.Anchored = true
										modelPart.CFrame = initialStats[modelPart].position
									end
								end
							end
						end
						task.wait(0.1)
					end
				end)()
			end
		end
	end
end)