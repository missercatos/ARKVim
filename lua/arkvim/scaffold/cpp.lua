-- arkvim/scaffold/cpp.lua — C / C++ / GUI / 图形库 模板
local util = require("arkvim.scaffold.util")

local M = {}
local gen = {}

-- ---------------------------------------------------------------------------
-- 基础
-- ---------------------------------------------------------------------------

gen.cmake_c = function(target, name)
  local t = util.project_tokens(name)
  util.write_tree(target, {
    ["CMakeLists.txt"] = util.fill("cmake_minimum_required(VERSION 3.16)\nproject({{NAME}} C)\nset(CMAKE_C_STANDARD 11)\nadd_executable({{kebab}} src/main.c)\n", t),
    ["src/main.c"] = util.fill('#include <stdio.h>\nint main(void) {\n  printf("Hello from {{NAME}}!\\n");\n  return 0;\n}\n', t),
    ["build.sh"] = "#!/usr/bin/env bash\nset -e\ncmake -S . -B build && cmake --build build && ./build/" .. t.kebab .. "\n",
    [".gitignore"] = "build/\n",
  })
  vim.fn.setfperm(target .. "/build.sh", "rwxr-xr-x")
  return "C + CMake 已生成"
end

gen.cmake_cpp = function(target, name)
  local t = util.project_tokens(name)
  util.write_tree(target, {
    ["CMakeLists.txt"] = util.fill("cmake_minimum_required(VERSION 3.16)\nproject({{NAME}} CXX)\nset(CMAKE_CXX_STANDARD 17)\nadd_executable({{kebab}} src/main.cpp)\n", t),
    ["src/main.cpp"] = util.fill('#include <iostream>\nint main() {\n  std::cout << "Hello from {{NAME}}!" << std::endl;\n  return 0;\n}\n', t),
    ["build.sh"] = "#!/usr/bin/env bash\nset -e\ncmake -S . -B build && cmake --build build && ./build/" .. t.kebab .. "\n",
    [".gitignore"] = "build/\n",
  })
  vim.fn.setfperm(target .. "/build.sh", "rwxr-xr-x")
  return "C++ + CMake 已生成"
end

-- ---------------------------------------------------------------------------
-- GUI 框架
-- ---------------------------------------------------------------------------

-- Qt6 Widgets（经典桌面）
gen.qt_widgets = function(target, name)
  local t = util.project_tokens(name)
  util.write_tree(target, {
    ["CMakeLists.txt"] = util.fill([[cmake_minimum_required(VERSION 3.16)
project({{NAME}} LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTOUIC ON)
set(CMAKE_AUTORCC ON)

find_package(Qt6 REQUIRED COMPONENTS Widgets)

add_executable({{kebab}}
  src/main.cpp
  src/mainwindow.cpp
  src/mainwindow.h
)

target_link_libraries({{kebab}} PRIVATE Qt6::Widgets)
]], t),
    ["src/main.cpp"] = util.fill([[#include <QApplication>
#include "mainwindow.h"

int main(int argc, char *argv[]) {
    QApplication app(argc, argv);
    MainWindow window;
    window.show();
    return app.exec();
}
]], t),
    ["src/mainwindow.h"] = [[#pragma once
#include <QMainWindow>

class MainWindow : public QMainWindow {
    Q_OBJECT
public:
    explicit MainWindow(QWidget *parent = nullptr);
};
]],
    ["src/mainwindow.cpp"] = util.fill([[#include "mainwindow.h"
#include <QLabel>

MainWindow::MainWindow(QWidget *parent) : QMainWindow(parent) {
    setWindowTitle("{{NAME}}");
    setCentralWidget(new QLabel("Hello from {{NAME}}!", this));
    resize(800, 600);
}
]], t),
    ["build.sh"] = "#!/usr/bin/env bash\nset -e\ncmake -S . -B build -DCMAKE_BUILD_TYPE=Release && cmake --build build -j && ./build/" .. t.kebab .. "\n",
    [".gitignore"] = "build/\n",
    ["README.md"] = util.fill("# {{NAME}}\n\nQt6 Widgets 桌面应用\n\n```bash\n./build.sh\n```\n", t),
  })
  vim.fn.setfperm(target .. "/build.sh", "rwxr-xr-x")
  return "Qt6 Widgets 已生成"
