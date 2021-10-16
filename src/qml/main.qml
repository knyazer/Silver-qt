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

        g.stream();
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
        inputType = "";
    }

    function clearOutput()
    {
        output.text = "Перевод";
        eraseOutput.visible = false;
    }

    function translate()
    {
        if (inputType === "")
        {
            output.text = "...";
            eraseOutput.visible = true;
            return;
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

            cameraStop.visible = true;
            process.visible = false;
        }
    }

    function stopTranslation()
    {
        cameraStop.visible = false;
        progress.visible = false;
        process.visible = true;
        g.stopAsync();
    }

    property string bg: "#aaa"
    property string silver: "#959595"
    property string borderCl: "#a1a1a1"
    property string inputUrl: ""
    property string inputType: ""
    property bool cameraAccept: false

    id: root
    visible: true
    width: 640
    height: 480
    minimumHeight: 420
    minimumWidth: 500

    color: bg

    font.capitalization: Font.MixedCase
    Dialog {
        id: cameraAccess
        title: "Вы разрешаете получить данному приложению доступ к камере?"
        visible: false

        x: (parent.width - width) / 2
        y: (parent.height - height) / 2

        DialogButtonBox {
            Button {
                text: "Да"
                DialogButtonBox.buttonRole: DialogButtonBox.AcceptRole
                onClicked:
                {
                    console.log("continue");
                    cameraAccept = true;

                    useCamera();

                    cameraAccess.visible = false;
                }
            }
            Button {
                text: "Нет"
                DialogButtonBox.buttonRole: DialogButtonBox.DestructiveRole

                onClicked:
                {
                    cameraAccept = false;

                    cameraAccess.visible = false;
                }
            }
        }

    }

    RowLayout
    {
        anchors.fill: parent
        anchors.margins: 15

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
                y: -45
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

                    ToolTip{
                            visible: videoTranslation.hovered
                            delay: 100
                            text: "Распознать жесты из видеофайла"
                            font.family: "tahoma"
                            timeout: 4000
                     }

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

                    ToolTip{
                            visible: cameraTranslation.hovered
                            delay: 100
                            text: "Распознать жесты с видеокамеры"
                            font.family: "tahoma"
                            timeout: 4000
                     }

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

                hoverEnabled: true

                ToolTip{
                        visible: eraseInput.hovered
                        delay: 100
                        text: "Очистить входные данные"
                        font.family: "tahoma"
                        timeout: 4000
                 }

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
            Button
            {
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                id: process

                icon.name: "process"
                icon.source: "../icons/arrow.png"
                flat: true

                ToolTip{
                        visible: process.hovered
                        delay: 100
                        text: "Запустить перевод"
                        font.family: "tahoma"
                        timeout: 4000
                 }

                background: Rectangle {
                        implicitWidth: 40
                        implicitHeight: 40
                        color: process.down ? "#ddd" : (process.hovered ? "#ccc" : "#bbb")
                        radius: 5
                }

                onClicked: translate()
            }

            Button
            {
                id: cameraStop

                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

                icon.name: "stop"
                icon.source: "../icons/stop.png"

                visible: false

                flat: true

                ToolTip{
                        visible: cameraStop.hovered
                        delay: 100
                        text: "Остановить обработку видеопотока"
                        font.family: "tahoma"
                        timeout: 4000
                 }

                background: Rectangle {
                        implicitWidth: 40
                        implicitHeight: 40
                        color: cameraStop.down ? "#ddd" : (cameraStop.hovered ? "#ccc" : "#bbb")
                        radius: 5
                }

                onClicked: stopTranslation()
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
                y: -45
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
                    font.pointSize: 20
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

                ToolTip{
                        visible: eraseOutput.hovered
                        delay: 100
                        text: "Стереть переведенный текст"
                        font.family: "tahoma"
                        timeout: 4000
                 }

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

    footer:
        Text {
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            padding: 1
            font.pointSize: 10
            font.family: "Roboto"
            text: "v2.1.0. silver.aiijc@gmail.com"
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
