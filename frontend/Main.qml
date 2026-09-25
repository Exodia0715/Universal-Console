import QtQuick
import QtQuick.Controls

ApplicationWindow {
    id: window

    width: 1280
    height: 720

    minimumWidth: 960
    minimumHeight: 540

    visible: true
    title: "Universal Console"

    color: "#06152c"

    // 0 = Disc
    // 1 = Settings
    property int currentCategory: 0

    // Settings submenu

    // 0 = History
    // 1 = Controller
    // 2 = Emulator
    property int settingsIndex: 0

    property bool popupOpen: false
    property string popupTitle: ""
    property string popupDescription: ""

    property string currentTime: ""

    function updateClock() {
        currentTime = Qt.formatTime(new Date(), "h:mm AP")
    }

    function openDiscPrompt() {
        popupTitle = "Insert Game Disc"
        popupDescription =
                "Please insert a PlayStation or PlayStation 2 game disc."
        popupOpen = true
    }

    function openPlaceholder(title, description) {
        popupTitle = title
        popupDescription = description
        popupOpen = true
    }

    Component.onCompleted: {
        updateClock()
        keyboardFocus.forceActiveFocus()
    }

    Timer {
        interval: 1000
        running: true
        repeat: true

        onTriggered: window.updateClock()
    }


    // Background

    Rectangle {
        anchors.fill: parent

        gradient: Gradient {
            GradientStop {
                position: 0.0
                color: "#061225"
            }

            GradientStop {
                position: 0.45
                color: "#0b3260"
            }

            GradientStop {
                position: 1.0
                color: "#030914"
            }
        }
    }

    // Slowly moving glow

    Rectangle {
        id: glowOne

        width: window.width * 0.85
        height: 340

        radius: height / 2

        x: -300
        y: window.height * 0.55

        color: "#1b65aa"
        opacity: 0.13

        SequentialAnimation on x {
            loops: Animation.Infinite

            NumberAnimation {
                to: 250
                duration: 10000
                easing.type: Easing.InOutSine
            }

            NumberAnimation {
                to: -300
                duration: 10000
                easing.type: Easing.InOutSine
            }
        }
    }

    Rectangle {
        width: window.width * 0.65
        height: 220

        radius: height / 2

        x: window.width * 0.4
        y: window.height * 0.18

        color: "#5b82c1"
        opacity: 0.06
        rotation: -12
    }

    // Keyboard Navigation

    Item {
        id: keyboardFocus

        anchors.fill: parent
        focus: true

        Keys.onPressed: function(event) {

            // Popup is open
            if (window.popupOpen) {

                if (event.key === Qt.Key_Escape ||
                    event.key === Qt.Key_Backspace) {

                    window.popupOpen = false
                    event.accepted = true
                }

                return
            }

            // Horizontal navigation
            if (event.key === Qt.Key_Left) {

                if (window.currentCategory > 0)
                    window.currentCategory--

                event.accepted = true
            }

            else if (event.key === Qt.Key_Right) {

                if (window.currentCategory < 1)
                    window.currentCategory++

                event.accepted = true
            }

            // Vertical Settings navigation
            else if (event.key === Qt.Key_Up) {

                if (window.currentCategory === 1 &&
                    window.settingsIndex > 0) {

                    window.settingsIndex--
                }

                event.accepted = true
            }

            else if (event.key === Qt.Key_Down) {

                if (window.currentCategory === 1 &&
                    window.settingsIndex < 2) {

                    window.settingsIndex++
                }

                event.accepted = true
            }

            // Select
            else if (event.key === Qt.Key_Return ||
                     event.key === Qt.Key_Enter ||
                     event.key === Qt.Key_Space) {

                if (window.currentCategory === 0) {

                    window.openDiscPrompt()
                }

                else {

                    switch (window.settingsIndex) {

                    case 0:
                        window.openPlaceholder(
                            "Game Library History",
                            "Game history functionality will be connected to the backend."
                        )
                        break

                    case 1:
                        window.openPlaceholder(
                            "Controller Input",
                            "Controller configuration will be connected to the backend."
                        )
                        break

                    case 2:
                        window.openPlaceholder(
                            "Emulator Settings",
                            "Emulator configuration will be connected to the backend."
                        )
                        break
                    }
                }

                event.accepted = true
            }
        }
    }

    // Header

    Text {
        anchors.left: parent.left
        anchors.top: parent.top

        anchors.leftMargin: 50
        anchors.topMargin: 32

        text: "Universal Console"

        color: "white"

        font.pixelSize: 18
        font.weight: Font.Medium

        opacity: 0.9
    }

    Row {
        anchors.right: parent.right
        anchors.top: parent.top

        anchors.rightMargin: 48
        anchors.topMargin: 32

        spacing: 20

        Text {
            text: window.currentTime

            color: "white"
            font.pixelSize: 16

            opacity: 0.9
        }
    }

    // XMB Category Bar

    Row {
        id: categoryRow

        anchors.horizontalCenter: parent.horizontalCenter

        y: 145

        spacing: 150

        // Disc

        Item {
            id: discCategory

            width: 170
            height: 125

            scale: window.currentCategory === 0 ? 1.16 : 1.0

            opacity:
                window.currentCategory === 0 ? 1.0 : 0.42

            Behavior on scale {
                NumberAnimation {
                    duration: 180
                    easing.type: Easing.OutCubic
                }
            }

            Behavior on opacity {
                NumberAnimation {
                    duration: 180
                }
            }

            Column {
                anchors.horizontalCenter: parent.horizontalCenter

                spacing: 9

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter

                    width: 56
                    height: 56

                    radius: 28

                    color: "transparent"

                    border.width: 3
                    border.color: "white"

                    Rectangle {
                        anchors.centerIn: parent

                        width: 14
                        height: 14

                        radius: 7

                        color: "transparent"

                        border.width: 2
                        border.color: "white"
                    }
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter

                    text: "Disc"

                    color: "white"

                    font.pixelSize: 19
                    font.bold: window.currentCategory === 0
                }
            }

            MouseArea {
                anchors.fill: parent

                onClicked: {
                    window.currentCategory = 0
                    keyboardFocus.forceActiveFocus()
                }

                onDoubleClicked: {
                    window.currentCategory = 0
                    window.openDiscPrompt()
                    keyboardFocus.forceActiveFocus()
                }
            }
        }

        // -----------------------------------------------------
        // SETTINGS
        // -----------------------------------------------------

        Item {
            id: settingsCategory

            width: 170
            height: 125

            scale: window.currentCategory === 1 ? 1.16 : 1.0

            opacity:
                window.currentCategory === 1 ? 1.0 : 0.42

            Behavior on scale {
                NumberAnimation {
                    duration: 180
                    easing.type: Easing.OutCubic
                }
            }

            Behavior on opacity {
                NumberAnimation {
                    duration: 180
                }
            }

            Column {
                anchors.horizontalCenter: parent.horizontalCenter

                spacing: 9

                Canvas {
                    id: gearIcon

                    anchors.horizontalCenter: parent.horizontalCenter

                    width: 58
                    height: 58

                    onPaint: {
                        var ctx = getContext("2d")

                        ctx.clearRect(0, 0, width, height)

                        var cx = width / 2
                        var cy = height / 2

                        var teeth = 8

                        var outerRadius = 27
                        var toothInnerRadius = 22
                        var bodyRadius = 19

                        ctx.strokeStyle = "white"
                        ctx.lineWidth = 3
                        ctx.lineJoin = "round"

                        ctx.beginPath()

                        for (var i = 0; i < teeth * 4; ++i) {

                            var angle =
                                (Math.PI * 2 * i) / (teeth * 4)
                                - Math.PI / 2

                            var pattern = i % 4

                            var radius

                            if (pattern === 1 || pattern === 2)
                                radius = outerRadius
                            else
                                radius = toothInnerRadius

                            var x = cx + Math.cos(angle) * radius
                            var y = cy + Math.sin(angle) * radius

                            if (i === 0)
                                ctx.moveTo(x, y)
                            else
                                ctx.lineTo(x, y)
                        }

                        ctx.closePath()
                        ctx.stroke()

                        // Inner gear body
                        ctx.beginPath()

                        ctx.arc(
                            cx,
                            cy,
                            bodyRadius,
                            0,
                            Math.PI * 2
                        )

                        ctx.stroke()

                        // Center hole
                        ctx.beginPath()

                        ctx.arc(
                            cx,
                            cy,
                            6,
                            0,
                            Math.PI * 2
                        )

                        ctx.stroke()
                    }
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter

                    text: "Settings"

                    color: "white"

                    font.pixelSize: 19
                    font.bold: window.currentCategory === 1
                }
            }

            MouseArea {
                anchors.fill: parent

                onClicked: {
                    window.currentCategory = 1
                    keyboardFocus.forceActiveFocus()
                }
            }
        }
    }

    // =========================================================
    // DISC MENU
    // =========================================================

    Item {
        id: discMenu

        // Force this item to use the entire application window
        parent: window.contentItem

        anchors.left: parent.left
        anchors.right: parent.right

        y: 305
        height: 150

        visible: window.currentCategory === 0

        Column {
            anchors.horizontalCenter: parent.horizontalCenter

            width: 600
            spacing: 14

            Text {
                width: parent.width

                text: "Insert Game Disc"

                horizontalAlignment: Text.AlignHCenter

                color: "white"

                font.pixelSize: 22
                font.bold: true
            }

            Text {
                width: parent.width

                text: "Insert a PlayStation or PlayStation 2 game disc to begin."

                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap

                color: "#c3cedc"

                font.pixelSize: 15
                opacity: 0.7
            }
        }
    }

    // =========================================================
    // SETTINGS MENU
    // =========================================================

    Column {
        id: settingsMenu

        x: settingsCategory.x +
           categoryRow.x -
           25

        y: 295

        width: 330

        visible: window.currentCategory === 1

        spacing: 8

        SettingsEntry {
            title: "Game Library History"
            selected: window.settingsIndex === 0

            onClicked: {
                window.settingsIndex = 0
                keyboardFocus.forceActiveFocus()
            }
        }

        SettingsEntry {
            title: "Controller Input"
            selected: window.settingsIndex === 1

            onClicked: {
                window.settingsIndex = 1
                keyboardFocus.forceActiveFocus()
            }
        }

        SettingsEntry {
            title: "Emulator Settings"
            selected: window.settingsIndex === 2

            onClicked: {
                window.settingsIndex = 2
                keyboardFocus.forceActiveFocus()
            }
        }
    }

    // Description

    Text {
        anchors.horizontalCenter: parent.horizontalCenter

        anchors.bottom: parent.bottom
        anchors.bottomMargin: 92

        width: 650

        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap

        text: {
            if (window.currentCategory === 0)
                return "Ready for a PlayStation game disc."

            switch (window.settingsIndex) {

            case 0:
                return "View your previously played games and activity."

            case 1:
                return "Configure game controllers and input devices."

            case 2:
                return "Configure PlayStation emulator preferences."
            }

            return ""
        }

        color: "#ced7e3"

        font.pixelSize: 14

        opacity: 0.62
    }

    // Controls Overlay

    Row {
        anchors.right: parent.right
        anchors.bottom: parent.bottom

        anchors.rightMargin: 48
        anchors.bottomMargin: 28

        spacing: 28

        Text {
            text: "ENTER   Select"

            color: "#d7dfe9"

            font.pixelSize: 13

            opacity: 0.8
        }

        Text {
            text: "ESC   Back"

            color: "#d7dfe9"

            font.pixelSize: 13

            opacity: 0.8
        }

        Text {
            text: "← ↑ ↓ →   Navigate"

            color: "#d7dfe9"

            font.pixelSize: 13

            opacity: 0.8
        }
    }

    // Insert Disc Screen

    Rectangle {
        id: popupOverlay

        anchors.fill: parent

        visible: window.popupOpen

        color: "#B0000000"

        z: 100

        opacity: visible ? 1 : 0

        Behavior on opacity {
            NumberAnimation {
                duration: 180
            }
        }

        Rectangle {
            anchors.centerIn: parent

            width: 560
            height: 300

            radius: 20

            color: "#E60B1728"

            border.width: 1
            border.color: "#52749a"

            Column {
                anchors.centerIn: parent

                width: parent.width - 80

                spacing: 22

                // Animated disc for disc prompt

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter

                    width: 72
                    height: 72

                    radius: 36

                    visible:
                        window.popupTitle === "Insert Game Disc"

                    color: "transparent"

                    border.width: 3
                    border.color: "white"

                    Rectangle {
                        anchors.centerIn: parent

                        width: 18
                        height: 18

                        radius: 9

                        color: "transparent"

                        border.width: 2
                        border.color: "white"
                    }

                    RotationAnimation on rotation {
                        from: 0
                        to: 360

                        duration: 4000

                        loops: Animation.Infinite

                        running:
                            window.popupOpen &&
                            window.popupTitle === "Insert Game Disc"
                    }
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter

                    text: window.popupTitle

                    color: "white"

                    font.pixelSize: 27
                    font.bold: true
                }

                Text {
                    width: parent.width

                    text: window.popupDescription

                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap

                    color: "#cad5e2"

                    font.pixelSize: 16
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter

                    text: "ESC   Cancel"

                    color: "#8798ac"

                    font.pixelSize: 13
                }
            }
        }

        MouseArea {
            anchors.fill: parent

            onClicked: {
                window.popupOpen = false
                keyboardFocus.forceActiveFocus()
            }
        }
    }

    // Reusable Settings Entry

    component SettingsEntry: Item {
        id: entry

        required property string title
        property bool selected: false

        signal clicked()

        width: 330
        height: 48

        opacity: selected ? 1.0 : 0.44

        x: selected ? 14 : 0

        Behavior on x {
            NumberAnimation {
                duration: 150
                easing.type: Easing.OutCubic
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: 150
            }
        }

        Row {
            anchors.verticalCenter: parent.verticalCenter

            spacing: 13

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter

                width: 7
                height: 7

                radius: 4

                color: "white"

                opacity: entry.selected ? 1 : 0
            }

            Text {
                text: entry.title

                color: "white"

                font.pixelSize:
                    entry.selected ? 20 : 18

                font.bold: entry.selected
            }
        }

        MouseArea {
            anchors.fill: parent

            hoverEnabled: false

            onClicked: entry.clicked()
        }
    }
}