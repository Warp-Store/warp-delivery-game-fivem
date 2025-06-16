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

local _CMR = {}

_CMR.__index = _CMR;

function _CMR:New()
    local instance = setmetatable({}, self)
    return instance
end

function _CMR:AddEvent(Name, Callback)
    RegisterNetEvent(Name, Callback)
end

function _CMR:ParseMessage(Message, Args)
    local function Replace(Placeholder)
        return Args[Placeholder] or ("%("..Placeholder..")")
    end

    return Message:gsub("%((%w+)%)", Replace)
end

function _CMR:Init()
    self:AddEvent("WarpStore:DisplayingPurchase", function(...) self:DisplayingPurchase(...) end) -- Just because of the Class
end

function _CMR:SendReactMessage(EventName, Payload)
    SendNUIMessage({ action = EventName, data = Payload })
end

function _CMR:DisplayingPurchase(PlayerName, ProductsName)
    if Config.Warp.Interface.Enable then
        local Message = self:ParseMessage(Config.Warp.Interface.Message, { ["name"] = PlayerName, ["products"] = ProductsName })

        self:SendReactMessage("WarpStore:DisplayingPurchase", {
            Message = Message,
            Ballons = Config.Warp.Interface.Ballons
        })
    end
end


CreateThread(function()
    local Main = _CMR:New()
    Main:Init()
end)