Dokumentasi: SkillR ECS (Input → Request → System → Animasi + VFX)
1) Tujuan

Membuat arsitektur skill yang:

Rapi & scalable (tambah skill baru tidak bikin script jadi spaghetti)

Secure (server yang memutuskan efek/damage)

Responsif (client bisa play animasi cepat, server tetap authoritative untuk VFX/damage)

2) Konsep ECS Singkat
Entity

“ID” yang mewakili sesuatu (contoh: player).
Entity tidak harus Instance Roblox, biasanya hanya angka/id.

Component

Data kecil yang ditempel ke entity.

Contoh:

CharacterRef → simpan reference character

WantsSkillR → request skill R (data request)

Cooldown → data cooldown

System

Loop yang mencari entity dengan komponen tertentu dan menjalankan logika.

Contoh:

skillRSystem → cari entity yang punya WantsSkillR + CharacterRef, lalu:

play animasi

spawn VFX

hapus WantsSkillR

Rule utama:
✅ Remote handler hanya mengubah event menjadi komponen request
❌ Jangan spawn VFX/damage di handler

3) Struktur Folder Rekomendasi
ReplicatedStorage
└── Remotes
    └── SkillRequest (RemoteEvent)

ReplicatedStorage
└── VFX
    └── RedExplosion (Model / Folder VFX)

StarterPlayer
└── StarterPlayerScripts
    └── input.client.lua

ServerScriptService
└── Server
    ├── init.server.lua
    ├── skillRequestHandler.server.lua
    ├── playerEntityBinder.server.lua
    └── ecsLoop.server.lua

ReplicatedStorage (atau src)
└── matter
    ├── components
    │   ├── CharacterRef.lua
    │   ├── WantsSkillR.lua
    │   └── Cooldown.lua (optional)
    └── systems
        ├── characterSystem.lua
        ├── cooldownSystem.lua (optional)
        └── skillRSystem.lua


Kalau project kamu sudah punya struktur matter/components dan matter/systems seperti screenshot, ini tinggal menyesuaikan nama file.

4) Remote & Komunikasi Client-Server
RemoteEvent: ReplicatedStorage.Remotes.SkillRequest

Payload sederhana:

Client → Server: "SkillR"

Kenapa string?

gampang debug

gampang di-extend "SkillQ", "SkillE", dll

5) Implementasi Lengkap (Contoh Kode)
5.1 Client: Input tekan R → FireServer

StarterPlayerScripts/input.client.lua

local UIS = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("SkillRequest")

UIS.InputBegan:Connect(function(input, gameProcessedEvent)
	if gameProcessedEvent then return end

	if input.KeyCode == Enum.KeyCode.R then
		remote:FireServer("SkillR")
	end
end)


Opsional: Kamu bisa play animasi client di sini untuk “feels” lebih cepat, tapi contoh ini fokus server-side.

5.2 Components
A) WantsSkillR (Request Component)

matter/components/WantsSkillR.lua

return function(data)
	return data or { t = os.clock() }
end

B) CharacterRef (Reference Character)

matter/components/CharacterRef.lua

return function(character)
	return { character = character }
end

C) Cooldown (Optional tapi disarankan)

matter/components/Cooldown.lua

return function()
	return { r = 0 } -- cooldown skill R dalam detik
end

5.3 Binding Player → Entity (Mapping)

Kamu butuh mapping:

playerEntity[player] = entityId

Server/playerEntityBinder.server.lua

local Players = game:GetService("Players")

return function(world, components)
	local playerEntity = {}

	Players.PlayerAdded:Connect(function(player)
		-- buat entity baru untuk player
		local id = world:spawn()
		playerEntity[player] = id

		-- attach default component (misal cooldown)
		world:insert(id, components.Cooldown())

		player.CharacterAdded:Connect(function(character)
			-- simpan reference character ke component
			world:insert(id, components.CharacterRef(character))
		end)

		player.AncestryChanged:Connect(function(_, parent)
			if parent == nil then
				-- player keluar, hapus entity
				local eid = playerEntity[player]
				if eid then
					world:despawn(eid)
				end
				playerEntity[player] = nil
			end
		end)
	end)

	return playerEntity
end

5.4 Remote Handler: “SkillRequest” → insert WantsSkillR

Server/skillRequestHandler.server.lua

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("SkillRequest")

return function(world, components, playerEntity)
	remote.OnServerEvent:Connect(function(player, skillName)
		if skillName ~= "SkillR" then return end

		local entityId = playerEntity[player]
		if not entityId then return end

		-- request component (eksekusi ada di System!)
		world:insert(entityId, components.WantsSkillR({ t = os.clock() }))
	end)
end

5.5 System: Cooldown (Optional)

matter/systems/cooldownSystem.lua

return function(world, components, dt)
	for id, cd in world:query(components.Cooldown) do
		if cd.r > 0 then
			cd.r = math.max(0, cd.r - dt)
			world:replace(id, components.Cooldown, cd)
		end
	end
