local curl = require("plenary.curl")
local log = require("zeta.log")

local client = {}

---@class zeta.PredictEditRequestBody
---editor events
---@field input_events string
---excerpt for cursor position
---@field input_excerpt string
---@field outline? string
---@field diagnostics? string[]

---@class zeta.PredictEditResponse
---@field request_id string
---@field output_excerpt string,

---@class zeta.ClientAdapterConfig
---@field url { predict_edit: string }

---@class zeta.ClientAdapter
---@field adapt_predict_edit_request fun(request: zeta.PredictEditRequestBody): table
---@field adapt_predict_edit_response fun(request: unknown): zeta.PredictEditResponse
---@field get_config fun(): zeta.ClientAdapterConfig


local API_TOKEN = "testtoken"

---@return zeta.ClientAdapter
local function get_backend_adapter_from_config()
    local config = require("zeta.config")
    local Backend = require("zeta.config.backend").Backend
    local backend = config.backend

    if backend == Backend.OPENAI then
        local openai_adpater = require("zeta.client.openai")
        return openai_adpater
    elseif backend == Backend.ZED then
        -- TODO: handle zed backend configuration
        error("not implemented for zed API")
    else
        -- TODO:
        error("not implemented for backend " .. backend)
    end
end

---@param body zeta.PredictEditRequestBody
---@param callback fun(res: zeta.PredictEditResponse)
function client.perform_predicted_edit(body, callback)
    local adapter = get_backend_adapter_from_config()
    local adapter_config = adapter.get_config()
    local api_url = adapter_config.url.predict_edit
    local json_body = vim.json.encode(adapter.adapt_predict_edit_request(body))

    log.debug(("POST %s %s"):format(api_url, json_body))

    curl.post(api_url, {
        body = json_body,
        headers = {
            ["Content-Type"] = "application/json",
            -- TODO: move auth logic to backend adapters
            ["Authorization"] = "Bearer " .. API_TOKEN,
        },
        callback = function(resp)
            if resp.status ~= 200 then
                -- TODO: handle response error
                local error_msg = ("POST %s %d %s"):format(api_url, resp.status, vim.inspect(resp))
                log.debug(error_msg)
                -- error(error_msg)
                return
            end
            local _ok, resp_body = pcall(vim.json.decode, resp.body)
            log.debug("response body:", resp_body)
            -- TODO: validate resp_body signature
            local predict_response = adapter.adapt_predict_edit_response(resp_body)
            log.debug("response transformed:", predict_response)
            callback(predict_response)
        end,
    })
end

return client
