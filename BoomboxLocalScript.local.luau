local runService = game:GetService("RunService")
local soundService = game:GetService("SoundService")
local boombox = game.Workspace:WaitForChild("Props"):WaitForChild("Boombox")
local audioPlayer = soundService:WaitForChild("BoomboxMusic")
local players = game:GetService("Players")
local player = players.LocalPlayer
local musicPlayer = script.Parent
local songTitleText = musicPlayer:WaitForChild("SongName")
local buttonsFolder = musicPlayer:WaitForChild("Buttons")
local nextButton = buttonsFolder:WaitForChild("Next")
local pauseButton = buttonsFolder:WaitForChild("Pause")
local playButton = buttonsFolder:WaitForChild("Play")
local previousButton = buttonsFolder:WaitForChild("Previous")
local canInteract = true
local serverRemotes = game.ReplicatedStorage:WaitForChild("ServerRemotes")
local updateBoombox = serverRemotes:WaitForChild("UpdateBoombox")
local boomboxVolumeChanged = serverRemotes:WaitForChild("BoomboxVolumeChanged")
function CooldownButtons()
	if canInteract == true then
		coroutine.wrap(function()
			canInteract = false
			for i, button in buttonsFolder:GetDescendants() do
				if button:IsA("ImageButton") then
					button.Interactable = false
				end
			end
			task.wait(2.5)
			for i, button in buttonsFolder:GetDescendants() do
				if button:IsA("ImageButton") then
					button.Interactable = true
				end
			end
			canInteract = true
		end)()
	end
end
local function ButtonInteraction(action)
	updateBoombox:FireServer(action)
	CooldownButtons()
end
nextButton.Activated:Connect(function()
	ButtonInteraction("Next")
end)
previousButton.Activated:Connect(function()
	ButtonInteraction("Previous")
end)
playButton.Activated:Connect(function()
	ButtonInteraction("Play")
end)
pauseButton.Activated:Connect(function()
	ButtonInteraction("Pause")
end)
updateBoombox.OnClientEvent:Connect(function(song)
	songTitleText.Text = song.Name
end)
local progression = musicPlayer:WaitForChild("Progression")
local duration = musicPlayer:WaitForChild("Duration")
local maxDistance = 450
local minDistance = 150
local baseVolume = 0.2
local targetVolume = baseVolume
runService.RenderStepped:Connect(function(dt)
	progression	.Size = UDim2.new(
		math.clamp(audioPlayer.TimePosition / audioPlayer.TimeLength, 0, 1), 
		0, 0.15, 0
	)
	duration.Text = string.format("%i:%02i / %i:%02i",
		math.floor(audioPlayer.TimePosition / 60),
		audioPlayer.TimePosition % 60,
		math.floor(audioPlayer.TimeLength / 60),
		audioPlayer.TimeLength % 60
	)
	if player.Character.PrimaryPart and boombox.PrimaryPart then
		local boomboxDistance = (player.Character.PrimaryPart.Position - boombox.PrimaryPart.Position).Magnitude
		local rawVolume = 1 - ((boomboxDistance - minDistance) / (maxDistance - minDistance))
		audioPlayer.Volume = math.clamp(rawVolume * targetVolume, 0, targetVolume)
	else
		audioPlayer.Volume = 0
	end
end)
local sliderRenderstep = nil
local volumeSlider = buttonsFolder:WaitForChild("VolumeSlider")
local volumeSliderKnob = volumeSlider:WaitForChild("Knob")
local muteVolumeButton = volumeSlider:WaitForChild("MuteVolumeButton")
local lowVolumeButton = volumeSlider:WaitForChild("LowVolumeButton")
local mediumVolumeButton = volumeSlider:WaitForChild("MediumVolumeButton")
local highVolumeButton = volumeSlider:WaitForChild("HighVolumeButton")
local tweenService = game:GetService("TweenService")
local knobTweenInfo = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local function LerpKnob(newX)
	local knobTween = tweenService:Create(volumeSliderKnob, knobTweenInfo, {Position = UDim2.new(newX, 0, 0.5, 0)})
	knobTween:Play()
	return knobTween
end
local linesFolder = volumeSlider:WaitForChild("Lines")
function ChangeVolume(mode)
	CooldownButtons()
	local newX = linesFolder:WaitForChild(mode .. "Line").Position.X.Scale
	if mode == "Mute" then
		targetVolume = 0
	elseif mode == "Low" then
		targetVolume = baseVolume * 0.5
	elseif mode == "Medium" then
		targetVolume = baseVolume
	elseif mode == "High" then
		targetVolume = baseVolume * 1.5
	end
	LerpKnob(newX)
	boomboxVolumeChanged:FireServer(mode)
end
muteVolumeButton.Activated:Connect(function() ChangeVolume("Mute") end)
lowVolumeButton.Activated:Connect(function() ChangeVolume("Low") end)
mediumVolumeButton.Activated:Connect(function() ChangeVolume("Medium") end)
highVolumeButton.Activated:Connect(function() ChangeVolume("High") end)
boomboxVolumeChanged.OnClientEvent:Connect(function(userId, mode)
	if userId == player.UserId then return end
	ChangeVolume(mode)
end)