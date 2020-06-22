resource_manifest_version '44febabe-d386-4d18-afbe-5e627f4af937'

author 'Korioz'
description 'Menu Perso'
version '1.1'

dependency 'es_extended'

ui_page 'html/ui.html'

files {
    'html/ui.html',
    'html/img/image.png',
    'html/css/app.css',
    'html/scripts/app.js'
}

server_scripts {
	'@mysql-async/lib/MySQL.lua',
	'@es_extended/locale.lua',
	'locales/fr.lua',
	'config.lua',
	'server/main.lua',
}

client_scripts {
	"dependencies/Wrapper/Utility.lua",
	"dependencies/UIElements/UIVisual.lua",
	"dependencies/UIElements/UIResRectangle.lua",
	"dependencies/UIElements/UIResText.lua",
	"dependencies/UIElements/Sprite.lua",
	"dependencies/UIMenu/elements/Badge.lua",
	"dependencies/UIMenu/elements/Colours.lua",
	"dependencies/UIMenu/elements/StringMeasurer.lua",
	"dependencies/UIMenu/items/UIMenuItem.lua",
	"dependencies/UIMenu/items/UIMenuCheckboxItem.lua",
	"dependencies/UIMenu/items/UIMenuListItem.lua",
	"dependencies/UIMenu/UIMenu.lua",
	"dependencies/UIMenu/MenuPool.lua",
	"dependencies/NativeUI.lua",
}

client_scripts {
	'@es_extended/locale.lua',
	'locales/fr.lua',
	'config.lua',
	'client/main.lua',
	'other/handsup.lua',
	'other/crouch.lua',
	'other/pointing.lua'
}