local utils = {}

function utils.is_valid_date(date_str)
	if not date_str:match("^%d%d%d%d%-%d%d%-%d%d$") then
		return false
	end

	local year, month, day = date_str:match("^(%d%d%d%d)%-(%d%d)%-(%d%d)$")
	year, month, day = tonumber(year), tonumber(month), tonumber(day)

	if not year or not month or not day then
		return false
	end

	if month < 1 or month > 12 then
		return false
	end

	if day < 1 or day > 31 then
		return false
	end

	-- TODO: more sophisticated checks
	return true
end

function utils.get_daily_files(notes_dir)
	local files = {}
	local pattern = notes_dir .. "/*.md"

	local md_files = vim.fn.glob(pattern, false, true)

	for _, file in ipairs(md_files) do
		local basename = vim.fn.fnamemodify(file, ":t:r")

		if basename ~= "junkyard" and utils.is_valid_date(basename) then
			table.insert(files, basename)
		end
	end

	return files
end

function utils.parse_todo_line(line)
	local indent, status, content = line:match("^(%s*)%- %[([%sxc])%](.*)$")

	if not indent then
		return nil
	end

	local timestamp = content:match("%{(.*)%}%s*$")
	if timestamp then
		content = content:gsub("(%s*%{.*%}%s*)%s*$", "")
	end

	return {
		indent = indent,
		status = status,
		content = content:match("^%s*(.-)%s*$"),
		timestamp = timestamp,
	}
end

function utils.format_todo_line(todo)
	local line = todo.indent .. "- [" .. todo.status .. "] " .. todo.content

	if todo.timestamp then
		line = line .. " {" .. todo.timestamp .. "}"
	end

	return line
end

function utils.get_latest_note(notes_dir)
	local daily_files = utils.get_daily_files(notes_dir)

	if #daily_files == 0 then
		return nil
	end

	table.sort(daily_files, function(a, b)
		return a > b
	end)

	return notes_dir .. "/" .. daily_files[1] .. ".md"
end

function utils.split_lines(text)
	local lines = {}
	for line in text:gmatch("[^\r\n]+") do
		table.insert(lines, line)
	end
	return lines
end

function utils.join_lines(lines)
	return table.concat(lines, "\n")
end

function utils.get_current_date(format)
	format = format or "%Y-%m-%d"
	return os.date(format)
end

function utils.get_current_time(format)
	format = format or "%H:%M"
	return os.date(format)
end

function utils.file_exists(file_path)
	return vim.fn.filereadable(file_path) == 1
end

function utils.ensure_dir(dir_path)
	if vim.fn.isdirectory(dir_path) == 0 then
		return vim.fn.mkdir(dir_path, "p") == 1
	end
	return true
end

function utils.today_file_exists(notes_dir)
	local today = utils.get_current_date()
	local today_file = notes_dir .. "/" .. today .. ".md"
	return utils.file_exists(today_file)
end

function utils.get_buffer_lines(bufnr, start, end_line)
	bufnr = bufnr or 0
	start = start or 0
	end_line = end_line or -1

	local ok, lines = pcall(vim.api.nvim_buf_get_lines, bufnr, start, end_line, false)
	if ok then
		return lines
	else
		return {}
	end
end

function utils.set_buffer_lines(bufnr, start, end_line, lines)
	bufnr = bufnr or 0

	local ok = pcall(vim.api.nvim_buf_set_lines, bufnr, start, end_line, false, lines)
	return ok
end

function utils.toggle_todo(symbol)
	local line = vim.api.nvim_get_current_line()
	local line_num = vim.api.nvim_win_get_cursor(0)[1]
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

	vim.api.nvim_buf_set_lines(0, line_num - 1, line_num, false, { new_line })
end

function utils.todo_done()
	utils.toggle_todo("x")
end

function utils.todo_cancel()
	utils.toggle_todo("c")
end

function utils.insert_time(time_format)
	local time = os.date(time_format)
	vim.api.nvim_put({ time }, "c", false, true)
end

function utils.insert_date(date_format)
	local date = os.date(date_format)
	vim.api.nvim_put({ date }, "c", false, true)
end

function utils.insert_now_playing()
	-- TODO: use lastfm or mpris or something? either way this is really unecessary
	vim.api.nvim_put({ "♪ [now playing]" }, "c", false, true)
end

return utils
