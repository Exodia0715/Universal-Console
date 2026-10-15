#pragma once
#include <QObject>
#include <QFile>
#include <QDir>
#include <QDirIterator>
#include <QUrl>
#include "../backend/backend.h"
#include "../settings/Settings.h"

class AppController : public QObject {
    Q_OBJECT
public:
    explicit AppController(QObject* parent = nullptr) : QObject(parent) {
        m_settings = Settings::load(configPath().toStdString());
    }

    Q_INVOKABLE bool isGameReady() const {
        return !m_settings.game_folder_path.empty();
    }

    Q_INVOKABLE bool launch() {
        rescanGameFolder();

        QString game = QString::fromStdString(m_settings.library_path);
        ConsoleType type = detectConsoleType(QFileInfo(game).fileName());

        QString emu;
        QStringList flags;
        if (type == ConsoleType::PS1) {
            emu = QString::fromStdString(m_settings.ps1_emulator_path);
            flags = {"-fullscreen", "-batch"};
        } else if (type == ConsoleType::PS2) {
            emu = QString::fromStdString(m_settings.ps2_emulator_path);
            flags = {"-nogui", "-fullscreen"};
        } else {
            return false;
        }

        if (emu.isEmpty()) {
            return false;
        }

        return launchGame(emu, game, flags);
    }

    Q_INVOKABLE void setPs1EmulatorPath(const QString& path) {
        QString localPath = QUrl(path).toLocalFile();
        m_settings.ps1_emulator_path = localPath.toStdString();
        m_settings.save(configPath().toStdString());
    }

    Q_INVOKABLE void setPs2EmulatorPath(const QString& path) {
        QString localPath = QUrl(path).toLocalFile();
        m_settings.ps2_emulator_path = localPath.toStdString();
        m_settings.save(configPath().toStdString());
    }

    Q_INVOKABLE void setGameFolder(const QString& folderPath) {
        m_settings.game_folder_path = QUrl(folderPath).toLocalFile().toStdString();
        rescanGameFolder();
    }





private:
    QString configPath() const {
        return QDir::currentPath() + "/settings.json";
    }

    QString findIsoInFolder(const QString& folderPath) const {
        QDirIterator cueIt(folderPath, {"*.cue"}, QDir::Files);
        if (cueIt.hasNext()) {
            return cueIt.next();
        }

        // Otherwise fall back to a single-file image (PS2 .iso, or a standalone .bin)
        QDirIterator imgIt(folderPath, {"*.iso", "*.bin"}, QDir::Files);
        if (imgIt.hasNext()) {
            return imgIt.next();
        }

        return QString();
    }

    void rescanGameFolder() {
        QString folder = QString::fromStdString(m_settings.game_folder_path);
        qDebug() << "Rescanning folder:" << folder;
        if (folder.isEmpty()) return;

        QString isoPath = findIsoInFolder(folder);
        qDebug() << "Found:" << isoPath;
        if (!isoPath.isEmpty()) {
            m_settings.library_path = isoPath.toStdString();
            m_settings.save(configPath().toStdString());
        }
    }

    QString m_gameFolder; // remembered so launch() can rescan it

    Settings m_settings;
};