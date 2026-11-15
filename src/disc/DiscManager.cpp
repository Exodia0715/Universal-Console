#include "DiscManager.h"

#include <QCoreApplication>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QNetworkRequest>
#include <QUrl>
#include <QDebug>

DiscManager::DiscManager(QObject* parent)
    : QObject(parent)
{
    QString resourceDir =
        QCoreApplication::applicationDirPath()
        + "/resources";

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
        &DiscManager::scanForDisc
        );

    m_pollTimer.start(2000);

    scanForDisc();
}


void DiscManager::scanForDisc()
{
    DiscInfo foundInfo;
    QString foundDrive;

    // Scan optical drives D: through Z:
    for (char c = 'D'; c <= 'Z'; ++c)
    {
        std::string drive =
            std::string(1, c) + ":";

        DiscInfo info =
            DiscInspector::inspectDrive(drive);

        if (info.isPlayStation)
        {
            foundInfo = info;

            foundDrive =
                QString::fromStdString(drive);

            break;
        }
    }

    // No PS1/PS2 disc detected.
    if (!foundInfo.isPlayStation)
    {
        clearDisc();
        return;
    }

    // Serial -> human-readable title.
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

    QString title =
        QString::fromStdString(
            foundInfo.gameTitle
            );

    QString serial =
        QString::fromStdString(
            foundInfo.cleanSerial
            );

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

    QString coversDir =
        QCoreApplication::applicationDirPath()
        + "/resources/covers_3d";
    QDir().mkpath(coversDir);

    // 3D covers are transparent PNGs
    QString localPath =
        coversDir + "/" + m_serial + ".png";

    // 1. Use cached 3D cover on disk if already downloaded
    if (QFileInfo::exists(localPath))
    {
        m_coverUrl = QUrl::fromLocalFile(localPath).toString();
        return;
    }

    // 2. Fetch from xlenore's 3D cover folder (/covers/3d/<SERIAL>.png)
    QString repo = (m_consoleType == 2) ? "ps2-covers" : "psx-covers";
    QString remoteUrl = QString(
        "https://raw.githubusercontent.com/xlenore/%1/main/covers/3d/%2.png"
    ).arg(repo, m_serial);

    m_coverUrl = remoteUrl;

    QNetworkRequest request{QUrl(remoteUrl)};
    request.setAttribute(QNetworkRequest::User, localPath);
    m_netManager.get(request);
}

void DiscManager::onCoverDownloaded(QNetworkReply* reply)
{
    reply->deleteLater();

    QString savePath =
        reply->request().attribute(QNetworkRequest::User).toString();

    // If the 3D .png cover returned 404, automatically fall back to the 2D default .jpg cover!
    if (reply->error() != QNetworkReply::NoError)
    {
        QString failedUrl = reply->url().toString();
        if (failedUrl.contains("/covers/3d/"))
        {
            QString fallbackUrl = failedUrl;
            fallbackUrl.replace("/covers/3d/", "/covers/default/");
            fallbackUrl.replace(".png", ".jpg");

            qDebug() << "3D cover not found, falling back to 2D cover:" << fallbackUrl;
            m_coverUrl = fallbackUrl;
            emit discChanged();

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