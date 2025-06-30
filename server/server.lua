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

local _CMR = {
    Endpoint = "https://api.warpstore.app/api/games/1.0/",
    Version = "2.1.0",
    Colors = {
        Red = "\27[91m",
        Blue = "\27[94m",
        Reset = "\27[0m"
    }
}

_CMR.__index = _CMR;

function _CMR:New()
    local instance = setmetatable({}, self)
    return instance
end

function _CMR:ConsoleMessage(Message, Center, Color)
    local ConsoleWidth = 80

    if Center then
        local Padding = math.floor((ConsoleWidth - #Message) / 2)
        Message = string.rep(" ", Padding)..Message
    end

    if not Color then
        Color = self.Colors.Blue
    end

    print(Color..Message..self.Colors.Reset)
end

function _CMR:FormatDate(Date)
    local CleanedDate = Date:gsub("T", " "):gsub("Z", "")
    local Year, Month, Day, Hour, Min, _ = CleanedDate:match("(%d+)-(%d+)-(%d+) (%d+):(%d+):(%d+)")
    local DateFormat = string.format("%02d/%02d/%d %02d:%02d", tonumber(Day), tonumber(Month), tonumber(Year), tonumber(Hour), tonumber(Min))

    return DateFormat
end

function _CMR:Request(Path, Method, Payload)
    local Result
    local StatusCode
    local Headers = {
        ["Authorization"] = "Bearer "..Config.Warp.Token,
        ["Content-Type"] = "application/json"
    }
    
    PerformHttpRequest(self.Endpoint..Path, function(ResultStatusCode, ResultData, _, ErrorData)
        StatusCode = ResultStatusCode
        
        if ResultStatusCode >= 200 and ResultStatusCode <= 300 then
            Result = json.decode(ResultData)
            return
        end
        
        Result = ErrorData
    end, Method, Payload and json.encode(Payload) or nil, Headers)

    repeat
        Wait(100)
    until StatusCode

    return Result, StatusCode
end

function _CMR:ParseCommand(Command)
    local CommandName, Args = Command:match("^(%S+) (.+)$")

    local ArgsTable = {}
    for Arg in Args:gmatch("%S+") do
        if Arg ~= "{userId}" then
            table.insert(ArgsTable, Arg)
        end
    end

    return {
        CommandName = CommandName,
        Args = ArgsTable
    }
end

function _CMR:ParseMessage(Message, Args)
    local function Replace(Placeholder)
        return Args[Placeholder] or ("%("..Placeholder..")")
    end

    return Message:gsub("%((%w+)%)", Replace)
end

function _CMR:Init()
    local Result, StatusCode = self:Request("init", "POST", {["serverPort"] = parseInt(GetConvar("sv_port", "30120"))})

    if StatusCode >= 300 then
        self:ConsoleMessage("O Token inserido está inválido, verifique e tente novamente!", true, self.Colors.Red)
        return
    end

    self:ConsoleMessage("")
    self:ConsoleMessage("Loja vinculada: "..Result.name.." | URL: https://"..Result.url, true)
    self:ConsoleMessage("Plano: "..Result.plan.." | Expira: "..self:FormatDate(Result.expirationDate), true)
    self:ConsoleMessage("")
    self:WaitCommands()
end

function _CMR:WaitCommands()
    Wait(200)

    while true do
        self:CommandsQueue()
        self:ConsoleMessage("Verificando Compras: "..os.date('[Data]: %d/%m/%Y [Hora]: %H:%M:%S'))
        Wait(Config.Warp.Interval * 60 * 1000)
    end
end

function _CMR:CommandsQueue()
    local Result, StatusCode = self:Request("commands/pending-commands", "GET")

    if StatusCode > 300 then
        self:ConsoleMessage("Erro ao tentar obter os comandos pedentes!", true, self.Colors.Red)
        return
    end

    if Result.checkouts and #Result.checkouts then
        for _, Values in pairs(Result.checkouts) do
            local ProductsName = {}
            local ProductSuccess = false
            local PlayerSource = Config.Framework.GetSource(Values.gameUserId)
            
            if PlayerSource and parseInt( PlayerSource ) > 0 then
                for _, Product in pairs(Values.products) do

                    for _, Command in pairs(Product.commands) do
                        local CommandFormat = self:ParseCommand(Command)
                        for i = 1, Product.quantity do
                            local ResultCommand = self:DeliveryCommand(CommandFormat.CommandName, Values.gameUserId, CommandFormat.Args)
                            if not ProductSuccess and ResultCommand then
                                ProductSuccess = true
                            end
                        end
                    end

                    table.insert(ProductsName, Product.name)
                end
            
                if ProductSuccess then
                    ProductsName = table.concat(ProductsName, ", ")
                    local PlayerName = Config.Framework.GetUserName(Values.gameUserId)

                    local _, StatusCode = self:Request("commands/mark-as-processed", "POST", {["commandQueueId"] = Values.id})

                    if StatusCode > 300 then
                        self:ConsoleMessage("Falha ao atualizar o pedido | Pagamento ID: "..Values.checkoutId, false, self.Colors.Red)
                        return
                    end

                    if Values.deliveryType == "APPROVE" then
                        if PlayerSource then
                            TriggerClientEvent("WarpStore:DisplayingPurchase", PlayerSource, PlayerName, ProductsName)

                            if Config.Warp.Notify.Enable then
                                local Message = self:ParseMessage(Config.Warp.Notify.Message, { name = PlayerName, products = ProductsName })
                                Config.Framework.Notify(PlayerSource, Message)
                            end
                        end

                        if Config.Warp.Chat.Enable then
                            local Message = self:ParseMessage(Config.Warp.Chat.Message, { name = PlayerName, products = ProductsName })
                            Config.Framework.Chat(Message)
                        end
                    end
                end
            end
        end
    end
end


function _CMR:DeliveryCommand(CommandName, Passport, Args)
    if not Commands[CommandName] then
        self:ConsoleMessage("Não conseguimos encontrar o comando "..CommandName, false, self.Colors.Red)
        return false
    end

    local CommandStatus, CommandErr = pcall(Commands[CommandName], Passport, Args)

    if not CommandStatus then
        self:ConsoleMessage("Erro ao processar o comando "..CommandName.." | Erro: "..CommandErr, false, self.Colors.Red)
        return false
    end

    return true
end


CreateThread(function()
    local Main = _CMR:New()

    Main:ConsoleMessage("")
    Main:ConsoleMessage(" __        ___    ____  ____    ____ _____ ___  ____  _____ ", true)
    Main:ConsoleMessage(" \\ \\      / / \\  |  _ \\|  _ \\  / ___|_   _/ _ \\|  _ \\| ____|", true)
    Main:ConsoleMessage("  \\ \\ /\\ / / _ \\ | |_) | |_) | \\___ \\ | || | | | |_) |  _|  ", true)
    Main:ConsoleMessage("   \\ V  V / ___ \\|  _ <|  __/   ___) || || |_| |  _ <| |___ ", true)
    Main:ConsoleMessage("    \\_/\\_/_/   \\_\\_| \\_\\_|     |____/ |_| \\___/|_| \\_\\_____|", true)
    Main:ConsoleMessage("                                                            ", true)

    Main:ConsoleMessage("warpstore.app | Monetize seu servidor de FiveM e Impulsione suas vendas!", true)
    Main:ConsoleMessage("Versão "..Main.Version, true)

    Main:Init()
end)