import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Controls.Material 2.12
import QtQuick.Layouts 1.1
import QtMultimedia 5.6
import QtQuick.Dialogs 1.1
import QtQuick.Window 2.2


ApplicationWindow {
    property string textColor: "white"
    property string green: "greenyellow"
    property string red: "orange"
    property var videos: [];

    function showVideos(urls)
    {
       for (var i = 0; i < urls.length; i++)
       {
           var url = urls[i];
           console.log("button pressed (" + url + ")");
           button.visible = false;
           var video = addVideo(url);
           container.visible = true;
           video.source = url;
           videoActions.visible = true;
           reloadVideo(video);

           videos.push(video);

           g.output(url);
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
        console.log("Reminder shown");
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

    function addVideo(url)
    {
        var _id = url.replace(/[^a-zA-Z0-9]/g, '');
        console.log("id:" + _id);
        var libs =  "import QtQuick 2.12;import QtQuick.Controls 2.12;import QtQuick.Controls.Material 2.12;" +
                    "import QtQuick.Layouts 1.1;import QtMultimedia 5.6;import QtQuick.Dialogs 1.1;import QtQuick.Window 2.2;";
        var _component = Qt.createQmlObject(libs + "Video {" +
                    //"Layout.minimumHeight: 150;" +
                    //"Layout.minimumWidth: 200;" +
                    "Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter;" +
                    "visible: true;" +
                    "source: '" + url + "';" +
                    "id: " + _id + ";" +
                    "MouseArea {" +
                        "anchors.fill: parent;" +
                        "onClicked: {" +
                            "if (playbackState === MediaPlayer.PlayingState) " +
                                "pause();" +
                            "else " +
                                "play();" +
                            "console.log('mouse clciked');" +
                        "}" +
                    "}" +
                    "Keys.onSpacePressed: playbackState == MediaPlayer.PlayingState ? pause() : play();" +
                    "onStopped: reloadVideo(this);" +
                "}", grid, "qml" + _id);
        return _component;
    }

    function updateGrid()
    {
        var sz = Math.round((root.width - grid.rowSpacing * 4 - 3) / 3);
        for (var i = 0; i < videos.length; i++)
        {
            videos[i].Layout.minimumWidth = sz;
            videos[i].Layout.minimumHeight = sz;
        }
        console.log(sz);
    }

    id: root
    visible: true
    width: 640
    height: 480
    minimumHeight: 300
    minimumWidth: 300

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
            Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
            text: qsTr("Choose video")

            onClicked: function()
            {
                fileDialog.visible = true
            }
        }

        RowLayout {
            id: videoActions
            Layout.alignment: Qt.Bottom | Qt.AlignHCenter
            visible: false
            spacing: Math.max(Math.min(300, parent.width - 260), 0)

            Button {
                text: qsTr("Choose another video")
                onClicked: function() {
                    fileDialog.open();
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
        title: qsTr("Please choose a video")
        folder: shortcuts.home
        selectMultiple: true
        nameFilters: [ "Video files (*.avi *.mp4)", "All file (*)" ]
        onAccepted: {
            console.log("You chose: " + fileDialog.fileUrls);
            showVideos(fileDialog.fileUrls);
            hideReminder();
        }
        onRejected: {
            console.log("Canceled");
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
                    Layout.alignment: Qt.AlignVCenter
                    from: 1
                    value: 5
                    to: 5
                    stepSize: 1
                    snapMode: Slider.SnapOnRelease
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
                text: qsTr("The video will be processed in ") + g.estimatedProcessingTime + qsTr(" seconds")
                Layout.alignment: Qt.AlignLeft
                color: textColor
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
                        g.process()
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
                            down = true
                            darkButton.down = false

                            root.Material.theme = Material.light
                            root.textColor = "black"
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
                            down = true
                            lightButton.down = false

                            root.Material.theme = Material.Dark
                            root.textColor = "white"
                        }
                        else
                        {
                            console.log("already checked")
                        }
                    }
                }
            }
        }
    }

    Image {
        source: "settings.png"
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
