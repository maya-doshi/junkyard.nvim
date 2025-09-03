local M = {}
local utils = require("junkyard.utils")
local config = require("junkyard.config")

-- #TODO: figure setting config variables
function M.setup(opts)
	if vim.fn.isdirectory(config.notes_dir) == 0 then
		vim.fn.mkdir(config.notes_dir, "p")
	end

	M.setup_commands()
	M.setup_autocommands()
end

function M.setup_commands()
	vim.api.nvim_create_user_command("JunkyardOpen", function()
		M.open_junkyard()
	end, { desc = "Open junkyard notes" })

	vim.api.nvim_create_user_command("JunkyardNewDay", function()
		M.new_day()
	end, { desc = "Create new day and carry over todos" })

	vim.api.nvim_create_user_command("JunkyardSave", function()
		M.save_notes()
	end, { desc = "Save and split junkyard notes into daily files" })

	vim.api.nvim_create_user_command("JunkyardTodoDone", function()
		utils.todo_done()
	end, { desc = "Toggle todo item status" })

	vim.api.nvim_create_user_command("JunkyardTodoCancel", function()
		utils.todo_cancel()
	end, { desc = "Toggle todo item status" })

	vim.api.nvim_create_user_command("JunkyardInsertDate", function()
		utils.insert_date(config.date_format)
	end, { desc = "Insert current date" })

	vim.api.nvim_create_user_command("JunkyardInsertTime", function()
		utils.insert_time(config.time_format)
	end, { desc = "Insert current time" })
end

function M.setup_autocommands()
	local group = vim.api.nvim_create_augroup("Junkyard", { clear = true })

	if config.auto_save then
		vim.api.nvim_create_autocmd("BufWritePost", {
			group = group,
			pattern = config.notes_dir .. "/*.md",
			callback = function()
				if vim.bo.filetype == "markdown" then
					M.save_notes()
				end
			end,
		})
	end
end

function M.open_junkyard()
	local junkyard_file = config.notes_dir .. "/junkyard.md"

	M.create_junkyard_view()

	vim.cmd("edit " .. junkyard_file)

	vim.bo.filetype = "markdown"
	vim.wo.wrap = true
	vim.wo.linebreak = true
end

function M.create_junkyard_view()
	local junkyard_file = config.notes_dir .. "/junkyard.md"
	local daily_files = utils.get_daily_files(config.notes_dir)

	local content = {}

	table.sort(daily_files, function(a, b)
		return a > b
	end)

	for i, date in ipairs(daily_files) do
		if i > config.carry_over_days then
			break
		end

		local file_path = config.notes_dir .. "/" .. date .. ".md"
		if vim.fn.filereadable(file_path) == 1 then
			local file_content = vim.fn.readfile(file_path)

			table.insert(content, "[[" .. date .. "]]")

			for j, line in ipairs(file_content) do
				if j > 1 or not line:match("^%[%[%d%d%d%d%-%d%d%-%d%d%]%]") then
					table.insert(content, line)
				end
			end

			table.insert(content, "")
		end
	end

	vim.fn.writefile(content, junkyard_file)
end

function M.new_day()
	local today = utils.get_current_date()
	local today_file = config.notes_dir .. "/" .. today .. ".md"

	if vim.fn.filereadable(today_file) == 1 then
		vim.cmd("edit " .. today_file)
		return
	end

	local content = { "[[" .. today .. "]]" }

	if config.carry_over_todos then
		local incomplete_todos = M.get_incomplete_todos()
		if #incomplete_todos > 0 then
			for _, todo in ipairs(incomplete_todos) do
				table.insert(content, todo)
			end
			table.insert(content, "")
		end
	end

	vim.fn.writefile(content, today_file)
	vim.cmd("edit " .. today_file)

	vim.cmd("normal! G")
end

function M.get_incomplete_todos()
	local last_day = utils.get_latest_note(config.notes_dir)
	local incomplete_todos = {}
	local file_content = vim.fn.readfile(last_day)

	for _, line in ipairs(file_content) do
		if line:match("^%s*%- %[ %]") then
			table.insert(incomplete_todos, line)
		end
	end

	return incomplete_todos
end

function M.save_notes()
	local junkyard_file = config.notes_dir .. "/junkyard.md"

	if vim.fn.filereadable(junkyard_file) == 0 then
		return
	end

	local content = vim.fn.readfile(junkyard_file)
	local current_date = nil
	local current_content = {}

	for _, line in ipairs(content) do
		local date_match = line:match("^%[%[(%d%d%d%d%-%d%d%-%d%d)%]%]")

		if date_match then
			if current_date and #current_content > 0 then
				M.save_daily_file(current_date, current_content)
				break
			end

			current_date = date_match
			current_content = { line }
		elseif current_date then
			table.insert(current_content, line)
		end
	end
end

function M.save_daily_file(date, content)
	local file_path = config.notes_dir .. "/" .. date .. ".md"

	while #content > 0 and content[#content]:match("^%s*$") do
		table.remove(content)
	end

	if #content > 0 then
		vim.fn.writefile(content, file_path)
	end
end

return M
