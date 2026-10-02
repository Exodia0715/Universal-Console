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
        if (m_settings.library_path.empty()) {
            m_settings.library_path = "G:\\Test iso folder\\game.iso";
            m_settings.ps2_emulator_path = "G:\\PCSX2\\pcsx2-qt.exe";
        }
    }

    Q_INVOKABLE bool isGameReady() const {
        QString game = QString::fromStdString(m_settings.library_path);
        QString emu  = QString::fromStdString(m_settings.ps2_emulator_path);
        return !game.isEmpty() && !emu.isEmpty() && QFile::exists(game);
    }

    Q_INVOKABLE bool launch() {
        QString emu  = QString::fromStdString(m_settings.ps2_emulator_path);
        QString game = QString::fromStdString(m_settings.library_path);
        return launchGame(emu, game);
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
        QDirIterator it(folderPath, {"*.iso", "*.bin"}, QDir::Files);
        if (it.hasNext()) {
            return it.next();
        }
        return QString();
    }

    Settings m_settings;
};