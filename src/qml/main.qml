    import QtQuick 2.12
    import QtQuick.Controls 2.12
    import QtQuick.Controls.Material 2.12
    import QtQuick.Layouts 1.1
    import QtQuick.Dialogs 1.1
    import QtQuick.Window 2.2


    ApplicationWindow {
    property string textColor: "white"
    property string green: "greenyellow"
    property string red: "orange"
    property var videos: [];
    property var videoUrls: [];
    property var videoTexts: [];
    property var results: [];

    function showVideos(urls)
    {
        button.visible = false;
        container.visible = true;
        videoActions.visible = true;
        settingsButton.visible = false;
        folderSwitch.visible = false;
        switchText.visible = false;
        for (var i = 0; i < urls.length; i++)
        {
            var url = urls[i];
            videoUrls.push(url);

            if (videos.length < 40)
            {
                var res = addVideo(url);

                if (g.QtMultimedia)
                    reloadVideo(res[0]);

                videos.push(res[0]);
                videoTexts.push(res[1]);
            }
        }

        updateGrid();
    }

    function reloadVideo(video)
    {
        video.seek(1);
        video.pause();
        video.forceActiveFocus();
    }

    function showReminder(text, urgency=3)
    {
        reminder.visible = true;
        reminder.text = text;

        if (urgency === 1)
            reminder.color = "red";
        else if (urgency === 2)
            reminder.color = "yellow";
        else if (urgency === 3)
            reminder.color = "white";
        else
            reminder.color = "blue";
    }

    function hideReminder()
    {
        reminder.visible = false;
    }

    function destroyVideo(obj)
    {
        for (var i = 0; i < videos.length; i++)
        {
            if (videos[i] === obj)
            {
                videos[i].destroy(30);
                videos.splice(i, 1);
                videoUrls.splice(i, 1);
                videoTexts.splice(i, 1);
                break;
            }
        }

        updateGrid();
    }

    function addVideo(url)
    {
        var _id = url.replace(/[^a-zA-Z0-9]/g, '');
        var libs =  "import QtQuick 2.12;import QtQuick.Controls 2.12;import QtQuick.Controls.Material 2.12;" +
                    "import QtQuick.Layouts 1.1;import QtQuick.Dialogs 1.1;import QtQuick.Window 2.2;";
        var type = "";
        var thumbnailRoot = "../../temp/";

        if (g.QtMultimedia)
        {
            libs += 'import QtMultimedia 5.6;';
            type = "Video";
        }
        else
        {
            type = "Image";
            g.makeThumbnail(String(url), _id + '.png');
        }
        
        var _component = Qt.createQmlObject(libs + type + "{" +
                    "Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter;" +
                    "visible: true;" +
                    "source: '" + (type === 'Image' ? thumbnailRoot + _id + '.png' : url) + "';" +
                    "id: " + _id + ";" +
                    (type === 'Image' ? "" : ("MouseArea {" +
                        "propagateComposedEvents: true;" +
                        "anchors.fill: parent;" +
                        "onClicked: {" +
                            "if (playbackState === MediaPlayer.PlayingState) " +
                                "pause();" +
                            "else " +
                                "play();" +
                        "}" +
                    "}")) +
                    (type === 'Image' ? "fillMode: Image.PreserveAspectFit;" : "") +
                    "Image {source: '../icons/trash.png'; width: 25; height: 25; x: parent.width - 28; y: 4; MouseArea{propagateComposedEvents:true;anchors.fill:parent;onClicked:{destroyVideo(parent.parent);}}}" +
                    (type === 'Image' ? "" : "Keys.onSpacePressed: playbackState == MediaPlayer.PlayingState ? pause() : play();") +
                    (type === 'Image' ? "" : "onStopped: reloadVideo(this);") +
                "}", grid, "qml" + _id);
        var _text = Qt.createQmlObject(libs + "Text {text: ''; x: 4; y: 4; color: 'red';}", _component, "qml_text" + _id);
        return [_component, _text];
    }

    function updateGrid()
    {
        if (videos.length > 3)
            container.ScrollBar.vertical.policy = ScrollBar.AlwaysOn;

        var sz = 90;
        if (videos.length >= 3)
            sz = Math.round((root.width - grid.rowSpacing * 5 - 3) / 3);
        else if (videos.length == 2)
            sz = Math.round((root.width - grid.rowSpacing * 4 - 3) / 2);
        else if (videos.length == 1)
            sz = Math.round(root.width - grid.rowSpacing * 3 - 3);

        for (var i = 0; i < videos.length; i++)
        {
            videos[i].Layout.minimumWidth = sz;
            videos[i].Layout.minimumHeight = sz;
            videos[i].Layout.preferredWidth = sz;
            videos[i].Layout.preferredHeight = sz;
            videoTexts[i].font.pixelSize = Math.max(sz / 10, 18);

        }
    }

    function updateTime()
    {
        if (g.QtMultimedia)
        {
            var len = 0;
            for (var i = 0; i < videos.length; i++)
                len += videos[i].duration / 16;
            len /= Math.max(videos.length, 1);
        }
        else
        {
            var len = 400;
        }

        var total = len * videoUrls.length;

        var estim = g.estimatedProcessingTime(total, 1 + accuracySlider.to - accuracySlider.value);
        var measure = "seconds";

        if (estim > 90)
        {
            estim = Math.round(estim / 60);
            measure = "minutes";
        }

        processingTime.text = qsTr("Dataset will be processed in ") + estim + qsTr(" " + measure);
    }

    id: root
    visible: true
    width: 640
    height: 480
    minimumHeight: 300
    minimumWidth: 450

    Material.theme: Material.Dark // or Material.Light
    Material.accent: Material.BlueGrey

    onWidthChanged: function() {
        updateGrid();
    }

    font.capitalization: Font.MixedCase
    ColumnLayout
    {
        anchors.fill: parent
        anchors.margins: 20

        Text {
            id: reminder
            text: ""
            visible: false
            Layout.alignment: Qt.AlignBottom | Qt.AlignHCenter
            color: textColor
            font.pixelSize: 22
        }

        ScrollView {
            Layout.fillHeight: true
            Layout.fillWidth: true
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
            clip: true

            id: container
            visible: false
            GridLayout
            {
                width: parent.width
                height: parent.height
                id: grid
                rowSpacing: 20;
                columnSpacing: 20;
                columns: 3;
            }
        }

        Button {
            id: button
            Layout.alignment: Qt.AlignBottom | Qt.AlignHCenter
            text: qsTr("Upload videos")

            onClicked: function()
            {
                if (folderSwitch.position < 0.5)
                    fileDialog.open();
                else
                    folderDialog.open();
            }
        }

        Text {
            id: switchText
            text: "Traverse entire folders"
            font.pixelSize: 18
            height: 20
            color: textColor
            Layout.alignment: Qt.AlignBottom | Qt.AlignHCenter
        }

        Switch {
            id: folderSwitch
            Layout.alignment: Qt.AlignTop | Qt.AlignHCenter
        }

        RowLayout {
            id: videoActions
            Layout.alignment: Qt.Bottom | Qt.AlignHCenter
            visible: false
            spacing: Math.max(Math.min(300, parent.width - 260), 0)

            Button {
                Layout.preferredWidth: 140;
                text: qsTr("Add more videos")
                onClicked: function() {
                    if (secondFolderSwitch.position < 0.5)
                        fileDialog.open();
                    else
                        folderDialog.open();
                }

                Switch {
                    id: secondFolderSwitch
                    x: parent.width + 5

                    onClicked: function() {
                        var TEXT_1 = qsTr("Add more videos"),
                            TEXT_2 = qsTr("Add more folders");

                        if (parent.text === TEXT_1)
                            parent.text = TEXT_2;
                        else
                            parent.text = TEXT_1;
                    }
                }
            }


            Button {
                text: qsTr("Process")
                onClicked: popup.open()
            }
        }
    }

    FileDialog {
        id: fileDialog
        title: qsTr("Choose videos")
        folder: shortcuts.home
        selectMultiple: true
        nameFilters: [ "Video files (*.avi *.mp4)", "All file (*)" ]
        onAccepted: {
            showVideos(fileUrls);
            hideReminder();
        }
        onRejected: {
            if (videos.length != 0)
                showReminder(qsTr("Video is required to continue!"));
            else
                hideReminder();
        }
    }

    FileDialog {
        id: folderDialog
        title: qsTr("Choose folders to traverse")
        folder: shortcuts.home
        selectMultiple: false
        selectFolder: true
        onAccepted: {
            console.log("Your choice is: " + fileUrls);
            showVideos(g.traverse(fileUrls));
        }
        onRejected: {
            if (container.visible)
                showReminder(qsTr("Video is required to continue!"));
        }
    }

    Popup {
        id: popup
        parent: Overlay.overlay
        modal: true

        x: Math.round((parent.width - width) / 2)
        y: Math.round((parent.height - height) / 5)
        padding: 20

        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent

        ColumnLayout
        {

            width: parent.width
            Text {
                id: title
                text: qsTr("Information and configuration")
                Layout.alignment: Qt.AlignHCenter | Qt.AlignTop
                color: textColor
                font.pixelSize: 22
                font.bold: true
            }

            RowLayout
            {
                Text {
                    Layout.alignment: Qt.AlignVCenter
                    id: fastSliderInfo
                    text: qsTr("Performance")
                    color: red
                }

                Slider {
                    id: accuracySlider
                    Layout.alignment: Qt.AlignVCenter
                    from: 1
                    value: 10
                    to: 10
                    stepSize: 1
                    snapMode: Slider.SnapOnRelease
                    onValueChanged: updateTime()
                    onVisibleChanged: updateTime()
                }

                Text {
                    Layout.alignment: Qt.AlignVCenter
                    id: slowSliderInfo
                    text: qsTr("Accuracy")
                    color: green
                }
            }

            Text {
                id: processingTime
                Layout.alignment: Qt.AlignHCenter
                color: textColor
            }


            RowLayout {
                Layout.alignment: Qt.AlignHCenter

                CheckBox {
                    id: dumpToFile
                    checked: true
                    text: "Dump results"
                    onCheckStateChanged: function()
                    {
                        if (fileNameField.readOnly === true)
                        {
                            fileNameField.readOnly = false;
                            fileNameField.font.italic = false;
                            fileNameField.color = textColor;
                        }
                        else
                        {
                            fileNameField.readOnly = true;
                            fileNameField.font.italic = true;
                            fileNameField.color = '#888';
                        }
                    }
                }
                TextField {
                    id: fileNameField
                    text: "results.csv"
                    readOnly: false
                    color: textColor
                }
            }

            ProgressBar
            {
                id: progress
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter
                visible: false
                indeterminate: true
                from: 0
                to: 1
            }

            Timer {
                id: timer
                function setTimeout(cb, delayTime) {
                    timer.interval = delayTime;
                    timer.repeat = false;
                    timer.triggered.connect(cb);
                    timer.triggered.connect(function release () {
                        timer.triggered.disconnect(cb); // This is important
                        timer.triggered.disconnect(release); // This is important as well
                    });
                    timer.start();
                }
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                Layout.fillWidth: true
                Button {
                    id: popupCancelButton
                    text: qsTr("Cancel")

                    onClicked: function()
                    {
                        popup.close()
                    }
                }

                Button {
                    id: popupOkButton
                    text: qsTr("Ok")

                    onClicked: function()
                    {
                        progress.visible = true;
                        down = false;

                        timer.setTimeout(function() {
                            results = g.process(videoUrls, dumpToFile.checked, fileNameField.text);

                            for (var i = 0; i < videoTexts.length; i++)
                                videoTexts[i].text = results[i];

                            progress.visible = false;
                            popup.close();
                        }, 100);
                    }
                }
            }
        }
    }

    Popup {
        id: settings

        modal: true

        parent: this

        x: Math.round((parent.width - width) / 2)
        y: Math.round((parent.height - height) / 2)
        padding: 20

        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent

        ColumnLayout {
            Text {
                text: qsTr("Global settings")
                Layout.alignment: Qt.AlignHCenter | Qt.AlignTop
                color: textColor
                font.pixelSize: 22
                font.bold: true
            }

            Text {
                text: qsTr("Language")
                Layout.alignment: Qt.AlignHCenter
                color: textColor
                font.pixelSize: 18
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter

                Button {
                    id: englishButton
                    text: "English"
                    down: true

                    onClicked: function()
                    {
                        if (down === false)
                        {
                            console.log("set lang to english");
                            down = true
                            russianButton.down = false
                        }
                        else
                        {
                            console.log("already checked")
                        }
                    }
                }

                Button {
                    id: russianButton
                    text: "Русский"

                    onClicked: function()
                    {
                        if (down === false)
                        {
                            console.log("set lang to russian");
                            //down = true
                            //englishButton.down = false
                        }
                        else
                        {
                            console.log("already checked")
                        }
                    }
                }
            }

            Text {
                text: qsTr("Color theme")
                Layout.alignment: Qt.AlignHCenter
                color: textColor
                font.pixelSize: 18
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter

                Button {
                    id: lightButton
                    text: qsTr("Light")

                    onClicked: function()
                    {
                        if (down === false)
                        {
                            console.log("set theme to light");
                            down = true;
                            darkButton.down = false;

                            root.Material.theme = Material.light;
                            root.textColor = "black";
                            settingsButton.source = "../icons/settings.png";
                        }
                        else
                        {
                            console.log("already checked")
                        }
                    }
                }

                Button {
                    id: darkButton
                    text: qsTr("Dark")
                    down: true

                    onClicked: function()
                    {
                        if (down === false)
                        {
                            console.log("set theme to dark");
                            down = true;
                            lightButton.down = false;

                            root.Material.theme = Material.Dark;
                            root.textColor = "white";
                            settingsButton.source = "../icons/white-settings.png";
                        }
                        else
                        {
                            console.log("already checked")
                        }
                    }
                }
            }

            Item {
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                Layout.preferredHeight: 30
            }

            Button {
                text: "Close"
                Layout.alignment: Qt.AlignHCenter | Qt.AlignBottom

                onClicked: function()
                {
                    settings.close()
                }
            }
        }
    }

    Image {
        id: settingsButton
        source: "../icons/white-settings.png"
        width: 50
        height: 50
        x: 3
        y: 3
        MouseArea {
            anchors.fill: parent
            onClicked: {
                settings.open()
            }
        }
    }
    }
