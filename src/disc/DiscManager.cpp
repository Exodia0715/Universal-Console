#include "DiscManager.h"

#include <QCoreApplication>
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

        emit discChanged();
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

    m_consoleType = 0;

    emit discChanged();
}