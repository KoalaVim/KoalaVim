-- Generates LuaLS type annotations from config_scheme.jsonc
-- Usage: nvim -l scripts/gen_conf_types.lua

local script_dir = debug.getinfo(1, 'S').source:match('@(.*/)') or './'
local root = script_dir .. '../'
local schema_path = root .. 'config_scheme.jsonc'
local output_path = root .. 'lua/KoalaVim/types/conf.lua'

local f = assert(io.open(schema_path, 'r'))
local raw = f:read('*a')
f:close()

-- Strip JSONC single-line comments (lines whose first non-whitespace token is //)
local json_str = raw:gsub('\n(%s*)//[^\n]*', '\n%1')
local schema = vim.json.decode(json_str)

local lines = {
	'---@meta',
	'-- Generated from config_scheme.jsonc — do not edit manually.',
	'-- Run: nvim -l scripts/gen_conf_types.lua',
	'',
}

local function json_type_to_lua(prop)
	local t = prop.type
	if type(t) == 'table' then
		local non_null = {}
		local nullable = false
		for _, v in ipairs(t) do
			if v == 'null' then
				nullable = true
			else
				table.insert(non_null, v)
			end
		end
		if #non_null == 1 then
			t = non_null[1]
		else
			t = non_null[1] or 'any'
		end
		local lua_t = json_type_to_lua({ type = t, items = prop.items, properties = prop.properties })
		return nullable and (lua_t .. '?') or lua_t
	end

	if t == 'string' then
		return 'string'
	elseif t == 'integer' or t == 'number' then
		return 'number'
	elseif t == 'boolean' then
		return 'boolean'
	elseif t == 'array' then
		if prop.items and prop.items.type then
			return json_type_to_lua(prop.items) .. '[]'
		end
		return 'any[]'
	elseif t == 'object' and not prop.properties then
		return 'table'
	end
	return nil
end

local function emit_class(class_name, properties)
	table.insert(lines, '---@class ' .. class_name)
	local nested = {}
	local sorted_keys = {}
	for k in pairs(properties) do
		table.insert(sorted_keys, k)
	end
	table.sort(sorted_keys)

	for _, key in ipairs(sorted_keys) do
		local prop = properties[key]
		if prop.type == 'object' and prop.properties then
			local child_class = class_name .. '.' .. key
			table.insert(lines, '---@field ' .. key .. ' ' .. child_class)
			table.insert(nested, { child_class, prop.properties })
		else
			local lua_type = json_type_to_lua(prop) or 'any'
			table.insert(lines, '---@field ' .. key .. ' ' .. lua_type)
		end
	end
	table.insert(lines, '')

	for _, child in ipairs(nested) do
		emit_class(child[1], child[2])
	end
end

emit_class('KoalaVim.Conf', schema.properties)

while lines[#lines] == '' do
	table.remove(lines)
end

local out = assert(io.open(output_path, 'w'))
out:write(table.concat(lines, '\n') .. '\n')
out:close()

print('Generated ' .. output_path)