end

-- Qt6 Quick / QML（现代声明式 UI）
gen.qt_qml = function(target, name)
  local t = util.project_tokens(name)
  util.write_tree(target, {
    ["CMakeLists.txt"] = util.fill([[cmake_minimum_required(VERSION 3.16)
project({{NAME}} LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS Quick)
qt_standard_project_setup()

qt_add_executable({{kebab}}
  src/main.cpp
)

qt_add_qml_module({{kebab}}
  URI {{Pascal}}App
  VERSION 1.0
  QML_FILES src/Main.qml
)

target_link_libraries({{kebab}} PRIVATE Qt6::Quick)
]], t),
    ["src/main.cpp"] = util.fill([[#include <QGuiApplication>
#include <QQmlApplicationEngine>

int main(int argc, char *argv[]) {
    QGuiApplication app(argc, argv);
    QQmlApplicationEngine engine;
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreationFailed,
                     &app, []() { QCoreApplication::exit(-1); },
                     Qt::QueuedConnection);
    engine.loadFromModule("{{Pascal}}App", "Main");
    return app.exec();
}
]], t),
    ["src/Main.qml"] = util.fill([[import QtQuick
import QtQuick.Controls

ApplicationWindow {
    visible: true
    width: 800
    height: 600
    title: "{{NAME}}"

    Text {
        anchors.centerIn: parent
        text: "Hello from {{NAME}}!"
        font.pixelSize: 24
    }
}
]], t),
    ["build.sh"] = "#!/usr/bin/env bash\nset -e\ncmake -S . -B build -DCMAKE_BUILD_TYPE=Release && cmake --build build -j && ./build/" .. t.kebab .. "\n",
    [".gitignore"] = "build/\n",
    ["README.md"] = util.fill("# {{NAME}}\n\nQt6 Quick (QML) 应用\n\n```bash\n./build.sh\n```\n", t),
  })
  vim.fn.setfperm(target .. "/build.sh", "rwxr-xr-x")
  return "Qt6 Quick/QML 已生成"
end

-- GTK4 (C)
gen.gtk4 = function(target, name)
  local t = util.project_tokens(name)
  util.write_tree(target, {
    ["CMakeLists.txt"] = util.fill([[cmake_minimum_required(VERSION 3.16)
project({{NAME}} C)

set(CMAKE_C_STANDARD 11)
find_package(PkgConfig REQUIRED)
pkg_check_modules(GTK4 REQUIRED gtk4)

add_executable({{kebab}} src/main.c)
target_include_directories({{kebab}} PRIVATE ${GTK4_INCLUDE_DIRS})
target_link_libraries({{kebab}} PRIVATE ${GTK4_LIBRARIES})
target_compile_options({{kebab}} PRIVATE ${GTK4_CFLAGS_OTHER})
]], t),
    ["src/main.c"] = util.fill([[#include <gtk/gtk.h>

static void activate(GtkApplication *app, gpointer user_data) {
    GtkWidget *window = gtk_application_window_new(app);
    gtk_window_set_title(GTK_WINDOW(window), "{{NAME}}");
    gtk_window_set_default_size(GTK_WINDOW(window), 800, 600);
    gtk_window_set_child(GTK_WINDOW(window), gtk_label_new("Hello from {{NAME}}!"));
    gtk_window_present(GTK_WINDOW(window));
}

int main(int argc, char **argv) {
    GtkApplication *app = gtk_application_new("com.example.{{snake}}", G_APPLICATION_DEFAULT_FLAGS);
    g_signal_connect(app, "activate", G_CALLBACK(activate), NULL);
    int status = g_application_run(G_APPLICATION(app), argc, argv);
    g_object_unref(app);
    return status;
}
]], t),
    ["build.sh"] = "#!/usr/bin/env bash\nset -e\ncmake -S . -B build && cmake --build build -j && ./build/" .. t.kebab .. "\n",
    [".gitignore"] = "build/\n",
  })
  vim.fn.setfperm(target .. "/build.sh", "rwxr-xr-x")
  return "GTK4 (C) 已生成"
end

