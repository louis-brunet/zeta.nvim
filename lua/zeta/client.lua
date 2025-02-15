local curl = require("plenary.curl")

local client = {}

---@class zeta.PredictEditRequestBody
---@field events any[]
---@field excerpt string
---@field outline? string
---@field diagnostics? string[]

---@class zeta.PredictEditResponse
---@field request_id string
---@field output_excerpt string,

local API_URL = ""
local API_TOKEN = ""

---@param body zeta.PredictEditRequestBody
---@param callback fun(res: zeta.PredictEditResponse)
function client.perform_predicted_edit(body, callback)
    curl.post(API_URL, {
        body = body,
        headers = {
            ["Content-Type"] = "application/json",
            ["Authorization"] = "Bearer " .. API_TOKEN,
        },
        callback = function(resp)
            if resp.status ~= 200 then
                -- TODO: handle response error
                return
            end
            local _ok, resp_body = pcall(vim.json.decode, resp.body)
            -- TODO: validate resp_body signature
            callback(resp_body)
        end,
    })
end

return client
