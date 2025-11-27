local runService = game:GetService("RunService")
local players = game:GetService("Players")
local pullHandle = game.Workspace:WaitForChild("Grabbable"):WaitForChild("Handle")
local pullmachine = game.Workspace:WaitForChild("Props"):WaitForChild("Exercise"):WaitForChild("PullMachine")
local weightHolderRope = pullmachine:WaitForChild("Structure"):WaitForChild("WeightHolder"):WaitForChild("RopeConstraint")
local weightPart =  pullmachine:WaitForChild("Weight")
local player = players.LocalPlayer
repeat
	task.wait(1)
until pullHandle.PrimaryPart
local initialPosition = pullHandle.PrimaryPart.Position
runService.RenderStepped:Connect(function(dt)
	if (player.Character.PrimaryPart.Position - weightPart.Position).Magnitude < 25 then
		local calculatedPosition = (pullHandle.PrimaryPart.Position - initialPosition).Magnitude
		weightHolderRope.Length = 8.5 - calculatedPosition
	end
end)