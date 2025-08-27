local M = {}

M.defaults = {
	notes_dir = "~/notes",

	date_format = "%Y-%m-%d",
	time_format = "%H:%M",
	datetime_format = "%Y-%m-%d %H:%M",
	auto_save = true,
	carry_over_todos = true,
	carryover_days = 1,
	keymaps = {
	},

	file_extension = ".md",

	new_day_template = {
		"[[{date}]]",
		"",
	},

	todo_symbols = {
		incomplete = " ",
		complete = "x",
		cancelled = "c",
	},

	highlight_groups = {
		incomplete = "JunkyardTodoIncomplete",
		complete = "JunkyardTodoComplete",
		cancelled = "JunkyardTodoCancelled",
		date_header = "JunkyardDateHeader",
		timestamp = "JunkyardTimestamp",
	},
}

M.current = {}

function M.init()
	M.current = vim.deepcopy(M.defaults)
end

function M.set(config)
	M.current = vim.tbl_deep_extend("force", M.current, config or {})
end

-- todo: use this
function M.validate()
	local config = M.current

	if type(config.notes_dir) ~= "string" or config.notes_dir == "" then
		vim.notify("junkyard: notes_dir must be a non-empty string", vim.log.levels.ERROR)
		return false
	end

	-- TODO: check if directory exists?
	config.notes_dir = vim.fn.expand(config.notes_dir)

	if type(config.date_format) ~= "string" then
		vim.notify("junkyard: date_format must be a string", vim.log.levels.ERROR)
		return false
	end

	if type(config.time_format) ~= "string" then
		vim.notify("junkyard: time_format must be a string", vim.log.levels.ERROR)
		return false
	end

	if config.keymaps and type(config.keymaps) ~= "table" then
		vim.notify("junkyard: keymaps must be a table", vim.log.levels.ERROR)
		return false
	end

	if config.todo_symbols and type(config.todo_symbols) ~= "table" then
		vim.notify("junkyard: todo_symbols must be a table", vim.log.levels.ERROR)
		return false
	end

	return true
end

function M.get_notes_dir()
	return vim.fn.expand(M.current.notes_dir)
end

function M.get_date_file_path(date)
	return vim.fn.resolve(M.get_notes_dir() .. "/" .. date .. M.current.file_extension)
end

function M.get_junkyard_path()
	return M.get_notes_dir() .. "/junkyard" .. M.current.file_extension
end

function M.format_date(date, format)
	date = date or os.time()
	format = format or M.current.date_format
	return os.date(format, date)
end

function M.format_time(time, format)
	time = time or os.time()
	format = format or M.current.time_format
	return os.date(format, time)
end

M.init()

return M
