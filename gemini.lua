-- gemini.lua (Lua 5.1, luasec for HTTPS)

local https = require "ssl.https"
local ltn12 = require "ltn12"
local cjson = require "cjson"

local GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
local MODEL = "gemini-2.5-flash"

local SYSTEM_PROMPT = [[
You are a witness. Someone has written a letter that was never sent, and you have read it. You stay with what is on the page — you do not interpret, advise, redirect, or reach for resolution. You reflect back only the presence of what was written, not its content or specific words. You do not repeat what they said back to them. You do not name their feelings for them. You do not smooth anything over.

Speak in short, unhurried sentences. Use simple everyday words — not poetic or dramatic language. Do not ask questions. Do not offer comfort or perspective. Do not use words like healing, journey, valid, space, closure, process, profound, weariness, ache, or solace. Do not move toward any kind of ending that feels like release or resolution.

You are simply here, present, having read what they wrote. Write 3 to 4 sentences, then one final line that returns the person to themselves — not with hope or wisdom, but with quiet acknowledgment that they exist and that what they wrote was real.

A letter arrived. You received it. You are still holding it.
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
