--[[
  e88'Y88         888 888 888                       888    
 d888  'Y  ,"Y88b 888 888 888 88e   ,"Y88b  e88'888 888 ee 
C8888     "8" 888 888 888 888 888b "8" 888 d888  '8 888 P  
 Y888  ,d ,ee 888 888 888 888 888P ,ee 888 Y888   , 888 b  
  "88,d88 "88 888 888 888 888 88"  "88 888  "88,e8' 888 8b 
]]

if not _G.Callback then

    class '_Callback'

    _G.CallBacks = {  LOAD           = "load",
                      UNLOAD         = "unload",
                      EXIT           = "exit",
                      TICK           = "tick",
                      DRAW           = "draw",
                      RESET          = "reset",
                      SEND_CHAT      = "sendchat",
                      RECV_CHAT      = "recvchat",
                      WND_MSG        = "wndmsg",
                      CREATE_OBJ     = "createobj",
                      DELETE_OBJ     = "deleteobj",
                      PROCESS_SPELL  = "processspell",
                      SEND_PACKET    = "sendpacket",
                      RECV_PACKET    = "recvpacket",
                      BUGSPLAT       = "bugsplat",
                      ANIMATION      = "animation",
                      NOTIFY         = "notify",
                      APPLY_PARTICLE = "applyparticle",
                   }

    function _Callback:__init()

        self.__callbacks = {}

    end

    function _Callback:Bind(eCallback, fnc)

        assert(type(eCallback) == "string" and type(fnc) == "function", "Callback:Bind(): Some or all arguments are wrong!")

        eCallback = eCallback:lower()

        assert(table.contains(_G.CallBacks, eCallback), "Callback:Bind(): Callback with the name \'" .. eCallback .. "\' does not exist!")

        if not self.__callbacks[eCallback] then
            self.__callbacks[eCallback] = {}
        end

        table.insert(self.__callbacks[eCallback], fnc)

        return true

    end

    function _Callback:Unbind(eCallback, fnc)

        assert(type(eCallback) == "string" and type(fnc) == "function", "Callback:Unbind(): Some or all arguments are wrong!")

        eCallback = eCallback:lower()

        assert(table.contains(_G.CallBacks, eCallback), "Callback:Unbind(): Callback with the name \'" .. eCallback .. "\' does not exist!")

        if self.__callbacks[eCallback] then

            for index, func in ipairs(self.__callbacks[eCallback]) do
                if func == fnc then
                    table.remove(self.__callbacks[eCallback], index)
                    return true
                end
            end

        end

        return false

    end

    function _Callback:GetCallbacks(eCallback)

        eCallback = eCallback:lower()

        assert(table.contains(_G.CallBacks, eCallback), "Callback:GetCallbacks(): Callback with the name \'" .. eCallback .. "\' does not exist!")

        return self.__callbacks[eCallback] or {}

    end

    -- Global instance
    _G.Callback = _Callback()

    -- Register callbacks
    AddLoadCallback(
    function()
        for _, callback in ipairs(Callback:GetCallbacks(CallBacks.LOAD)) do
            callback()
        end
    end)

    AddUnloadCallback(
    function()
        for _, callback in ipairs(Callback:GetCallbacks(CallBacks.UNLOAD)) do
            callback()
        end
    end)

    AddExitCallback(
    function()
        for _, callback in ipairs(Callback:GetCallbacks(CallBacks.EXIT)) do
            callback()
        end
    end)

    AddTickCallback(
    function()
        for _, callback in ipairs(Callback:GetCallbacks(CallBacks.TICK)) do
            callback()
        end
    end)

    AddDrawCallback(
    function()
        for _, callback in ipairs(Callback:GetCallbacks(CallBacks.DRAW)) do
            callback()
        end
    end)

    AddResetCallback(
    function()
        for _, callback in ipairs(Callback:GetCallbacks(CallBacks.RESET)) do
            callback()
        end
    end)

    AddChatCallback(
    function(text)
        for _, callback in ipairs(Callback:GetCallbacks(CallBacks.SEND_CHAT)) do
            callback(text)
        end
    end)

    AddRecvChatCallback(
    function(text)
        for _, callback in ipairs(Callback:GetCallbacks(CallBacks.RECV_CHAT)) do
            callback(text)
        end
    end)

    AddMsgCallback(
    function(msg, wParam)
        for _, callback in ipairs(Callback:GetCallbacks(CallBacks.WND_MSG)) do
            callback(msg,wParam)
        end
    end)

    AddCreateObjCallback(
    function(obj)
        for _, callback in ipairs(Callback:GetCallbacks(CallBacks.CREATE_OBJ)) do
            callback(obj)
        end
    end)

    AddDeleteObjCallback(
    function(obj)
        for _, callback in ipairs(Callback:GetCallbacks(CallBacks.DELETE_OBJ)) do
            callback(obj)
        end
    end)

    AddProcessSpellCallback(
    function(unit, spell)
        for _, callback in ipairs(Callback:GetCallbacks(CallBacks.PROCESS_SPELL)) do
            callback(unit, spell)
        end
    end)

    AddSendPacketCallback(
    function(p)
        for _, callback in ipairs(Callback:GetCallbacks(CallBacks.SEND_PACKET)) do
            callback(p)
        end
    end)

    AddRecvPacketCallback(
    function(p)
        for _, callback in ipairs(Callback:GetCallbacks(CallBacks.RECV_PACKET)) do
            callback(p)
        end
    end)

    AddBugsplatCallback(
    function()
        for _, callback in ipairs(Callback:GetCallbacks(CallBacks.BUGSPLAT)) do
            callback()
        end
    end)

    AddAnimationCallback(
    function(object, animation)
        for _, callback in ipairs(Callback:GetCallbacks(CallBacks.ANIMATION)) do
            callback(object, animation)
        end
    end)
    AddNotifyEventCallback(
    function(event, unit)
        for _, callback in ipairs(Callback:GetCallbacks(CallBacks.NOTIFY)) do
            callback(event, unit)
        end
    end)

    AddParticleCallback(
    function(unit, particle)
        for _, callback in ipairs(Callback:GetCallbacks(CallBacks.APPLY_PARTICLE)) do
            callback(unit, particle)
        end
    end)

end
