--------------------------------------------------------------------------------
-- Written by David von Tamar © MIT License.
--------------------------------------------------------------------------------
-- Lexers are on the left, and their analyzers are on the right.
--------------------------------------------------------------------------------
local analyzers = {
	["lua"] = require("textadept-analyzer.lua"),
}
--------------------------------------------------------------------------------
local issue_types = {
	ERROR = 1,
	WARNING = 2,
	INFO = 3
}
--------------------------------------------------------------------------------
local issue_names = {}
local annotation_styles = {}
local indicator_types = {}
local indicator_styles = {}
local indicator_colors = {}
--------------------------------------------------------------------------------
local function init_styles()
	-- Names for statusbar summary
	issue_names[issue_types.ERROR] = "error(s)"
	issue_names[issue_types.WARNING] = "warning(s)"
	issue_names[issue_types.INFO] = "note(s)"
	-- Styles for annotations
	if not CURSES then
		annotation_styles[issue_types.ERROR] = buffer:style_of_name("annotation")
		annotation_styles[issue_types.WARNING] = buffer:style_of_name("annotation")
		annotation_styles[issue_types.INFO] = buffer:style_of_name("annotation")
	else
		annotation_styles[issue_types.ERROR] = buffer:style_of_name("annotation")
		annotation_styles[issue_types.WARNING] = buffer:style_of_name("annotation")
		annotation_styles[issue_types.INFO] = buffer:style_of_name("annotation")
	end
	-- Indicators
	indicator_types[issue_types.ERROR] = _SCINTILLA.next_indic_number()
	indicator_types[issue_types.WARNING] = _SCINTILLA.next_indic_number()
	indicator_types[issue_types.INFO] = _SCINTILLA.next_indic_number()
	if not CURSES then
		-- Indicator styles
		indicator_styles[issue_types.ERROR] = view.INDIC_SQUIGGLEPIXMAP
		indicator_styles[issue_types.WARNING] = view.INDIC_SQUIGGLEPIXMAP
		indicator_styles[issue_types.INFO] = view.INDIC_DOTS
		-- Indicator colors
		indicator_colors[issue_types.ERROR] = view.colors["red"]
		indicator_colors[issue_types.WARNING] = view.colors["yellow"]
		indicator_colors[issue_types.INFO] = view.colors["blue"]
	else
		-- Indicator styles with CURSES
		indicator_styles[issue_types.ERROR] = view.INDIC_STRAIGHTBOX
		indicator_styles[issue_types.WARNING] = view.INDIC_STRAIGHTBOX
		indicator_styles[issue_types.INFO] = view.INDIC_STRAIGHTBOX
		-- Indicator colors with CURSES
		indicator_colors[issue_types.ERROR] = view.colors["light_red"]
		indicator_colors[issue_types.WARNING] = view.colors["light_yellow"]
		indicator_colors[issue_types.INFO] = view.colors["light_blue"]
	end
	-- Apply indicator styles
	for _, issue_type in pairs(issue_types) do
		view.indic_style[indicator_types[issue_type]] = indicator_styles[issue_type]
		view.indic_fore[indicator_types[issue_type]] = indicator_colors[issue_type]
	end
end
--------------------------------------------------------------------------------
local function clear_issues()
	for _, issue_type in pairs(issue_types) do
		buffer.indicator_current = indicator_types[issue_type]
		buffer:indicator_clear_range(0, buffer.length)
	end
	buffer:eol_annotation_clear_all()
end
--------------------------------------------------------------------------------
local function parse_issues(handle, analyzer)
	local issues = {}
	local line = handle:read()
	while line do
		local issue = {}
		local line_index, from, to, type, message = analyzer.parse_issue(line)
		if message then
			issue.line = line_index
			issue.at = buffer:position_from_line(line_index) + from - 1
			issue.length = buffer:position_from_line(line_index) + to - issue.at
			issue.message = message
			issue.type = type
			table.insert(issues, issue)
		end
		line = handle:read()
	end
	return issues
end
--------------------------------------------------------------------------------
local function update_statusbar(counts)
	local summary = ""
	for issue_type, count in pairs(counts) do
		if count > 0 then
			if summary ~= "" then summary = summary..", and " end
			summary = count.." "..summary..issue_names[issue_type]
		end
	end
	if summary ~= "" then
		summary = "Found "..summary
	else
		summary = "No issues found."
	end
	ui.statusbar_text = summary
end
--------------------------------------------------------------------------------
local function analyze_file()
	-- Find an available analyzer.
	local analyzer = analyzers[buffer:get_lexer()]
	if not analyzer then return end
	ui.statusbar_text = "Analyzing file..."
	-- Clear  previous issues.
	clear_issues()
	-- Analyze the file.
	local handle = os.spawn(
		analyzer.command..' "'..buffer.filename..'"',
		io.get_project_root())
	local issues = parse_issues(handle, analyzer)
	handle:close()
	-- Count the issues.
	local counts = {}
	for _, issue_type in pairs(issue_types) do counts[issue_type] = 0 end
	-- Mark the issues.
	for _, issue in ipairs(issues) do
		counts[issue.type] = counts[issue.type] + 1
		buffer.indicator_current = indicator_types[issue.type]
		buffer:indicator_fill_range(issue.at, issue.length)
		buffer.eol_annotation_text[issue.line] =
			buffer.eol_annotation_text[issue.line]..issue.message.."; "
		buffer.eol_annotation_style[issue.line] = annotation_styles[issue.type]
	end
	-- Notify the user.
	update_statusbar(counts)
end
--------------------------------------------------------------------------------
events.connect(events.INITIALIZED, init_styles)
events.connect(events.FILE_AFTER_SAVE, analyze_file)
--------------------------------------------------------------------------------
-- EOF
--------------------------------------------------------------------------------