-- gtkmm3 (C++)
gen.gtkmm = function(target, name)
  local t = util.project_tokens(name)
  util.write_tree(target, {
    ["CMakeLists.txt"] = util.fill([[cmake_minimum_required(VERSION 3.16)
project({{NAME}} CXX)

set(CMAKE_CXX_STANDARD 17)
find_package(PkgConfig REQUIRED)
pkg_check_modules(GTKMM REQUIRED gtkmm-3.0)

add_executable({{kebab}} src/main.cpp)
target_include_directories({{kebab}} PRIVATE ${GTKMM_INCLUDE_DIRS})
target_link_libraries({{kebab}} PRIVATE ${GTKMM_LIBRARIES})
target_compile_options({{kebab}} PRIVATE ${GTKMM_CFLAGS_OTHER})
]], t),
    ["src/main.cpp"] = util.fill([[#include <gtkmm.h>

int main(int argc, char *argv[]) {
    auto app = Gtk::Application::create(argc, argv, "com.example.{{snake}}");
    Gtk::Window window;
    window.set_title("{{NAME}}");
    window.set_default_size(800, 600);
    Gtk::Label label("Hello from {{NAME}}!");
    window.add(label);
    window.show_all_children();
    return app->run(window);
}
]], t),
    ["build.sh"] = "#!/usr/bin/env bash\nset -e\ncmake -S . -B build && cmake --build build -j && ./build/" .. t.kebab .. "\n",
    [".gitignore"] = "build/\n",
  })
  vim.fn.setfperm(target .. "/build.sh", "rwxr-xr-x")
  return "gtkmm3 (C++) 已生成"
end

-- wxWidgets
gen.wxwidgets = function(target, name)
  local t = util.project_tokens(name)
  util.write_tree(target, {
    ["CMakeLists.txt"] = util.fill([[cmake_minimum_required(VERSION 3.16)
project({{NAME}} CXX)

set(CMAKE_CXX_STANDARD 17)
find_package(wxWidgets REQUIRED COMPONENTS core base)
include(${wxWidgets_USE_FILE})

add_executable({{kebab}} src/main.cpp)
target_link_libraries({{kebab}} PRIVATE ${wxWidgets_LIBRARIES})
]], t),
    ["src/main.cpp"] = util.fill([[#include <wx/wx.h>

class App : public wxApp {
public:
    bool OnInit() override;
};

class Frame : public wxFrame {
public:
    Frame();
};

wxIMPLEMENT_APP(App);

bool App::OnInit() {
    auto *frame = new Frame();
    frame->Show();
    return true;
}

Frame::Frame() : wxFrame(nullptr, wxID_ANY, "{{NAME}}", wxDefaultPosition, wxSize(800, 600)) {
    new wxStaticText(this, wxID_ANY, "Hello from {{NAME}}!", wxPoint(20, 20));
    Centre();
}
]], t),
    ["build.sh"] = "#!/usr/bin/env bash\nset -e\ncmake -S . -B build && cmake --build build -j && ./build/" .. t.kebab .. "\n",
    [".gitignore"] = "build/\n",
  })
  vim.fn.setfperm(target .. "/build.sh", "rwxr-xr-x")
  return "wxWidgets 已生成"
end

-- ---------------------------------------------------------------------------
-- 图形库（严格说是库，但定义项目骨架）
-- ---------------------------------------------------------------------------

-- SDL3
gen.sdl3 = function(target, name)
  local t = util.project_tokens(name)
  util.write_tree(target, {
    ["CMakeLists.txt"] = util.fill([[cmake_minimum_required(VERSION 3.16)
project({{NAME}} CXX)

set(CMAKE_CXX_STANDARD 17)
find_package(PkgConfig REQUIRED)
pkg_check_modules(SDL3 REQUIRED sdl3)

add_executable({{kebab}} src/main.cpp)
target_include_directories({{kebab}} PRIVATE ${SDL3_INCLUDE_DIRS})
target_link_libraries({{kebab}} PRIVATE ${SDL3_LIBRARIES})
target_compile_options({{kebab}} PRIVATE ${SDL3_CFLAGS_OTHER})
]], t),
    ["src/main.cpp"] = util.fill([[#include <SDL3/SDL.h>

int main(int argc, char *argv[]) {
    SDL_Init(SDL_INIT_VIDEO);
    SDL_Window *window = SDL_CreateWindow("{{NAME}}", 800, 600, 0);
    SDL_Renderer *renderer = SDL_CreateRenderer(window, nullptr);

    bool running = true;
    while (running) {
        SDL_Event e;
        while (SDL_PollEvent(&e)) {
            if (e.type == SDL_EVENT_QUIT) running = false;
        }
        SDL_SetRenderDrawColor(renderer, 20, 20, 30, 255);
        SDL_RenderClear(renderer);
        SDL_RenderPresent(renderer);
        SDL_Delay(16);
    }

    SDL_DestroyRenderer(renderer);
    SDL_DestroyWindow(window);
    SDL_Quit();
    return 0;
}
]], t),
    ["build.sh"] = "#!/usr/bin/env bash\nset -e\ncmake -S . -B build && cmake --build build -j && ./build/" .. t.kebab .. "\n",
    [".gitignore"] = "build/\n",
  })
  vim.fn.setfperm(target .. "/build.sh", "rwxr-xr-x")
  return "SDL3 已生成"
