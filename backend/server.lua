-- server.lua (Lua 5.1, luasocket, luasql-sqlite3)

local socket = require "socket"
local gemini = require "gemini"

-- ── SQLite self-destruct setup ──────────────────────────────────────────
local driver = require "luasql.sqlite3"
local env = driver.sqlite3()
local db = env:connect(":memory:")

db:execute([[
  CREATE TABLE IF NOT EXISTS letters (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    recipient TEXT,
    text TEXT NOT NULL
  )
]])

db:execute([[
  CREATE TRIGGER IF NOT EXISTS self_destruct
  AFTER INSERT ON letters
  BEGIN
    DELETE FROM letters WHERE id = NEW.id;
  END
]])

-- ── Helpers ─────────────────────────────────────────────────────────────
local function trim(s)
  return s:match("^%s*(.-)%s*$")
end

local function parse_headers(client)
  local headers = {}
  local request_line = client:receive("*l")
  if not request_line then return nil, nil, nil, nil end

  local method, path = request_line:match("^(%u+) (/[^ ]*) HTTP")
  local content_length = 0

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

  return method, path, headers, content_length
end

local function send_response(client, status, status_text, body)
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

local cjson = require "cjson"

-- ── Main server loop ────────────────────────────────────────────────────
local PORT = tonumber(os.getenv("PORT")) or 10000
local server = assert(socket.bind("0.0.0.0", PORT))
server:settimeout(0)
print("UNSENT server running on port " .. PORT)

local clients = {}

while true do
  -- accept new connections
  local client = server:accept()
  if client then
    client:settimeout(60)
    table.insert(clients, client)
  end

  -- handle waiting clients
  for i = #clients, 1, -1 do
    local c = clients[i]
    local method, path, headers, content_length = parse_headers(c)

    if method then
      -- CORS preflight
      if method == "OPTIONS" then
        send_response(c, 204, "No Content", "{}")

      elseif method == "POST" and path == "/letter" then
        local body = ""
        if content_length > 0 then
          body = c:receive(content_length) or ""
        end

        local ok, parsed = pcall(cjson.decode, body)

        if not ok or not parsed.text or trim(parsed.text) == "" then
          send_response(c, 400, "Bad Request", cjson.encode({ error = "missing letter text" }))
        else
          local letter_text = trim(parsed.text)
          local recipient   = parsed.to or ""

          -- insert → trigger deletes immediately
          local escaped_text      = letter_text:gsub("'", "''")
          local escaped_recipient = recipient:gsub("'", "''")
          db:execute(string.format(
            "INSERT INTO letters (recipient, text) VALUES ('%s', '%s')",
            escaped_recipient, escaped_text
          ))

          -- call Gemini (text already in memory, not read from DB)
          local response, err = gemini.get_witness_response(letter_text, recipient)

          if not response then
            print("Gemini error: " .. tostring(err))
            send_response(c, 502, "Bad Gateway",
              cjson.encode({ error = "witness unavailable" }))
          else
            send_response(c, 200, "OK",
              cjson.encode({ response = response }))
          end
        end

      else
        send_response(c, 404, "Not Found", cjson.encode({ error = "not found" }))
      end

      c:close()
      table.remove(clients, i)
    else
      -- client disconnected or timed out
      c:close()
      table.remove(clients, i)
    end
  end

  socket.sleep(0.01)
end