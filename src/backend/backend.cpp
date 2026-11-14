#include "backend.h"
#include <QProcess>
#include <QFile>
#include <QFileInfo>
#include <QDir>
#include <QDebug>

bool launchGame(
    const QString& emulator,
    const QString& game,
    const QStringList& flags
    )
{
    QStringList arguments;

    // Emulator options MUST come first.
    arguments.append(flags);

    // The game/disc argument comes last.
    if (!game.isEmpty())
        arguments.append(game);

    qDebug() << "Launching emulator:";
    qDebug() << "Executable:" << emulator;
    qDebug() << "Arguments:" << arguments;

    return QProcess::startDetached(
        emulator,
        arguments
        );
}

//Valid for 95% of PS2 library, but some PS2 CD-ROM games use .cue files
//Inform disk-reading team to account for this in their system
ConsoleType detectConsoleType(const QString& isoFileName) {
    QString ext = QFileInfo(isoFileName).suffix().toLower();
    if (ext == "cue") {
        return ConsoleType::PS1;
    }
    if (ext == "iso") {
        return ConsoleType::PS2;
    }
    return ConsoleType::Unknown;
}