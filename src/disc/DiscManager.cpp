#include "DiscManager.h"
#include "../backend/backend.h"

#include <QCoreApplication>
#include <QDir>
#include <QDirIterator>
#include <QFile>
#include <QFileInfo>
#include <QNetworkRequest>
#include <QProcess>
#include <QUrl>
#include <QVariantMap>
#include <QRegularExpression>
#include <QDebug>

DiscManager::DiscManager(QObject* parent)
    : QObject(parent)
{
    QString resourceDir =
        QCoreApplication::applicationDirPath()
        + "/resources";

    if (!QFileInfo::exists(resourceDir + "/GameIndex.yaml") &&
        QFileInfo::exists("./resources/GameIndex.yaml"))
    {
        resourceDir = QFileInfo("./resources").absoluteFilePath();
    }

    m_gameDb.loadFromDirectory(
        resourceDir.toStdString()
        );

    qDebug()
        << "Loaded game database entries:"
        << static_cast<qulonglong>(m_gameDb.count());

    connect(
        &m_netManager,
        &QNetworkAccessManager::finished,
        this,
        &DiscManager::onCoverDownloaded
        );

    connect(
        &m_pollTimer,
        &QTimer::timeout,
        this,
        [this]() {
            scanForDisc();
            refreshLibrary();
        }
        );

    m_pollTimer.start(2000);

    scanForDisc();
    refreshLibrary();
}


QString DiscManager::findDumpsDir() const
{
    QString appDumps = QCoreApplication::applicationDirPath() + "/dumps";
    if (QDir(appDumps).exists())
    {
        return appDumps;
    }

    QString rootDumps = QFileInfo("./dumps").absoluteFilePath();
    QDir().mkpath(rootDumps);
    return rootDumps;
}


QString DiscManager::resolve3DCoverUrl(const QString& serial, int consoleType)
{
    if (serial.isEmpty())
    {
        return "";
    }

    QString coversDir =
        QCoreApplication::applicationDirPath()
        + "/resources/covers_3d";
    QDir().mkpath(coversDir);

    QString localPng = coversDir + "/" + serial + ".png";
    if (QFileInfo::exists(localPng))
    {
        return QUrl::fromLocalFile(localPng).toString();
    }

    QString localJpg = coversDir + "/" + serial + ".jpg";
    if (QFileInfo::exists(localJpg))
    {
        return QUrl::fromLocalFile(localJpg).toString();
    }

    QString repo = (consoleType == 2) ? "ps2-covers" : "psx-covers";
    QString remoteUrl = QString(
        "https://raw.githubusercontent.com/xlenore/%1/main/covers/3d/%2.png"
    ).arg(repo, serial);

    // Download and cache it in the background
    QNetworkRequest request{QUrl(remoteUrl)};
    request.setAttribute(QNetworkRequest::User, localPng);
    m_netManager.get(request);

    return remoteUrl;
}


bool DiscManager::launchLibraryFile(const QString& emulatorPath, const QString& filePath)
{
    QString cleanEmuPath = emulatorPath;
    if (cleanEmuPath.startsWith("file:///"))
    {
        cleanEmuPath = QUrl(cleanEmuPath).toLocalFile();
    }

    if (cleanEmuPath.isEmpty() || !QFileInfo::exists(cleanEmuPath))
    {
        qWarning() << "Emulator path is not configured or does not exist:" << cleanEmuPath;
        return false;
    }

    if (filePath.isEmpty() || !QFileInfo::exists(filePath))
    {
        qWarning() << "Dumped game file does not exist:" << filePath;
        return false;
    }

    // Pass standard fullscreen/batch flags and the exact .cue / .iso file on disk!
    QStringList flags = {"-fullscreen", "-nogui"};
    return launchGame(
        QDir::toNativeSeparators(cleanEmuPath),
        QDir::toNativeSeparators(filePath),
        flags
    );
}


void DiscManager::refreshLibrary()
{
    QString dumpsPath = findDumpsDir();

    QStringList currentPaths;
    QVariantList newLibrary;

    QDirIterator it(
        dumpsPath,
        QStringList() << "*.cue" << "*.iso",
        QDir::Files,
        QDirIterator::Subdirectories
    );

    static QRegularExpression serialRegex(R"(([A-Za-z]{4}[-_]\d{5}))");

    while (it.hasNext())
    {
        QString filePath = it.next();
        QFileInfo fileInfo(filePath);

        QString ext = fileInfo.suffix().toLower();
        int cType = (ext == "iso") ? 2 : 1;
        QString cName = (cType == 2) ? "PlayStation 2" : "PlayStation";

        QString baseName = fileInfo.completeBaseName();

        QString serial;
        QRegularExpressionMatch match = serialRegex.match(filePath);
        if (match.hasMatch())
        {
            serial = match.captured(1).toUpper().replace('_', '-');
        }
        else
        {
            serial = QString::fromStdString(
                m_gameDb.getSerialByTitle(baseName.toStdString(), cType)
            );
        }

        if (serial.size() >= 7)
        {
            int numPart = serial.mid(5).toInt();
            if (numPart > 0 && numPart < 20000 && !serial.startsWith("SCPS-15") && !serial.startsWith("SLPM-6"))
            {
                cType = 1;
                cName = "PlayStation";
            }
        }

        QString displayTitle = baseName;
        if (!serial.isEmpty())
        {
            std::string lookedUp = m_gameDb.getGameTitle(serial.toStdString());
            if (!lookedUp.empty() && lookedUp != serial.toStdString())
            {
                displayTitle = QString::fromStdString(lookedUp);
            }
        }

        QVariantMap entry;
        entry["title"]       = displayTitle;
        entry["filePath"]    = QDir::toNativeSeparators(fileInfo.absoluteFilePath());
        entry["folderPath"]  = QDir::toNativeSeparators(fileInfo.absolutePath());
        entry["consoleType"] = cType;
        entry["consoleName"] = cName;
        entry["serial"]      = serial;
        entry["coverUrl"]    = resolve3DCoverUrl(serial, cType);

        newLibrary.append(entry);
        currentPaths.append(filePath);
    }

    currentPaths.sort();
    if (currentPaths != m_lastLibraryPaths)
    {
        m_lastLibraryPaths = currentPaths;
        m_libraryGames = newLibrary;
        emit libraryChanged();
    }
}


