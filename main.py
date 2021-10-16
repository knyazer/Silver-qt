from PyQt5.QtWidgets import QApplication
from PyQt5.QtQml import QQmlApplicationEngine
from PyQt5.QtCore import QUrl, QObject, pyqtSignal, QThreadPool, QRunnable
from PyQt5 import QtCore, QtGui
from predict import VID_FORMATS, predict, labels, CLASSIFIER
import math
import glob
import os
import platform
import csv
import cv2 as cv
import numpy as np
import time
import io

CAMERA_INDEX = 0

try:
    print("try to init camera")
    with io.open("camera.txt", mode="r", encoding="utf-8") as f:
        s = f.read()
    print(s)
    CAMERA_INDEX = int(s)
except Exception as e:
    CAMERA_INDEX = 0

os.environ["QT_QUICK_CONTROLS_STYLE"] = "Material"

WINDOWS = (platform.system() == "Windows")

def make_thumbnail(inp):
    cap = cv.VideoCapture(inp)
    _, img = cap.read()
    if _ == False:
        img = np.zeros((100, 100, 3), dtype=np.uint8)
    else:
        f = 480.0 / max(img.shape[0], img.shape[1])
        img = cv.resize(img, None, fx=f, fy=f)

    cv.imwrite("temp/thumbnail0.jpg", img)
    cv.imwrite("temp/thumbnail1.jpg", img)
    cap.release()

PREDICTOR_EXIT = False

class Predictor(QRunnable):
    def __init__(self, urls, doDump, fileName, step, output, progress, padding=True):
        super().__init__()
        self.urls = urls
        self.doDump = doDump
        self.fileName = fileName
        self.output = output
        self.step = step
        self.progress = progress
        self.ignorePadding = not padding

    @QtCore.pyqtSlot()
    def run(self):
        global PREDICTOR_EXIT, labels, PREV_FINISHED
        PREV_FINISHED = False
        predictions = []
        i = 0
        beg = time.time()
        passed = 0
        for url in self.urls:
            if not self.ignorePadding:
                if WINDOWS:
                    url = url[8:]
                else:
                    url = url[7:]

            if url[1] == ":":
                url = url[0] + url[1] + "\\" + url[3:]
                print(url)

            predictions.append(predict(url, step=self.step))

            if PREDICTOR_EXIT:
                PREDICTOR_EXIT = False
                PREV_FINISHED = True
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
                        PREV_FINISHED = True
                        return

        for i in range(len(predictions)):
            print(predictions[i][0])
            if predictions[i][0] != -1:
                predictions[i] = predictions[i][1]
            else:
                predictions[i] = ""

            if PREDICTOR_EXIT:
                PREDICTOR_EXIT = False
                PREV_FINISHED = True
                return

        if PREDICTOR_EXIT:
            PREDICTOR_EXIT = False
            PREV_FINISHED = True
            return

        PREV_FINISHED = True

        if ASYNC_PROCESS and predictions[0] == "":
            return
        if not ASYNC_PROCESS and self.ignorePadding:
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
            if predictions[i][0] != -1:
                predictions[i] = predictions[i][1]
            else:
                predictions[i] = ""

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


STREAMING = True
ASYNC_PROCESS = False
PREV_FINISHED = True

