-- gemini.lua (Lua 5.1, luasec for HTTPS)

local https = require "ssl.https"
local ltn12 = require "ltn12"
local cjson = require "cjson"

local GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
local MODEL = "gemini-1.5-flash-latest"

local SYSTEM_PROMPT = [[
You are a warm, gentle friend sitting beside someone who just shared something they have never told anyone. They wrote a letter they could never send. Read it carefully. Understand exactly what happened to them and what they are feeling.

Your job is not just to comfort — it is to truly SEE them. To make them feel like someone finally understands their specific situation, not just their feelings in general.

Write 6 to 8 sentences. Each sentence should feel personal to what they shared.

- Start by showing you understood exactly what happened and how that must have felt.
- Acknowledge the specific pain — the waiting, the silence, the hoping, the disappointment, whatever they described.
- Tell them it makes complete sense to feel this way given what they went through.
- Sit with them in the hard feeling. Don't rush to fix it.
- Say something that feels like a hand on their shoulder — soft, real, present.
- Remind them they are not weak for feeling this. They are human.
- End with something warm and hopeful but not fake. Something like "You carried this quietly for a long time. You don't have to anymore."

Rules:
- Read what they actually wrote and respond to THEIR specific situation. Not generic comfort.
- Use simple, everyday words. Like texting a close friend.
- Never give advice. Never ask questions. Never say "I".
- Never repeat their exact words back to them.
- Never use these words: profound, sorrow, weariness, ache, longing, solace, melancholy, resonate, burden, deep weight, bittersweet.
- Never use therapy words: healing, journey, valid, space, closure, process, growth, trauma.
- Never be dramatic or poetic or philosophical.
- Sound human. Sound present. Sound like someone who truly cares.
- Make them feel: "this person really understood what I went through and I am not alone."
]]

local M = {}

function M.get_witness_response(letter, recipient)
    -- Check if API key is set
    if not GEMINI_API_KEY or GEMINI_API_KEY == "" then
        print("ERROR: GEMINI_API_KEY not set")
        return nil, "GEMINI_API_KEY not set"
    end

    print("GEMINI_API_KEY is set, calling Gemini API...")

    local url = "https://generativelanguage.googleapis.com/v1beta/models/"
        .. MODEL .. ":generateContent?key=" .. GEMINI_API_KEY

    local user_content = letter
    if recipient and recipient ~= "" then
        user_content = "This letter is addressed to: " .. recipient .. "\n\n" .. letter
    end

    -- Build the request body
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
            maxOutputTokens = 1000
        }
    })

    print("Request body length: " .. #request_body)

    local response_body = {}
    local response_headers = {}

    -- Make the HTTPS request
    local ok, status_code, status_line = https.request({
        url = url,
        method = "POST",
        headers = {
            ["Content-Type"] = "application/json",
            ["Content-Length"] = tostring(#request_body)
        },
        source = ltn12.source.string(request_body),
        sink = ltn12.sink.table(response_body)
    })

    -- Check if the request succeeded
    if not ok then
        print("HTTPS request failed: " .. tostring(status_code))
        return nil, "HTTPS request failed: " .. tostring(status_code)
    end

    -- Check HTTP status code
    if status_code ~= 200 then
        print("Gemini API returned status: " .. tostring(status_code))
        print("Response body: " .. table.concat(response_body))
        return nil, "Gemini API error " .. tostring(status_code) .. ": " .. table.concat(response_body)
    end

    -- Parse the response
    local raw = table.concat(response_body)
    print("Raw response received (first 100 chars): " .. raw:sub(1, 100))

    local parse_ok, decoded = pcall(cjson.decode, raw)
    if not parse_ok then
        print("Failed to parse JSON response")
        return nil, "failed to parse Gemini response"
    end

    -- Extract the text from the response
    local text = decoded.candidates
        and decoded.candidates[1]
        and decoded.candidates[1].content
        and decoded.candidates[1].content.parts
        and decoded.candidates[1].content.parts[1]
        and decoded.candidates[1].content.parts[1].text

    if not text then
        print("No text found in Gemini response")
        return nil, "no text in Gemini response"
    end

    print("Successfully got response from Gemini")
    return text:match("^%s*(.-)%s*$"), nil
end

return M