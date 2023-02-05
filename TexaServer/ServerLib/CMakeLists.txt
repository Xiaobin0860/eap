file(GLOB SRCS "./*.cpp")
file(GLOB INCS "./*.h")

add_library(ServerLib STATIC ${SRCS} ${INCS})
