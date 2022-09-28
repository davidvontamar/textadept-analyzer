--------------------------------------------------------------------------------
-- Written by David von Tamar © MIT License.
--------------------------------------------------------------------------------
local analyzer = {}
--------------------------------------------------------------------------------
analyzer.config = {
	command = "luacheck",
	options = {
		[1] = {
			-- "lua51", "lua52", "lua53", "luajit" etc...
			["--std"] = "lua51"
		},
		-- Options for filtering warnings:
		[2] = {
			-- Filter out warnings related to global variables.
			["--no-global"] = false,
			-- Filter out warnings related to unused variables and values.
			["--no-unused"] = false,
			-- Filter out warnings related to redefined variables.
			["--no-redefined"] = false,
			-- Filter out warnings related to unused arguments and loop variables.
			["--no-unused-args"] = false,
			-- Filter out warnings related to unused variables set together with used ones.
			["--no-unused-secondaries"] = false,
			-- Filter out warnings related to implicit self argument.
			["--no-self"] = false,
		},
		-- Options for line length limits:
		[3] = {
			-- Set maximum allowed line length (default: 120).
			["--max-line-length"] = 80,
			-- Do not limit string line length.
			["--no-max-comment-line-length"] = true,
			-- Do not limit string line length.
			["--no-max-string-line-length"] = true,
		},
		-- Output formatting options:
		[4] = {
			-- Show warning codes.
			["--codes"] = true,
			-- Show ranges of columns related to warnings.
			["--ranges"] = true,
			-- Do not color output.
			["--no-color"] = true,
		},
		-- Filename
		[5] = {
			[""] = function() return '"'..buffer.filename..'"' end,
		},
		-- Options for globals:
		[6] = {
			-- Add read-only global variables or fields.
			["--globals"] = false,
			-- Add read-only global variables or fields.
			["--read-globals"] = false,
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
	else
    analyzer.config.options[6]["--globals"] = false
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
