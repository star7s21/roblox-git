game.Players.PlayerAdded:Connect(function(player)

	player.CharacterAdded:Connect(function(character)

		local humanoid = character:WaitForChild("Humanoid")

		humanoid.Died:Connect(function()

			print(player.Name .. " died")

			-- Treasureタグ削除
			local treasure = player:FindFirstChild("HasTreasure")
			if treasure then
				treasure:Destroy()
			end

			-- 頭に持っているTreasure削除f
			local carried = character:FindFirstChild("CarriedTreasure")
			if carried then
				carried:Destroy()
			end

		end)

	end)

end)