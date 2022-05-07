local function note(letter, octave)
    local notes = {
        C = 0,
        Cs = 1,
        D = 2,
        Ds = 3,
        E = 4,
        F = 5,
        Fs = 6,
        G = 7,
        Gs = 8,
        A = 9,
        As = 10,
        B = 11
    }
    local notes_per_octive = 12
    return (octave + 1) * notes_per_octive + notes[letter]
end

local function duration(value)
    local tempo = 100
    local quarter = 60 / tempo
    local durations = {
        h = 2.0,
        q = 1.0,
        ed = 0.75,
        e = 0.5,
        s = 0.25
    }
    return durations[value] * quarter
end

local function parse_note(s)
    local letter, octave, value = string.match(s, "([A-Gs]+)(%d+)(%a+)")
    if not (letter and octave and value) then
        print("Invalid note: " .. s)
        return nil
    end
    return {
        note = note(letter, octave),
        duration = duration(value)
    }
end
