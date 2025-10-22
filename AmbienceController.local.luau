local soundService = game:GetService("SoundService")
local runService = game:GetService("RunService")
local players = game:GetService("Players")
local player = players.LocalPlayer
local lowAmbience = "LowAmbience"
local highAmbience = "HighAmbience"
local ambienceSound = soundService.Ambience
local lowAmbienceLevel = 150
local highAmbienceLevel = lowAmbienceLevel * 2
local ambienceInfo = TweenInfo.new(5, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut)
local initialPosition = Vector3.new(0, 0, 0)
local targetVolume = 0
player.CharacterAdded:Connect(function(character)
	initialPosition = character.PrimaryPart.Position
end)
runService.Heartbeat:Connect(function(dt)
	if not player.Character.PrimaryPart then return end
	local yPosition = (player.Character.PrimaryPart.Position - initialPosition).Y
	if yPosition > lowAmbienceLevel and yPosition < highAmbienceLevel then
		if ambienceSound.IsPlaying == false then
			ambienceSound:Play()
		end
		targetVolume = 0.25
	elseif yPosition > highAmbienceLevel then
		if ambienceSound.IsPlaying == false then
			ambienceSound:Play()
		end
		targetVolume = 0.4
	else
		targetVolume = 0
		if ambienceSound.IsPlaying then
			ambienceSound.Volume = math.max(0, ambienceSound.Volume - (0.1 * dt))
			if ambienceSound.Volume <= 0 then
				ambienceSound:Stop()
			end
		end
	end
	if targetVolume ~= 0 then
		if math.abs(ambienceSound.Volume - targetVolume) > 0.01 then
			ambienceSound.Volume += (ambienceSound.Volume > targetVolume and -0.1 or 0.1) * dt
			ambienceSound.Volume = math.clamp(ambienceSound.Volume, 0, 1)
		end
	end
end)