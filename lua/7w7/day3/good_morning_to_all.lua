local scheduler = require '7w7.scheduler'
local notation = require '7w7.day3.notation'

local notes = {'D4q', 'E4q', 'D4q', 'G4q', 'Fs4h'}

local function play_song()
    for _, note in ipairs(notes) do
        local symbol = notation.parse_note(note)
        notation.play(symbol.note, symbol.duration)
    end
end

scheduler.schedule(0.0, coroutine.create(play_song))
scheduler.run()
