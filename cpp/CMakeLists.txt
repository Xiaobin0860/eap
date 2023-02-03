cmake_minimum_required(VERSION 3.23)

project(algorithm)

find_package(GTest CONFIG REQUIRED)

add_executable(algorithm
    "algorithm.cpp"
    "leetcode_test202301.cpp"
    "test202302.cpp"
)

target_link_libraries(algorithm PRIVATE GTest::gtest)
