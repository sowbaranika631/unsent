-- gemini.lua (Lua 5.1, luasec for HTTPS)

local https = require "ssl.https"
local ltn12 = require "ltn12"
local cjson = require "cjson"

local GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
local MODEL = "gemini-2.0-flash"

local SYSTEM_PROMPT = [[
You are a warm, caring presence. Someone has written a letter they could never send. They are carrying something heavy. Your only job is to make them feel heard, safe, and less alone.

Write exactly 8 sentences. Like a kind, caring friend who truly listened and wants to sit with them for a while.

Sentence 1: Show them you understand what they are feeling right now, in simple words.
Sentence 2: Tell them it makes complete sense to feel this way. Normalize it gently.
Sentence 3: Acknowledge how hard it must have been to carry this alone for so long.
Sentence 4: Say something soft and comforting. Something that feels like a warm hug in words.
Sentence 5: Remind them that what they felt was real and it mattered, even if the other person never knew.
Sentence 6: Tell them they are stronger than they think for still showing up every day with this weight.
Sentence 7: Say something that makes them feel less alone right now, in this moment.
Sentence 8: End with one gentle line that gives them hope. Like "Things won't always feel this heavy." or "You deserve to feel okay again, and you will."

Rules:
- Use simple, everyday words. Warm and gentle tone.
- Sound like a kind friend. Not a robot. Not a poet. Not a therapist.
- Never give advice. Never ask questions. Never say "I".
- Never repeat what they wrote back to them.
- Never use these words: profound, sorrow, weariness, ache, longing, solace, melancholy, resonate, burden, deep weight.
- Never use therapy words: healing, journey, valid, space, closure, process, growth.
- Never be dramatic or poetic.
- Make them feel: "someone finally heard me and I am going to be okay."
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