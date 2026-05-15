local RocketVisual = {}

local function draw_flames(cx, bottom, body_w, intensity)
    local t = love.timer.getTime()
    local flame_h = 10 + intensity * 6
    local flame_w = body_w * 0.55

    local flicker = 0.8 + 0.2 * math.sin(t * 15)
    love.graphics.setColor(1, 0.3, 0, 0.5 * flicker)
    love.graphics.polygon("fill",
        cx - flame_w / 2, bottom,
        cx + flame_w / 2, bottom,
        cx, bottom + flame_h * 1.4 * flicker
    )

    flicker = 0.8 + 0.2 * math.sin(t * 20 + 1)
    love.graphics.setColor(1, 0.85, 0, 0.7 * flicker)
    love.graphics.polygon("fill",
        cx - flame_w / 3, bottom,
        cx + flame_w / 3, bottom,
        cx, bottom + flame_h * flicker
    )
end

function RocketVisual.draw(x, y, w, h, levels)
    if not levels then return end
    love.graphics.push()

    local cx = x + w / 2
    local body_w = w * 0.38
    local body_h = h * 0.45
    local nose_h = h * 0.18
    local body_x = cx - body_w / 2
    local body_top = y + (h - body_h - nose_h) / 2
    local body_bot = body_top + body_h

    local engine_lv = levels.engine or 0
    local hull_lv = levels.hull or 0
    local tank_lv = levels.tank or 0
    local fins_lv = levels.fins or 0
    local magnet_lv = levels.magnet or 0
    local mult_lv = levels.multiplier or 0
    local repair_lv = levels.auto_repair or 0
    local shield_lv = levels.survival_qte or 0

    if engine_lv > 0 then
        draw_flames(cx, body_bot, body_w, engine_lv)
    end

    if magnet_lv > 0 then
        local radius = 18 + magnet_lv * 6
        local t = love.timer.getTime()
        local pulse = 0.12 + 0.08 * math.sin(t * 2)
        love.graphics.setColor(0.8, 0.3, 0.8, pulse)
        love.graphics.circle("fill", cx, (body_top + body_bot) / 2, radius)
        love.graphics.setColor(0.8, 0.3, 0.8, 0.35)
        love.graphics.circle("line", cx, (body_top + body_bot) / 2, radius)
    end

    love.graphics.setColor(0.7, 0.7, 0.75)
    love.graphics.rectangle("fill", body_x, body_top, body_w, body_h)

    love.graphics.setColor(0.9, 0.2, 0.2)
    love.graphics.polygon("fill",
        body_x, body_top,
        cx, body_top - nose_h,
        body_x + body_w, body_top
    )

    local win_r = body_w * 0.14
    local win_y = (body_top + body_bot) / 2
    love.graphics.setColor(0.3, 0.7, 1)
    love.graphics.circle("fill", cx, win_y, win_r)
    love.graphics.setColor(0.6, 0.9, 1)
    love.graphics.circle("fill", cx - win_r * 0.25, win_y - win_r * 0.25, win_r * 0.35)

    if fins_lv > 0 then
        local fw = body_w * 0.22
        local fh = body_h * 0.28
        local fy = body_bot - fh
        love.graphics.setColor(0.8, 0.4, 0.1)
        love.graphics.polygon("fill", body_x, fy, body_x - fw, fy + fh * 0.5, body_x, fy + fh)
        love.graphics.polygon("fill", body_x + body_w, fy, body_x + body_w + fw, fy + fh * 0.5, body_x + body_w, fy + fh)
    end

    if hull_lv > 0 then
        local t = 2 + hull_lv * 0.5
        love.graphics.setColor(0.3, 0.3, 0.4)
        love.graphics.setLineWidth(t)
        love.graphics.rectangle("line", body_x - 2, body_top - 2, body_w + 4, body_h + 4)
        love.graphics.setLineWidth(1)
    end

    if tank_lv > 0 then
        local tw = body_w * 0.18
        local th = body_h * (0.15 + tank_lv * 0.07)
        local tx = body_x + body_w + 5
        local ty = body_bot - th
        love.graphics.setColor(0.2, 0.4, 0.8)
        love.graphics.rectangle("fill", tx, ty, tw, th, 2)
        love.graphics.setColor(0.4, 0.6, 1)
        love.graphics.rectangle("line", tx, ty, tw, th, 2)
    end

    if mult_lv > 0 then
        local t = love.timer.getTime()
        love.graphics.setColor(1, 0.9, 0.2)
        for i = 1, mult_lv do
            local a = t + i * (math.pi * 2 / 8)
            local d = 22 + i * 2
            local sx = cx + math.cos(a) * d
            local sy = body_top + math.sin(a) * d + body_h * 0.3
            love.graphics.circle("fill", sx, sy, 1.5 + math.sin(t * 3 + i) * 0.8)
        end
    end

    if repair_lv > 0 then
        local t = love.timer.getTime()
        local pulse = 0.6 + 0.4 * math.sin(t * 2)
        local cs = 5 + repair_lv * 0.8
        local cx2 = body_x + body_w * 0.22
        local cy2 = body_top + body_h * 0.15
        love.graphics.setColor(0.2, 0.9 * pulse, 0.3)
        love.graphics.rectangle("fill", cx2 - cs, cy2 - 2, cs * 2, 4)
        love.graphics.rectangle("fill", cx2 - 2, cy2 - cs, 4, cs * 2)
    end

    if shield_lv > 0 then
        local t = love.timer.getTime()
        local pulse = 0.15 + 0.1 * math.sin(t * 1.5)
        local sr = body_w * 0.55 + shield_lv * 1.5
        love.graphics.setColor(0.3, 0.6, 1, pulse)
        love.graphics.circle("line", cx, (body_top + body_bot) / 2, sr)
        love.graphics.setColor(0.3, 0.6, 1, pulse * 0.4)
        love.graphics.circle("fill", cx, (body_top + body_bot) / 2, sr)
    end
    love.graphics.pop()
end

return RocketVisual
