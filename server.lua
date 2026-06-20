local socket = require("socket")
local env = require("luasql.sqlite3")

-- Gemini API key from environment
local GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
if not GEMINI_API_KEY then
  print("[WARN] GEMINI_API_KEY not set — Gemini calls will fail when integrated")
end

-- SQLite setup
local db_env = env.sqlite3()
local conn = db_env:connect("unsent.db")

-- Create table + self-deleting trigger
conn:execute([[
  CREATE TABLE IF NOT EXISTS letters (
    id INTEGER PRIMARY KEY,
    body TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
  );
]])

conn:execute([[
  CREATE TRIGGER IF NOT EXISTS delete_on_insert
  AFTER INSERT ON letters
  BEGIN
    DELETE FROM letters WHERE id = NEW.id;
  END;
]])

print("[UNSENT] DB + trigger ready")

-- HTTP helper: read exactly n bytes
local function read_body(client, length)
  local body = ""
  local remaining = length
  while remaining > 0 do
    local chunk, err = client:receive(remaining)
    if not chunk then break end
    body = body .. chunk
    remaining = remaining - #chunk
  end
  return body
end

-- Parse raw HTTP request
local function parse_request(client)
  local method, path
  local headers = {}
  local content_length = 0

  local line = client:receive("*l")
  if not line then return nil end
  method, path = line:match("^(%u+)%s+(%S+)")

  while true do
    line = client:receive("*l")
    if not line or line == "" or line == "\r" then break end
    local key, val = line:match("^([^:]+):%s*(.+)")
    if key then
      headers[key:lower():gsub("%s+", "")] = val:gsub("%r", "")
    end
  end

  content_length = tonumber(headers["content-length"]) or 0
  local body = ""
  if content_length > 0 then
    body = read_body(client, content_length)
  end

  return method, path, body
end

-- Send plain text HTTP response
local function send_response(client, status, body)
  local response = table.concat({
    "HTTP/1.1 " .. status,
    "Content-Type: text/plain",
    "Content-Length: " .. #body,
    "Access-Control-Allow-Origin: *",
    "Access-Control-Allow-Methods: POST, OPTIONS",
    "Access-Control-Allow-Headers: Content-Type",
    "",
    body
  }, "\r\n")
  client:send(response)
end

-- Send JSON HTTP response
local function send_json(client, status, body)
  local response = table.concat({
    "HTTP/1.1 " .. status,
    "Content-Type: application/json",
    "Content-Length: " .. #body,
    "Access-Control-Allow-Origin: *",
    "Access-Control-Allow-Methods: POST, OPTIONS",
    "Access-Control-Allow-Headers: Content-Type",
    "",
    body
  }, "\r\n")
  client:send(response)
end

-- Main server
local server = assert(socket.bind("*", 8080))
server:settimeout(0)
print("[UNSENT] Server running on http://localhost:8080")

while true do
  local client = server:accept()
  if client then
    client:settimeout(5)

    local method, path, body = parse_request(client)

    if method == "OPTIONS" then
      -- CORS preflight
      send_response(client, "204 No Content", "")

    elseif method == "POST" and path == "/submit" then
      if not body or body:gsub("%s+", "") == "" then
        send_json(client, "400 Bad Request", '{"response":"empty letter"}')
      else
        local ok, err = conn:execute(
          string.format("INSERT INTO letters (body) VALUES (%q)", body)
        )
        if ok then
          print(string.format("[%s] letter received — %d chars — deleted by trigger",
            os.date("%H:%M:%S"), #body))
          -- P3 will replace this line with the Gemini call
          send_json(client, "200 OK", '{"response":"witnessed"}')
        else
          print("[ERROR] DB insert failed: " .. tostring(err))
          send_json(client, "500 Internal Server Error", '{"response":"It heard you."}')
        end
      end

    else
      send_json(client, "404 Not Found", '{"response":"not found"}')
    end

    client:close()
  end

  socket.sleep(0.01)
end
