cmake_minimum_required(VERSION 3.24)
project(UniversalConsole LANGUAGES C CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
set(CMAKE_POLICY_VERSION_MINIMUM 3.5)

# Added Network so both the QML frontend and Dumper can fetch box art
find_package(Qt6 REQUIRED COMPONENTS Quick Widgets Network)
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

# Automatically download and extract redumper.exe into build/bin/
set(REDUMPER_URL "https://github.com/superg/redumper/releases/download/b767/redumper-b767-windows-x64.zip")
set(DOWNLOAD_DEST "${CMAKE_CURRENT_BINARY_DIR}/redumper.zip")

if(NOT EXISTS "${CMAKE_CURRENT_BINARY_DIR}/bin/redumper.exe")
    message(STATUS "Downloading redumper backend...")
    file(DOWNLOAD ${REDUMPER_URL} ${DOWNLOAD_DEST} SHOW_PROGRESS)

    message(STATUS "Extracting redumper...")
    execute_process(
        COMMAND tar -xf ${DOWNLOAD_DEST} --strip-components=1
        WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
    )

    file(REMOVE ${DOWNLOAD_DEST})
endif()

if (EXISTS "${CMAKE_CURRENT_LIST_DIR}/src/frontend/importedcontent/CMakeLists.txt")
    add_subdirectory(${CMAKE_CURRENT_LIST_DIR}/src/frontend/importedcontent)
endif()

qt_add_executable(console
    src/frontend/main.cpp

    src/frontend/AppController.h

    src/frontend/ControllerManager.h
    src/frontend/ControllerManager.cpp

    src/disc/DiscManager.h
    src/disc/DiscManager.cpp
    src/disc/discInspector.hpp
    src/disc/gameDatabase.hpp

    src/settings/Settings.cpp
    src/settings/Settings.h

    src/backend/backend.h
    src/backend/backend.cpp
)

target_compile_definitions(console PRIVATE SDL_MAIN_HANDLED)

qt_add_qml_module(console
    URI UniversalConsole

    QML_FILES
        src/frontend/Main.qml

    RESOURCES
        src/frontend/fonts/NotoSans-Regular.ttf
)

target_link_libraries(console PRIVATE
        Qt6::Quick
        Qt6::Network
        nlohmann_json::nlohmann_json
        SDL2::SDL2
        sqlite3)

add_custom_command(TARGET console POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
        $<TARGET_FILE:SDL2::SDL2> $<TARGET_FILE_DIR:console>)

add_custom_command(
    TARGET console
    POST_BUILD

    COMMAND ${CMAKE_COMMAND} -E make_directory
        "$<TARGET_FILE_DIR:console>/resources"

    COMMAND ${CMAKE_COMMAND} -E copy_if_different
         "${CMAKE_CURRENT_SOURCE_DIR}/resources/gamedb.yaml"
        "$<TARGET_FILE_DIR:console>/resources/gamedb.yaml"

    COMMAND ${CMAKE_COMMAND} -E copy_if_different
        "${CMAKE_CURRENT_SOURCE_DIR}/resources/GameIndex.yaml"
        "$<TARGET_FILE_DIR:console>/resources/GameIndex.yaml"
)


qt_add_executable(UniversalConsoleDumper
    src/dumper/dumperMain.cpp
    src/dumper/mainWindow.cpp
    src/dumper/mainWindow.hpp
    src/disc/discInspector.hpp
    src/disc/gameDatabase.hpp
)

# Allow src/dumper/ files to include "discInspector.hpp" and "gameDatabase.hpp" directly
target_include_directories(UniversalConsoleDumper PRIVATE
    src/dumper
    src/disc
)

target_link_libraries(UniversalConsoleDumper PRIVATE
    Qt6::Widgets
    Qt6::Network
)