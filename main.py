from PyQt5.QtWidgets import QApplication
from PyQt5.QtQml import QQmlApplicationEngine
from PyQt5.QtCore import QUrl, QObject, pyqtSignal, QThreadPool, QRunnable
from PyQt5 import QtCore
from predict import VID_FORMATS, predict, labels, CLASSIFIER
import math
import glob
import os
import csv
import cv2 as cv
import numpy as np
import time

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

PREDICTOR_EXIT = False

class Predictor(QRunnable):
    def __init__(self, urls, doDump, fileName, step, output, progress):
        super().__init__()
        self.urls = urls
        self.doDump = doDump
        self.fileName = fileName
        self.output = output
        self.step = step
        self.progress = progress

    @QtCore.pyqtSlot()
    def run(self):
        global PREDICTOR_EXIT, labels
        predictions = []
        i = 0
        beg = time.time()
        passed = 0
        for url in self.urls:
            try:
                predictions.append(predict(url[7:], step=self.step))
            except Exception as e:
                predictions.append((-1, -1))

            if PREDICTOR_EXIT:
                PREDICTOR_EXIT = False
                return

            i += 1
            passed = time.time() - beg
            if i > 1:
                k = 0.7 + (float(i) / float(len(self.urls))) * 0.3
                leftSecs = int(round(((passed / i) * (len(self.urls) - i))) * k + leftSecs * (1 - k))
            else:
                leftSecs = int(round(0.8 * (passed / i) * (len(self.urls) - i)))

            leftText = ""
            if leftSecs < 90:
                leftText = f"{leftSecs} seconds left"
            else:
                leftText = f"{leftSecs//60} minutes left"

            self.progress.emit(float(i) / float(len(self.urls)), leftText)

        if self.doDump:
            with open(self.fileName, 'w', encoding='UTF8') as f:
                writer = csv.writer(f)
                writer.writerow(['path', 'label', 'label_txt'])

                for url, pred in zip(self.urls, predictions):
                    writer.writerow([url, pred[0], pred[1]])
                    if PREDICTOR_EXIT:
                        PREDICTOR_EXIT = False
                        return

        for i in range(len(predictions)):
            predictions[i] = predictions[i][1]
            if PREDICTOR_EXIT:
                PREDICTOR_EXIT = False
                return

        if PREDICTOR_EXIT:
            PREDICTOR_EXIT = False
            return

        self.output.emit(predictions)

class Labeler(QRunnable):
    def __init__(self, name, path, prg, out):
        super().__init__()
        self.name = name
        self.urls = traverse_folder(path)
        self.progress = prg
        self.output = out

    @QtCore.pyqtSlot()
    def run(self):
        global PREDICTOR_EXIT
        predictions = []
        i = 0
        beg = time.time()
        passed = 0
        for url in self.urls:
            try:
                predictions.append(predict(url[7:], step=8))
            except Exception as e:
                predictions.append((-1, -1))

            if PREDICTOR_EXIT:
                PREDICTOR_EXIT = False
                return

            i += 1
            passed = time.time() - beg
            if i > 1:
                k = 0.7 + (float(i) / float(len(self.urls))) * 0.3
                leftSecs = int(round(((passed / i) * (len(self.urls) - i))) * k + leftSecs * (1 - k))
            else:
                leftSecs = int(round(0.8 * (passed / i) * (len(self.urls) - i)))

            leftText = ""
            if leftSecs < 90:
                leftText = f"{leftSecs} seconds left"
            else:
                leftText = f"{leftSecs//60} minutes left"

            self.progress.emit(float(i) / float(len(self.urls)), leftText)

        for i in range(len(predictions)):
            predictions[i] = predictions[i][1]
            if PREDICTOR_EXIT:
                PREDICTOR_EXIT = False
                return

        if PREDICTOR_EXIT:
            PREDICTOR_EXIT = False
            return

        labels.append(self.name)
        global CLASSIFIER
        counts = {i:predictions.count(i) for i in predictions}
        for i in range(len(labels)):
            if labels[i] in counts.keys() and i <= 50:
                p = float(counts[labels[i]]) / len(self.urls)
                pp = p / (len(CLASSIFIER[labels[i]].keys()) + 1)
                for key in CLASSIFIER[labels[i]].keys():
                    CLASSIFIER[labels[i]][key] *= (1 - pp)
                CLASSIFIER[labels[i]][labels[len(labels) - 1]] = pp

        #print(labels)
        #print(CLASSIFIER)
        self.output.emit([])

def traverse_folder(url):
    filenames = []
    for format in VID_FORMATS:
        for filename in glob.iglob(url[7:] + f"/**/*.{format}", recursive=True):
            filenames.append('file://' + filename)
    return filenames

class App(QObject):
    def __init__(self):
        super().__init__()
        self.threadpool = QThreadPool()

        self.labelFileName = "labels.txt"
        self.setFileName = "set.npy"
        self.modelFileName = "lstm.onnx"

    finished = pyqtSignal(list, arguments=['results'])
    progress = pyqtSignal([float, str], arguments=['fraction', 'timeLeftText'])

    @QtCore.pyqtSlot(str, result=bool)
    def correctSetFolder(self, path):
        labelFileExists = False
        setFileExists = False

        for filename in glob.glob(f"sets/{path}/*"):
            name = filename.split("/")[-1]
            if name == self.labelFileName:
                labelFileExists = True

            if name == self.setFileName:
                setFileExists = True

        return setFileExists and labelFileExists

    @QtCore.pyqtSlot(str, str)
    def addLabel(self, labelName, imagesFolder):
        self.progress.emit(0.04, "")
        labeler = Labeler(labelName, imagesFolder, self.progress, self.finished)
        self.threadpool.start(labeler)

    @QtCore.pyqtSlot(float, float, result=int)
    def estimatedProcessingTime(self, framesN, perf):
        self.step = int(round(perf + 0.1 * (perf ** 2)))
        return int(round(framesN * (0.001 + 0.1 / self.step)))

    @QtCore.pyqtSlot(str)
    def output(self, s):
        print("gotcha:" + s)

    @QtCore.pyqtSlot(result=str)
    def labelsSize(self):
        global labels
        return str(len(labels))

    @QtCore.pyqtSlot(list, bool, str)
    def process(self, urls, doDump, fileName):
        self.progress.emit(0, "Processing begins")

        predictor = Predictor(urls, doDump, fileName, self.step, self.finished, self.progress)
        self.threadpool.start(predictor)

    @QtCore.pyqtSlot()
    def stopProcessing(self):
        PREDICTOR_EXIT = True

    @QtCore.pyqtSlot(str, result=list)
    def traverse(self, url):
        return traverse_folder(url)

    @QtCore.pyqtProperty(bool)
    def QtMultimedia(self):
        return False
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
