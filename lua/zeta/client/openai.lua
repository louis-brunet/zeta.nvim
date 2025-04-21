local prompt = require('zeta.prompt')
local log = require('zeta.log')

---See https://platform.openai.com/docs/api-reference/completions
---@class zeta.OpenAiCompletionRequest
---@field prompt string
---@field model string
---@field max_tokens? integer
---@field temperature? float
---@field top_p? float
---@field stream? boolean
---@field stop? string|string[]

---@type zeta.ClientAdapter
local openai_adapter = {
    get_config = function()
        local config = require("zeta.config")
        ---@type zeta.ClientAdapterConfig
        return {
            url = {
                predict_edit = config.backend_config.openai.url,
            }
        }
    end,

    --- Adapt the edit prediction request for an OpenAI-compatible server
    ---
    ---@param request zeta.PredictEditRequestBody
    ---@return zeta.OpenAiCompletionRequest
    adapt_predict_edit_request = function(request)
        -- TODO: how many max response tokens?
        local MAX_RESPONSE_TOKENS = 512

        local full_prompt = prompt.predict_edit_prompt(request)
        log.debug("created prompt:\n", full_prompt)

        ---@type zeta.OpenAiCompletionRequest
        return {
            prompt = full_prompt,
            max_tokens = MAX_RESPONSE_TOKENS,
            temperature = 0.0,
            top_p = 0.9,
            stream = false,
            model = "some_model", -- seemingly not used by llama-server
            -- stop = EDITABLE_REGION_END_MARKER,
        }
    end,

    --- Adapt the edit prediction response from an OpenAI-compatible server
    ---@param response unknown
    ---@return zeta.PredictEditResponse
    adapt_predict_edit_response = function(response)
        vim.validate("predict_edit_response", response, "table")
        vim.validate("predict_edit_response.id", response.id, "string")
        vim.validate("predict_edit_response.choices", response.choices, "table")
        vim.validate("predict_edit_response.choices[1]", response.choices[1], "table")
        vim.validate("predict_edit_response.choices[1].text", response.choices[1].text, "string")

        ---@type zeta.PredictEditResponse
        return {
            output_excerpt = response.choices[1].text,
            request_id = response.id, -- TODO: is this the right id?
        }
    end,
}


return openai_adapter
