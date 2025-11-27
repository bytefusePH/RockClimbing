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
GrabObject.OnServerEvent:Connect(function(player: Player, right: boolean, action: string, part: BasePart?, otherPart)
	local dummyCharacter = dummyCharacterFolder:FindFirstChild(player.Name) :: Model
	if not dummyCharacter then return end
	local primaryString = right == true and "Right" or "Left"
	local otherString = right == true and "Left" or "Right"
	local handName = primaryString .. "Origin"
	local otherHandName = otherString .. "Origin"
	local VRModel = dummyCharacter:FindFirstChild("VRModel")
	if not VRModel then return end
	local handOrigin = VRModel:FindFirstChild(handName)
	local otherHandOrigin = VRModel:FindFirstChild(otherHandName)
	if not handOrigin and not otherHandOrigin then return end
	local partModel = part:FindFirstAncestorOfClass("Model")
	if action == "Grab" then
		for i, child in partModel:GetChildren() do
			if child:IsA("BasePart") then
				child.CanCollide = false
				child.Anchored = false
				child.Massless = true
			end
		end
		part:SetNetworkOwner(player)
		respawningObjects[partModel] = {time = 10, grabbed = true}
	elseif action == "Release" then
		for i, child in partModel:GetDescendants() do
			if child:IsA("BasePart") then
				child.CanCollide = true
			end
		end
		coroutine.wrap(function()
			respawningObjects[partModel] = {time = 10, grabbed = false}
			while respawningObjects[partModel] do
				if respawningObjects[partModel].grabbed == true then
					break
				end
				if respawningObjects[partModel].time > 0 then
					task.wait(1)
					respawningObjects[partModel].time = respawningObjects[partModel].time - 1
				else
					if partModel then
						for i, modelPart in pairs(partModel:GetChildren()) do
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
	--if action == "Grab" then
	--	local grabAttachment = Instance.new("Attachment")
	--	grabAttachment.Parent = handOrigin:WaitForChild("ServerHand")
	--	local partAttachment = Instance.new("Attachment")
	--	partAttachment.Parent = part
	--	local alignPosition = Instance.new("AlignPosition")
	--	alignPosition.Attachment0 = partAttachment
	--	alignPosition.Attachment1 = grabAttachment
	--	alignPosition.RigidityEnabled = true
	--	alignPosition.Parent = part
	--	local model = part:FindFirstAncestorOfClass("Model")
	--	for i, modelPart in model:GetChildren() do
	--		if modelPart:IsA("BasePart") then
	--			modelPart.Anchored = false
	--		end
	--	end
	--end
	-- if action == "Grab" then
	-- 	local weld = Instance.new("Weld")
	-- 	weld.Parent = part
	-- 	weld.Part0 = part
	-- 	weld.Part1 = handOrigin
	-- 	weld.Name = player.Name .. primaryString .. "Weld"
	-- 	local partOffsetCFrame = part.CFrame:ToObjectSpace(clientHandCFrame)
	-- 	weld.C0 = partOffsetCFrame
	-- 	local model = part:FindFirstAncestorOfClass("Model")
	-- 	for i, modelPart in model:GetChildren() do
	-- 		if modelPart:IsA("BasePart") then
	-- 			modelPart.Anchored = false
	-- 			modelPart.CanCollide = false
	-- 		end
	-- 	end
	-- 	local otherWeld = part:FindFirstChild(player.Name .. otherString .. "Weld")
	-- 	if otherWeld then
	-- 		-- GrabObject:FireClient(player, right, action, part)
	-- 		-- playerHeartbeats[player.UserId] = runService.Heartbeat:Connect(function()
	-- 		-- 	local middlePosition = (handOrigin.Position + otherHandOrigin.Position) / 2
	-- 		-- 	weld.C0 = handOrigin.CFrame:ToObjectSpace(CFrame.new(middlePosition)):Inverse() * part.CFrame.Rotation
	-- 		-- end)
	-- 	end
	-- 	respawningObjects[model] = {time = 10, grabbed = true}
	-- elseif action == "Release" then
	-- 	local weld = part[player.Name .. primaryString .. "Weld"]
	-- 	if playerHeartbeats[player.UserId] then
	-- 		playerHeartbeats[player.UserId]:Disconnect()
	-- 		playerHeartbeats[player.UserId] = nil
	-- 	end
	-- 	local previousPosition = part.Position
	-- 	weld:Destroy()
	-- 	local model = part:FindFirstAncestorOfClass("Model")
	-- 	if not otherGrabWeld or otherGrabWeld.Part1:FindFirstAncestorOfClass("Model") ~= model then
	-- 		part.Position = previousPosition
	-- 		for i, modelPart in pairs(model:GetChildren()) do
	-- 			if modelPart:IsA("BasePart") then
	-- 				modelPart.CanCollide = true
	-- 			end
	-- 		end
	-- 		-- grabbedPart:ApplyImpulse(velocityDirection * 5)
	-- 		coroutine.wrap(function()
	-- 			respawningObjects[model] = {time = 10, grabbed = false}
	-- 			while respawningObjects[model] do
	-- 				if respawningObjects[model].grabbed == true then
	-- 					break
	-- 				end
	-- 				if respawningObjects[model].time > 0 then
	-- 					task.wait(1)
	-- 					respawningObjects[model].time = respawningObjects[model].time - 1
	-- 				else
	-- 					if model then
	-- 						for i, modelPart in pairs(model:GetChildren()) do
	-- 							if modelPart:IsA("BasePart") then
	-- 								modelPart.CanCollide = true
	-- 								modelPart.Anchored = true
	-- 								modelPart.CFrame = initialStats[modelPart].position
	-- 							end
	-- 						end
	-- 					end
	-- 				end
	-- 				task.wait(0.1)
	-- 			end
	-- 		end)()
	-- 	end
	-- end
	-- if action == "Grab" then
	--  	local grabWeld = Instance.new("Weld")
	-- 	grabWeld.Name = "GrabWeld"
	-- 	grabWeld.Part0 = handOrigin
	-- 	grabWeld.Part1 = part
	-- 	grabWeld.C0 = clientHandCFrame:Inverse() * clientPartCFrame
	-- 	grabWeld.Parent = handOrigin
	-- 	local otherGrabWeld = otherHandOrigin:FindFirstChild("GrabWeld")
	-- 	if otherGrabWeld and otherGrabWeld.Part1 == part then
	-- 		GrabObject:FireClient(player, right, action, part)
	-- 		playerHeartbeats[player.UserId] = runService.Heartbeat:Connect(function()
	-- 			local middlePosition = (handOrigin.Position + otherHandOrigin.Position) / 2
	-- 			local partMiddleCFrame = CFrame.new(middlePosition):ToObjectSpace(part.CFrame)
	-- 			grabWeld.C0 = handOrigin.CFrame:ToObjectSpace(CFrame.new(middlePosition + partMiddleCFrame.Position)) * part.CFrame.Rotation
	-- 		end)
	-- 	end
	-- 	local model = part:FindFirstAncestorOfClass("Model")
	-- 	if model then
	-- 		for i, modelPart in pairs(model:GetDescendants()) do
	-- 			if modelPart:IsA("BasePart") then
	-- 				modelPart.Anchored = false
	-- 				modelPart.CanCollide = false
	-- 			end
	-- 		end
	-- 	end
	-- 	respawningObjects[model] = {time = 10, grabbed = true}
	-- elseif action == "Release" then
	-- 	local grabWeld = handOrigin:FindFirstChild("GrabWeld") :: Weld
	-- 	local otherGrabWeld = otherHandOrigin:FindFirstChild("GrabWeld") :: Weld
	-- 	local grabbedPart = grabWeld.Part1
	-- 	local model = grabbedPart:FindFirstAncestorOfClass("Model")
	-- 	grabWeld:Destroy()
	-- 	GrabObject:FireClient(player, right, action, part)
	-- 	if not otherGrabWeld or otherGrabWeld.Part1:FindFirstAncestorOfClass("Model") ~= model then
	-- 		for i, modelPart in pairs(model:GetDescendants()) do
	-- 			if modelPart:IsA("BasePart") then
	-- 				modelPart.CanCollide = true
	-- 			end
	-- 		end
	-- 		--grabbedPart:ApplyImpulse(velocityDirection * 5)
	-- 		coroutine.wrap(function()
	-- 			respawningObjects[model] = {time = 10, grabbed = false}
	-- 			while respawningObjects[model] do
	-- 				if respawningObjects[model].grabbed == true then
	-- 					break
	-- 				end
	-- 				if respawningObjects[model].time > 0 then
	-- 					task.wait(1)
	-- 					respawningObjects[model].time = respawningObjects[model].time - 1
	-- 				else
	-- 					if model then
	-- 						for i, modelPart in pairs(model:GetChildren()) do
	-- 							if modelPart:IsA("BasePart") then
	-- 								modelPart.CanCollide = true
	-- 								modelPart.Anchored = true
	-- 								modelPart.CFrame = initialStats[modelPart].position
	-- 							end
	-- 						end
	-- 					end
	-- 				end
	-- 				task.wait(0.1)
	-- 			end
	-- 		end)()
	-- 	end
	-- end
end)