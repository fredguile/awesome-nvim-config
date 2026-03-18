return {
	"David-Kunz/jester",
	enabled = false,
	config = function()
		require("jester").setup({
			cmd = function()
				return "echo hello"
			end,
		})
	end,
}
