local players = game:GetService("Players")
local soundService = game:GetService("SoundService")
local songs = {}
local musicFolder = game.ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Music")
for i, music in ipairs(musicFolder:GetChildren()) do
	if music:IsA("Sound") then
		table.insert(songs, {Name = music.Name, id = music.SoundId})
	end
end
local currentIndex = math.random(1, #songs)
local serverRemotes = game.ReplicatedStorage:WaitForChild("ServerRemotes")
local updateBoombox = serverRemotes:WaitForChild("UpdateBoombox")
local boomboxVolumeChanged = serverRemotes:WaitForChild("BoomboxVolumeChanged")
local audioPlayer = soundService:WaitForChild("BoomboxMusic")
local currentMode = "Medium"
players.PlayerAdded:Connect(function(player)
	updateBoombox:FireClient(player, songs[currentIndex])
	boomboxVolumeChanged:FireClient(player, nil, currentMode)
end)
function PlaySong(index)
	audioPlayer:Stop()
	local song = songs[index]
	audioPlayer.SoundId = song.id
	currentIndex = index
	audioPlayer.TimePosition = 0
	audioPlayer:Play()
	updateBoombox:FireAllClients(songs[currentIndex])
end
function SwitchSong(nextSong)
	local newIndex = nextSong == true and currentIndex + 1 or currentIndex - 1
	if newIndex > #songs then
		newIndex = 1
	elseif newIndex <= 0 then
		newIndex = #songs
	end
	PlaySong(newIndex <= #songs and newIndex or 1)
end
updateBoombox.OnServerEvent:Connect(function(player, action)
	if action == "Pause" then
		audioPlayer:Stop()
	elseif action == "Play" then
		audioPlayer:Play()
	elseif action == "Next" or action == "Previous" then
		SwitchSong(action == "Next")
	end
end)
audioPlayer.Ended:Connect(function()
	SwitchSong(true)
end)
PlaySong(currentIndex)
boomboxVolumeChanged.OnServerEvent:Connect(function(player, mode)
	currentMode = mode
	boomboxVolumeChanged:FireAllClients(player.UserId, mode)
end)
