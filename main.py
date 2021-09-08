from PyQt5.QtWidgets import QApplication
from PyQt5.QtQml import QQmlApplicationEngine
from PyQt5.QtCore import QUrl, QObject
from PyQt5 import QtCore
from predict import VID_FORMATS, predict
import math
import glob
import os
import csv
import cv2 as cv
import numpy as np

os.environ["QT_QUICK_CONTROLS_STYLE"] = "Material"

def make_thumbnail(inp, out):
    cap = cv.VideoCapture(inp)
    _, img = cap.read()
    if _ == False:
        img = np.zeros((100, 100, 3), dtype=np.uint8)
    else:
        f = 480.0 / max(img.shape[0], img.shape[1])
        img = cv.resize(img, None, fx=f, fy=f)

    cv.imwrite(out, img)
    cap.release()


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
        predictions = []
        for url in urls:
            try:
                predictions.append(predict(url[7:], step=self.step))
            except Exception as e:
                predictions.append((-1, -1))

        if doDump:
            with open(fileName, 'w', encoding='UTF8') as f:
                writer = csv.writer(f)
                writer.writerow(['path', 'label', 'label_txt'])

                for url, pred in zip(urls, predictions):
                    writer.writerow([url, pred[0], pred[1]])

        for i in range(len(predictions)):
            predictions[i] = predictions[i][1]

        return predictions

    @QtCore.pyqtSlot(str, result=list)
    def traverse(self, url):
        filenames = []
        for format in VID_FORMATS:
            for filename in glob.iglob(url[7:] + f"/**/*.{format}", recursive=True):
                filenames.append('file://' + filename)
        return filenames

    @QtCore.pyqtProperty(bool)
    def QtMultimedia(self):
        try:
            from PyQt5 import QtMultimedia
            return True
        except ImportError as e:
            return False

    @QtCore.pyqtSlot(str, str)
    def makeThumbnail(self, video_url, image_path):
        return make_thumbnail(video_url[7:], 'temp/' + image_path)


app = QApplication(["Silver"])
app.setOrganizationName("K")
app.setOrganizationDomain("K")

view = QQmlApplicationEngine()
url = QUrl("src/qml/main.qml")

g = App()
context = view.rootContext()
context.setContextProperty("g", g)

view.load(url)


app.exec()
