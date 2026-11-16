#pragma once
#include <string>
#include <unordered_map>
#include <fstream>
#include <filesystem>
#include <algorithm>
#include <cctype>

class GameDatabase {
public:
    void loadFromDirectory(const std::string& resourceDir) {
        loadYamlDatabase(resourceDir + "/GameIndex.yaml", 2); // PCSX2 (PS2)
        loadYamlDatabase(resourceDir + "/gamedb.yaml", 1);    // DuckStation (PS1)
    }

    // Returns the human-readable game title, or the serial ID if not found
    std::string getGameTitle(std::string cleanSerial) const {
        std::transform(cleanSerial.begin(), cleanSerial.end(), cleanSerial.begin(), ::toupper);
        auto it = m_titles.find(cleanSerial);
        if (it != m_titles.end()) {
            return it->second;
        }
        return cleanSerial; // Fallback if unknown disc
    }

std::string getSerialByTitle(const std::string& folderOrTitle, int consoleType = 0) const {
        std::string baseKey = toLower(sanitizeForFilename(folderOrTitle));
        std::vector<std::string> keysToTry = {
            baseKey,
            baseKey + " (disc 1)",
            baseKey + " (usa)",
            baseKey + " (usa) (disc 1)"
        };

        for (const auto& key : keysToTry) {
            if (consoleType == 1) {
                auto it = m_ps1TitleToSerial.find(key);
                if (it != m_ps1TitleToSerial.end()) return it->second;
            } else if (consoleType == 2) {
                auto it = m_ps2TitleToSerial.find(key);
                if (it != m_ps2TitleToSerial.end()) return it->second;
            }
        }

        for (const auto& key : keysToTry) {
            auto it1 = m_ps1TitleToSerial.find(key);
            if (it1 != m_ps1TitleToSerial.end()) return it1->second;
            auto it2 = m_ps2TitleToSerial.find(key);
            if (it2 != m_ps2TitleToSerial.end()) return it2->second;
        }
        return "";
    }

    // Strips illegal Windows filename characters (: * ? " < > | / \) for folder naming
    static std::string sanitizeForFilename(std::string title) {
        const std::string illegalChars = "\\/:*?\"<>|";
        for (char& c : title) {
            if (illegalChars.find(c) != std::string::npos) {
                c = '_';
            }
        }
        return title;
    }

    size_t count() const { return m_titles.size(); }

private:
    std::unordered_map<std::string, std::string> m_titles;
    std::unordered_map<std::string, std::string> m_ps1TitleToSerial;
    std::unordered_map<std::string, std::string> m_ps2TitleToSerial;

    static std::string toLower(std::string s) {
        std::transform(s.begin(), s.end(), s.begin(),
                       [](unsigned char c) { return std::tolower(c); });
        return s;
    }

    void loadYamlDatabase(const std::string& filePath, int consoleType) {
        if (!std::filesystem::exists(filePath)) return;

        std::ifstream file(filePath);
        std::string line;
        std::string currentSerial;

        auto& targetMap = (consoleType == 2) ? m_ps2TitleToSerial : m_ps1TitleToSerial;

        while (std::getline(file, line)) {
            if (line.empty() || line[0] == '#') continue;

            // Top-level YAML key (no leading spaces) = Game Serial ID (e.g. "SCUS-97328:")
            if (!std::isspace(static_cast<unsigned char>(line[0]))) {
                size_t colonPos = line.find(':');
                if (colonPos != std::string::npos) {
                    currentSerial = line.substr(0, colonPos);
                    currentSerial.erase(std::remove(currentSerial.begin(), currentSerial.end(), '\"'), currentSerial.end());
                    currentSerial.erase(currentSerial.find_last_not_of(" \r\n\t") + 1);
                    std::transform(currentSerial.begin(), currentSerial.end(), currentSerial.begin(), ::toupper);
                }
            } 
            // Indented line: check for "  name:" (PCSX2) or "  title:" (DuckStation)
            else if (!currentSerial.empty()) {
                size_t firstChar = line.find_first_not_of(" \t");
                if (firstChar == std::string::npos) continue;

                if (firstChar <= 4 && (line.compare(firstChar, 5, "name:") == 0 || 
                                       line.compare(firstChar, 6, "title:") == 0)) {
                    size_t colonPos = line.find(':', firstChar);
                    std::string title = line.substr(colonPos + 1);

                    size_t start = title.find_first_not_of(" \t\"");
                    size_t end = title.find_last_not_of(" \r\n\t\"");
                    if (start != std::string::npos && end != std::string::npos && end >= start) {
                        std::string cleanTitle = title.substr(start, end - start + 1);
                        m_titles[currentSerial] = cleanTitle;

                        std::string sanitizedKey = toLower(sanitizeForFilename(cleanTitle));
                        bool isUsRelease = (currentSerial.size() >= 3 && currentSerial[2] == 'U');
                        if (targetMap.find(sanitizedKey) == targetMap.end() || isUsRelease) {
                            targetMap[sanitizedKey] = currentSerial;
                        }
                    }
                    currentSerial.clear();
                }
            }
        }
    }
};