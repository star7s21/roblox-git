local template = workspace:WaitForChild("Wave")

local startZ = 1024
local endZ = -705

local minSpeed = 80
local maxSpeed = 200

local minWait = 1
local maxWait = 4

-- 当たり判定
local function setupWave(wave)
	wave.Touched:Connect(function(hit)

		local character = hit.Parent
		local humanoid = character:FindFirstChild("Humanoid")

		if humanoid then
			local root = character:FindFirstChild("HumanoidRootPart")

			if root and root.Position.Y < 7 then
				return
			end

			humanoid.Health = 0
		end
	end)
end

-- 津波生成
local function spawnWave()

	local wave = template:Clone()
	wave.Parent = workspace

	-- ランダム横位置（例: 横方向にも少しランダム性を加える場合）
	-- local x = math.random(-50, 50)
	-- Y座標を少しランダムにする
	local yOffset = math.random(-5, 5)
	wave.CFrame = CFrame.new(0, 57 + yOffset, startZ)

	-- ランダム速度
	local speed = math.random(minSpeed, maxSpeed)

	setupWave(wave)

	-- 移動（並列処理）
	task.spawn(function()
		while wave and wave.Parent and wave.CFrame.Position.Z > endZ do
			local dt = task.wait()
			-- CFrame を使用して更新
			wave.CFrame = wave.CFrame * CFrame.new(0, 0, -speed * dt)
		end

		wave:Destroy()
	end)
end

-- 無限ループ
while true do
	spawnWave()

	-- ランダム間隔
	task.wait(math.random(minWait, maxWait))
end
