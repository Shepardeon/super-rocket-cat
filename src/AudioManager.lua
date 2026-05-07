local AudioManager = {}

local music_assets = {
    menu = "assets/audio/music/menu.ogg",
    game = "assets/audio/music/game.ogg",
}

local sfx_assets = {
    confirm    = "assets/audio/sfx/confirm.wav",
    select     = "assets/audio/sfx/select.wav",
    explosion  = "assets/audio/sfx/explosion.wav",
    collect    = "assets/audio/sfx/collect.wav",
    qte_ok     = "assets/audio/sfx/qte_ok.wav",
    qte_fail   = "assets/audio/sfx/qte_fail.wav",
    click      = "assets/audio/sfx/click.wav",
}

function AudioManager.load() end
function AudioManager.playMusic(key, loop) end
function AudioManager.stopMusic() end
function AudioManager.playSfx(key) end
function AudioManager.setMusicVolume(v) end
function AudioManager.setSfxVolume(v) end
function AudioManager.getMusicVolume() end
function AudioManager.getSfxVolume() end
function AudioManager.fadeMusic(targetVol, duration, callback) end
function AudioManager.update(dt) end

return AudioManager
