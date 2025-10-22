local obstaclesFolder = game.Workspace:WaitForChild("Obstacles")
for i, folder in obstaclesFolder:GetChildren() do
    for i, model in folder:GetChildren() do
        local teleportersFolder = model:FindFirstChild("TeleportZoneFolder")
        local checkpointsFolder = model:FindFirstChild("CheckpointsFolder")
        for i, part in teleportersFolder:GetChildren() do
            local nameIndex = string.sub(part.Name, 13)
            local checkpoint = checkpointsFolder:FindFirstChild("Checkpoint" .. nameIndex)
            part.Touched:Connect(function(hit: BasePart)
				if hit.Name == "HumanoidRootPart" then
					hit.Position = checkpoint.Position
				end
            end)
        end
    end
end