--------------------------------------------------------------------------------
-- Written by David von Tamar © MIT License.
--------------------------------------------------------------------------------
local analyzer = {}
--------------------------------------------------------------------------------
analyzer.command = "luacheck --codes --ranges --no-color"
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
