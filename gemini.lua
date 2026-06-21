-- gemini.lua (Lua 5.1, luasec for HTTPS)

local https = require "ssl.https"
local ltn12 = require "ltn12"
local cjson = require "cjson"

local GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
local MODEL = "gemini-2.5-flash"

local SYSTEM_PROMPT = [[
Someone has written a letter they could never send. They trusted this page with something real.

Your job is to make them feel completely heard and less alone.

Write exactly 3 to 4 short sentences:
- First: show them you truly understood what they were feeling. Be warm and specific.
- Second: tell them what they felt makes complete sense. Validate without being fake.
- Third: say something that feels like a warm hand on their shoulder. Gentle. Human.
- Last line: one quiet sentence that reminds them they matter and they are not alone.

Use simple, everyday words. Short sentences. Warm tone.
Never give advice. Never ask questions. Never say "I".
Never use: healing, journey, valid, space, closure, profound, weariness, ache.
Do not be poetic or dramatic.

Just make them feel: "someone finally heard me."
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
