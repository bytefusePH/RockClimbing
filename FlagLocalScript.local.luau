local flagsFolder = game.Workspace:WaitForChild("Props"):WaitForChild("Flags")
local flagAnimationId = "rbxassetid://140234601545028"
for i, flag in flagsFolder:GetChildren() do
	local animation = flag:FindFirstChildOfClass("Animation")
	local animationController = flag:FindFirstChildOfClass("AnimationController")
	local animationTrack = animationController:LoadAnimation(animation)
	coroutine.wrap(function()
		task.wait(math.random(1, 5))
		animationTrack:Play()
	end)()
end