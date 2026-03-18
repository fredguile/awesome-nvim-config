-- Setup "alternate" mappings for JS/TS files
-- @see https://github.com/sabinmarcu/config.nvim/blob/971e2bf83e072de40ead5171d76786e0788a9a41/lua/plugins/other.lua
local extensions = { "ts", "tsx", "js", "jsx", "mjs", "cjs", "css" }

local targets = {
	default = "source",
	css = "vanilla css",
	stories = "stories",
	spec = "spec",
	jest = "jest test",
	test = "generic test",
	type = "type file",
	mdx = "mdx documentation",
	["type.spec"] = "type spec",
}

local mappings = {}
local function getMid(target)
	if target == "default" then
		return ""
	end
	return "." .. target
end

local function processTarget(patternTarget)
	for _, extension in pairs(extensions) do
		local mapping = {}
		local mappingTargets = {}
		for target, targetDescription in pairs(targets) do
			if target ~= patternTarget then
				for _, targetExtension in pairs(extensions) do
					local newTarget = {
						target = "%1" .. getMid(target) .. "." .. targetExtension,
						context = targetDescription,
					}
					mappingTargets[#mappingTargets + 1] = newTarget
				end
			end
		end
		mapping["pattern"] = "(.*)" .. getMid(patternTarget) .. "." .. extension .. "$"
		mapping["target"] = mappingTargets
		mappings[#mappings + 1] = mapping
	end
end

for patternTarget, patternTargetDescription in pairs(targets) do
	if patternTarget ~= "default" then
		processTarget(patternTarget)
	end
end

processTarget("default")

return {
	{
		"rgroli/other.nvim",
		event = "VeryLazy",
		cond = true,
		config = function()
			require("other-nvim").setup({
				mappings = mappings,
				showMissingFiles = false,
			})
		end,
		keys = {
			{ "gt", "<cmd>Other<cr>", desc = "Open 'other' file" },
			{ "gtt", "<cmd>Other<cr>", desc = "Open 'other' file" },
			{ "gt\\", "<cmd>OtherVSplit<cr>", desc = "Open 'other' vertical split file" },
			{ "gt-", "<cmd>OtherSplit<cr>", desc = "Open 'other' split file" },
		},
	},
}
