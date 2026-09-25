#include "Settings.h"
#include <nlohmann/json.hpp>
#include <fstream>

Settings Settings::load(const std::string& config_path) {
    Settings s;
    std::ifstream in(config_path);
    if (!in.is_open()) {
        return s;
    }
    nlohmann::json j;
    in >> j;
    s.ps1_emulator_path = j.value("ps1_emulator_path", "");
    s.ps2_emulator_path = j.value("ps2_emulator_path", "");
    s.library_path      = j.value("library_path", "");
    return s;
}

void Settings::save(const std::string& config_path) const {
    nlohmann::json j;
    j["ps1_emulator_path"] = ps1_emulator_path;
    j["ps2_emulator_path"] = ps2_emulator_path;
    j["library_path"]      = library_path;

    std::ofstream out(config_path);
    out << j.dump(4);
}