local module = {}

function module.formatNumber(n)
	local suffixes = {"", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc"}
	local i = 1
	local val = n
	while val >= 1000 and i < #suffixes do
		val = val / 1000
		i = i + 1
	end
	return i == 1 and tostring(math.floor(val)) or string.format("%.1f%s", val, suffixes[i])
end

return module
