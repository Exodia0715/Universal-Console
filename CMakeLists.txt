cmake_minimum_required(VERSION 3.24)
project(UniversalConsole LANGUAGES C CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
set(CMAKE_POLICY_VERSION_MINIMUM 3.5)

find_package(Qt6 REQUIRED COMPONENTS Quick)
qt_standard_project_setup(REQUIRES 6.10)

include(FetchContent)

FetchContent_Declare(json
        URL https://github.com/nlohmann/json/releases/download/v3.11.3/json.tar.xz)
FetchContent_Declare(SDL2
        URL https://github.com/libsdl-org/SDL/releases/download/release-2.30.9/SDL2-2.30.9.tar.gz)
FetchContent_Declare(sqlite
        URL https://www.sqlite.org/2024/sqlite-amalgamation-3450100.zip)
FetchContent_MakeAvailable(json SDL2 sqlite)

add_library(sqlite3 STATIC ${sqlite_SOURCE_DIR}/sqlite3.c)
target_include_directories(sqlite3 PUBLIC ${sqlite_SOURCE_DIR})

if (EXISTS "${CMAKE_CURRENT_LIST_DIR}/src/frontend/importedcontent/CMakeLists.txt")
    add_subdirectory(${CMAKE_CURRENT_LIST_DIR}/src/frontend/importedcontent)
endif()

qt_add_executable(console
        src/frontend/main.cpp
        src/settings/Settings.cpp
        src/settings/Settings.h
        src/settings/Settings.cpp
)

qt_add_qml_module(console
        URI UniversalConsole
        QML_FILES
        src/frontend/Main.qml
)

target_link_libraries(console PRIVATE
        Qt6::Quick
        nlohmann_json::nlohmann_json
        SDL2::SDL2
        sqlite3)

add_custom_command(TARGET console POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
        $<TARGET_FILE:SDL2::SDL2> $<TARGET_FILE_DIR:console>)