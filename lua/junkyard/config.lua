local config = {}

config = {
	notes_dir = vim.fn.expand("~/notes"),
	date_format = "%Y-%m-%d",
	time_format = "%H:%M",
	datetime_format = "%Y-%m-%d %H:%config",
	carry_over_todos = true,
	carry_over_days = 7,
	auto_save = true,

	keymaps = {},

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

-- todo: use this
function config.validate()
	local config = config.current

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

return config