bool DiscManager::launchDumper()
{
    QString appDir = QCoreApplication::applicationDirPath();

    QStringList candidatePaths = {
        appDir + "/UniversalConsoleDumper.exe",
        appDir + "/dumper/UniversalConsoleDumper.exe",
        QFileInfo("./UniversalConsoleDumper.exe").absoluteFilePath(),
        QFileInfo("./build/UniversalConsoleDumper.exe").absoluteFilePath()
    };

    for (const QString& exePath : candidatePaths)
    {
        if (QFileInfo::exists(exePath))
        {
            qDebug() << "Launching Disc Dumper:" << exePath;
            return QProcess::startDetached(
                exePath,
                QStringList(),
                QFileInfo(exePath).absolutePath()
            );
        }
    }

    qWarning()
        << "Could not find UniversalConsoleDumper.exe! Checked:"
        << candidatePaths;
    return false;
}


void DiscManager::scanForDisc()
{
    DiscInfo foundInfo;
    QString foundDrive;

    for (char c = 'D'; c <= 'Z'; ++c)
    {
        std::string drive =
            std::string(1, c) + ":";

        DiscInfo info =
            DiscInspector::inspectDrive(drive);

        if (info.isPlayStation)
        {
            foundInfo = info;
            foundDrive = QString::fromStdString(drive);
            break;
        }
    }

    if (!foundInfo.isPlayStation)
    {
        clearDisc();
        return;
    }

    foundInfo.gameTitle =
        m_gameDb.getGameTitle(
            foundInfo.cleanSerial
            );

    int type = 0;
    QString console;

    if (foundInfo.consoleType == "PS1")
    {
        type = 1;
        console = "PlayStation";
    }
    else if (foundInfo.consoleType == "PS2")
    {
        type = 2;
        console = "PlayStation 2";
    }

    QString title = QString::fromStdString(foundInfo.gameTitle);
    QString serial = QString::fromStdString(foundInfo.cleanSerial);

    bool changed =
        !m_discReady ||
        m_drivePath != foundDrive ||
        m_serial != serial ||
        m_consoleType != type ||
        m_gameTitle != title;

    m_discReady = true;
    m_drivePath = foundDrive;
    m_serial = serial;
    m_consoleType = type;
    m_consoleName = console;
    m_gameTitle = title;

    if (changed)
    {
        qDebug()
            << "PlayStation disc detected:"
            << m_gameTitle
            << m_consoleName
            << m_serial
            << m_drivePath;

        updateCoverArt();
        emit discChanged();
    }
}


void DiscManager::updateCoverArt()
{
    if (!m_discReady || m_serial.isEmpty())
    {
        m_coverUrl.clear();
        return;
    }

    m_coverUrl = resolve3DCoverUrl(m_serial, m_consoleType);
}


void DiscManager::onCoverDownloaded(QNetworkReply* reply)
{
    reply->deleteLater();

    QString savePath =
        reply->request().attribute(QNetworkRequest::User).toString();

    if (reply->error() != QNetworkReply::NoError)
    {
        QString failedUrl = reply->url().toString();
        if (failedUrl.contains("/covers/3d/"))
        {
            QString fallbackUrl = failedUrl;
            fallbackUrl.replace("/covers/3d/", "/covers/default/");
            fallbackUrl.replace(".png", ".jpg");

            if (m_coverUrl == failedUrl)
            {
                m_coverUrl = fallbackUrl;
                emit discChanged();
            }

            QString jpgSavePath = savePath;
            jpgSavePath.replace(".png", ".jpg");

            QNetworkRequest fallbackReq{QUrl(fallbackUrl)};
            fallbackReq.setAttribute(QNetworkRequest::User, jpgSavePath);
            m_netManager.get(fallbackReq);
        }
        return;
    }

    QByteArray data = reply->readAll();
    if (data.isEmpty())
    {
        return;
    }

    if (!savePath.isEmpty())
    {
        QFile file(savePath);
        if (file.open(QIODevice::WriteOnly))
        {
            file.write(data);
            file.close();
        }
    }
}


void DiscManager::clearDisc()
{
    if (!m_discReady &&
        m_gameTitle.isEmpty() &&
        m_drivePath.isEmpty())
    {
        return;
    }

    qDebug()
        << "PlayStation disc removed.";

    m_discReady = false;

    m_gameTitle.clear();
    m_consoleName.clear();
    m_serial.clear();
    m_drivePath.clear();
    m_coverUrl.clear();

    m_consoleType = 0;

    emit discChanged();
}