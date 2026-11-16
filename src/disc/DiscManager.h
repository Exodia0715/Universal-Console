#pragma once

#include <QObject>
#include <QTimer>
#include <QString>
#include <QVariantList>
#include <QNetworkAccessManager>
#include <QNetworkReply>

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

    Q_PROPERTY(
        QString coverUrl
            READ coverUrl
                NOTIFY discChanged
        )

    Q_PROPERTY(
        QVariantList libraryGames
            READ libraryGames
                NOTIFY libraryChanged
        )

public:
    explicit DiscManager(QObject* parent = nullptr);

    bool discReady() const { return m_discReady; }
    QString gameTitle() const { return m_gameTitle; }
    QString consoleName() const { return m_consoleName; }
    QString serial() const { return m_serial; }
    QString drivePath() const { return m_drivePath; }
    int consoleType() const { return m_consoleType; }
    QString coverUrl() const { return m_coverUrl; }
    QVariantList libraryGames() const { return m_libraryGames; }

    Q_INVOKABLE bool launchDumper();

    Q_INVOKABLE bool launchLibraryFile(const QString& emulatorPath, const QString& filePath);

    Q_INVOKABLE void refreshLibrary();

signals:
    void discChanged();
    void libraryChanged();

private slots:
    void scanForDisc();
    void onCoverDownloaded(QNetworkReply* reply);

private:
    void clearDisc();
    void updateCoverArt();
    QString findDumpsDir() const;
    QString resolve3DCoverUrl(const QString& serial, int consoleType);

    QTimer m_pollTimer;
    QNetworkAccessManager m_netManager;

    GameDatabase m_gameDb;

    bool m_discReady = false;

    QString m_gameTitle;
    QString m_consoleName;
    QString m_serial;
    QString m_drivePath;
    QString m_coverUrl;
    int m_consoleType = 0;

    QVariantList m_libraryGames;
    QStringList m_lastLibraryPaths;
};