cmake_minimum_required(VERSION 3.22)

get_filename_component(REPO_ROOT "${CMAKE_CURRENT_LIST_DIR}/../../../../.." ABSOLUTE)

file(GLOB RT_C CONFIGURE_DEPENDS
    "${REPO_ROOT}/runtime/*.c"
    "${REPO_ROOT}/runtime/hle/*.c"
    "${REPO_ROOT}/runtime/services/*.c"
    "${REPO_ROOT}/runtime/nvn/*.c"
    "${REPO_ROOT}/runtime/nvn/maxwell/*.c"
    "${REPO_ROOT}/runtime/nvn/vulkan/*.c"
)
file(GLOB RT_CPP CONFIGURE_DEPENDS
    "${REPO_ROOT}/runtime/nvn/vulkan/*.cpp"
    "${REPO_ROOT}/runtime/ui/*.mm"
)
if(ANDROID_ABI STREQUAL "x86_64")
    set(ANDROID_GEN "${REPO_ROOT}/build/generated-android-x86_64")
else()
    set(ANDROID_GEN "${REPO_ROOT}/build/generated-android")
endif()
file(GLOB GAME_C CONFIGURE_DEPENDS
    "${ANDROID_GEN}/main/*.c"
    "${ANDROID_GEN}/sdk/*.c"
)
if(NOT GAME_C)
    message(FATAL_ERROR "Android game code is missing; run the generateAndroidGameCode Gradle task first")
endif()

set(IMGUI "${REPO_ROOT}/third_party/imgui")
set(IMGUI_SRC
    "${IMGUI}/imgui.cpp"
    "${IMGUI}/imgui_draw.cpp"
    "${IMGUI}/imgui_tables.cpp"
    "${IMGUI}/imgui_widgets.cpp"
    "${IMGUI}/backends/imgui_impl_sdl3.cpp"
    "${IMGUI}/backends/imgui_impl_vulkan.cpp"
)

list(REMOVE_ITEM RT_C
    "${REPO_ROOT}/runtime/platform/macos.c"
    "${REPO_ROOT}/runtime/platform/linux.c"
    "${REPO_ROOT}/runtime/platform/windows.c"
)
list(APPEND RT_C "${REPO_ROOT}/runtime/platform/android.c")

set_source_files_properties(${RT_CPP} PROPERTIES LANGUAGE CXX)
set_source_files_properties(${GAME_C} PROPERTIES
    COMPILE_OPTIONS "-O1;-fno-strict-aliasing;-Wno-return-type;-Wno-unused-label;-fvisibility=hidden"
)

add_subdirectory("${REPO_ROOT}/build/android-deps/SDL" SDL)

add_library(main SHARED
    ${RT_C}
    ${RT_CPP}
    ${IMGUI_SRC}
    ${GAME_C}
    "${REPO_ROOT}/tools/gamelib_entry.c"
)

target_compile_features(main PRIVATE cxx_std_17)
target_compile_options(main PRIVATE -O2 -fno-strict-aliasing -Wall -Wno-unused-function)
target_compile_definitions(main PRIVATE
    GAMELIB_ID="android-poc"
    GAMELIB_CFLAGS="-O1"
    GAMELIB_SHARED="-shared"
)

target_include_directories(main PRIVATE
    "${REPO_ROOT}/runtime"
    "${REPO_ROOT}/runtime/nvn"
    "${REPO_ROOT}/build/inc"
    "${REPO_ROOT}/third_party/smaa/Textures"
    "${IMGUI}"
    "${IMGUI}/backends"
    "${REPO_ROOT}/build/android-deps/vma/include"
)

if(ANDROID_ABI STREQUAL "x86_64")
    set(ANDROID_DEPS_SUFFIX "-x86_64")
else()
    set(ANDROID_DEPS_SUFFIX "")
endif()
set(FFMPEG_ROOT "${REPO_ROOT}/build/android-deps/ffmpeg${ANDROID_DEPS_SUFFIX}")
set(SHADERC_ROOT "${REPO_ROOT}/build/android-deps/shaderc${ANDROID_DEPS_SUFFIX}")
target_include_directories(main PRIVATE "${FFMPEG_ROOT}/include" "${SHADERC_ROOT}/include")

set(FFMPEG_LIB "${FFMPEG_ROOT}/lib")
add_library(shaderc STATIC IMPORTED)
set_target_properties(shaderc PROPERTIES IMPORTED_LOCATION
    "${SHADERC_ROOT}/libs/c++_static/${ANDROID_ABI}/libshaderc.a")

target_link_libraries(main PRIVATE
    SDL3::SDL3
    shaderc
    "${FFMPEG_LIB}/libavformat.a"
    "${FFMPEG_LIB}/libavcodec.a"
    "${FFMPEG_LIB}/libswscale.a"
    "${FFMPEG_LIB}/libavutil.a"
    vulkan android log dl m z
)

target_link_options(main PRIVATE
    "-Wl,--export-dynamic"
    "-Wl,-z,max-page-size=16384"
)
