local RunService = game:GetService("RunService")

local template = workspace:WaitForChild("Wave")

local MAP_WIDTH = 512
local HALF_MAP = MAP_WIDTH / 2

local startZ = 1024
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
		if root then
			-- 地面付近（安全地帯など）はスルー
			if root.Position.Y < 7 then
				return
			end
			-- 波の頂点よりプレイヤーの足元が高ければ（ジャンプして飛び越えていれば）スルー
			local waveTop = wave.Position.Y + (wave.Size.Y / 2)
			if (root.Position.Y - 3) > waveTop then
				return
			end
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

	-- 🔥 波の高さ（Yサイズ）もランダムに変更（通常の50%〜180%）
	local heightScale = math.random(50, 180) / 100
	local waveHeight = template.Size.Y * heightScale

	wave.Size = Vector3.new(
		waveWidth,
		waveHeight,
		wave.Size.Z
	)

	-- 高さが変わった時に底面が合わさるよう調整
	local heightDiffOffset = (waveHeight - template.Size.Y) / 2
	local adjustedPosition = basePosition + Vector3.new(0, heightDiffOffset, 0)

	wave.CFrame = CFrame.new(adjustedPosition) * CFrame.Angles(0, math.rad(-90), 0)

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
	time = time + dt

	for i = #waves, 1, -1 do
		local w = waves[i]
		local part = w.part

		if part and part.Parent then
			w.z = w.z - (w.speed * dt)

			if w.z < endZ then
				part:Destroy()
				table.remove(waves, i)
			else
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

				-- 高さ調整（波のサイズ変化に対応）
				local heightDiffOffset = (part.Size.Y - template.Size.Y) / 2

				part.CFrame = CFrame.new(
					w.baseX + snakeOffset,
					w.baseY + heightDiffOffset,
					w.z
				)
				* CFrame.Angles(0, math.rad(-90), 0)
			end
		else
			table.remove(waves, i)
		end
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
