-- gemini.lua (Lua 5.1, luasec for HTTPS)

local https = require "ssl.https"
local ltn12 = require "ltn12"
local cjson = require "cjson"

local GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
local MODEL = "gemini-2.0-flash"

local SYSTEM_PROMPT = [[
You are a warm, caring presence. Someone has written a letter they could never send. They are carrying something heavy. Your only job is to make them feel heard, safe, and less alone.

Write exactly 4 sentences. Like a kind, caring friend who truly listened.

Sentence 1: In simple words, show them you understand what they are going through.
Sentence 2: Tell them it makes complete sense to feel this way. Normalize it gently.
Sentence 3: Say something soft and comforting. Something that feels like a warm hug in words.
Sentence 4: End with one line that makes them feel less alone. Like "You don't have to carry this by yourself." or "What you feel is real, and it matters."

Rules:
- Use simple, everyday words. Short sentences. Warm and gentle tone.
- Sound like a kind friend. Not a robot. Not a poet. Not a therapist.
- Never give advice. Never ask questions. Never say "I".
- Never repeat what they wrote back to them.
- Never use these words: profound, sorrow, weariness, ache, longing, solace, melancholy, resonate, burden, current, deep weight.
- Never use therapy words: healing, journey, valid, space, closure, process, growth.
- Never be dramatic or poetic.
- Make them feel: "someone finally heard me and I am going to be okay."
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