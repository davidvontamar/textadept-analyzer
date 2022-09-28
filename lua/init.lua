--------------------------------------------------------------------------------
-- Written by David von Tamar © MIT License.
--------------------------------------------------------------------------------
local analyzer = {}
--------------------------------------------------------------------------------
analyzer.config = {
	command = "luacheck",
	options = {
		[1] = {
			["--std"] = "lua51" -- "lua51", "lua52", "lua53", "luajit" etc...
		},
		-- Options for filtering warnings:
		[2] = {
			["--no-global"] = false, -- Filter out warnings related to global variables.
			["--no-unused"] = false, -- Filter out warnings related to unsed variables and values.
			["--no-redefined"] = false, -- Filter out warnings related to redefined variables.
			["--no-unused-args"] = false, -- Filter out warnings related to unused arguments and loop variables.
			["--no-unused-secondaries"] = false, -- Filter out warnings related to unused variables set together with used ones.
			["--no-self"] = false, -- Filter out warnings related to implicit self argument.
		},
		-- Options for line length limits:
		[3] = {
			["--max-line-length"] = 80, -- Set maximum allowed line length (default: 120).
			["--no-max-string-line-length"] = true, -- Do not limit string line length.
			["--no-max-comment-line-length"] = true, -- Do not limit string line length.
		},
		-- Output formatting options:
		[4] = {
			["--codes"] = true, -- Show warning codes.
			["--ranges"] = true, -- Show ranges of columns related to warnings.
			["--no-color"] = true, -- Do not color output.
		},
		-- Filename
		[5] = {
			[""] = function() return '"'..buffer.filename..'"' end,
		},
		-- Options for globals:
		[6] = {
			["--globals"] = false, -- Add read-only global variables or fields.
			["--read-globals"] = false, -- Add read-only global variables or fields.
		}
	}
}
--------------------------------------------------------------------------------
local textadept_globals = require("textadept-analyzer.lua.textadept-globals")
--------------------------------------------------------------------------------
function analyzer.configure()
	-- Add Textadept's globals if appropriate.
	if (buffer.filename):match(".*textadept.*") then
		analyzer.config.options[6]["--globals"] = textadept_globals
	end
end
--------------------------------------------------------------------------------
function analyzer.parse_issues(handle)
	local issues = {errors = {}, warnings = {}}
	local line = handle:read()
	while line do
		local line_index, from, to, prefix, message =
			line:match(".+:(%d+):(%d+)%-(%d+): %(([EW])%d+%) (.+)$")
		if line_index then
			local issue = {}
			local at = buffer:position_from_line(line_index) + from - 1
			issue.line = line_index
			issue.length = buffer:position_from_line(line_index) + to - at
			issue.message = message
			if prefix == "E" then
				issues.errors[at] = issue
			elseif prefix == "W" then
				issues.warnings[at] = issue
			end
		end
		line = handle:read()
	end
	return issues
end
--------------------------------------------------------------------------------
return analyzer
--------------------------------------------------------------------------------
-- EOF
--------------------------------------------------------------------------------