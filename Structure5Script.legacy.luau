local runService = game:GetService("RunService")
local hexagonModel = script.Parent:WaitForChild("Hexagons")
local rotationStep = CFrame.Angles(0, math.rad(-0.2), 0)
runService.Heartbeat:Connect(function(dt)
	for _, part in ipairs(hexagonModel:GetChildren()) do
		part.CFrame = part.CFrame * rotationStep
	end
end)