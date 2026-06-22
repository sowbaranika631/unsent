-- server.lua (simple blocking Lua server)
local socket = require "socket"
local cjson = require "cjson"
local gemini = require "gemini"

local function trim(s)
  return s:match("^%s*(.-)%s*$")
end

local PORT = tonumber(os.getenv("PORT")) or 10000
print("Starting UNSENT server on port " .. PORT)

local server = assert(socket.bind("0.0.0.0", PORT))
server:settimeout(nil)
print("UNSENT server running on port " .. PORT)

while true do
  local client = server:accept()
  if client then
    client:settimeout(60)

    local request_line = client:receive("*l")
    if request_line then
      local method, path = request_line:match("^(%u+) (/[^ ]*) HTTP")
      local content_length = 0
      local headers = {}

      while true do
        local line = client:receive("*l")
        if not line or line == "" then break end
        local key, value = line:match("^([^:]+):%s*(.+)$")
        if key and value then
          headers[key:lower()] = trim(value)
          if key:lower() == "content-length" then
            content_length = tonumber(value) or 0
          end
        end
      end

      local function send_response(status, status_text, body)
        local json_body = body or "{}"
        client:send("HTTP/1.1 " .. status .. " " .. status_text .. "\r\n")
        client:send("Content-Type: application/json\r\n")
        client:send("Access-Control-Allow-Origin: *\r\n")
        client:send("Access-Control-Allow-Methods: POST, OPTIONS\r\n")
        client:send("Access-Control-Allow-Headers: Content-Type\r\n")
        client:send("Content-Length: " .. #json_body .. "\r\n")
        client:send("Connection: close\r\n")
        client:send("\r\n")
        client:send(json_body)
      end

      if method == "OPTIONS" then
        send_response(204, "No Content", "{}")

      elseif method == "POST" and path == "/letter" then
        local body = ""
        if content_length > 0 then
          body = client:receive(content_length) or ""
        end

        local ok, parsed = pcall(cjson.decode, body)

        if not ok or not parsed.text or trim(parsed.text) == "" then
          send_response(400, "Bad Request", cjson.encode({ error = "missing letter text" }))
        else
          local letter_text = trim(parsed.text)
          local recipient = parsed.to or ""

          print("Received letter, calling Gemini...")
          local response, err = gemini.get_witness_response(letter_text, recipient)

          if not response then
            print("Gemini error: " .. tostring(err))
            send_response(502, "Bad Gateway", cjson.encode({ error = "witness unavailable" }))
          else
            print("Sending response back to client")
            send_response(200, "OK", cjson.encode({ response = response }))
          end
        end

      elseif method == "GET" and (path == "/" or path == "/health") then
        send_response(200, "OK", cjson.encode({ status = "ok" }))

      else
        send_response(404, "Not Found", cjson.encode({ error = "not found" }))
      end
    end

    client:close()
  end
end