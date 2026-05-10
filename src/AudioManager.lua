local AudioManager = {}

local music_assets = {
    menu = "assets/audio/music/menu.ogg",
    game = "assets/audio/music/game.ogg",
}

local sfx_assets = {
    confirm = "assets/audio/sfx/confirm.wav",
    select = "assets/audio/sfx/select.wav",
    buy = "assets/audio/sfx/buy.wav",
    explosion = "assets/audio/sfx/explosion.wav",
    collect = "assets/audio/sfx/collect.wav",
    qte_ok = "assets/audio/sfx/qte_ok.wav",
    qte_fail = "assets/audio/sfx/qte_fail.wav",
    click = "assets/audio/sfx/click.wav",
}

local sources = {
    music = {},
    sfx = {},
}

function AudioManager.load()
    for key, path in pairs(music_assets) do
        local ok, source = pcall(love.audio.newSource, path, "stream")
        sources.music[key] = ok and source or nil
    end
    for key, path in pairs(sfx_assets) do
        local ok, source = pcall(love.audio.newSource, path, "static")
        sources.sfx[key] = ok and source or nil
    end
end

local music_volume = 0.5
local sfx_volume = 0.5
local current_music = nil
local fade_state = nil

function AudioManager.playMusic(key, loop)
    if loop == nil then
        loop = true
    end
    local source = sources.music[key]
    if not source then
        return
    end
    AudioManager.stopMusic()
    source:setLooping(loop)
    source:setVolume(music_volume)
    source:play()
    current_music = source
end

function AudioManager.stopMusic()
    if current_music then
        current_music:stop()
        current_music = nil
    end
end

function AudioManager.playSfx(key)
    local source = sources.sfx[key]
    if not source then
        return
    end
    local clone = source:clone()
    clone:setVolume(sfx_volume)
    clone:play()
end

function AudioManager.setMusicVolume(v)
    music_volume = v
    if current_music then
        current_music:setVolume(v)
    end
end

function AudioManager.setSfxVolume(v)
    sfx_volume = v
end

function AudioManager.getMusicVolume()
    return music_volume
end

function AudioManager.getSfxVolume()
    return sfx_volume
end

function AudioManager.fadeMusic(targetVol, duration, callback)
    local startVol = current_music and current_music:getVolume() or music_volume
    fade_state = {
        start_vol = startVol,
        target_vol = targetVol,
        duration = duration,
        elapsed = 0,
        callback = callback,
    }
end

function AudioManager.update(dt)
    if not fade_state then
        return
    end
    fade_state.elapsed = fade_state.elapsed + dt
    local t = math.min(fade_state.elapsed / fade_state.duration, 1)
    local vol = fade_state.start_vol + (fade_state.target_vol - fade_state.start_vol) * t
    AudioManager.setMusicVolume(vol)
    if t >= 1 then
        local cb = fade_state.callback
        fade_state = nil
        if cb then
            cb()
        end
    end
end

return AudioManager
