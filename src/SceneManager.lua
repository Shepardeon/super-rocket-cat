local SceneManager = {}
local stack = {}

function SceneManager.push(scene, skip_deactivate)
    if not skip_deactivate then
        local top = stack[#stack]
        if top and top.deactivate then
            top.deactivate()
        end
    end

    table.insert(stack, scene)
    if scene.load then
        scene.load()
    end
    if scene.activate then
        scene.activate()
    end
end

function SceneManager.pop(skip_activate)
    if #stack == 0 then
        love.event.quit()
        return
    end

    local top = stack[#stack]
    if top.unload then
        top.unload()
    end
    table.remove(stack, #stack)

    if not skip_activate then
        top = stack[#stack]
        if top and top.activate then
            top.activate()
        end
    end
end

function SceneManager.switch(scene)
    if #stack > 0 then
        SceneManager.pop(true)
    end
    SceneManager.push(scene, true)
end

function SceneManager.update(dt)
    if #stack == 0 then
        return
    end
    local top = stack[#stack]
    if top.update then
        top.update(dt)
    end
end

function SceneManager.draw()
    if #stack == 0 then
        return
    end
    for i = 1, #stack do
        local scene = stack[i]
        if scene.draw then
            scene.draw()
        end
    end
end

function SceneManager.keypressed(key)
    if #stack == 0 then
        return
    end
    local top = stack[#stack]
    if top.keypressed then
        top.keypressed(key)
    end
end

function SceneManager.gamepadpressed(joystick, button)
    if #stack == 0 then
        return
    end
    local top = stack[#stack]
    if top.gamepadpressed then
        top.gamepadpressed(joystick, button)
    end
end

function SceneManager.gamepadaxis(joystick, axis, value)
    if #stack == 0 then
        return
    end
    local top = stack[#stack]
    if top.gamepadaxis then
        top.gamepadaxis(joystick, axis, value)
    end
end

function SceneManager.mousemoved(x, y)
    if #stack == 0 then
        return
    end
    local top = stack[#stack]
    if top.mousemoved then
        top.mousemoved(x, y)
    end
end

function SceneManager.mousepressed(x, y, button)
    if #stack == 0 then
        return
    end
    local top = stack[#stack]
    if top.mousepressed then
        top.mousepressed(x, y, button)
    end
end

function SceneManager.is_top(scene)
    return #stack > 0 and stack[#stack] == scene
end

return SceneManager
