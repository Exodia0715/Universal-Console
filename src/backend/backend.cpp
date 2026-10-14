#include "backend.h"
#include <QProcess>
#include <QFile>
#include <QFileInfo>
#include <QDir>

bool launchGame(const QString& emulatorPath, const QString& gamePath, const QStringList& flags) {
    QString nativeGamePath = QDir::toNativeSeparators(gamePath);
    QStringList args = {nativeGamePath};
    args.append(flags);
    return QProcess::startDetached(emulatorPath, args);
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