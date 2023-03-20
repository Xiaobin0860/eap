#include "LuaBinder.h"

#include <luabind/luabind.hpp>

#include "Driver.h"
#include "LuaVM.h"


Driver* GetDriver()
{
    return driver;
}

void Print(const char* str)
{
    printf("%s\n", str);
}

void LOG_(const char* str)
{
    LOG("%s", str);
}

void LuaBinder::Bind(LuaVM* vm)
{
    using namespace luabind;
    module(vm->GetLuaState())[def("GetDriver", &GetDriver), def("Print", &Print), def("LOG", &LOG_),
                              class_<Driver>("Driver")
                                  .def("Send", &Driver::Send)
                                  .def("StartTimer", &Driver::StartTimer)
                                  .def("StopTimer", &Driver::StopTimer)
                                  .def("GetRestTime", &Driver::GetRestTime)];
}
