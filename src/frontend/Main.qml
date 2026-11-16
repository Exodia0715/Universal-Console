import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs

ApplicationWindow {
    id: window

    width: 1280
    height: 720

    minimumWidth: 960
    minimumHeight: 540

    visible: true
    title: "Universal Console"

    color: "#06152c"

    onActiveChanged: {
        if (active) {
            if (discLaunching) {
                discLaunching = false
            }
            discManager.refreshLibrary()
        }
    }

    FontLoader {
        id: xmbFont

        source: "qrc:/qt/qml/UniversalConsole/src/frontend/fonts/NotoSans-Regular.ttf"
    }

    // 0 = Disc
    // 1 = Library
    // 2 = Settings
    property int currentCategory: 0

    // Library Navigation:
    // libraryFocusRow:
    //   0 = "+ Launch Disc Dumper" button
    //   1 = Platform Filter Selector (All | PlayStation | PlayStation 2)
    //   2 = 3D Cover Flow Carousel
    property int libraryFocusRow: 1

    // 0 = All Games, 1 = PlayStation (PS1), 2 = PlayStation 2 (PS2)
    property int libraryFilter: 0

    property int selectedGameIndex: 0

    // Dynamically filtered list of games based on libraryFilter (0 = All, 1 = PS1, 2 = PS2)
    property var filteredLibraryGames: {
        var all = discManager.libraryGames
        if (window.libraryFilter === 0)
            return all

        var result = []
        for (var i = 0; i < all.length; ++i) {
            if (all[i].consoleType === window.libraryFilter) {
                result.push(all[i])
            }
        }
        return result
    }

    onLibraryFilterChanged: {
        window.selectedGameIndex = 0
    }

    // Settings submenu
    // 0 = History
    // 1 = Controller
    // 2 = Emulator
    property int settingsIndex: 0

    property bool emulatorSettingsOpen: false
    property int emulatorSettingsIndex: 0
    property bool discLaunching: false

    property bool popupOpen: false
    property string popupTitle: ""
    property string popupDescription: ""

    property string currentTime: ""

    Connections {
        target: discManager
        function onLibraryChanged() {
            if (window.filteredLibraryGames.length === 0) {
                window.selectedGameIndex = 0
            } else if (window.selectedGameIndex >= window.filteredLibraryGames.length) {
                window.selectedGameIndex = window.filteredLibraryGames.length - 1
            }
        }
    }

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

    function moveLeft() {
        if (window.popupOpen ||
            window.emulatorSettingsOpen)
            return

        if (window.currentCategory === 1) {
            // Row 1: Platform Filter Tabs (All | PlayStation | PlayStation 2)
            if (window.libraryFocusRow === 1 && window.libraryFilter > 0) {
                window.libraryFilter--
                return
            }

            // Row 2: 3D Cover Flow Carousel
            if (window.libraryFocusRow === 2 && window.filteredLibraryGames.length > 0) {
                if (window.selectedGameIndex > 0) {
                    window.selectedGameIndex--
                    return
                }
            }
        }

        if (window.currentCategory > 0)
            window.currentCategory--
    }

    function moveRight() {
        if (window.popupOpen ||
            window.emulatorSettingsOpen)
            return

        if (window.currentCategory === 1) {
            // Row 1: Platform Filter Tabs (All | PlayStation | PlayStation 2)
            if (window.libraryFocusRow === 1 && window.libraryFilter < 2) {
                window.libraryFilter++
                return
            }

            // Row 2: 3D Cover Flow Carousel
            if (window.libraryFocusRow === 2 && window.filteredLibraryGames.length > 0) {
                if (window.selectedGameIndex < window.filteredLibraryGames.length - 1) {
                    window.selectedGameIndex++
                    return
                }
            }
        }

        if (window.currentCategory < 2)
            window.currentCategory++
    }

    function moveUp() {
        if (window.popupOpen)
            return

        if (window.emulatorSettingsOpen) {
            if (window.emulatorSettingsIndex > 0)
                window.emulatorSettingsIndex--

            return
        }

        if (window.currentCategory === 1) {
            if (window.libraryFocusRow > 0)
                window.libraryFocusRow--
            return
        }

        if (window.currentCategory === 2 &&
            window.settingsIndex > 0) {

            window.settingsIndex--
        }
    }

    function moveDown() {
        if (window.popupOpen)
            return

        if (window.emulatorSettingsOpen) {
            if (window.emulatorSettingsIndex < 1)
                window.emulatorSettingsIndex++

            return
        }

        if (window.currentCategory === 1) {
            var maxRow = window.filteredLibraryGames.length > 0 ? 2 : 1
            if (window.libraryFocusRow < maxRow)
                window.libraryFocusRow++
            return
        }

        if (window.currentCategory === 2 &&
            window.settingsIndex < 2) {

            window.settingsIndex++
        }
    }

    function launchLibraryGame(gameIndex) {
        if (gameIndex < 0 || gameIndex >= window.filteredLibraryGames.length)
            return

        var game = window.filteredLibraryGames[gameIndex]
        var emuPath = (game.consoleType === 2)
                      ? appController.ps2EmulatorPath
                      : appController.ps1EmulatorPath

        window.discLaunching = true

        var launched = discManager.launchLibraryFile(
            emuPath,
            game.filePath
        )

        if (!launched) {
            console.log("Unable to launch library game:", game.filePath)
            window.discLaunching = false
            window.openPlaceholder(
                "Emulator Not Configured",
                "Please select your " + game.consoleName + " emulator executable under Settings -> Emulator Settings."
            )
        }
    }

    function selectAction() {

        if (window.emulatorSettingsOpen) {
            if (window.emulatorSettingsIndex === 0)
                duckstationDialog.open()
            else
                pcsx2Dialog.open()

            return
        }

        if (window.popupOpen)
            return

        // Category 0: Physical Disc
        if (window.currentCategory === 0) {

            if (window.discLaunching)
                return

            if (!discManager.discReady) {
                console.log("No PlayStation disc detected")
                return
            }

            window.discLaunching = true

            var launched = appController.launchDisc(
                discManager.consoleType,
                discManager.drivePath
            )

            if (!launched) {
                console.log("Unable to launch disc")
                window.discLaunching = false
            }

            return
        }

        // Category 1: Game Library & Dumper
        if (window.currentCategory === 1) {
            if (window.libraryFocusRow === 0) {
                var started = discManager.launchDumper()
                if (!started) {
                    window.openPlaceholder(
                        "Disc Dumper Not Found",
                        "Place UniversalConsoleDumper.exe in the build/ folder to launch the disc extraction utility."
                    )
                }
            } else if (window.libraryFocusRow === 1) {
                // Pressing Select on a filter tab moves down into the 3D carousel if games exist
                if (window.filteredLibraryGames.length > 0)
                    window.libraryFocusRow = 2
            } else {
                window.launchLibraryGame(window.selectedGameIndex)
            }
            return
        }

        // Category 2: Settings
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
            window.emulatorSettingsOpen = true
            window.emulatorSettingsIndex = 0
            break
        }
    }

    function cancelAction() {

        if (window.emulatorSettingsOpen) {
            window.emulatorSettingsOpen = false
            keyboardFocus.forceActiveFocus()
            return
        }

        if (window.popupOpen) {
            window.popupOpen = false
            keyboardFocus.forceActiveFocus()
            return
        }
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

    Connections {
        target: controllerManager

        function onMoveLeft() {
            window.moveLeft()
        }

        function onMoveRight() {
            window.moveRight()
        }

        function onMoveUp() {
            window.moveUp()
        }

        function onMoveDown() {
            window.moveDown()
        }

        function onSelectPressed() {
            window.selectAction()
        }

        function onCancelPressed() {
            window.cancelAction()
        }

        function onControllerConnected(name) {
            console.log("Controller connected:", name)
        }

        function onControllerDisconnected() {
            console.log("Controller disconnected")
        }
    }

    FileDialog {
        id: duckstationDialog

        title: "Select DuckStation Executable"

        nameFilters: [
            "Executable (*.exe)"
        ]

        onAccepted: {
            appController.setPs1EmulatorPath(selectedFile)
            keyboardFocus.forceActiveFocus()
        }
    }

    FileDialog {
        id: pcsx2Dialog

        title: "Select PCSX2 Executable"

        nameFilters: [
            "Executable (*.exe)"
        ]

        onAccepted: {
            appController.setPs2EmulatorPath(selectedFile)
            keyboardFocus.forceActiveFocus()
        }
    }

    FolderDialog {
        id: gameDialog

        title: "Select Game Folder"

        onAccepted: {
            appController.setGameFolder(selectedFolder)

            if (!appController.launch()) {
                console.log("Unable to launch selected game")
            }

            keyboardFocus.forceActiveFocus()
        }
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

            if (event.key === Qt.Key_Left) {
                window.moveLeft()
                event.accepted = true
            }

            else if (event.key === Qt.Key_Right) {
                window.moveRight()
                event.accepted = true
            }

            else if (event.key === Qt.Key_Up) {
                window.moveUp()
                event.accepted = true
            }

            else if (event.key === Qt.Key_Down) {
                window.moveDown()
                event.accepted = true
            }

            else if (event.key === Qt.Key_Return ||
                     event.key === Qt.Key_Enter ||
                     event.key === Qt.Key_Space) {

                window.selectAction()
                event.accepted = true
            }

            else if (event.key === Qt.Key_Escape ||
                     event.key === Qt.Key_Backspace) {

                window.cancelAction()
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

        font.family: xmbFont.name
        font.pixelSize: 18
        font.weight: Font.Normal

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

        y: 120

        spacing: 120

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

                    font.family: xmbFont.name
                    font.pixelSize: 19
                    font.weight: Font.Normal
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


        Item {
            id: libraryCategory

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
                    id: booksIcon

                    anchors.horizontalCenter: parent.horizontalCenter

                    width: 58
                    height: 58

                    onPaint: {
                        var ctx = getContext("2d")
                        ctx.clearRect(0, 0, width, height)

                        ctx.strokeStyle = "white"
                        ctx.lineWidth = 3
                        ctx.lineJoin = "round"
                        ctx.lineCap = "round"

                        ctx.strokeRect(10, 12, 10, 36)
                        ctx.beginPath()
                        ctx.moveTo(10, 20)
                        ctx.lineTo(20, 20)
                        ctx.stroke()

                        ctx.strokeRect(22, 8, 11, 40)
                        ctx.beginPath()
                        ctx.moveTo(22, 17)
                        ctx.lineTo(33, 17)
                        ctx.stroke()

                        ctx.save()
                        ctx.translate(36, 48)
                        ctx.rotate(-0.22)
                        ctx.strokeRect(0, -36, 10, 36)
                        ctx.beginPath()
                        ctx.moveTo(0, -28)
                        ctx.lineTo(10, -28)
                        ctx.stroke()
                        ctx.restore()
                    }
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter

                    text: "Library"

                    color: "white"

                    font.family: xmbFont.name
                    font.pixelSize: 19
                    font.weight: Font.Normal
                }
            }

            MouseArea {
                anchors.fill: parent

                onClicked: {
                    window.currentCategory = 1
                    discManager.refreshLibrary()
                    if (window.filteredLibraryGames.length > 0)
                        window.libraryFocusRow = 2
                    else
                        window.libraryFocusRow = 1
                    keyboardFocus.forceActiveFocus()
                }
            }
        }


        Item {
            id: settingsCategory

            width: 170
            height: 125

            scale: window.currentCategory === 2 ? 1.16 : 1.0

            opacity:
                window.currentCategory === 2 ? 1.0 : 0.42

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

                        ctx.beginPath()
                        ctx.arc(cx, cy, bodyRadius, 0, Math.PI * 2)
                        ctx.stroke()

                        ctx.beginPath()
                        ctx.arc(cx, cy, 6, 0, Math.PI * 2)
                        ctx.stroke()
                    }
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter

                    text: "Settings"

                    color: "white"

                    font.family: xmbFont.name
                    font.pixelSize: 19
                    font.weight: Font.Normal
                }
            }

            MouseArea {
                anchors.fill: parent

                onClicked: {
                    window.currentCategory = 2
                    keyboardFocus.forceActiveFocus()
                }
            }
        }
    }


    Item {
        id: discMenu

        parent: window.contentItem

        anchors.left: parent.left
        anchors.right: parent.right

        y: 265
        height: 380

        visible: window.currentCategory === 0

        Column {
            anchors.horizontalCenter: parent.horizontalCenter

            width: 700
            spacing: 8

            Text {
                width: parent.width

                text: {
                    if (window.discLaunching)
                        return "Reading Disc..."

                    if (discManager.discReady)
                        return discManager.gameTitle

                    return "Insert Game Disc"
                }

                horizontalAlignment: Text.AlignHCenter
                color: "white"
                font.family: xmbFont.name
                font.pixelSize: 22
                font.weight: Font.Normal
            }

            Text {
                width: parent.width

                text: {
                    if (window.discLaunching)
                        return "Preparing " + discManager.consoleName + " game..."

                    if (discManager.discReady)
                        return discManager.consoleName + "  •  Ready to Run"

                    return "Insert a PlayStation or PlayStation 2 game disc to begin."
                }

                horizontalAlignment: Text.AlignHCenter
                color: "#c3cedc"
                font.family: xmbFont.name
                font.pixelSize: 15
                font.weight: Font.Normal
                opacity: 0.8
            }

            Item {
                width: 1
                height: 8
            }

            // 3D Floating Box Art Container
            Item {
                id: coverArtContainer

                anchors.horizontalCenter: parent.horizontalCenter
                width: 240
                height: 260

                visible: discManager.discReady

                Rectangle {
                    id: dropShadow

                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 4

                    width: 140
                    height: 18
                    radius: 9
                    color: "#000000"
                    opacity: 0.35

                    SequentialAnimation on scale {
                        running: coverImage.status === Image.Ready
                        loops: Animation.Infinite
                        NumberAnimation { to: 0.82; duration: 2200; easing.type: Easing.InOutSine }
                        NumberAnimation { to: 1.0;  duration: 2200; easing.type: Easing.InOutSine }
                    }

                    SequentialAnimation on opacity {
                        running: coverImage.status === Image.Ready
                        loops: Animation.Infinite
                        NumberAnimation { to: 0.18; duration: 2200; easing.type: Easing.InOutSine }
                        NumberAnimation { to: 0.40; duration: 2200; easing.type: Easing.InOutSine }
                    }
                }

                Image {
                    id: coverImage

                    anchors.horizontalCenter: parent.horizontalCenter
                    y: 0

                    width: 210
                    height: 235

                    source: discManager.coverUrl
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                    smooth: true
                    mipmap: true

                    transform: Rotation {
                        id: boxRotation
                        origin.x: coverImage.width / 2
                        origin.y: coverImage.height / 2
                        axis { x: 0.15; y: 1.0; z: 0.0 }
                        angle: 0
                    }

                    onStatusChanged: {
                        if (status === Image.Ready) {
                            entranceAnim.restart()
                        }
                    }

                    ParallelAnimation {
                        id: entranceAnim
                        NumberAnimation {
                            target: coverImage
                            property: "scale"
                            from: 0.6
                            to: 1.0
                            duration: 550
                            easing.type: Easing.OutBack
                        }
                        NumberAnimation {
                            target: coverImage
                            property: "opacity"
                            from: 0.0
                            to: 1.0
                            duration: 350
                        }
                        NumberAnimation {
                            target: boxRotation
                            property: "angle"
                            from: -65
                            to: 0
                            duration: 600
                            easing.type: Easing.OutCubic
                        }
                    }

                    SequentialAnimation on y {
                        running: coverImage.status === Image.Ready
                        loops: Animation.Infinite
                        NumberAnimation { to: -12; duration: 2200; easing.type: Easing.InOutSine }
                        NumberAnimation { to: 0;   duration: 2200; easing.type: Easing.InOutSine }
                    }

                    SequentialAnimation {
                        running: coverImage.status === Image.Ready && !entranceAnim.running
                        loops: Animation.Infinite
                        NumberAnimation {
                            target: boxRotation
                            property: "angle"
                            to: 12
                            duration: 2800
                            easing.type: Easing.InOutSine
                        }
                        NumberAnimation {
                            target: boxRotation
                            property: "angle"
                            to: -12
                            duration: 2800
                            easing.type: Easing.InOutSine
                        }
                    }
                }

                Text {
                    anchors.centerIn: parent
                    visible: coverImage.status !== Image.Ready

                    text: coverImage.status === Image.Loading
                          ? "Loading 3D Box..."
                          : discManager.serial

                    color: "#93a2b4"
                    font.family: xmbFont.name
                    font.pixelSize: 14
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        window.selectAction()
                        keyboardFocus.forceActiveFocus()
                    }
                }
            }
        }
    }


    Item {
        id: libraryMenu

        parent: window.contentItem
        anchors.left: parent.left
        anchors.right: parent.right
        y: 235
        height: 430

        visible: window.currentCategory === 1

        property var activeGame:
            (window.filteredLibraryGames.length > 0 &&
             window.selectedGameIndex >= 0 &&
             window.selectedGameIndex < window.filteredLibraryGames.length)
            ? window.filteredLibraryGames[window.selectedGameIndex]
            : null

        // Row 0: "+ Launch Disc Dumper" Pill Button
        Rectangle {
            id: dumperPillBtn

            anchors.horizontalCenter: parent.horizontalCenter
            y: 0
            width: 230
            height: 32
            radius: 16

            color: window.libraryFocusRow === 0 ? "#2b6cb0" : "#14000000"
            border.width: window.libraryFocusRow === 0 ? 2 : 1
            border.color: window.libraryFocusRow === 0 ? "white" : "#4a6785"
            scale: window.libraryFocusRow === 0 ? 1.06 : 0.96
            opacity: window.libraryFocusRow === 0 ? 1.0 : 0.65

            Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
            Behavior on opacity { NumberAnimation { duration: 150 } }
            Behavior on color { ColorAnimation { duration: 150 } }

            Text {
                anchors.centerIn: parent
                text: "+ Launch Disc Dumper"
                color: "white"
                font.family: xmbFont.name
                font.pixelSize: 13
                font.bold: window.libraryFocusRow === 0
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    window.libraryFocusRow = 0
                    window.selectAction()
                    keyboardFocus.forceActiveFocus()
                }
            }
        }

        // Row 1: Console Filter Selector (All | PlayStation | PlayStation 2)
        Row {
            id: filterBarRow

            anchors.horizontalCenter: parent.horizontalCenter
            y: 40
            spacing: 12

            Repeater {
                model: [
                    { label: "All Games",     filterVal: 0 },
                    { label: "PlayStation",   filterVal: 1 },
                    { label: "PlayStation 2", filterVal: 2 }
                ]

                delegate: Rectangle {
                    required property int index
                    required property var modelData

                    property bool isActiveFilter: window.libraryFilter === modelData.filterVal
                    property bool isRowFocused: window.libraryFocusRow === 1

                    width: 135
                    height: 30
                    radius: 15

                    color: isActiveFilter
                           ? (isRowFocused ? "#1e5aa8" : "#163d73")
                           : "#10000000"

                    border.width: isActiveFilter ? 2 : 1
                    border.color: isActiveFilter
                                  ? (isRowFocused ? "white" : "#7fa9d9")
                                  : "#3d5573"

                    opacity: isActiveFilter ? 1.0 : 0.55
                    scale: (isActiveFilter && isRowFocused) ? 1.05 : 1.0

                    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                    Behavior on opacity { NumberAnimation { duration: 150 } }

                    Text {
                        anchors.centerIn: parent
                        text: parent.modelData.label
                        color: "white"
                        font.family: xmbFont.name
                        font.pixelSize: 13
                        font.bold: parent.isActiveFilter
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            window.libraryFilter = parent.modelData.filterVal
                            if (window.filteredLibraryGames.length > 0)
                                window.libraryFocusRow = 2
                            else
                                window.libraryFocusRow = 1
                            keyboardFocus.forceActiveFocus()
                        }
                    }
                }
            }
        }

        // Empty State Message (if no games match the selected filter)
        Column {
            anchors.centerIn: parent
            anchors.verticalCenterOffset: 35
            spacing: 10
            visible: window.filteredLibraryGames.length === 0

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: {
                    if (window.libraryFilter === 1)
                        return "No PlayStation (PS1) Games Found"
                    if (window.libraryFilter === 2)
                        return "No PlayStation 2 Games Found"
                    return "No Extracted Games in Library"
                }
                color: "white"
                font.family: xmbFont.name
                font.pixelSize: 22
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Extract a disc with '+ Launch Disc Dumper' or switch the platform filter above."
                color: "#93a2b4"
                font.family: xmbFont.name
                font.pixelSize: 14
            }
        }

        // Selected Game Title & Index Counter (e.g., "PlayStation  •  1 of 3")
        Column {
            id: selectedGameHeader

            anchors.horizontalCenter: parent.horizontalCenter
            y: 80
            width: 750
            spacing: 3

            visible: window.filteredLibraryGames.length > 0
            opacity: window.libraryFocusRow === 2 ? 1.0 : 0.65

            Behavior on opacity { NumberAnimation { duration: 180 } }

            Text {
                width: parent.width
                text: libraryMenu.activeGame ? libraryMenu.activeGame.title : ""
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                color: "white"
                font.family: xmbFont.name
                font.pixelSize: 21
            }

            Text {
                width: parent.width
                text: libraryMenu.activeGame
                      ? (libraryMenu.activeGame.consoleName + "   •   " +
                         (window.selectedGameIndex + 1) + " of " + window.filteredLibraryGames.length)
                      : ""
                horizontalAlignment: Text.AlignHCenter
                color: "#c3cedc"
                font.family: xmbFont.name
                font.pixelSize: 14
                opacity: 0.85
            }
        }

        Item {
            id: coverFlowStage

            anchors.left: parent.left
            anchors.right: parent.right
            y: 162
            height: 265

            visible: window.filteredLibraryGames.length > 0

            Repeater {
                model: window.filteredLibraryGames

                delegate: Item {
                    id: cardDelegate

                    required property int index
                    required property var modelData

                    // Signed distance from the currently selected center game
                    property int offset: index - window.selectedGameIndex
                    property int absOffset: Math.abs(offset)
                    property bool isCenter: offset === 0

                    width: 200
                    height: 230

                    // Overlapping horizontal layout
                    x: {
                        var centerX = (coverFlowStage.width - width) / 2
                        if (offset === 0)
                            return centerX
                        var dir = offset > 0 ? 1 : -1
                        return centerX + dir * (135 + (absOffset - 1) * 92)
                    }

                    // Spaced below the subtitle text
                    y: isCenter ? 4 : Math.min(8 + absOffset * 10, 38)

                    // Center card is in front of all others
                    z: 100 - absOffset

                    // Progressive scale drop-off for depth
                    scale: isCenter
                           ? (window.libraryFocusRow === 2 ? 1.12 : 1.0)
                           : Math.max(0.55, 0.90 - (absOffset - 1) * 0.13)

                    // Fade out cards far in the background
                    opacity: absOffset > 5
                             ? 0.0
                             : (isCenter ? 1.0 : Math.max(0.28, 0.82 - (absOffset - 1) * 0.16))

                    visible: opacity > 0.01

                    Behavior on x {
                        NumberAnimation { duration: 340; easing.type: Easing.OutCubic }
                    }
                    Behavior on y {
                        NumberAnimation { duration: 340; easing.type: Easing.OutCubic }
                    }
                    Behavior on scale {
                        NumberAnimation { duration: 340; easing.type: Easing.OutCubic }
                    }
                    Behavior on opacity {
                        NumberAnimation { duration: 260; easing.type: Easing.OutCubic }
                    }

                    // 1. Reactive Dark Floor Shadow underneath each 3D box
                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 2

                        width: 135
                        height: 16
                        radius: 8
                        color: "#000000"
                        opacity: cardDelegate.isCenter ? 0.42 : 0.25

                        SequentialAnimation on scale {
                            running: cardDelegate.isCenter && coverArtImg.status === Image.Ready
                            loops: Animation.Infinite
                            NumberAnimation { to: 0.82; duration: 2200; easing.type: Easing.InOutSine }
                            NumberAnimation { to: 1.0;  duration: 2200; easing.type: Easing.InOutSine }
                        }
                    }

                    // 2. The 3D Case Image
                    Image {
                        id: coverArtImg

                        anchors.horizontalCenter: parent.horizontalCenter
                        y: 0

                        width: 195
                        height: 215

                        source: cardDelegate.modelData.coverUrl
                        fillMode: Image.PreserveAspectFit
                        asynchronous: true
                        smooth: true
                        mipmap: true

                        Behavior on y {
                            NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
                        }

                        transform: Rotation {
                            id: cardRotation
                            origin.x: coverArtImg.width / 2
                            origin.y: coverArtImg.height / 2
                            axis { x: 0.12; y: 1.0; z: 0.0 }

                            property real idleRockAngle: 0

                            angle: cardDelegate.isCenter
                                   ? idleRockAngle
                                   : (cardDelegate.offset < 0 ? 22 : -22)

                            Behavior on angle {
                                NumberAnimation { duration: 340; easing.type: Easing.OutCubic }
                            }
                        }

                        // Continuous Levitation (Bobbing up and down) on the center selected card
                        SequentialAnimation on y {
                            running: cardDelegate.isCenter &&
                                     window.libraryFocusRow === 2 &&
                                     coverArtImg.status === Image.Ready
                            loops: Animation.Infinite
                            NumberAnimation { to: -10; duration: 2200; easing.type: Easing.InOutSine }
                            NumberAnimation { to: 0;   duration: 2200; easing.type: Easing.InOutSine }
                        }

                        // Continuous 3D Perspective Rocking on the center selected card
                        SequentialAnimation {
                            running: cardDelegate.isCenter &&
                                     window.libraryFocusRow === 2 &&
                                     coverArtImg.status === Image.Ready
                            loops: Animation.Infinite
                            NumberAnimation {
                                target: cardRotation
                                property: "idleRockAngle"
                                to: 11
                                duration: 2800
                                easing.type: Easing.InOutSine
                            }
                            NumberAnimation {
                                target: cardRotation
                                property: "idleRockAngle"
                                to: -11
                                duration: 2800
                                easing.type: Easing.InOutSine
                            }
                        }
                    }

                    // Fallback title card if 3D image is still loading or missing
                    Rectangle {
                        anchors.centerIn: parent
                        width: 155
                        height: 200
                        radius: 6
                        color: "#102444"
                        border.color: cardDelegate.isCenter ? "white" : "#4a6785"
                        border.width: 2
                        visible: coverArtImg.status !== Image.Ready

                        Text {
                            anchors.centerIn: parent
                            width: parent.width - 20
                            text: coverArtImg.status === Image.Loading
                                  ? "Loading 3D Box..."
                                  : cardDelegate.modelData.title
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.WordWrap
                            color: "white"
                            font.family: xmbFont.name
                            font.pixelSize: 13
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            window.libraryFocusRow = 2
                            if (cardDelegate.isCenter) {
                                window.selectAction()
                            } else {
                                window.selectedGameIndex = cardDelegate.index
                            }
                            keyboardFocus.forceActiveFocus()
                        }
                    }
                }
            }
        }

        // Mouse Wheel support to scroll smoothly through the 3D Cover Flow
        WheelHandler {
            onWheel: function(event) {
                if (window.filteredLibraryGames.length === 0)
                    return
                window.libraryFocusRow = 2
                if (event.angleDelta.y < 0 || event.angleDelta.x < 0) {
                    if (window.selectedGameIndex < window.filteredLibraryGames.length - 1)
                        window.selectedGameIndex++
                } else if (event.angleDelta.y > 0 || event.angleDelta.x > 0) {
                    if (window.selectedGameIndex > 0)
                        window.selectedGameIndex--
                }
            }
        }
    }

    Column {
        id: settingsMenu

        x: settingsCategory.x +
           categoryRow.x -
           25

        y: 280

        width: 330

        visible: window.currentCategory === 2

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
                window.emulatorSettingsOpen = true
                window.emulatorSettingsIndex = 0
                keyboardFocus.forceActiveFocus()
            }
        }
    }

    // Emulator Settings Screen

    Rectangle {
        id: emulatorSettingsPanel

        anchors.centerIn: parent

        width: 720
        height: 360

        visible: window.emulatorSettingsOpen

        z: 200

        radius: 18

        color: "#E60B1728"

        border.width: 1
        border.color: "#52749a"

        Column {
            anchors.fill: parent
            anchors.margins: 40

            spacing: 24

            Text {
                text: "Emulator Settings"

                color: "white"

                font.family: xmbFont.name
                font.pixelSize: 28
                font.weight: Font.Normal
            }

            Item {
                width: parent.width
                height: window.discLaunching ? 54 : 0

                visible: window.discLaunching

                Rectangle {
                    id: loadingDisc

                    anchors.horizontalCenter: parent.horizontalCenter

                    width: 42
                    height: 42

                    radius: 21

                    color: "transparent"

                    border.width: 2
                    border.color: "white"

                    Rectangle {
                        anchors.centerIn: parent

                        width: 10
                        height: 10

                        radius: 5

                        color: "transparent"

                        border.width: 2
                        border.color: "white"
                    }

                    RotationAnimation on rotation {
                        from: 0
                        to: 360

                        duration: 1800
                        loops: Animation.Infinite

                        running: window.discLaunching
                    }
                }
            }

            Text {
                text: "Choose the executable used for each PlayStation emulator."

                color: "#aebccc"

                font.family: xmbFont.name
                font.pixelSize: 14
                font.weight: Font.Light
            }

            EmulatorEntry {
                title: "DuckStation"
                subtitle: "PlayStation"
                path: appController.ps1EmulatorPath

                selected:
                    window.emulatorSettingsIndex === 0

                onClicked: {
                    window.emulatorSettingsIndex = 0
                    duckstationDialog.open()
                    keyboardFocus.forceActiveFocus()
                }
            }

            EmulatorEntry {
                title: "PCSX2"
                subtitle: "PlayStation 2"
                path: appController.ps2EmulatorPath

                selected:
                    window.emulatorSettingsIndex === 1

                onClicked: {
                    window.emulatorSettingsIndex = 1
                    pcsx2Dialog.open()
                    keyboardFocus.forceActiveFocus()
                }
            }

            Item {
                height: 10
            }

            Text {
                text: controllerManager.hasController
                      ? "X   Select Emulator     O   Back"
                      : "ENTER   Select Emulator     ESC   Back"

                color: "#8798ac"

                font.family: xmbFont.name
                font.pixelSize: 13
                font.weight: Font.Light
            }
        }
    }

    // Description

    Text {
        anchors.horizontalCenter: parent.horizontalCenter

        anchors.bottom: parent.bottom
        anchors.bottomMargin: 64

        width: 650

        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap

        text: {
            if (window.currentCategory === 0)
                return discManager.discReady
                       ? "Press Select to launch " + discManager.gameTitle + "."
                       : "Ready for a PlayStation game disc."

            if (window.currentCategory === 1) {
                if (window.libraryFocusRow === 0)
                    return "Open the Disc Dumper utility to extract games to your local library."
                if (window.libraryFocusRow === 1)
                    return "Use Left / Right to filter between All Games, PlayStation, and PlayStation 2."
                if (window.selectedGameIndex >= 0 && window.selectedGameIndex < window.filteredLibraryGames.length)
                    return "Press Select to play " + window.filteredLibraryGames[window.selectedGameIndex].title + "  •  Press Up to filter by console."
                return "Browse and launch your extracted PlayStation games."
            }

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

        font.family: xmbFont.name
        font.pixelSize: 14
        font.weight: Font.Normal

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
            text: controllerManager.hasController
                  ? "X   Select"
                  : "ENTER   Select"

            color: "#d7dfe9"

            font.family: xmbFont.name
            font.pixelSize: 13
            font.weight: Font.Normal

            opacity: 0.8
        }

        Text {
            text: controllerManager.hasController
                  ? "O   Back"
                  : "ESC   Back"

            color: "#d7dfe9"

            font.family: xmbFont.name
            font.pixelSize: 13
            font.weight: Font.Normal

            opacity: 0.8
        }

        Text {
            text: controllerManager.hasController
                  ? "D-PAD / L STICK   Browse"
                  : "← ↑ ↓ →   Browse"

            color: "#d7dfe9"

            font.family: xmbFont.name
            font.pixelSize: 13
            font.weight: Font.Normal

            opacity: 0.8
        }
    }

    // Insert Disc Screen

    Rectangle {
        id: popupOverlay

        anchors.fill: parent

        visible: window.popupOpen

        color: "#B0000000"

        z: 300

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

    component EmulatorEntry: Item {
        id: emulatorEntry

        required property string title
        required property string subtitle
        required property string path

        property bool selected: false

        signal clicked()

        width: 640
        height: 72

        opacity: selected ? 1.0 : 0.45
        x: selected ? 12 : 0

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
            spacing: 16

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter

                width: 8
                height: 8
                radius: 4

                color: "white"
                opacity: emulatorEntry.selected ? 1 : 0
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                width: 170
                spacing: 4

                Text {
                    text: emulatorEntry.title

                    color: "white"
                    font.family: xmbFont.name
                    font.pixelSize: emulatorEntry.selected ? 20 : 18
                    font.weight: Font.Normal
                }

                Text {
                    text: emulatorEntry.subtitle

                    color: "#93a2b4"
                    font.family: xmbFont.name
                    font.pixelSize: 13
                    font.weight: Font.Light
                }
            }

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter

                width: 430
                height: 40
                radius: 8

                color: "#14000000"
                border.width: 1
                border.color: emulatorEntry.selected ? "#6d8fb8" : "#3d5573"

                Text {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter

                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideMiddle

                    text: emulatorEntry.path.length > 0
                          ? emulatorEntry.path
                          : "No executable selected"

                    color: emulatorEntry.path.length > 0
                           ? "#d7dfe9"
                           : "#7f90a5"

                    font.family: xmbFont.name
                    font.pixelSize: 13
                    font.weight: Font.Normal
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: false

            onClicked: emulatorEntry.clicked()
        }
    }

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
                width: entry.width - 35
                elide: Text.ElideRight
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