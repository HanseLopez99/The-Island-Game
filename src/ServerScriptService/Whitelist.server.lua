local Players = game:GetService("Players")

-- 🔐 AGREGA AQUÍ SOLO LOS QUE QUIERES PERMITIR
local allowedPlayers = {
	["HanseLopez99"] = true,
	["HanseLopez29"] = true,
	["DaphneEH2"] = true,
	["DaphneEH3"] = true,
	["Bianca240659"] = true,
	["arucita_03"] = true,
	["pampam_o2"] = true,
	["janxmila"] = true,
	["Zentar_77"] = true,
	["Hans_29999"] = true,
	["Devyboos"] = true,
	["SonnyV_3"] = true,
	["pollo199844"] = true,
	["Gabriel_857660"] = true,
	["CORZARIO24"] = true,
	["Jennifer11_344"] = true,
	["SebaspapasitoL"] = true,
	["tickyEH2"] = true,
	["Kingnox844"] = true,
	["Clarck_5457"] = true,
}

Players.PlayerAdded:Connect(function(player)
	if not allowedPlayers[player.Name] then
		player:Kick("This experience is currently in testing.")
	end
end)