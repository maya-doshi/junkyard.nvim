if vim.g.loaded_junkyard then
	return
end
vim.g.loaded_junkyard = 1

vim.api.nvim_set_hl(0, "JunkyardTodoIncomplete", { link = "Todo" })
vim.api.nvim_set_hl(0, "JunkyardTodoComplete", { link = "Comment" })
vim.api.nvim_set_hl(0, "JunkyardTodoCancelled", { link = "Comment", strikethrough = true })
vim.api.nvim_set_hl(0, "JunkyardDateHeader", { link = "Title", bold = true })
vim.api.nvim_set_hl(0, "JunkyardTimestamp", { link = "Comment" })

vim.api.nvim_create_autocmd("FileType", {
	pattern = "markdown",
	callback = function()
		local bufname = vim.api.nvim_buf_get_name(0)
		if bufname:match("junkyard%.md$") or bufname:match("%d%d%d%d%-%d%d%-%d%d%.md$") then
			vim.cmd([[
        syntax match JunkyardDateHeader /\[\[\d\d\d\d-\d\d-\d\d\]\]/
        syntax match JunkyardTodoIncomplete /- \[ \].*/
        syntax match JunkyardTodoComplete /- \[x\].*/
        syntax match JunkyardTodoCancelled /- \[c\].*/
        syntax match JunkyardTimestamp /(\d\d:\d\d)/
        syntax match JunkyardTimestamp /(cancelled \d\d:\d\d)/
      ]])
		end
	end,
})

-- keymaps when in the junkyard
vim.api.nvim_create_autocmd("BufEnter", {
	pattern = "*.md",
	callback = function()
		local bufname = vim.api.nvim_buf_get_name(0)
		if bufname:match("junkyard%.md$") or bufname:match("%d%d%d%d%-%d%d%-%d%d%.md$") then
			local opts = { buffer = true, silent = true }

			vim.keymap.set("n", "<leader>jt", "<cmd>JunkyardTodoDone<cr>", opts)
			vim.keymap.set("n", "<leader>jc", "<cmd>JunkyardTodoCancel<cr>", opts)
			vim.keymap.set("n", "<leader>jn", "<cmd>JunkyardNewDay<cr>", opts)
			vim.keymap.set("n", "<leader>js", "<cmd>JunkyardSave<cr>", opts)

			vim.keymap.set("n", "<leader>jid", "<cmd>JunkyardInsertDate<cr>", opts)
			vim.keymap.set("n", "<leader>jit", "<cmd>JunkyardInsertTime<cr>", opts)
		end
	end,
})

vim.keymap.set("n", "<leader>j", "<cmd>JunkyardOpen<cr>", { desc = "Open Junkyard" })
