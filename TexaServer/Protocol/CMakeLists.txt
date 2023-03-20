file(GLOB SRCS "./cpp/*.cc")
file(GLOB INCS "./cpp/*.h")

add_library(Protocol STATIC ${SRCS} ${INCS})
