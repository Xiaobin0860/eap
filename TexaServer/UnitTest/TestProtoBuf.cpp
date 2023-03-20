#include "TestProtoBuf.h"

#include "LuaVM.h"
#include "addressbook.pb.h"


void TestProtoBuf()
{
    tutorial::Person person;
    person.set_name("test");
    person.set_id(123);
    person.set_email("test@163.com");

    tutorial::Person_PhoneNumber* phone1 = person.add_phone();
    phone1->set_number("12345678");
    phone1->set_type(tutorial::Person_PhoneType_HOME);

    tutorial::Person_PhoneNumber* phone2 = person.add_phone();
    phone2->set_number("87654321");
    phone2->set_type(tutorial::Person_PhoneType_HOME);

    person.add_test(1);

    std::string pkt;
    person.SerializeToString(&pkt);

    {
        LuaVM* lua_vm = new LuaVM;
        // pbc Test
        {
            lua_vm->Load("test2.lua");
            lua_vm->Call("OnUserData", pkt);
            lua_vm->Call("OnUserData", pkt);
        }
        delete lua_vm;
    }
}
