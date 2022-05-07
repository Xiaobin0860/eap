cmake_minimum_required(VERSION 3.23)

project(play)

find_package(Lua REQUIRED)
find_package(RtMidi CONFIG REQUIRED)

add_executable(play "play.cpp")

target_include_directories(play PRIVATE ${LUA_INCLUDE_DIR})
target_link_libraries(play ${LUA_LIBRARIES} RtMidi::rtmidi)
