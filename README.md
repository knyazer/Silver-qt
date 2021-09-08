# Silver-qt
Application for Russian Sign Language recognition

### Technology
+ PyQT5+QML and ONNX models for inference;
+ Material style;
+ Dark/Light color themes
+ Russian/English languages (currently unavailable)

### Installation
```
pip3 install -r requirements.txt
```
Install PyQt5.3+ with additional multimedia part on your own, as usually multimedia does not provided in GPL Qt, eventhough it should be there. On linux (Ubuntu) you can simply install it using package manager, like so:
```
sudo apt install -y qt5-default pyqt5-devlibqt5multimedia5-plugins qml-module-qtmultimedia qml-module-qt-labs-settings libqt5multimedia5-plugins
```
Also, there is added part which checks whether you have multimedia installed, and if not the app will merely have limited functionality
### Instructions
Nothing there :)
