file(GLOB SRCS "./*.cpp")
file(GLOB INCS "./*.h")

add_executable(Driver
    ${SRCS} ${INCS}
)