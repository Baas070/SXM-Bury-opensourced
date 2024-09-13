fx_version "cerulean"
game "gta5"

author 'illie070'
description 'drag/bury resource'
version '1.0.0'

shared_scripts {
    "config.lua"
}

client_scripts {
    "client/client.lua", 
    "client/sync.lua"
}

server_scripts {
    "server.lua"
}

escrow_ignore {
    "config.lua", 
    "client/client.lua", 
    "client/sync.lua",
    "server.lua"
}

lua54 "yes"
