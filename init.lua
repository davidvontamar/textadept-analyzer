--------------------------------------------------------------------------------
-- Written by David von Tamar © MIT License.
--------------------------------------------------------------------------------
-- Lexers are on the left, and their analyzers are on the right.
--------------------------------------------------------------------------------
local analyzers = {
	["lua"] = require("textadept-analyzer.lua"),
}
--------------------------------------------------------------------------------
local indicators = {}
--------------------------------------------------------------------------------
local function init_styles()
	-- Error
	indicators.error = _SCINTILLA.next_indic_number()
	view.indic_style[indicators.error] = view.INDIC_SQUIGGLEPIXMAP
	view.indic_fore[indicators.error] = 0x3C14DC
	-- Warning
	indicators.warning = _SCINTILLA.next_indic_number()
	view.indic_style[indicators.warning] = view.INDIC_SQUIGGLEPIXMAP
	view.indic_fore[indicators.warning] = 0x00C0FF
	-- Annotation type
	--view.eol_annotation_visible = view.EOLANNOTATION_STANDARD
end
--------------------------------------------------------------------------------
local function get_command(analyzer)
	local command = analyzer.config.command
	for _, optiongroup in ipairs(analyzer.config.options) do
		for key, value in pairs(optiongroup) do
			if value then
				command = command.." "..key
				if type(value) == "number" or type(value) == "string" then
					command = command.." "..value
				elseif type(value) == "function" then
					command = command.." "..value()
				end
			end
		end
	end
	return command
end
--------------------------------------------------------------------------------
local function analyze_file()
	-- Find an available analyzer.
	local analyzer = analyzers[buffer:get_lexer()]
	if not analyzer then return end
	-- Configure the analyzer.
	analyzer.configure()
	-- Analyze the file.
	local issues
	local handle = io.popen(get_command(analyzer))
	issues = analyzer.parse_issues(handle)
	handle:close()
	-- Remove the previous issues.
	buffer.indicator_current = indicators.error
	buffer:indicator_clear_range(0, buffer.length)
	buffer.indicator_current = indicators.warning
	buffer:indicator_clear_range(0, buffer.length)
	buffer:eol_annotation_clear_all()
	-- Mark the errors.
	local error_index = 0
	buffer.indicator_current = indicators.error
	for at, issue in pairs(issues.errors) do
		error_index = error_index + 1
		buffer:indicator_fill_range(at, issue.length)
		buffer.eol_annotation_text[issue.line] =
			buffer.eol_annotation_text[issue.line]..issue.message.."; "
	end
	-- Mark the warnings.
	local warning_index = 0
	buffer.indicator_current = indicators.warning
	for at, issue in pairs(issues.warnings) do
		warning_index = warning_index + 1
		buffer:indicator_fill_range(at, issue.length)
		buffer.eol_annotation_text[issue.line] =
			buffer.eol_annotation_text[issue.line]..issue.message.."; "
	end
	-- Notify the user.
	local summary = ""
	if error_index == 0 and warning_index == 0 then
		summary = "No issues found."
	else
		if error_index > 0 then
			summary = summary.."Errors: "..error_index
		end
		if error_index > 0 and warning_index > 0 then
			summary = summary..", "
		end
		if warning_index > 0 then
			summary = summary.."Warnings: "..warning_index
		end
	end
	ui.statusbar_text = summary
end
--------------------------------------------------------------------------------
events.connect(events.INITIALIZED, init_styles)
events.connect(events.FILE_AFTER_SAVE, analyze_file)
events.connect(events.BUFFER_AFTER_SWITCH, analyze_file)
events.connect(events.BUFFER_NEW, analyze_file)
--------------------------------------------------------------------------------
-- EOF
--------------------------------------------------------------------------------