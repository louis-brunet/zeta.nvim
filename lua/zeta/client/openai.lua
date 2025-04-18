local prompt = require('zeta.prompt')
local log = require('zeta.log')

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
    --- TODO: return type for OpenAI completion request
    ---
    ---@param request zeta.PredictEditRequestBody
    adapt_predict_edit_request = function(request)
        -- TODO: how many max tokens? (probably higher than the current 256?)
        local MAX_RESPONSE_TOKENS = 512

        local full_prompt = prompt.predict_edit_prompt(request)
        log.debug("created prompt:\n", full_prompt)
        return {
            prompt = full_prompt,
            max_tokens = MAX_RESPONSE_TOKENS,
            temperature = 0.0,
            stream = false,
            -- model = "some_model",
            -- stop = EDITABLE_REGION_END_MARKER,
        }
    end,

    --- Adapt the edit prediction response from an OpenAI-compatible server
    ---@param response unknown
    ---@return zeta.PredictEditResponse
    adapt_predict_edit_response = function(response)
        ---@type zeta.PredictEditResponse
        return {
            -- TODO: validate response, could be dereferencing nil here
            output_excerpt = response.choices[1].text,
            request_id = response.id, -- TODO: is this the right id?
        }
    end,
}


return openai_adapter
