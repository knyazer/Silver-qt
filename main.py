from PyQt5.QtWidgets import QApplication
from PyQt5.QtQml import QQmlApplicationEngine
from PyQt5.QtCore import QUrl, QObject
from PyQt5 import QtCore
from predict import predict
import math
import glob
import os
import csv

os.environ["QT_QUICK_CONTROLS_STYLE"] = "Material"

class App(QObject):
    @QtCore.pyqtSlot(float, float, result=int)
    def estimatedProcessingTime(self, framesN, perf):
        self.step = int(round(perf + 0.1 * (perf ** 2)))
        return int(round(framesN * (0.001 + 0.1 / self.step)))

    @QtCore.pyqtSlot(str)
    def output(self, s):
        print("gotcha:" + s)

    @QtCore.pyqtSlot(list, bool, str, result=list)
    def process(self, urls, doDump, fileName):
        predictions = [predict(url, step=self.step) for url in urls]

        if doDump:
            with open(fileName, 'w', encoding='UTF8') as f:
                writer = csv.writer(f)
                writer.writerow(['path', 'result'])

                for url, pred in zip(urls, predictions):
                    writer.writerow([url, pred])

        return predictions

    @QtCore.pyqtSlot(str, result=list)
    def traverse(self, url):
        filenames = []
        for filename in glob.iglob(url[7:] + "/**/*.mp4", recursive=True):
            filenames.append(filename)
        return filenames

app = QApplication(["RSL silver"])
app.setOrganizationName("K")
app.setOrganizationDomain("K")

view = QQmlApplicationEngine()
url = QUrl("main.qml")

g = App()
context = view.rootContext()
context.setContextProperty("g", g)

view.load(url)


app.exec()
