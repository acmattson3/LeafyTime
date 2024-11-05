#include "windowtracker.h"
#include <godot_cpp/core/class_db.hpp>
#include <iostream>
#include <vector>
#include <string>

#if defined(_WIN32)
#include <windows.h>
#include <psapi.h>
#elif defined(__linux__)
#include <fstream>
#include <sstream>
#include <dirent.h>
#endif

using namespace godot;

void WindowTracker::_bind_methods() {
    ClassDB::bind_method(D_METHOD("get_open_windows"), &WindowTracker::get_open_windows);
    ClassDB::bind_method(D_METHOD("get_open_applications"), &WindowTracker::get_open_applications);
}

WindowTracker::WindowTracker() {
    // Initialize any variables here.
}

WindowTracker::~WindowTracker() {
    // Add your cleanup here.
}

Array WindowTracker::get_open_windows() {
    Array open_windows;

#if defined(_WIN32)
    // Enumerate all top-level windows on Windows.
    EnumWindows([](HWND hwnd, LPARAM lParam) -> BOOL {
        char window_title[256];
        if (GetWindowTextA(hwnd, window_title, sizeof(window_title))) {
            if (IsWindowVisible(hwnd) && strlen(window_title) > 0) {
                Array *windows = reinterpret_cast<Array *>(lParam);
                windows->append(String(window_title));
            }
        }
        return TRUE;
    }, reinterpret_cast<LPARAM>(&open_windows));
#elif defined(__linux__)
    // Use /proc to get a list of windows (works with X11 window manager names).
    DIR *proc_dir = opendir("/proc");
    if (proc_dir) {
        struct dirent *entry;
        while ((entry = readdir(proc_dir)) != nullptr) {
            if (entry->d_type == DT_DIR && std::all_of(entry->d_name, entry->d_name + strlen(entry->d_name), ::isdigit)) {
                std::string pid_dir = entry->d_name;
                std::string cmdline_path = "/proc/" + pid_dir + "/cmdline";
                std::ifstream cmdline_stream(cmdline_path);
                if (cmdline_stream) {
                    std::string line;
                    std::getline(cmdline_stream, line);
                    if (!line.empty()) {
                        open_windows.append(String(line.c_str()));
                    }
                }
            }
        }
        closedir(proc_dir);
    }
#endif

    return open_windows;
}

Array WindowTracker::get_open_applications() {
    Array open_applications;

#if defined(_WIN32)
    // Enumerate all top-level windows to get the list of open applications on Windows.
    EnumWindows([](HWND hwnd, LPARAM lParam) -> BOOL {
        DWORD process_id;
        GetWindowThreadProcessId(hwnd, &process_id);
        HANDLE process_handle = OpenProcess(PROCESS_QUERY_INFORMATION | PROCESS_VM_READ, FALSE, process_id);
        if (process_handle) {
            char process_name[MAX_PATH];
            if (GetModuleBaseNameA(process_handle, nullptr, process_name, sizeof(process_name))) {
                if (IsWindowVisible(hwnd) && strlen(process_name) > 0) {
                    Array *applications = reinterpret_cast<Array *>(lParam);
                    applications->append(String(process_name));
                }
            }
            CloseHandle(process_handle);
        }
        return TRUE;
    }, reinterpret_cast<LPARAM>(&open_applications));
#elif defined(__linux__)
    // Use /proc to get a list of running applications.
    DIR *proc_dir = opendir("/proc");
    if (proc_dir) {
        struct dirent *entry;
        while ((entry = readdir(proc_dir)) != nullptr) {
            if (entry->d_type == DT_DIR && std::all_of(entry->d_name, entry->d_name + strlen(entry->d_name), ::isdigit)) {
                std::string pid_dir = entry->d_name;
                std::string cmdline_path = "/proc/" + pid_dir + "/comm";
                std::ifstream cmdline_stream(cmdline_path);
                if (cmdline_stream) {
                    std::string line;
                    std::getline(cmdline_stream, line);
                    if (!line.empty()) {
                        open_applications.append(String(line.c_str()));
                    }
                }
            }
        }
        closedir(proc_dir);
    }
#endif

    return open_applications;
}
