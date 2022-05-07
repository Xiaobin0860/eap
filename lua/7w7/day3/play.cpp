#include <iostream>
#include "lua.hpp"
#include "rtmidi/RtMidi.h"

namespace {
RtMidiOut midi;

int midi_send(lua_State* L)
{
    auto status = (unsigned char)lua_tonumber(L, -3);
    auto data1 = (unsigned char)lua_tonumber(L, -2);
    auto data2 = (unsigned char)lua_tonumber(L, -1);

    std::vector<unsigned char> message{status, data1, data2};
    midi.sendMessage(&message);
    return 0;
}
}  // namespace

int main(int argc, const char* argv[])
{
    if (argc < 2) {
        std::cout << "Usage: " << argv[0] << " <lua_file>" << std::endl;
        return -1;
    }

    auto ports = midi.getPortCount();
    if (ports < 1) {
        std::cerr << "No MIDI ports available!" << std::endl;
        return -1;
    }
    midi.openPort(0);

    lua_State* L = luaL_newstate();
    luaL_openlibs(L);

    lua_pushcfunction(L, midi_send);
    lua_setglobal(L, "midi_send");

    luaL_dofile(L, argv[1]);

    lua_close(L);
    return 0;
}
