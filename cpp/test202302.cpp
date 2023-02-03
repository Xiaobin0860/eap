#include <gtest/gtest.h>
#include "singleton.h"

TEST(Singleton2, test)
{
    ASSERT_EQ(1, GetSingleton().GetCount());
    ASSERT_EQ(1, GetSingleton().GetCount());
}

TEST(Singleton2, test2)
{
    ASSERT_EQ(1, GetSingleton().GetCount());
    ASSERT_EQ(1, GetSingleton().GetCount());
}
