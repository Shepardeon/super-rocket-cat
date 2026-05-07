local SceneManager = {}
local stack = {}

function SceneManager.push(scene)
    table.insert(stack, scene)
    if scene.load then
        scene.load()
    end
end

function SceneManager.pop()
    if #stack == 0 then
        love.event.quit()
        return
    end
    local top = stack[#stack]
    if top.unload then
        top.unload()
    end
    table.remove(stack, #stack)
end

function SceneManager.switch(scene)
    if #stack > 0 then
        local top = stack[#stack]
        if top.unload then
            top.unload()
        end
        table.remove(stack, #stack)
    end
    SceneManager.push(scene)
end

function SceneManager.update(dt)
    if #stack == 0 then return end
    local top = stack[#stack]
    if top.update then
        top.update(dt)
    end
end

function SceneManager.draw()
    if #stack == 0 then return end
    for i = 1, #stack do
        local scene = stack[i]
        if scene.draw then
            scene.draw()
        end
    end
end

function SceneManager.keypressed(key)
    if #stack == 0 then return end
    local top = stack[#stack]
    if top.keypressed then
        top.keypressed(key)
    end
end

return SceneManager
