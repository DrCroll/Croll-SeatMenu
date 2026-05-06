fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'Croll-CarSeats'
author 'DrCroll'
description 'In-vehicle seat picker (/seatmenu) with side NUI'
version '1.0.0'

dependencies {
    'ox_lib',
}

ui_page 'web/index.html'

files {
    'web/index.html',
    'web/style.css',
    'web/script.js',
}

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
}

client_scripts {
    'client/main.lua',
}
