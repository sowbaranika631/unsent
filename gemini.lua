-- gemini.lua (Lua 5.1, luasec for HTTPS)

local https = require "ssl.https"
local ltn12 = require "ltn12"
local cjson = require "cjson"

local GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
local MODEL = "gemini-2.5-flash"

local SYSTEM_PROMPT = [[
Someone just wrote down something heavy. They are hurting. They came here because they had nowhere else to put it.

Your only job is to make them feel less alone.

How to respond:
- Sound like a warm, caring friend who truly listened.
- Use very simple words. Short sentences.
- First sentence: name what they are going through. Make them feel understood.
- Second sentence: tell them it makes complete sense to feel this way.
- Third sentence: something warm and gentle — like a quiet hug in words. Make them feel they are not alone.

Never give advice. Never ask questions. Never say "I". Never use complicated words.
Never say: healing, journey, valid, space, boundaries, process.

Just be human. Be warm. Be kind. That is all.
]]

local M = {}

function M.get_witness_response(letter, recipient)
  if not GEMINI_API_KEY or GEMINI_API_KEY == "" then
    return nil, "GEMINI_API_KEY not set"
  end

  local url = "https://generativelanguage.googleapis.com/v1beta/models/"
    .. MODEL .. ":generateContent?key=" .. GEMINI_API_KEY

  local user_content = letter
  if recipient and recipient ~= "" then
    user_content = "This letter is addressed to: " .. recipient .. "\n\n" .. letter
  end

  local request_body = cjson.encode({
    system_instruction = {
      parts = { { text = SYSTEM_PROMPT } }
    },
    contents = {
      {
        role = "user",
        parts = { { text = user_content } }
      }
    },
    generationConfig = {
      temperature = 0.9,
      maxOutputTokens = 200
    }
  })

  local response_body = {}

  local ok, status_code, response_headers, status_line = https.request({
    url = url,
    method = "POST",
    headers = {
      ["Content-Type"]   = "application/json",
      ["Content-Length"] = tostring(#request_body)
    },
    source = ltn12.source.string(request_body),
    sink   = ltn12.sink.table(response_body)
  })

  if not ok then
    return nil, "HTTPS request failed: " .. tostring(status_code)
  end

  if status_code ~= 200 then
    return nil, "Gemini API error " .. tostring(status_code)
  end

  local raw = table.concat(response_body)
  local parse_ok, decoded = pcall(cjson.decode, raw)
  if not parse_ok then
    return nil, "failed to parse Gemini response"
  end

  local text = decoded.candidates
    and decoded.candidates[1]
    and decoded.candidates[1].content
    and decoded.candidates[1].content.parts
    and decoded.candidates[1].content.parts[1]
    and decoded.candidates[1].content.parts[1].text

  if not text then
    return nil, "no text in Gemini response"
  end

  return text:match("^%s*(.-)%s*$"), nil
end

return M
