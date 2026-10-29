cmake_minimum_required(VERSION 3.22)
project(OfflineDokkanNative C)
if(NOT ANDROID)
  message(FATAL_ERROR "Use an Android NDK toolchain; this target must not bind Android's private system SQLite")
endif()
get_filename_component(OD_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/../.." ABSOLUTE)
get_filename_component(REPO_ROOT "${OD_ROOT}/.." ABSOLUTE)
set(OD_SQLITE_DIR "${REPO_ROOT}/downloads/sqlite-amalgamation/source" CACHE PATH "Pinned public SQLite amalgamation; run mobile/setup-sqlite.py first")
if(NOT EXISTS "${OD_SQLITE_DIR}/sqlite3.c")
  message(FATAL_ERROR "Missing pinned public SQLite source: run offline-dokkan/mobile/setup-sqlite.py")
endif()
add_library(odsqlite STATIC "${OD_SQLITE_DIR}/sqlite3.c")
set_target_properties(odsqlite PROPERTIES POSITION_INDEPENDENT_CODE ON)
target_include_directories(odsqlite PUBLIC "${OD_SQLITE_DIR}")
target_compile_definitions(odsqlite PUBLIC SQLITE_THREADSAFE=1 SQLITE_OMIT_LOAD_EXTENSION=1 SQLITE_DQS=0)
target_compile_options(odsqlite PRIVATE -fvisibility=hidden)
file(GLOB OD_CORE_SOURCES CONFIGURE_DEPENDS "${OD_ROOT}/core/*.c")
list(FILTER OD_CORE_SOURCES EXCLUDE REGEX "/(od_cli|test_[^/]*|check_[^/]*)\\.c$")
add_library(odbridge SHARED
  "${OD_ROOT}/adapter/od_bridge.c"
  "${OD_ROOT}/adapter/android/od_jni.c"
  "${CMAKE_CURRENT_SOURCE_DIR}/master_archive_jni.c"
  ${OD_CORE_SOURCES}
  "${OD_ROOT}/content/master_archive.c"
  "${OD_ROOT}/content/content.c")
target_compile_features(odbridge PRIVATE c_std_11)
target_compile_options(odbridge PRIVATE -Wall -Wextra -Werror -fvisibility=hidden)
target_link_options(odbridge PRIVATE -Wl,--no-undefined -Wl,-z,max-page-size=16384 -Wl,-z,common-page-size=16384)
# JNIEXPORT keeps the Java symbols visible; all SQLite code is our pinned public source.
target_link_libraries(odbridge PRIVATE odsqlite m z)
