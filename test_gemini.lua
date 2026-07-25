local https = require("ssl.https")
local ltn12 = require("ltn12")

local api_key = os.getenv("GEMINI_API_KEY")

local letter = "I never got to say goodbye and I don't know how to live with that."

local json_body = string.format([[{
  "system_instruction": {
    "parts": [{ "text": "You are a witness, not a therapist. Reflect the feeling beneath the words. No advice. No questions. No therapy buzzwords like healing, journey, valid, space. Write 3-4 sentences and one closing line that returns the person to themselves." }]
  },
  "contents": [{ "parts": [{ "text": %q }] }]
}]], letter)

local response_body = {}
local res, code = https.request({
  url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-lite:generateContent?key=" .. api_key,
  method = "POST",
  headers = {
    ["Content-Type"] = "application/json",
    ["Content-Length"] = tostring(#json_body)
  },
  source = ltn12.source.string(json_body),
  sink = ltn12.sink.table(response_body)
})

local full = table.concat(response_body)
print("STATUS:", code)
print("RESPONSE:", full)
