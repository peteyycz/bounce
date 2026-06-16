cmake_minimum_required(VERSION 3.21)
project(bounce LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOMOC ON)

find_package(Qt6 6.5 REQUIRED COMPONENTS Quick Network NetworkAuth)
find_package(Qt6Keychain CONFIG REQUIRED)

# ---------- OAuth credentials baked at build time ----------
# Point at any "Desktop app" JSON downloaded from the Google Cloud Console.
# Defaults to credentials.json in the repo root (gitignored).
if(NOT DEFINED BOUNCE_CREDENTIALS_FILE)
    set(BOUNCE_CREDENTIALS_FILE "${CMAKE_CURRENT_SOURCE_DIR}/credentials.json")
endif()

set(BOUNCE_OAUTH_CLIENT_ID "")
set(BOUNCE_OAUTH_CLIENT_SECRET "")

if(EXISTS "${BOUNCE_CREDENTIALS_FILE}")
    file(READ "${BOUNCE_CREDENTIALS_FILE}" _creds_json)
    # Google wraps the keys under "installed" for Desktop credentials.
    string(JSON _wrapper ERROR_VARIABLE _err GET "${_creds_json}" "installed")
    if(_err)
        set(_wrapper "${_creds_json}")
    endif()
    string(JSON BOUNCE_OAUTH_CLIENT_ID     GET "${_wrapper}" "client_id")
    string(JSON BOUNCE_OAUTH_CLIENT_SECRET GET "${_wrapper}" "client_secret")
    message(STATUS "Baking OAuth credentials from ${BOUNCE_CREDENTIALS_FILE}")
else()
    message(WARNING
        "No OAuth credentials at ${BOUNCE_CREDENTIALS_FILE}. "
        "Sign-in will be disabled. "
        "Re-configure with -DBOUNCE_CREDENTIALS_FILE=/path/to/client_secret.json")
endif()

configure_file(
    "${CMAKE_CURRENT_SOURCE_DIR}/src/Credentials.h.in"
    "${CMAKE_CURRENT_BINARY_DIR}/generated/Credentials.h"
    @ONLY
)

add_executable(bounce
    src/main.cpp
    src/GoogleAuth.h
    src/GoogleAuth.cpp
    qml.qrc
)

target_include_directories(bounce PRIVATE "${CMAKE_CURRENT_BINARY_DIR}/generated")

target_link_libraries(bounce PRIVATE Qt6::Quick Qt6::Network Qt6::NetworkAuth qt6keychain)

install(TARGETS bounce RUNTIME DESTINATION bin)
