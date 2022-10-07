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
	-- Default Colors
	-- These colors are used if the current theme does not define them.
	if not view.colors["error"] then view.colors["error"] = 0x3c14dc end
	if not view.colors["warning"] then view.colors["warning"] = 0x00c0ff end
	-- Default Styles
	-- These styles are used if the current theme does not define them.
	if not view.styles["error"] then
		view.styles["error"] = {
			fore = 0xffffff,
			back = view.colors["error"],
		}
	end
	if not view.styles["warning"] then
		view.styles["warning"] = {
			fore = 0x000000,
			back = view.colors["warning"],
		}
	end
	-- Error
	indicators.error = _SCINTILLA.next_indic_number()
	view.indic_style[indicators.error] = view.INDIC_SQUIGGLEPIXMAP
	view.indic_fore[indicators.error] = view.colors["error"]
	-- Warning
	indicators.warning = _SCINTILLA.next_indic_number()
	view.indic_style[indicators.warning] = view.INDIC_SQUIGGLEPIXMAP
	view.indic_fore[indicators.warning] = view.colors["warning"]
	-- Annotation type
	view.eol_annotation_visible = view.EOLANNOTATION_STANDARD
end
--------------------------------------------------------------------------------
local function analyze_file()
	-- Find an available analyzer.
	local analyzer = analyzers[buffer:get_lexer()]
	if not analyzer then return end
	-- Analyze the file.
	local issues
	local handle = os.spawn(
		analyzer.command.." "..buffer.filename,
		io.get_project_root())
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
		buffer.eol_annotation_style[issue.line] = buffer:style_of_name("error")
	end
	-- Mark the warnings.
	local warning_index = 0
	buffer.indicator_current = indicators.warning
	for at, issue in pairs(issues.warnings) do
		warning_index = warning_index + 1
		buffer:indicator_fill_range(at, issue.length)
		buffer.eol_annotation_text[issue.line] =
			buffer.eol_annotation_text[issue.line]..issue.message.."; "
		buffer.eol_annotation_style[issue.line] = buffer:style_of_name("warning")
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
--------------------------------------------------------------------------------
-- EOF
--------------------------------------------------------------------------------
