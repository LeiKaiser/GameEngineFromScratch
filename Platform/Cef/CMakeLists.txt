if(${APPLE})
    find_library(CEF_LIBRARY NAMES "Chromium Embedded Framework" PATHS ${MYGE_EXTERNAL_FRAMEWORK_PATH} NO_CMAKE_FIND_ROOT_PATH NO_SYSTEM_ENVIRONMENT_PATH)
else(${APPLIE})
    find_library(CEF_LIBRARY NAMES cef libcef PATHS ${MYGE_EXTERNAL_LIBRARY_PATH} NO_CMAKE_FIND_ROOT_PATH NO_SYSTEM_ENVIRONMENT_PATH)
endif(${APPLE})

find_library(CEF_WRAPPER NAMES cef_dll_wrapper libcef_dll_wrapper PATHS ${MYGE_EXTERNAL_LIBRARY_PATH} NO_CMAKE_FIND_ROOT_PATH NO_SYSTEM_ENVIRONMENT_PATH)

set(CefSources
                simple_handler.cpp
                CefApplication.cpp
)

add_library(CEF ${CefSources})

target_link_libraries(CEF
    ${CEF_WRAPPER}
    ${CEF_LIBRARY}
)
