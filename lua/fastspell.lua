local interface = require("util.interface")
local spell_check_request = require("requests.spell_check_request")


local M = {}

---@class FastSpellSettings
local default_settings = {
    namespace = "fastspell",
    server_code_path =
        debug.getinfo(1).source:sub(2):gsub("fastspell.lua", "") ..
        (vim.fn.has("win32") and ".\\scripts\\start_server.cmd" or "./scripts/start_server.sh"),
    filter_by_buf_type = true,
    diagnostic_severity = vim.diagnostic.severity.INFO
}

function M.setup(user_settings)

    ---@type FastSpellSettings
    local settings = vim.tbl_deep_extend("force", default_settings, user_settings or {})

    local namespace = vim.api.nvim_create_namespace(settings.namespace)

    vim.diagnostic.config({
        update_in_insert = true
    },namespace)


    spell_check_request.setup(namespace, interface, settings)
    interface.setup(spell_check_request.processSpellCheckRequest,settings)

    M.sendSpellCheckRequest = spell_check_request.sendSpellCheckRequest

end

return M
