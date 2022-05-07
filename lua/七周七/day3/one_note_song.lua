local NOTE_DOWN = 0x90
local NOTE_UP = 0x80
local NOTE_VELOCITY = 0x7f

local function play(note)
    midi_send(NOTE_DOWN, note, NOTE_VELOCITY)
    while os.clock() < 1 do
    end
    midi_send(NOTE_UP, note, NOTE_VELOCITY)
end

play(60)
