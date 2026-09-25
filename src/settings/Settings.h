#pragma once
#include <string>

struct Settings {
    std::string ps1_emulator_path;
    std::string ps2_emulator_path;
    std::string library_path;

    static Settings load(const std::string& config_path);
    void save(const std::string& config_path) const;
};