end

5.6 System: SkillR (Animasi + VFX Model)

Ini bagian utama yang kamu minta: clone VFX model + loop children.

matter/systems/skillRSystem.lua

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local VFX_TEMPLATE = ReplicatedStorage:WaitForChild("VFX"):WaitForChild("RedExplosion")

-- (Opsional) animation id
local ANIM_ID = "rbxassetid://ANIM_ID"

local function playAnimation(character)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	local anim = Instance.new("Animation")
	anim.AnimationId = ANIM_ID

	local track = humanoid:LoadAnimation(anim)
	track:Play()
end

local function spawnVFXAtHRP(character)
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	local parts = VFX_TEMPLATE:Clone()
	parts.Parent = workspace

	-- posisikan VFX ke HRP
	if parts:IsA("Model") then
		if not parts.PrimaryPart then
			local pp = parts:FindFirstChildWhichIsA("BasePart", true)
			if pp then parts.PrimaryPart = pp end
		end
		if parts.PrimaryPart then
			parts:PivotTo(hrp.CFrame)
		end
	elseif parts:IsA("BasePart") then
		parts.CFrame = hrp.CFrame
	end

	-- penting:
	-- GetChildren() hanya level 1. Jika VFX nested, pakai GetDescendants()
	for _, inst in ipairs(parts:GetDescendants()) do
		if inst:IsA("BasePart") then
			inst.Anchored = false
			inst.CanCollide = false
			inst.CFrame = hrp.CFrame

			-- weld agar VFX ikut gerak player (opsional)
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = hrp
			weld.Part1 = inst
			weld.Parent = inst
		end

		-- auto emit particle kalau ada emitter
		if inst:IsA("ParticleEmitter") then
			inst:Emit(inst:GetAttribute("Burst") or 30)
		end
	end

	-- cleanup VFX
	Debris:AddItem(parts, 2)
end

return function(world, components)
	for id, wants, cref, cd in world:query(
		components.WantsSkillR,
		components.CharacterRef,
		components.Cooldown
	) do
		local character = cref.character
		if not character or not character.Parent then
			world:remove(id, components.WantsSkillR)
			continue
		end

		-- cooldown check
		if cd.r > 0 then
			world:remove(id, components.WantsSkillR)
			continue
		end

		-- eksekusi skill
		playAnimation(character)
		spawnVFXAtHRP(character)

		-- set cooldown (misal 3 detik)
		cd.r = 3
		world:replace(id, components.Cooldown, cd)

		-- hapus request
		world:remove(id, components.WantsSkillR)
	end
end

5.7 ECS Loop / Init Server

Ini contoh sederhana “tick loop” yang memanggil systems.

Server/ecsLoop.server.lua

local RunService = game:GetService("RunService")

return function(world, systems, components)
	local last = os.clock()

	RunService.Heartbeat:Connect(function()
		local now = os.clock()
		local dt = now - last
		last = now

		-- urutan system
		systems.cooldownSystem(world, components, dt)
		systems.skillRSystem(world, components)
	end)
end


Server/init.server.lua

-- pseudo: sesuaikan dengan cara kamu membuat world dari matter
local matter = require(ReplicatedStorage.Shared.matter) -- contoh path
local world = matter.World.new()

local components = {
	CharacterRef = require(ReplicatedStorage.Shared.matter.components.CharacterRef),
	WantsSkillR = require(ReplicatedStorage.Shared.matter.components.WantsSkillR),
	Cooldown = require(ReplicatedStorage.Shared.matter.components.Cooldown),
}

local systems = {
	skillRSystem = require(ReplicatedStorage.Shared.matter.systems.skillRSystem),
	cooldownSystem = require(ReplicatedStorage.Shared.matter.systems.cooldownSystem),
}

local bindPlayers = require(script.Parent.playerEntityBinder.server)
local playerEntity = bindPlayers(world, components)

local setupHandler = require(script.Parent.skillRequestHandler.server)
setupHandler(world, components, playerEntity)

local loop = require(script.Parent.ecsLoop.server)
loop(world, systems, components)


Catatan: cara import matter/World.new() bisa beda tergantung setup kamu. Intinya pola init-nya seperti ini.

6) Checklist VFX Model supaya aman

Agar VFX kamu tidak error:

ReplicatedStorage.VFX.RedExplosion harus ada

Kalau Model, idealnya punya PrimaryPart (kalau tidak, kode di atas coba set otomatis)

Kalau VFX nested, gunakan GetDescendants() (sudah aku pakai)


7) Best Practice (Penting)

Remote handler jangan menjalankan VFX/damage

handler = translate input → request component

Server yang menjalankan efek yang “berpengaruh”

VFX bisa server atau client (tergantung kebutuhan)

damage/hitbox wajib server

Request component harus dihapus setelah dieksekusi

supaya skill tidak kepanggil berulang di frame berikutnya

Cooldown taruh di component + system

bukan debounce variable di satu script besar