end

-- raylib (C)
gen.raylib = function(target, name)
  local t = util.project_tokens(name)
  util.write_tree(target, {
    ["CMakeLists.txt"] = util.fill([[cmake_minimum_required(VERSION 3.16)
project({{NAME}} C)

set(CMAKE_C_STANDARD 11)
find_package(PkgConfig REQUIRED)
pkg_check_modules(RAYLIB REQUIRED raylib)

add_executable({{kebab}} src/main.c)
target_include_directories({{kebab}} PRIVATE ${RAYLIB_INCLUDE_DIRS})
target_link_libraries({{kebab}} PRIVATE ${RAYLIB_LIBRARIES})
]], t),
    ["src/main.c"] = util.fill([[#include "raylib.h"

int main(void) {
    InitWindow(800, 600, "{{NAME}}");
    SetTargetFPS(60);

    while (!WindowShouldClose()) {
        BeginDrawing();
        ClearBackground(RAYWHITE);
        DrawText("Hello from {{NAME}}!", 190, 200, 20, LIGHTGRAY);
        EndDrawing();
    }

    CloseWindow();
    return 0;
}
]], t),
    ["build.sh"] = "#!/usr/bin/env bash\nset -e\ncmake -S . -B build && cmake --build build -j && ./build/" .. t.kebab .. "\n",
    [".gitignore"] = "build/\n",
  })
  vim.fn.setfperm(target .. "/build.sh", "rwxr-xr-x")
  return "raylib (C) 已生成"
end

-- GLFW + Dear ImGui（FetchContent 拉取 ImGui）
gen.imgui = function(target, name)
  local t = util.project_tokens(name)
  util.write_tree(target, {
    ["CMakeLists.txt"] = util.fill([[cmake_minimum_required(VERSION 3.16)
project({{NAME}} CXX)

set(CMAKE_CXX_STANDARD 17)
find_package(glfw3 REQUIRED)

include(FetchContent)
FetchContent_Declare(imgui
  GIT_REPOSITORY https://github.com/ocornut/imgui.git
  GIT_TAG v1.90.4
)
FetchContent_MakeAvailable(imgui)

add_library(imgui STATIC
  ${imgui_SOURCE_DIR}/imgui.cpp
  ${imgui_SOURCE_DIR}/imgui_draw.cpp
  ${imgui_SOURCE_DIR}/imgui_tables.cpp
  ${imgui_SOURCE_DIR}/imgui_widgets.cpp
  ${imgui_SOURCE_DIR}/backends/imgui_impl_glfw.cpp
  ${imgui_SOURCE_DIR}/backends/imgui_impl_opengl3.cpp
)
target_include_directories(imgui PUBLIC ${imgui_SOURCE_DIR} ${imgui_SOURCE_DIR}/backends)
target_link_libraries(imgui PUBLIC glfw)

add_executable({{kebab}} src/main.cpp)
target_link_libraries({{kebab}} PRIVATE imgui glfw)
]], t),
    ["src/main.cpp"] = util.fill([[#include "imgui.h"
#include "imgui_impl_glfw.h"
#include "imgui_impl_opengl3.h"
#include <GLFW/glfw3.h>

int main() {
    if (!glfwInit()) return 1;
    GLFWwindow *window = glfwCreateWindow(1280, 720, "{{NAME}}", nullptr, nullptr);
    glfwMakeContextCurrent(window);
    glfwSwapInterval(1);

    IMGUI_CHECKVERSION();
    ImGui::CreateContext();
    ImGui::StyleColorsDark();
    ImGui_ImplGlfw_InitForOpenGL(window, true);
    ImGui_ImplOpenGL3_Init("#version 130");

    while (!glfwWindowShouldClose(window)) {
        glfwPollEvents();
        ImGui_ImplOpenGL3_NewFrame();
        ImGui_ImplGlfw_NewFrame();
        ImGui::NewFrame();

        ImGui::Begin("{{NAME}}");
        ImGui::Text("Hello from {{NAME}}!");
        ImGui::End();

        ImGui::Render();
        glViewport(0, 0, 1280, 720);
        glClearColor(0.1f, 0.1f, 0.15f, 1.0f);
        glClear(GL_COLOR_BUFFER_BIT);
        ImGui_ImplOpenGL3_RenderDrawData(ImGui::GetDrawData());
        glfwSwapBuffers(window);
    }

    ImGui_ImplOpenGL3_Shutdown();
    ImGui_ImplGlfw_Shutdown();
    ImGui::DestroyContext();
    glfwDestroyWindow(window);
    glfwTerminate();
    return 0;
}
]], t),
    ["build.sh"] = "#!/usr/bin/env bash\nset -e\ncmake -S . -B build && cmake --build build -j && ./build/" .. t.kebab .. "\n",
    [".gitignore"] = "build/\n",
    ["README.md"] = util.fill("# {{NAME}}\n\nGLFW + Dear ImGui（首次构建会用 FetchContent 拉取 ImGui）\n\n```bash\n./build.sh\n```\n", t),
  })
  vim.fn.setfperm(target .. "/build.sh", "rwxr-xr-x")
  return "GLFW + Dear ImGui 已生成"
