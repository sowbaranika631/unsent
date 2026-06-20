FROM debian:bullseye-slim

RUN apt-get update && apt-get install -y \
    lua5.1 \
    luarocks \
    sqlite3 \
    libsqlite3-dev \
    libssl-dev \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN luarocks install luasocket
RUN luarocks install luasql-sqlite3

WORKDIR /app
COPY server.lua .

EXPOSE 8080
CMD ["lua5.1", "server.lua"]

