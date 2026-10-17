#include "ControllerManager.h"

#include <QDebug>

ControllerManager::ControllerManager(QObject* parent)
    : QObject(parent)
{

    SDL_SetMainReady();

    if (SDL_InitSubSystem(
            SDL_INIT_JOYSTICK |
            SDL_INIT_GAMECONTROLLER
        ) != 0)
    {
        qWarning()
            << "SDL controller initialization failed:"
            << SDL_GetError();

        return;
    }

    SDL_GameControllerEventState(SDL_ENABLE);

    // Open controllers that were already connected
    // before Universal Console started.
    const int joystickCount = SDL_NumJoysticks();

    for (int i = 0; i < joystickCount; ++i)
    {
        if (SDL_IsGameController(i))
        {
            openController(i);
        }
    }

    connect(
        &m_pollTimer,
        &QTimer::timeout,
        this,
        &ControllerManager::pollEvents
    );

    // Roughly 60 updates per second.
    m_pollTimer.start(16);
}


ControllerManager::~ControllerManager()
{
    for (SDL_GameController* controller :
         m_controllers)
    {
        if (controller)
        {
            SDL_GameControllerClose(controller);
        }
    }

    m_controllers.clear();
}


void ControllerManager::openController(
    int deviceIndex
)
{
    if (!SDL_IsGameController(deviceIndex))
    {
        return;
    }

    SDL_GameController* controller =
        SDL_GameControllerOpen(deviceIndex);

    if (!controller)
    {
        qWarning()
            << "Could not open controller:"
            << SDL_GetError();

        return;
    }

    SDL_Joystick* joystick =
        SDL_GameControllerGetJoystick(controller);

    SDL_JoystickID instanceId =
        SDL_JoystickInstanceID(joystick);

    // Avoid opening the same controller twice.
    if (m_controllers.contains(instanceId))
    {
        SDL_GameControllerClose(controller);
        return;
    }

    m_controllers.insert(
        instanceId,
        controller
    );

    m_horizontalState.insert(instanceId, 0);
    m_verticalState.insert(instanceId, 0);

    if (m_controllers.size() == 1)
    {
        emit hasControllerChanged();
    }

    QString name =
        QString::fromUtf8(
            SDL_GameControllerName(controller)
        );

    qDebug()
        << "Controller connected:"
        << name;

    emit controllerConnected(name);
}


void ControllerManager::closeController(
    SDL_JoystickID instanceId
)
{
    if (!m_controllers.contains(instanceId))
    {
        return;
    }

    SDL_GameController* controller =
        m_controllers.take(instanceId);

    if (controller)
    {
        SDL_GameControllerClose(controller);
    }

    m_horizontalState.remove(instanceId);
    m_verticalState.remove(instanceId);

    if (m_controllers.isEmpty())
    {
        emit hasControllerChanged();
    }

    qDebug()
        << "Controller disconnected";

    emit controllerDisconnected();
}


void ControllerManager::pollEvents()
{
    SDL_Event event;

    while (SDL_PollEvent(&event))
    {
        switch (event.type)
        {
        // Controller plugged in while program is running.
        case SDL_CONTROLLERDEVICEADDED:
            openController(
                event.cdevice.which
            );
            break;


        // Controller unplugged.
        case SDL_CONTROLLERDEVICEREMOVED:
            closeController(
                event.cdevice.which
            );
            break;


        // --------------------------------------------------
        // DIGITAL BUTTONS
        // --------------------------------------------------

        case SDL_CONTROLLERBUTTONDOWN:

            switch (event.cbutton.button)
            {
            case SDL_CONTROLLER_BUTTON_DPAD_LEFT:
                emit moveLeft();
                break;

            case SDL_CONTROLLER_BUTTON_DPAD_RIGHT:
                emit moveRight();
                break;

            case SDL_CONTROLLER_BUTTON_DPAD_UP:
                emit moveUp();
                break;

            case SDL_CONTROLLER_BUTTON_DPAD_DOWN:
                emit moveDown();
                break;


            // SDL "A" = physical south face button.
            //
            // PlayStation: Cross
            // Xbox:        A
            case SDL_CONTROLLER_BUTTON_A:
                emit selectPressed();
                break;


            // SDL "B" = physical east face button.
            //
            // PlayStation: Circle
            // Xbox:        B
            case SDL_CONTROLLER_BUTTON_B:
                emit cancelPressed();
                break;

            default:
                break;
            }

            break;


        // --------------------------------------------------
        // LEFT ANALOG STICK
        // --------------------------------------------------

        case SDL_CONTROLLERAXISMOTION:

            if (event.caxis.axis ==
                    SDL_CONTROLLER_AXIS_LEFTX ||
                event.caxis.axis ==
                    SDL_CONTROLLER_AXIS_LEFTY)
            {
                handleAxis(
                    event.caxis.which,
                    event.caxis.axis,
                    event.caxis.value
                );
            }

            break;

        default:
            break;
        }
    }
}


void ControllerManager::handleAxis(
    SDL_JoystickID instanceId,
    Uint8 axis,
    Sint16 value
)
{
    int newState = 0;

    if (value < -ANALOG_DEADZONE)
    {
        newState = -1;
    }
    else if (value > ANALOG_DEADZONE)
    {
        newState = 1;
    }


    // --------------------------------------------------
    // Horizontal
    // --------------------------------------------------

    if (axis == SDL_CONTROLLER_AXIS_LEFTX)
    {
        int oldState =
            m_horizontalState.value(
                instanceId,
                0
            );

        if (newState == oldState)
        {
            return;
        }

        m_horizontalState[instanceId] =
            newState;

        if (newState == -1)
        {
            emit moveLeft();
        }
        else if (newState == 1)
        {
            emit moveRight();
        }
    }


    // --------------------------------------------------
    // Vertical
    // --------------------------------------------------

    else if (
        axis == SDL_CONTROLLER_AXIS_LEFTY
    )
    {
        int oldState =
            m_verticalState.value(
                instanceId,
                0
            );

        if (newState == oldState)
        {
            return;
        }

        m_verticalState[instanceId] =
            newState;

        if (newState == -1)
        {
            emit moveUp();
        }
        else if (newState == 1)
        {
            emit moveDown();
        }
    }
}