#pragma once
#include <QString>

enum class ConsoleType { PS1, PS2, Unknown };

ConsoleType detectConsoleType(const QString& isoFileName);
bool launchGame(const QString& emulatorPath, const QString& gamePath, const QStringList& flags);