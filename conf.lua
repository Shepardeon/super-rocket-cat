local IS_DEBUG = os.getenv("LOCAL_LUA_DEBUGGER_VSCODE") == "1" and arg[2] == "debug"
if IS_DEBUG then
    require("lldebugger").start()
    local love_errorhandler = love.errorhandler

    function love.errorhandler(msg)
        if lldebugger then
            error(msg, 2)
        else
            return love_errorhandler(msg)
        end
    end
end

function love.conf(t)
    t.window.width = 1280
    t.window.height = 720
    t.window.title = "Super Rocket Cat"
    t.window.vsync = 1
    t.window.resizable = false
    t.console = true
end
