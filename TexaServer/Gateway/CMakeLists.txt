file(GLOB SRCS "./*.cpp")
file(GLOB INCS "./*.h")

add_executable(Gateway
    ${SRCS} ${INCS}
)