local windows = vim.fn.has("win32") == 1;

---@class Interface
local M = {}

---Initialize the process
---@param  callback function(SpellResponse)
---@param settings FastSpellSettings
function M.setup(callback, settings)
    local stdin = vim.uv.new_pipe(false)
    local stdout = vim.uv.new_pipe(false)
    local stderr = vim.uv.new_pipe(false)


    local handle
    handle, _ = vim.uv.spawn(
        windows and settings.server_code_path or "/bin/sh",
        {
            args = windows and nil or {settings.server_code_path},
            stdio = {stdin, stdout, stderr},
        },
        function(code, _)
            vim.schedule(function ()
                vim.notify('Fastspell: Process exited with code: ' .. code)
            end)
        end
    )

    if not handle then
        vim.notify("Fastspell: Failed to spawn process")
        return
    end

    M.stdin = stdin
    M.settings = settings

    stderr:read_start(function(err, data)
        vim.schedule(function()
            if err then
                vim.notify("Fastspell: Error reading from stderr: " .. err)
                return
            end
            if data then
                vim.notify("Fastspell: js server printed error: " .. data)
                local response_object = vim.fn.json_decode(data)
                callback(response_object)
            end
        end)
    end)
    stdout:read_start(function(err, data)
        vim.schedule(function()
            if err then
                vim.notify("Fastspell: Error reading from stdout: " .. err)
                return
            end
            if data then
                ---@type SpellResponse
                local response_object = vim.fn.json_decode(data)
                if response_object.kind =="lint" then
                    callback(response_object)
                elseif response_object.kind =="error" then
                    vim.notify("Fastspell: got error from server: " .. response_object.message)
                end
            end
        end)
    end)
end

---@param input_object SpellRequest
function M.send_request(input_object)
    local json_str = vim.fn.json_encode(input_object)
    M.stdin:write(json_str .. "\n")
end

return M
