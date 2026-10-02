#include "backend.h"
#include <QProcess>
#include <QFile>
#include <QFileInfo>
#include <QDir>

bool launchGame(const QString& emulatorPath, const QString& gamePath) {
    QString nativeGamePath = QDir::toNativeSeparators(gamePath);
    return QProcess::startDetached(emulatorPath, {nativeGamePath, "-nogui", "-fullscreen"});
}