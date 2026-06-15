--!strict

local SoundService = game:GetService("SoundService")
local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

local DEFAULT_VOLUME = 0.5

local MusicService = Knit.CreateService({
	Name = "MusicService",

	Client = {
		PlayMusic = function(self, player, name)
			return self.Server:PlayMusic(name)
		end,

		StopMusic = function(self)
			return self.Server:StopMusic()
		end,

		PlaySound = function(self, player, name, parent)
			return self.Server:PlaySound(name, parent)
		end,

		StopAllSounds = function(self)
			return self.Server:StopAllSounds()
		end,

		SetVolume = function(self, player, volume)
			return self.Server:SetVolume(volume)
		end,

		GetSoundId = function(self, player, name, groupName)
			return self.Server:GetSoundId(name, groupName)
		end,
	},

	_currentBGM = nil,
	_activeSounds = {},
	_currentVolume = DEFAULT_VOLUME,
	_soundIdCache = {},

	GetSoundId = function(self, name, groupName)
		groupName = groupName or "SoundGroup"
		local key = groupName .. "/" .. name
		if self._soundIdCache[key] then
			return self._soundIdCache[key]
		end
		local template = self:_FindSoundInGroup(groupName, name)
		if template then
			local id = template.SoundId
			self._soundIdCache[key] = id
			return id
		end
		return nil
	end,

	_FindSoundInGroup = function(self, groupName, soundName)
		local group = SoundService:FindFirstChild(groupName)
		if not group then return nil end
		local sound = group:FindFirstChild(soundName)
		if sound and sound:IsA("Sound") then
			return sound
		end
		for _, child in ipairs(group:GetChildren()) do
			if child:IsA("Sound") and child.Name == soundName then
				return child
			end
		end
		return nil
	end,

	PlayMusic = function(self, name)
		local template = self:_FindSoundInGroup("MusicGroup", name)
		if not template then
			warn("MusicService: BGM not found:", name)
			return false
		end

		self:StopMusic()

		local bgm = template:Clone()
		bgm.Name = "BGM_Active"
		bgm.Volume = self._currentVolume
		bgm.Looped = true
		bgm.Parent = SoundService
		bgm:Play()

		self._currentBGM = bgm
		return true
	end,

	StopMusic = function(self)
		if self._currentBGM then
			self._currentBGM:Stop()
			self._currentBGM:Destroy()
			self._currentBGM = nil
		end
	end,

	PlaySound = function(self, name, parent: Instance?)
		local template = self:_FindSoundInGroup("SoundGroup", name)
		if not template then
			warn("MusicService: Sound not found:", name)
			return false
		end

		local sound = template:Clone()
		sound.Name = "SFX_" .. name
		sound.Volume = self._currentVolume
		sound.Looped = false

		if parent then
			sound.Parent = parent
		else
			sound.Parent = SoundService
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

		return true
	end,

	StopAllSounds = function(self)
		for _, sound in ipairs(self._activeSounds) do
			if sound and sound.Parent then
				sound:Stop()
				sound:Destroy()
			end
		end
		self._activeSounds = {}
	end,

	SetVolume = function(self, volume)
		self._currentVolume = math.clamp(volume, 0, 1)
		if self._currentBGM then
			self._currentBGM.Volume = self._currentVolume
		end
	end,

	KnitInit = function(self)
		print("MusicService initialized")
	end,

	KnitStart = function(self)
		print("MusicService started")
	end,
})

return MusicService
