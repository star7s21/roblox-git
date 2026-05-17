local RunService = game:GetService("RunService")

local template = workspace:WaitForChild("Wave")

local MAP_WIDTH = 512
local HALF_MAP = MAP_WIDTH / 2

local startZ = 512
local endZ = -700

local minSpeed = 50
local maxSpeed = 150

local minWait = 1
local maxWait = 4

local waves = {}

---------------------------------------------------
-- 当たり判定
---------------------------------------------------
local Players = game:GetService("Players")

local function setupWave(wave)
	wave.Touched:Connect(function(hit)

		if hit.Name ~= "HumanoidRootPart" then
			return
		end

		local character = hit:FindFirstAncestorOfClass("Model")
		if not character then return end

		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if not humanoid then return end

		-- プレイヤー以外除外
		if not Players:GetPlayerFromCharacter(character) then
			return
		end

		local root = character:FindFirstChild("HumanoidRootPart")
		if root and root.Position.Y < 7 then
			return
		end

		humanoid.Health = 0
	end)
end

---------------------------------------------------
-- 波生成
---------------------------------------------------
local function spawnWave()

	local wave = template:Clone()
	wave.Parent = workspace

	-- 🔥 サイズ調整（小さい波を増やすため偏り変更）
	local r = math.random()
	local widthScale

	if r < 0.6 then
		widthScale = math.random(20, 60) / 100 -- 小波多め
	elseif r < 0.9 then
		widthScale = math.random(50, 80) / 100 -- 中波
	else
		widthScale = math.random(80, 100) / 100 -- 大波少し
	end

	local waveWidth = template.Size.X * widthScale

	-- はみ出し防止
	local maxXOffset = HALF_MAP - (waveWidth / 2)
	local xOffset = math.random(-maxXOffset, maxXOffset)

	local basePosition = Vector3.new(xOffset, 57, startZ)

	wave.Size = Vector3.new(
		waveWidth,
		wave.Size.Y,
		wave.Size.Z
	)

	wave.CFrame = CFrame.new(basePosition) * CFrame.Angles(0, math.rad(-90), 0)

	local speed = math.random(minSpeed, maxSpeed)

	-- 🔥 小さい波だけ蛇行（40%以下）
	local snakeEnabled = widthScale <= 0.4

	local data = {
		part = wave,
		baseX = basePosition.X,
		baseY = basePosition.Y,
		z = startZ,
		speed = speed,
		phase = math.random() * math.pi * 2,
		snakeEnabled = snakeEnabled,
		intensity = math.random(8, 20) -- 派手さ
	}

	table.insert(waves, data)

	setupWave(wave)
end

---------------------------------------------------
-- 更新処理
---------------------------------------------------
local time = 0

RunService.Heartbeat:Connect(function(dt)
	time += dt

	for i = #waves, 1, -1 do
		local w = waves[i]
		local part = w.part

		if not part or not part.Parent then
			table.remove(waves, i)
			continue
		end

		w.z -= w.speed * dt

		if w.z < endZ then
			part:Destroy()
			table.remove(waves, i)
			continue
		end

		---------------------------------------------------
		-- 🌊 蛇行（派手版）
		---------------------------------------------------
		local snakeOffset = 0

		if w.snakeEnabled then
			local t = time * 4 + w.phase

			-- 横揺れ + 波状揺れ（2段構造）
			snakeOffset =
				math.sin(t) * w.intensity +
				math.sin(t * 0.5) * (w.intensity * 1.5)
		end

		part.CFrame = CFrame.new(
			w.baseX + snakeOffset,
			w.baseY,
			w.z
		)
		* CFrame.Angles(0, math.rad(-90), 0)
	end
end)

---------------------------------------------------
-- スポーン
---------------------------------------------------
task.spawn(function()
	while true do
		spawnWave()
		task.wait(math.random(minWait, maxWait))
	end
end)