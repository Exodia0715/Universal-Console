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
        QString game = QString::fromStdString(m_settings.library_path);
        QString emu  = QString::fromStdString(m_settings.ps2_emulator_path);
        return !game.isEmpty() && !emu.isEmpty() && QFile::exists(game);
    }

    Q_INVOKABLE bool launch() {
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
        QString localPath = QUrl(folderPath).toLocalFile();
        QString isoPath = findIsoInFolder(localPath);
        if (!isoPath.isEmpty()) {
            m_settings.library_path = isoPath.toStdString();
            m_settings.save(configPath().toStdString());
        }
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

    Settings m_settings;
};