local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
local SoundService = game:GetService("SoundService")
local Players = game:GetService("Players")

local SOUND_IDS = {
	shoot = { id = "rbxassetid://8595974357" },
	coins = { id = "rbxassetid://662290183" },
	Sprint = { id = "rbxassetid://12221842", startTime = 1 },
}

local SoundController = Knit.CreateController({
	Name = "SoundController",

	_activeSounds = {},

	_Play = function(self, name, parent)
		local config = SOUND_IDS[name]
		if not config then return end

		local sound = Instance.new("Sound")
		sound.Name = "SFX_" .. name
		sound.SoundId = config.id
		sound.Volume = 0.6
		sound.Looped = false
		if config.startTime then
			sound.TimePosition = config.startTime
		end

		if parent then
			sound.Parent = parent
		else
			local player = Players.LocalPlayer
			local char = player and player.Character
			if char then
				sound.Parent = char:FindFirstChild("HumanoidRootPart") or char
			else
				sound.Parent = SoundService
			end
		end

		sound:Play()
		table.insert(self._activeSounds, sound)

		sound.Ended:Connect(function()
			sound:Destroy()
			for i, s in ipairs(self._activeSounds) do
				if s == sound then
					table.remove(self._activeSounds, i)
					break
				end
			end
		end)
	end,

	KnitStart = function(self)
		local ReplicatedStorage = game:GetService("ReplicatedStorage")
		local soundEvent = ReplicatedStorage:WaitForChild("SoundEvent", 5)
		if soundEvent and soundEvent:IsA("RemoteEvent") then
			print("SoundController: SoundEvent connected")
			soundEvent.OnClientEvent:Connect(function(soundName)
					self:_Play(soundName)
			end)
		else
			warn("SoundController: SoundEvent not found after 5s")
		end

		print("SoundController started")
	end,

	KnitInit = function(self)
		print("SoundController initialized")
	end,
})

return SoundController

