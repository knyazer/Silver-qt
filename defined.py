from PyQt5.QtWidgets import QApplication
from PyQt5.QtQml import QQmlApplicationEngine
from PyQt5.QtCore import QUrl, QObject
from PyQt5 import QtCore

import os
os.environ["QT_QUICK_CONTROLS_STYLE"] = "Material"

class App(QObject):
    @QtCore.pyqtProperty(float)
    def estimatedProcessingTime(self):
        return 12.3

    @QtCore.pyqtSlot(str)
    def output(self, s):
        print("gotcha:" + s)

    @QtCore.pyqtSlot()
    def process(self):
        print("Processing!!!!")

app = QApplication(["RSL silver"])
app.setOrganizationName("K")
app.setOrganizationDomain("K")

view = QQmlApplicationEngine()
url = QUrl("design.qml")

g = App()
context = view.rootContext()
context.setContextProperty("g", g)

view.load(url)


app.exec()
