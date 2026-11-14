#pragma once

#include <QObject>
#include <QTimer>
#include <QString>

#include "discInspector.hpp"
#include "gameDatabase.hpp"

class DiscManager : public QObject
{
    Q_OBJECT

    Q_PROPERTY(
        bool discReady
            READ discReady
                NOTIFY discChanged
        )

    Q_PROPERTY(
        QString gameTitle
            READ gameTitle
                NOTIFY discChanged
        )

    Q_PROPERTY(
        QString consoleName
            READ consoleName
                NOTIFY discChanged
        )

    Q_PROPERTY(
        QString serial
            READ serial
                NOTIFY discChanged
        )

    Q_PROPERTY(
        QString drivePath
            READ drivePath
                NOTIFY discChanged
        )

    Q_PROPERTY(
        int consoleType
            READ consoleType
                NOTIFY discChanged
        )

public:
    explicit DiscManager(QObject* parent = nullptr);

    bool discReady() const
    {
        return m_discReady;
    }

    QString gameTitle() const
    {
        return m_gameTitle;
    }

    QString consoleName() const
    {
        return m_consoleName;
    }

    QString serial() const
    {
        return m_serial;
    }

    QString drivePath() const
    {
        return m_drivePath;
    }

    int consoleType() const
    {
        return m_consoleType;
    }

signals:
    void discChanged();

private slots:
    void scanForDisc();

private:
    void clearDisc();

    QTimer m_pollTimer;

    GameDatabase m_gameDb;

    bool m_discReady = false;

    QString m_gameTitle;
    QString m_consoleName;
    QString m_serial;
    QString m_drivePath;

    // 0 = none
    // 1 = PS1
    // 2 = PS2
    int m_consoleType = 0;
};