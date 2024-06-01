local M = {}

local usercmd = require('KoalaVim.utils.cmd')

local hydra_keys = {}
local hydra_cmds = {}
local hydra_fts = {}
for name, conf in pairs(HYDRAS) do
	if conf.body then
		table.insert(hydra_keys, { conf.body, desc = 'Trigger ' .. name .. ' hydra' })
	end
	if conf.cmd then
		table.insert(hydra_cmds, conf.cmd.name)
	end
	if conf.ft then
		table.insert(hydra_fts, conf.ft)
	end
	if conf.custom_bodies then
		for _, body in ipairs(conf.custom_bodies) do
			table.insert(hydra_keys, body)
		end
	end
end

table.insert(M, {
	'anuvyklack/hydra.nvim',
	keys = hydra_keys,
	cmd = hydra_cmds,
	ft = hydra_fts,
	config = function()
		-- Registers all hydras
		local Hydra = require('hydra')
		local hydra_autocmds = vim.api.nvim_create_augroup('koala_hydra', { clear = true })

		for _, conf in pairs(HYDRAS) do
			local curr_hydra = Hydra(conf)

			-- Setup user cmd
			if conf.cmd then
				usercmd.create(conf.cmd.name, conf.cmd.desc, function()
					curr_hydra:activate()
				end, {})
			end

			-- Setup autocmd
			if conf.ft then
				vim.api.nvim_create_autocmd('FileType', {
					group = hydra_autocmds,
					pattern = conf.ft,
					callback = function(events)
						if conf.helper then
							require('KoalaVim.utils.map').map_buffer(events.buffer, 'n', 'g?', function()
								curr_hydra:activate()
							end)
						else
							curr_hydra:activate()
						end
					end,
				})

				-- register helper
				if conf.helper then
					HELEPER_FTS[conf.ft] = true
				end
			end

			-- Setup custom bodies if needed
			if conf.custom_bodies then
				for _, body in ipairs(conf.custom_bodies) do
					require('KoalaVim.utils.map').map(body.mode, body[1], function()
						body.callback(curr_hydra)
					end, body.desc)
				end
			end
		end
	end,
})

return M
