import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Controls.Material 2.12
import QtQuick.Layouts 1.1
import QtQuick.Dialogs 1.1
import QtQuick.Window 2.2

ApplicationWindow {
    function useCamera()
    {
        if (cameraAccept !== true)
        {
            cameraAccess.visible = true;
            return;
        }

        g.stream(0);
        console.log("Streaming");

        inputControls.visible = false;
        image.visible = true;
        image.source = "../icons/load.png"
        imageText.text = "";
        eraseInput.visible = true;

        inputType = "camera";
    }

    function useVideo(url)
    {
        g.makeThumbnail(url);

        imageText.text = url.substr(url.lastIndexOf("/") + 1);

        console.log("Use video");

        inputControls.visible = false;
        image.visible = true;
        image.source = "../icons/load.png"
        eraseInput.visible = true;

        inputUrl = url;
        inputType = "video";
    }

    function clearInput()
    {
        g.stopStream();

        image.visible = false;
        inputControls.visible = true;
        eraseInput.visible = false;

        progress.visible = false;
        g.stopAsync();
        progress.visible = false;
    }

    function clearOutput()
    {
        output.text = "Перевод";
        eraseOutput.visible = false;
        g.stopAsync();
        progress.visible = false;
    }

    function translate()
    {
        if (inputType === "camera" && progress.visible === true)
        {
            progress.visible = false;
            g.stopAsync();
        }


        if (output.text === "Перевод")
            output.text = "";

        progress.visible = true;
        if (inputType === "video")
        {
            g.process([inputUrl], false, "");
            g.stopStream();
        }

        if (inputType == "camera")
        {
            g.asyncProcess();
        }
    }

    property string bg: "#999999"
    property string silver: "#828282"
    property string borderCl: "#909090"
    property string inputUrl: ""
    property string inputType: ""
    property bool cameraAccept: false

    id: root
    visible: true
    width: 640
    height: 480
    minimumHeight: 400
    minimumWidth: 500

    //Material.theme: Material.Dark // or Material.Light
    //Material.accent: Material.BlueGrey

    color: bg

    font.capitalization: Font.MixedCase
    MessageDialog {
        id: cameraAccess
        title: "Разрешение на доступ к камере"
        text: "Вы разрешаете получить данному приложению доступ к камере?"
        standardButtons: StandardButton.Yes | StandardButton.No
        Component.onCompleted: visible = false

        onYes:
        {
            console.log("continue");
            cameraAccept = true;

            useCamera();
        }

        onNo:
        {
            cameraAccept = false;
        }

        onRejected:
        {
            cameraAccept = false;
        }
    }

    RowLayout
    {
        anchors.fill: parent
        anchors.margins: 20
        Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

        Rectangle
        {
            color: silver
            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.maximumHeight: 300
            border.color: borderCl
            border.width: 2

            TabBar {
                y: -48
                width: parent.width
                background: Rectangle {
                    color: "#ccc"
                }

                TabButton {
                    text: qsTr("Жестовый")
                    background: Rectangle {
                        color: "#ccc"
                    }
                }
            }

            Image
            {
                id: image

                fillMode: Image.PreserveAspectFit

                y: 2
                x: 2
                width: parent.width - 4
                height: parent.height - 4

                source: "../icons/load.png"

                visible: false;

                Text {
                    id: imageText

                    width: parent.width
                    y: parent.height - 30
                    x: 6

                    font.italic: true
                    font.bold: true
                    font.pointSize: 14

                    color: "#a91e62"

                    font.family: "Roboto"

                    text: ""
                }
            }

            RowLayout
            {
                id: inputControls

                width: parent.width
                height: parent.height
                Button
                {
                    Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                    id: videoTranslation

                    icon.name: "video"
                    icon.source: "../icons/video.png"
                    icon.width: 60
                    icon.height: 60

                    flat: true

                    background: Rectangle {
                            implicitWidth: 80
                            implicitHeight: 80
                            color: videoTranslation.down ? "#ddd" : (videoTranslation.hovered ? "#aaa" : borderCl)
                            radius: 5
                    }
                    
                    onClicked: fileDialog.open();
                }

                Button
                {
                    Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                    id: cameraTranslation

                    icon.name: "camera"
                    icon.source: "../icons/camera.png"
                    icon.width: 60
                    icon.height: 60

                    flat: true

                    background: Rectangle {
                            implicitWidth: 80
                            implicitHeight: 80
                            color: cameraTranslation.down ? "#ddd" : (cameraTranslation.hovered ? "#aaa" : borderCl)
                            radius: 5
                    }

                    onClicked: useCamera()
                }
            }

            Button
            {
                id: eraseInput

                flat: true
                visible: false

                x: parent.width - 40
                y: 5
                padding: 5

                icon.name: "cross"
                icon.source: "../icons/cross.png"
                icon.width: 20
                icon.height: 20

                background: Rectangle {
                    implicitWidth: 30
                    implicitHeight: 30
                    radius: 15

                    color: eraseInput.down ? "#ddd" : (eraseInput.hovered ? "#aaa" : borderCl)
                }

                onClicked: clearInput()
            }
        }

        ColumnLayout
        {
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            Button
            {
                id: process

                icon.name: "process"
                icon.source: "../icons/arrow.png"
                flat: true

                background: Rectangle {
                        implicitWidth: 40
                        implicitHeight: 40
                        color: process.down ? "#ddd" : (process.hovered ? "#ccc" : "#bbb")
                        radius: 5
                }

                onClicked: translate()
            }
        }

        Rectangle
        {
            id: translateArea

            color: silver
            Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.maximumHeight: 300
            border.color: borderCl
            border.width: 2

            TabBar {
                y: -48
                id: bar
                width: parent.width

                background: Rectangle {
                    color: "#ccc"
                }

                TabButton {
                    text: "Русский"
                    background: Rectangle {
                        color: "#ccc"
                    }
                }
            }

            ScrollView
            {
                clip: true
                anchors.fill: parent
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                x: 5
                y: 5
                width: parent.width - 10
                height: parent.height - 10


                TextEdit {
                    width: translateArea.width - 15
                    wrapMode: Text.Wrap
                    padding: 10
                    font.family: "Roboto"
                    font.pointSize: 22
                    selectByMouse: true
                    readOnly: true

                    id: output
                    text: "Перевод"
                }
            }

            Button
            {
                id: eraseOutput

                visible: false
                flat: true

                x: parent.width - 40
                y: 5
                padding: 5

                icon.name: "cross"
                icon.source: "../icons/cross.png"
                icon.width: 20
                icon.height: 20

                background: Rectangle {
                    implicitWidth: 30
                    implicitHeight: 30
                    radius: 15

                    color: eraseOutput.down ? "#ddd" : (eraseOutput.hovered ? "#aaa" : borderCl)
                }

                onClicked: clearOutput()
            }

            ProgressBar
            {
                id: progress
                visible: false
                indeterminate: true

                width: parent.width - 20
                x: 10
                y : parent.height - 12
            }
        }
    }

    FileDialog {
        id: fileDialog
        title: qsTr("Choose video")
        folder: shortcuts.home
        selectMultiple: false
        selectFolder: false
        nameFilters: [ "Video files (*.avi *.mp4)", "All file (*)" ]
        onAccepted: {
            console.log("Your choice is: " + fileUrls[0]);

            useVideo(fileUrls[0]);
        }
        onRejected: {
            console.log("rejected");
        }
    }

    property int ind: 0;

    Connections {
        target: g

        // Finished signal handler
        onFinished:
        {
            if (results.length === 1)
            {
                output.text += results[0] + " ";
                eraseOutput.visible = true;

                if (inputType == "video")
                    progress.visible = false;
            }
        }

        onImageSync:
        {
            ind = ind % 2
            image.source = "../../temp/frame" + ind + ".jpg"
            ind += 1
        }

        onThumbnailSync:
        {
            ind = ind % 2;
            image.source = "../../temp/thumbnail" + ind + ".jpg";
            ind += 1;
        }
    }
}
