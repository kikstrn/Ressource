resource_manifest_version '44febabe-d386-4d18-afbe-5e627f4af937'

description 'ESX KMS'

server_scripts {
	'server/main.lua',
	'@mysql-async/lib/MySQL.lua'
}

client_scripts {
	'client/main.lua'
}