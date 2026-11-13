#pragma once

#include <QObject>
#include <QTimer>
#include <QHash>

#include <SDL.h>

class ControllerManager : public QObject
{
    Q_OBJECT

    Q_PROPERTY(
        bool hasController
            READ hasController
                NOTIFY hasControllerChanged
        )

public:
    explicit ControllerManager(QObject* parent = nullptr);
    ~ControllerManager();

    bool hasController() const
    {
        return !m_controllers.isEmpty();
    }

signals:
    void moveLeft();
    void moveRight();
    void moveUp();
    void moveDown();

    void selectPressed();
    void cancelPressed();

    void controllerConnected(const QString& name);
    void controllerDisconnected();

    void hasControllerChanged();

private slots:
    void pollEvents();

private:
    void openController(int deviceIndex);
    void closeController(SDL_JoystickID instanceId);

    void handleAxis(
        SDL_JoystickID instanceId,
        Uint8 axis,
        Sint16 value
        );

    QTimer m_pollTimer;

    QHash<SDL_JoystickID, SDL_GameController*> m_controllers;

    // Used so holding the analog stick doesn't generate
    // hundreds of navigation events.
    QHash<SDL_JoystickID, int> m_horizontalState;
    QHash<SDL_JoystickID, int> m_verticalState;

    static constexpr int ANALOG_DEADZONE = 16000;
};