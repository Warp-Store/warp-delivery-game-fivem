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

-- Todos os comandos são server-side
Commands = { }


Commands["Money"] = function( Passport, Args )

    vRP.giveBankMoney( parseInt( Passport ), parseInt( Args[ 1 ] ) )
    return true
end


Commands["AddGroup"] = function( Passport, Args )

    local nplayer = vRP.getUserSource( parseInt( Passport ) )
    if nplayer then
        
        vRP.addUserGroup( parseInt( Passport ), Args[ 1 ] )

        local dias = parseInt(os.time( ) + (((24 * parseInt(Args[ 2 ])) * 60) * 60))
        vRP.query("add/vip/player", { user_id = parseInt( Passport ), vip = Args[ 1 ], timer_remover = dias })
        return true
    else
        
        local data = json.decode( vRP.getUData( parseInt( Passport ), "vRP:datatable" ) )
        if data.groups then
            data.groups[ Args[ 1 ] ] = true
        end
        vRP.setUData( parseInt( Passport ), "vRP:datatable", json.encode( data ) )

        local dias = parseInt(os.time( ) + (((24 * parseInt(Args[ 2 ])) * 60) * 60))
        vRP.query("add/vip/player", { user_id = parseInt( Passport ), vip = Args[ 1 ], timer_remover = dias })
        return true
    end

    return true
end


Commands["RemGroup"] = function( Passport, Args )
    local nplayer = vRP.getUserSource( parseInt( Passport ) )
    if nplayer then
        
        vRP.removeUserGroup( parseInt( Passport ), Args[ 1 ] )
        vRP.query("remove/vip/player", { user_id = parseInt( Passport ), vip = Args[ 1 ] })
        return true
    else
        
        local data = json.decode( vRP.getUData( parseInt( Passport ), "vRP:datatable" ) )
        if data.groups then
            data.groups[ Args[ 1 ] ] = nil
        end
        vRP.setUData( parseInt( Passport ), "vRP:datatable", json.encode( data ) )
        vRP.query("remove/vip/player", { user_id = parseInt( Passport ), vip = Args[ 1 ] })
        return true
    end
end

 
Commands["AddCar"] = function( Passport, Args )

    local dias = parseInt(os.time( ) + ( ( (24 * parseInt( Args[ 2 ] ) ) * 60) * 60))
    local plate = generatePlateNumber( )
    local dados = {plate = plate, tuning = exports['nation-garages']:getVehicleTuning(plate, Args[ 1 ], parseInt( Passport )), days = dias}
    exports['nation-garages']:addUserVehicle( Args[ 1 ], parseInt( Passport ), dados )
    return true
end


Commands["RemCar"] = function(Passport, Args)

    vRP.execute("nation_conce/removeUserVehicle", { user_id = parseInt(Passport), vehicle = Args[ 1 ], ipva = parseInt(os.time())  }) 
    return true
end


Commands["giveItem"] = function(Passport, Args)
    
    local nplayer = vRP.getUserSource(parseInt(Passport))
    local user_id_alvo = vRP.getUserId(nplayer)
    if user_id_alvo then
        vRP.giveInventoryItem(user_id_alvo, Args[ 1 ], parseInt(Args[ 2 ]))
        return true
    end
    return false
end


return Commands