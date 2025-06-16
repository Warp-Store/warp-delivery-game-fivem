--[[
╔══════════════════════════════════════════════════[ www.warpstore.app ]═════════════════════════════════════════════════════════════╗

                               ██╗    ██╗ █████╗ ██████╗ ██████╗     ███████╗████████╗ ██████╗ ██████╗ ███████╗
                               ██║    ██║██╔══██╗██╔══██╗██╔══██╗     ██╔════╝╚══██╔══╝██╔═══██╗██╔══██╗██╔════╝
                               ██║ █╗ ██║███████║██████╔╝██████╔╝    ███████╗   ██║   ██║   ██║██████╔╝█████╗  
                               ██║███╗██║██╔══██║██╔══██╗██╔═══╝       ╚════██║   ██║   ██║   ██║██╔══██╗██╔══╝  
                               ╚███╔███╔╝██║  ██║██║  ██║██║         ███████║   ██║   ╚██████╔╝██║  ██║███████╗
                                ╚══╝╚══╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝           ╚══════╝   ╚═╝    ╚═════╝ ╚═╝  ╚═╝╚══════╝
                                                                                                                                         
╚══════════════════════════════════════════════════[ www.warpstore.app ]═════════════════════════════════════════════════════════════╝                                                                                                         
--]]
local Proxy = module("vrp", "lib/Proxy")
local vRP = Proxy.getInterface("vRP")



Config = {}

Config.Warp = {
    Token = "Seu Token", -- Pegue seu token em https://warpstore.app/dashboard/integration
    Interval = 1, -- Tempo em minutos que irá verificar se existe uma nova compra
    -- Todas as notificações a baixo só aparecem caso ser entrega, não reembolso e nem remoção do produto.
    ServerPort = 30120,
    Interface = {
        Enable = true,
        Ballons = true,
        Message = "💎 Olá <b>(name)</b>, a cidade agradece sua compra de (products)!"
    },
    Chat = {
        Enable = true,
        Message = "🚗💎 (name) agora faz parte da elite! Acabou de comprar ^*(products)!"
    },
    Notify = {
        Enable = true,
        Message = "✨ <b>(name)</b>, você agora faz parte do time elite! Sua compra de <b>(products)</b> está à sua disposição!"
    }
}

-- Todas as funções a baixo são server-side
Config.Framework = {
    GetUserName = function(Passport)
        local Identities = vRP.getUserIdentity(parseInt(Passport))

        return (Identities.name and Identities.name or 'indigente').." "..(Identities.firstname and Identities.firstname or 'indigente')
    end,
    GetSource = function(Passport)
        local player = vRP.getUserSource(parseInt(Passport))
        return player
    end,
    Notify = function(player, Message)
        TriggerClientEvent("Notify", player, "Aviso!", Message, 10000)
    end,
    Chat = function(Message)
        TriggerClientEvent("chatMessage", -1, '[🌴Paradise Loja🌴]', {158, 143, 210}, Message)
    end
}





function PassportPlate(Plate)
    return vRP.query("vehicles/plateVehicles",{ plate = Plate })[1] or false
end

function GenerateString(Format)
    local Number = ""
    for i = 1, #Format do
        if string.sub(Format, i,i) == "D" then
            Number = Number..string.char(string.byte("0") + math.random(0,9))
        elseif "L" == string.sub(Format,i,i) then
            Number = Number..string.char(string.byte("A") + math.random(0,25))
        else
            Number = Number..string.sub(Format,i,i)
        end
    end
    return Number
end

function generatePlateNumber()
    local Passport = nil
    local Serial = ""
    repeat
        Passport = PassportPlate(GenerateString("DDLLLDDD"))
        Serial = GenerateString("DDLLLDDD")
    until not Passport

    return Serial
end