return {
	"MeanderingProgrammer/render-markdown.nvim",
	ft = { "markdown", "codecompanion" },
	opts = {
		render_modes = true,
		sign = { enabled = false },
		-- Default (applies to plain *.md files, which typically have the full
		-- editor width available): fully-bordered but column-width-optimized
		-- tables (shrink each column to its actual content width instead of
		-- preserving/extending whatever whitespace padding the source file has).
		pipe_table = {
			preset = "round", -- rounded box-drawing border corners
			cell = "trimmed", -- shrink columns to content width, ignore source padding
			style = "full", -- draw top & bottom border lines
		},
		-- Tables wider than the window get corrupted by Neovim's soft-wrap: the
		-- box-drawing border/pipe extmarks are anchored to source byte columns, so
		-- when a long row wraps mid-cell the borders visibly overlap/misalign with
		-- the row above (this is what shows up as "overlapping table headers").
		-- Turn `wrap` off only while the *rendered* view is showing (wide tables
		-- then simply scroll horizontally instead of breaking); raw editing keeps
		-- whatever `wrap` was already set to.
		win_options = {
			wrap = {
				default = vim.o.wrap,
				rendered = false,
			},
		},
	},
}
