#pragma once

#include <QObject>
#include <QFile>
#include <QFileInfo>
#include <QDir>
#include <QDirIterator>
#include <QUrl>
#include <QDebug>

#include "../backend/backend.h"
#include "../settings/Settings.h"

class AppController : public QObject
{
    Q_OBJECT

    Q_PROPERTY(
        QString ps1EmulatorPath
            READ ps1EmulatorPath
                NOTIFY ps1EmulatorPathChanged
        )

    Q_PROPERTY(
        QString ps2EmulatorPath
            READ ps2EmulatorPath
                NOTIFY ps2EmulatorPathChanged
        )

public:

    explicit AppController(QObject* parent = nullptr)
        : QObject(parent)
    {
        m_settings = Settings::load(
            configPath().toStdString()
            );
    }

    // =========================================================
    // EMULATOR PATH GETTERS
    // =========================================================

    QString ps1EmulatorPath() const
    {
        return QString::fromStdString(
            m_settings.ps1_emulator_path
            );
    }

    QString ps2EmulatorPath() const
    {
        return QString::fromStdString(
            m_settings.ps2_emulator_path
            );
    }

    // =========================================================
    // GAME STATUS
    // =========================================================

    Q_INVOKABLE bool isGameReady() const
    {
        return !m_settings.game_folder_path.empty();
    }

    // =========================================================
    // GAME LAUNCHING
    // =========================================================

    Q_INVOKABLE bool launch()
    {
        rescanGameFolder();

        QString game =
            QString::fromStdString(
                m_settings.library_path
                );

        if (game.isEmpty()) {
            qWarning() << "No game path configured.";
            return false;
        }

        ConsoleType type =
            detectConsoleType(
                QFileInfo(game).fileName()
                );

        QString emu;
        QStringList flags;

        if (type == ConsoleType::PS1) {

            emu =
                QString::fromStdString(
                    m_settings.ps1_emulator_path
                    );

            flags = {
                "-fullscreen",
                "-batch"
            };
        }

        else if (type == ConsoleType::PS2) {

            emu =
                QString::fromStdString(
                    m_settings.ps2_emulator_path
                    );

            flags = {
                "-nogui",
                "-fullscreen"
            };
        }

        else {
            qWarning() << "Unknown console type.";
            return false;
        }

        if (emu.isEmpty()) {
            qWarning()
            << "Emulator path has not been configured.";

            return false;
        }

        if (!QFileInfo::exists(emu)) {
            qWarning()
            << "Emulator executable does not exist:"
            << emu;

            return false;
        }

        qDebug() << "Launching emulator:" << emu;
        qDebug() << "Launching game:" << game;

        return launchGame(
            emu,
            game,
            flags
            );
    }

    // =========================================================
    // EMULATOR PATH CONFIGURATION
    // =========================================================

    Q_INVOKABLE bool setPs1EmulatorPath(
        const QString& path
        )
    {
        QString localPath =
            convertToLocalPath(path);

        QFileInfo emulator(localPath);

        if (!emulator.exists() ||
            !emulator.isFile()) {

            qWarning()
            << "Invalid DuckStation path:"
            << localPath;

            return false;
        }

        m_settings.ps1_emulator_path =
            emulator.absoluteFilePath().toStdString();

        m_settings.save(
            configPath().toStdString()
            );

        emit ps1EmulatorPathChanged();

        qDebug()
            << "DuckStation path saved:"
            << emulator.absoluteFilePath();

        return true;
    }

    Q_INVOKABLE bool setPs2EmulatorPath(
        const QString& path
        )
    {
        QString localPath =
            convertToLocalPath(path);

        QFileInfo emulator(localPath);

        if (!emulator.exists() ||
            !emulator.isFile()) {

            qWarning()
            << "Invalid PCSX2 path:"
            << localPath;

            return false;
        }

        m_settings.ps2_emulator_path =
            emulator.absoluteFilePath().toStdString();

        m_settings.save(
            configPath().toStdString()
            );

        emit ps2EmulatorPathChanged();

        qDebug()
            << "PCSX2 path saved:"
            << emulator.absoluteFilePath();

        return true;
    }

    // =========================================================
    // GAME FOLDER
    // =========================================================

    Q_INVOKABLE void setGameFolder(
        const QString& folderPath
        )
    {
        m_settings.game_folder_path =
            convertToLocalPath(folderPath)
                .toStdString();

        rescanGameFolder();
    }

signals:

    void ps1EmulatorPathChanged();
    void ps2EmulatorPathChanged();

private:

    // =========================================================
    // PATH HELPERS
    // =========================================================

    QString convertToLocalPath(
        const QString& path
        ) const
    {
        QUrl url(path);

        if (url.isLocalFile()) {
            return url.toLocalFile();
        }

        return path;
    }

    QString configPath() const
    {
        return QDir::currentPath()
        + "/settings.json";
    }

    // =========================================================
    // GAME SCANNING
    // =========================================================

    QString findIsoInFolder(
        const QString& folderPath
        ) const
    {
        // PS1 multi-file games should prefer the .cue file.
        QDirIterator cueIt(
            folderPath,
            {"*.cue"},
            QDir::Files
            );

        if (cueIt.hasNext()) {
            return cueIt.next();
        }

        // PS2 ISO or standalone PS1 BIN.
        QDirIterator imgIt(
            folderPath,
            {"*.iso", "*.bin"},
            QDir::Files
            );

        if (imgIt.hasNext()) {
            return imgIt.next();
        }

        return QString();
    }

    void rescanGameFolder()
    {
        QString folder =
            QString::fromStdString(
                m_settings.game_folder_path
                );

        qDebug()
            << "Rescanning folder:"
            << folder;

        if (folder.isEmpty()) {
            return;
        }

        QString isoPath =
            findIsoInFolder(folder);

        qDebug()
            << "Found:"
            << isoPath;

        if (!isoPath.isEmpty()) {
            m_settings.library_path = isoPath.toStdString();
        } else {
            m_settings.library_path.clear();
        }

        m_settings.save(configPath().toStdString());
    }

    Settings m_settings;
};