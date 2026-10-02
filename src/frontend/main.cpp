#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include "AppController.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    QQmlApplicationEngine engine;
    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);
    AppController controller;
    engine.rootContext()->setContextProperty("appController", &controller);
    engine.loadFromModule("UniversalConsole", "Main");

    return QGuiApplication::exec();
}
