local M = {}
local api = vim.api
local fn = vim.fn
local utils = require("junkyard.utils")
local config = require("junkyard.config")

M.config = {
	notes_dir = vim.fn.expand("~/notes"),
	date_format = "[%Y-%m-%d]",
	time_format = "%H:%M",
	datetime_format = "%Y-%m-%d %H:%M",
	carry_over_todos = true,
	carry_over_days = 7,
	auto_save = true,
}

function M.setup(opts)
	M.config = vim.tbl_deep_extend("force", M.config, opts or {})

	if fn.isdirectory(M.config.notes_dir) == 0 then
		fn.mkdir(M.config.notes_dir, "p")
	end

	M.setup_commands()
	M.setup_autocommands()
end

function M.setup_commands()
	api.nvim_create_user_command("JunkyardOpen", function()
		M.open_junkyard()
	end, { desc = "Open junkyard notes" })

	api.nvim_create_user_command("JunkyardNewDay", function()
		M.new_day()
	end, { desc = "Create new day and carry over todos" })

	api.nvim_create_user_command("JunkyardSave", function()
		M.save_notes()
	end, { desc = "Save and split junkyard notes into daily files" })

	api.nvim_create_user_command("JunkyardTodoDone", function()
		M.todo_done()
	end, { desc = "Toggle todo item status" })

	api.nvim_create_user_command("JunkyardTodoCancel", function()
		M.todo_cancel()
	end, { desc = "Toggle todo item status" })

	api.nvim_create_user_command("JunkyardInsertDate", function()
		M.insert_date()
	end, { desc = "Insert current date" })

	api.nvim_create_user_command("JunkyardInsertTime", function()
		M.insert_time()
	end, { desc = "Insert current time" })
end

function M.setup_autocommands()
	local group = api.nvim_create_augroup("Junkyard", { clear = true })

	if M.config.auto_save then
		api.nvim_create_autocmd("BufWritePost", {
			group = group,
			pattern = M.config.notes_dir .. "/*.md",
			callback = function()
				if vim.bo.filetype == "markdown" then
					M.save_notes()
				end
			end,
		})
	end
end

function M.open_junkyard()
	local junkyard_file = M.config.notes_dir .. "/junkyard.md"

	M.create_junkyard_view()

	vim.cmd("edit " .. junkyard_file)

	vim.bo.filetype = "markdown"
	vim.wo.wrap = true
	vim.wo.linebreak = true
end

function M.create_junkyard_view()
	local junkyard_file = M.config.notes_dir .. "/junkyard.md"
	local daily_files = utils.get_daily_files(M.config.notes_dir)

	local content = {}

	table.sort(daily_files, function(a, b)
		return a > b
	end)

	for i, date in ipairs(daily_files) do
		if i > M.config.carry_over_days then
			break
		end

		local file_path = M.config.notes_dir .. "/" .. date .. ".md"
		if fn.filereadable(file_path) == 1 then
			local file_content = fn.readfile(file_path)

			table.insert(content, "[[" .. date .. "]]")

			for j, line in ipairs(file_content) do
				if j > 1 or not line:match("^%[%[%d%d%d%d%-%d%d%-%d%d%]%]") then
					table.insert(content, line)
				end
			end

			table.insert(content, "")
		end
	end

	fn.writefile(content, junkyard_file)
end

function M.new_day()
	local today = utils.get_current_date()
	local today_file = M.config.notes_dir .. "/" .. today .. ".md"

	if fn.filereadable(today_file) == 1 then
		vim.cmd("edit " .. today_file)
		return
	end

	local content = { "[[" .. today .. "]]" }

	if M.config.carry_over_todos then
		local incomplete_todos = M.get_incomplete_todos()
		if #incomplete_todos > 0 then
			for _, todo in ipairs(incomplete_todos) do
				table.insert(content, todo)
			end
			table.insert(content, "")
		end
	end

	fn.writefile(content, today_file)
	vim.cmd("edit " .. today_file)

	vim.cmd("normal! G")
end

function M.get_incomplete_todos()
	local last_day = utils.get_latest_note(M.config.notes_dir)
	local incomplete_todos = {}
	local file_content = fn.readfile(last_day)

	for _, line in ipairs(file_content) do
		if line:match("^%s*%- %[ %]") then
			table.insert(incomplete_todos, line)
		end
	end

	return incomplete_todos
end

function M.save_notes()
	local junkyard_file = M.config.notes_dir .. "/junkyard.md"

	if fn.filereadable(junkyard_file) == 0 then
		return
	end

	local content = fn.readfile(junkyard_file)
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
	local file_path = M.config.notes_dir .. "/" .. date .. ".md"

	while #content > 0 and content[#content]:match("^%s*$") do
		table.remove(content)
	end

	if #content > 0 then
		fn.writefile(content, file_path)
	end
end

function M.toggle_todo(symbol)
	local line = api.nvim_get_current_line()
	local line_num = api.nvim_win_get_cursor(0)[1]
	local new_line = line
	local timestamp = utils.get_current_time()

	if line:match("^(%s*%- )%[ %](.*)") then
		-- nothing -> symbol
		new_line = line:gsub("^(%s*%- )%[ %](.*)", "%1[" .. symbol .. "]%2 {" .. timestamp .. "}")
	elseif line:match("^(%s*%- )%[[^%s]%](.*)") then
		-- symbol -> nothing
		new_line = line:gsub("^(%s*%- )%[[^%s]%](.*)", "%1[ ]%2")
		new_line = new_line:gsub(" %{.*%}%s*$", "")
	end

	api.nvim_buf_set_lines(0, line_num - 1, line_num, false, { new_line })
end

function M.todo_done()
	M.toggle_todo("x")
end

function M.todo_cancel()
	M.toggle_todo("c")
end

function M.insert_time()
	local time = os.date(M.config.time_format)
	api.nvim_put({ time }, "c", false, true)
end

function M.insert_date()
	local date = os.date(M.config.date_format)
	api.nvim_put({ date }, "c", false, true)
end

function M.insert_now_playing()
	-- TODO: use lastfm or mpris or something? either way this is really unecessary
	api.nvim_put({ "♪ [now playing]" }, "c", false, true)
end

return M
