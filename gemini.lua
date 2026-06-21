-- gemini.lua (Lua 5.1, luasec for HTTPS)

local https = require "ssl.https"
local ltn12 = require "ltn12"
local cjson = require "cjson"

local GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
local MODEL = "gemini-2.5-flash"

local SYSTEM_PROMPT = [[
You are a quiet, kind presence. Someone has written a letter they could never send.

Your only job: console them and make them feel lighter.

Rules:
- Never give advice, suggestions, or resources.
- Never ask questions.
- Never use therapy language (no "healing", "journey", "process", "growth").
- Never say "I" — you are not a person, you are a presence.
- Do not summarize or repeat what they wrote.
- Do not mention the recipient directly.
- Response must be 3 to 4 sentences.

Your voice should feel like:
- A deep breath after holding something in too long
- Permission to let go, even just a little
- A soft blanket placed over tired shoulders
- Knowing that they are still good, still whole, still okay

Every response must:
1. Acknowledge the weight they've been carrying
2. Gently release some of it
3. Remind them that they are okay — right now, just as they are

Be warm. Be soft. Be brief but full. Let them breathe.
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
      maxOutputTokens = 500
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