class Capture(QRunnable):
    def __init__(self, index, signal, thread, finish, progress):
        super().__init__()
        self.index = index
        self.signal = signal
        self.thread = thread
        self.finish = finish
        self.progress = progress

    @QtCore.pyqtSlot()
    def run(self):
        global STREAMING, ASYNC_PROCESS, PREV_FINISHED
        self.cap = cv.VideoCapture(self.index)

        success = True
        count = 0
        vid_num = 0
        out = cv.VideoWriter(f'temp/out_{vid_num}.mp4',cv.VideoWriter_fourcc('M','P','4','V'), 20, (640,480))

        while STREAMING and success:
            success, pic = self.cap.read()
            if pic is None or len(pic) == 0:
                continue

            cv.imwrite("temp/frame0.jpg", pic)
            cv.imwrite("temp/frame1.jpg", pic)

            if ASYNC_PROCESS:
                if count < 70:
                    out.write(pic)
                    count += 1

                if count >= 70 and PREV_FINISHED:
                    out.release()
                    count = 0
                    vid_num += 1
                    out = cv.VideoWriter(f'temp/out_{vid_num}.mp4',cv.VideoWriter_fourcc('M','P','4','V'), 20,(640,480))
                    self.thread.start(Predictor([f'temp/out_{vid_num - 1}.mp4'], False, "", 3, self.finish, self.progress, False))
                    PREV_FINISHED = False


            time.sleep(0.001)
            
            self.signal.emit()

            time.sleep(0.015)

        self.cap.release()

class Thumbnail(QRunnable):
    def __init__(self, url, signal):
        super().__init__()
        self.signal = signal
        self.url = url

    @QtCore.pyqtSlot()
    def run(self):
        global STREAMING
        self.cap = cv.VideoCapture(self.url)

        success = True
        while STREAMING and success:
            for i in range(4):
                success, pic = self.cap.read()
                if not STREAMING or not success:
                    break

            if not STREAMING or not success:
                break

            cv.imwrite("temp/thumbnail0.jpg", pic)
            cv.imwrite("temp/thumbnail1.jpg", pic)

            self.signal.emit()

            cv.waitKey(20)

        self.cap.release()

class App(QObject):
    def __init__(self):
        super().__init__()
        self.threadpool = QThreadPool()
        self.threadpoolProcess = QThreadPool()

        self.labelFileName = "labels.txt"
        self.setFileName = "set.npy"
        self.modelFileName = "lstm.onnx"

    finished = pyqtSignal(list, arguments=['results'])
    progress = pyqtSignal([float, str], arguments=['fraction', 'timeLeftText'])
    imageSync = pyqtSignal()
    thumbnailSync = pyqtSignal()

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
        self.threadpoolProcess.start(labeler)

    @QtCore.pyqtSlot()
    def stream(self):
        global STREAMING, CAMERA_INDEX
        STREAMING = True

        cap = Capture(CAMERA_INDEX, self.imageSync, self.threadpoolProcess, self.finished, self.progress)
        self.threadpool.start(cap)

    @QtCore.pyqtSlot()
    def stopStream(self):
        global STREAMING
        STREAMING = False

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

        predictor = Predictor(urls, doDump, fileName, 5, self.finished, self.progress)
        self.threadpoolProcess.start(predictor)

    @QtCore.pyqtSlot()
    def stopProcessing(self):
        PREDICTOR_EXIT = True

    @QtCore.pyqtSlot(str, result=list)
    def traverse(self, url):
        return traverse_folder(url)

    @QtCore.pyqtSlot(str)
    def makeThumbnail(self, video_url):
        global STREAMING
        STREAMING = True

        gen = Thumbnail(video_url[7:], self.thumbnailSync)
        self.threadpool.start(gen)

    @QtCore.pyqtSlot()
    def asyncProcess(self):
        global ASYNC_PROCESS
        ASYNC_PROCESS = True

    @QtCore.pyqtSlot()
    def stopAsync(self):
        global ASYNC_PROCESS
        ASYNC_PROCESS = False



def close(*args, **kwargs):
    global STREAMING

    STREAMING = False

    print("Close and stop everything")


app = QApplication(["Silver"])
app.setWindowIcon(QtGui.QIcon("src/icons/icon.jpg"))
app.setApplicationName("Silver Translator")
app.setOrganizationName("K")
app.setOrganizationDomain("K")

view = QQmlApplicationEngine()
url = QUrl("src/qml/main.qml")

g = App()
app.aboutToQuit.connect(close)
context = view.rootContext()
context.setContextProperty("g", g)

view.load(url)

app.exec()