end

M.frameworks = {
  { label = "C + CMake", lang = "c", gen = gen.cmake_c, main = "src/main.c",
    requires = { bins = { "cmake", "gcc" }, pacman = { "cmake", "gcc" } } },
  { label = "C++ + CMake (C++17)", lang = "cpp", gen = gen.cmake_cpp, main = "src/main.cpp",
    requires = { bins = { "cmake", "g++" }, pacman = { "cmake", "gcc" } } },
  { label = "Qt6 Widgets (C++)", lang = "cpp", gen = gen.qt_widgets, main = "src/mainwindow.cpp",
    requires = { bins = { "cmake", "g++", "qmake6" }, pacman = { "cmake", "gcc", "qt6-base" } } },
  { label = "Qt6 Quick/QML (C++)", lang = "cpp", gen = gen.qt_qml, main = "src/Main.qml",
    requires = { bins = { "cmake", "g++", "qmake6" }, pacman = { "cmake", "gcc", "qt6-declarative" } } },
  { label = "GTK4 (C)", lang = "c", gen = gen.gtk4, main = "src/main.c",
    requires = { bins = { "cmake", "gcc", "pkg-config" }, pacman = { "cmake", "gcc", "gtk4" } } },
  { label = "gtkmm3 (C++)", lang = "cpp", gen = gen.gtkmm, main = "src/main.cpp",
    requires = { bins = { "cmake", "g++", "pkg-config" }, pacman = { "cmake", "gcc", "gtkmm3" } } },
  { label = "wxWidgets (C++)", lang = "cpp", gen = gen.wxwidgets, main = "src/main.cpp",
    requires = { bins = { "cmake", "g++" }, pacman = { "cmake", "gcc", "wxwidgets-gtk3" } } },
  { label = "SDL3 (C++)", lang = "cpp", gen = gen.sdl3, main = "src/main.cpp",
    requires = { bins = { "cmake", "g++", "pkg-config" }, pacman = { "cmake", "gcc", "sdl3" } } },
  { label = "raylib (C)", lang = "c", gen = gen.raylib, main = "src/main.c",
    requires = { bins = { "cmake", "gcc", "pkg-config" }, pacman = { "cmake", "gcc", "raylib" } } },
  { label = "GLFW + Dear ImGui (C++)", lang = "cpp", gen = gen.imgui, main = "src/main.cpp",
    requires = { bins = { "cmake", "g++", "git" }, pacman = { "cmake", "gcc", "glfw" }, note = "首次构建需要联网拉取 ImGui" } },
}

return M
