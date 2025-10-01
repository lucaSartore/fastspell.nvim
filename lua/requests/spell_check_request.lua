local M = {}

---@class Request
---@field is_in_execution boolean inclusive, 0 indexed
---@field in_queue boolean exclusive
---@field next_request_args SpellCheckRequestArgs|nil

---@class SpellCheckRequestArgs
---@field line_start number
---@field line_end number
---@field buffer number


---@type Request

local request = {
    is_in_execution = false,
    in_queue = false,
    next_request_args = nil
}

---@param namespace number
---@param interface Interface
---@param settings FastSpellSettings
function M.setup(namespace, interface, settings)
	M.interface = interface
	M.namespace = namespace
    M.settings = settings
end


---@param input SpellResponse
function M.processSpellCheckRequest(input)
    vim.schedule(function ()
        assert(input.kind == "lint")

        ---@type vim.Diagnostic[]
        local diagnostics = {}

        for _, value in ipairs(input.problems) do
            table.insert(diagnostics, {
                lnum = value.lineStart,
                col = value.lineOfset,
                end_col = value.lineOfset + #value.word,
                severity = M.settings.diagnostic_severity,
                message = "Misspelled word: " .. value.word,
            })
        end

        vim.diagnostic.reset(M.namespace, vim.api.nvim_get_current_buf())
        vim.diagnostic.set(M.namespace, vim.api.nvim_get_current_buf(), diagnostics)

        request.is_in_execution = false

        if request.in_queue then
            request.in_queue = false
            M.sendSpellCheckRequest(
                request.next_request_args.line_start,
                request.next_request_args.line_end,
                request.next_request_args.buffer
            )
        else

        end
    end)
end

---@param line_start number
---@param line_end number
---@param buffer number | nil
function M.sendSpellCheckRequest(line_start, line_end, buffer)

    if buffer == nil then
        buffer = vim.api.nvim_get_current_buf()
    end

    if M.settings.filter_by_buf_type and vim.api.nvim_get_option_value("buftype", {}) ~= "" then
        return
    end

    line_start = math.max(0, line_start)
    line_end = math.min(vim.api.nvim_buf_line_count(buffer), line_end)


    vim.schedule(function ()
        if not buffer then
            buffer = vim.api.nvim_get_current_buf()
        end

        ---@type SpellCheckRequestArgs
        local args = {
            line_start = line_start,
            line_end = line_end,
            buffer = buffer
        }

        if request.is_in_execution then
            request.next_request_args = args
            request.in_queue = true
            return
        end

        request.is_in_execution = true
        local linesArray = vim.api.nvim_buf_get_lines(args.buffer, args.line_start, args.line_end, true)
        local lines = table.concat(linesArray, "\n")
        local file_type = vim.api.nvim_get_option_value('filetype', { buf = buffer })
        M.interface.send_request({
            Kind = "check_spell",
            text = lines,
            startLine = args.line_start,
            languageId = file_type,
        })
    end)
end

return M
