file(GLOB SRCS "./*.cpp")
file(GLOB INCS "./*.h")

add_executable(Record
    ${SRCS} ${INCS}
)