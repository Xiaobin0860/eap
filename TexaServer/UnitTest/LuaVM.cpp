#include "LuaVM.h"

extern "C" {
#include <lua.hpp>
};

#include <luabind/operator.hpp>

#include "../Common/Types.h"

int pcall_error_callback(lua_State* L)
{
    lua_Debug d;
    lua_getstack(L, 1, &d);
    lua_getinfo(L, "Sln", &d);
    std::string err = lua_tostring(L, -1);
    lua_pop(L, 1);

    std::ostringstream msg;
    msg << d.short_src << ":" << d.currentline;

    if (d.name != 0) {
        msg << "(" << d.namewhat << " " << d.name << ")";
    }
    msg << " " << err;
    printf("%s\n", msg.str().c_str());
    return 0;
}

LuaVM::LuaVM()
{
    L = luaL_newstate();
    luaL_openlibs(L);

    luabind::open(L);
    luabind::set_pcall_callback(&pcall_error_callback);

#define POD_MODULE(t)                                                                                                  \
    luabind::class_<t>(#t)                                                                                             \
        .def(luabind::constructor<t>())                                                                                \
        .def(luabind::constructor<int>())                                                                              \
        .def(luabind::tostring(luabind::self))                                                                         \
        .def(luabind::const_self* int())                                                                               \
        .def(luabind::const_self* t())                                                                                 \
        .def(luabind::const_self* luabind::const_self)                                                                 \
        .def(luabind::const_self / int())                                                                              \
        .def(luabind::const_self / t())                                                                                \
        .def(luabind::const_self / luabind::const_self)                                                                \
        .def(luabind::const_self + int())                                                                              \
        .def(luabind::const_self + t())                                                                                \
        .def(luabind::const_self + luabind::const_self)                                                                \
        .def(luabind::const_self - int())                                                                              \
        .def(luabind::const_self - t())                                                                                \
        .def(luabind::const_self - luabind::const_self)                                                                \
        .def(luabind::const_self < t())                                                                                \
        .def(luabind::const_self == t())                                                                               \
        .def(luabind::const_self <= t())

    luabind::module(L)[POD_MODULE(int64), POD_MODULE(uint64)];
}

LuaVM::~LuaVM()
{
    if (L) {
        lua_close(L);
        L = 0;
    }
}

void LuaVM::Execute(const std::string& script)
{
    if (L) {
        luaL_dostring(L, script.c_str());
    }
}

void LuaVM::Load(const std::string& file)
{
    if (L) {
        luaL_dofile(L, file.c_str());
    }
}

ScriptSystem* ScriptSystem::instance_ = 0;
ScriptSystem::ScriptSystem()
{
}

ScriptSystem::~ScriptSystem()
{
    vms_.clear();
}

ScriptSystem& ScriptSystem::Instance()
{
    if (!instance_) {
        instance_ = new ScriptSystem;
    }
    return *instance_;
}

LuaVM* ScriptSystem::CreateVM()
{
    LuaVM* vm = new LuaVM;
    vms_.push_back(vm);
    return vm;
}

LuaVM* ScriptSystem::GetVM(int index)
{
    return vms_[index];
}
