local M = {}
local fn = vim.fn

function M.is_valid_date(date_str)
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

function M.get_daily_files(notes_dir)
	local files = {}
	local pattern = notes_dir .. "/*.md"

	local md_files = fn.glob(pattern, false, true)

	for _, file in ipairs(md_files) do
		local basename = fn.fnamemodify(file, ":t:r")

		if basename ~= "junkyard" and M.is_valid_date(basename) then
			table.insert(files, basename)
		end
	end

	return files
end

function M.parse_todo_line(line)
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

function M.format_todo_line(todo)
	local line = todo.indent .. "- [" .. todo.status .. "] " .. todo.content

	if todo.timestamp then
		line = line .. " {" .. todo.timestamp .. "}"
	end

	return line
end

function M.get_latest_note(notes_dir)
	local daily_files = M.get_daily_files(notes_dir)

	if #daily_files == 0 then
		return nil
	end

	table.sort(daily_files, function(a, b)
		return a > b
	end)

	return notes_dir .. "/" .. daily_files[1] .. ".md"
end

function M.split_lines(text)
	local lines = {}
	for line in text:gmatch("[^\r\n]+") do
		table.insert(lines, line)
	end
	return lines
end

function M.join_lines(lines)
	return table.concat(lines, "\n")
end

function M.get_current_date(format)
	format = format or "%Y-%m-%d"
	return os.date(format)
end

function M.get_current_time(format)
	format = format or "%H:%M"
	return os.date(format)
end

function M.file_exists(file_path)
	return fn.filereadable(file_path) == 1
end

function M.ensure_dir(dir_path)
	if fn.isdirectory(dir_path) == 0 then
		return fn.mkdir(dir_path, "p") == 1
	end
	return true
end

function M.today_file_exists(notes_dir)
	local today = M.get_current_date()
	local today_file = notes_dir .. "/" .. today .. ".md"
	return M.file_exists(today_file)
end

function M.get_buffer_lines(bufnr, start, end_line)
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

function M.set_buffer_lines(bufnr, start, end_line, lines)
	bufnr = bufnr or 0

	local ok = pcall(vim.api.nvim_buf_set_lines, bufnr, start, end_line, false, lines)
	return ok
end

return M
