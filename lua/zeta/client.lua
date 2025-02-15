local curl = require("plenary.curl")

local client = {}

---@class zeta.PredictEditRequestBody
---@field events any[]
---@field excerpt string
---@field outline? string
---@field diagnostics? string[]

local API_URL = ""
local API_TOKEN = ""

---@param body zeta.PredictEditRequestBody
---@param callback fun(zeta.PredictEditResponse)
function client.perform_predicted_edit(body, callback)
    curl.post(API_URL, {
        body = body,
        headers = {
            ["Content-Type"] = "application/json",
            ["Authorization"] = "Bearer " .. API_TOKEN,
        },
        callback = callback,
    })
end

return client
