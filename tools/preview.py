#!/usr/bin/env python3
"""Runs the Meniscus QML without a compositor.

KWin, Kirigami and Milou are replaced by small stand-ins (tools/mock), a
wallpaper and a few fake windows play the desktop, and a scene script from
tools/preview/scenes drives the UI and saves frames to preview/out.

    python tools/preview.py palette --theme tide --set Frost=10

Needs PySide6 and, for --sheet, Pillow.
"""

from __future__ import annotations

import argparse
import os
import sys
import uuid
import xml.etree.ElementTree as ET
from enum import IntEnum, IntFlag
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
UI = ROOT / "package" / "effects" / "meniscus" / "contents" / "ui"
MOCK = ROOT / "tools" / "mock"
SCENES = ROOT / "tools" / "preview" / "scenes"

# The shaders are baked for GLSL only.
os.environ.setdefault("QSG_RHI_BACKEND", "opengl")
os.environ.setdefault("QT_QUICK_CONTROLS_STYLE", "Basic")
# One scene pixel per frame pixel, whatever the display scale is.
os.environ.setdefault("QT_ENABLE_HIGHDPI_SCALING", "0")
# console.log from QML; without a console window Windows would send it to the debugger instead.
os.environ.setdefault("QT_FORCE_STDERR_LOGGING", "1")

from PySide6.QtCore import (  # noqa: E402
    Property, QAbstractListModel, QCoreApplication, QEvent, QModelIndex, QObject, QPointF,
    QRectF, QSortFilterProxyModel, QTimer, QUrl, Qt, Signal, Slot, QEnum, QFlag,
)
from PySide6.QtGui import QFocusEvent, QGuiApplication, QKeyEvent, QMouseEvent  # noqa: E402
from PySide6.QtQml import (  # noqa: E402
    QmlAnonymous, QmlAttached, QmlElement, QQmlComponent, QQmlPropertyMap,
    qmlRegisterSingletonInstance, qmlRegisterSingletonType, qmlRegisterType,
)
from PySide6.QtQuick import QQuickView  # noqa: E402

QML_IMPORT_NAME = "org.kde.kwin"
QML_IMPORT_MAJOR_VERSION = 1


def declare(namespace, name, kind, default=None):
    """Adds a notifying read-write property to the class being defined."""
    changed = Signal()

    def read(self):
        return self._values.get(name, default)

    def write(self, value):
        if self._values.get(name, default) != value:
            self._values[name] = value
            getattr(self, name + "Changed").emit()

    namespace[name + "Changed"] = changed
    namespace[name] = Property(kind, read, write, notify=changed)


class Thing(QObject):
    def __init__(self, parent=None, **values):
        super().__init__(parent)
        self._values = dict(values)


class Desktop(Thing):
    declare(locals(), "id", str, "")
    declare(locals(), "name", str, "")
    declare(locals(), "x11DesktopNumber", int, 1)


class Output(Thing):
    declare(locals(), "name", str, "MOCK-1")
    declare(locals(), "geometry", QRectF, QRectF())
    declare(locals(), "devicePixelRatio", float, 1.0)


class Window(Thing):
    closed = Signal()
    frameGeometryChanged = Signal(QRectF)
    maximizedChanged = Signal()

    for _name, _kind, _default in (
        ("internalId", str, ""), ("caption", str, ""), ("resourceClass", str, ""),
        ("resourceName", str, ""), ("desktopFileName", str, ""), ("icon", str, ""),
        ("noBorder", bool, False), ("fullScreen", bool, False), ("minimized", bool, False),
        ("keepAbove", bool, False), ("keepBelow", bool, False), ("onAllDesktops", bool, False),
        ("active", bool, False), ("hidden", bool, False), ("deleted", bool, False),
        ("normalWindow", bool, True), ("dialog", bool, False), ("dock", bool, False),
        ("desktopWindow", bool, False), ("popupWindow", bool, False), ("splash", bool, False),
        ("utility", bool, False), ("notification", bool, False), ("transient", bool, False),
        ("managed", bool, True), ("moveable", bool, True), ("resizeable", bool, True),
        ("closeable", bool, True), ("maximizable", bool, True), ("minimizable", bool, True),
        ("skipSwitcher", bool, False), ("skipTaskbar", bool, False), ("stackingOrder", int, 0),
        ("maximizeMode", int, 0), ("opacity", float, 1.0), ("pid", int, 0),
        ("desktops", "QVariantList", ()), ("output", QObject, None), ("tile", QObject, None),
        ("transientFor", QObject, None), ("mockKind", str, "document"), ("mockColor", str, "#3b82f6"),
    ):
        declare(locals(), _name, _kind, _default)

    def _geometry(self):
        return self._values.get("frameGeometry", QRectF())

    def _set_geometry(self, rect):
        old = self._geometry()
        rect = QRectF(rect)
        if rect != old:
            self._values["frameGeometry"] = rect
            self.frameGeometryChanged.emit(old)

    frameGeometry = Property(QRectF, _geometry, _set_geometry, notify=frameGeometryChanged)
    clientGeometry = Property(QRectF, _geometry, notify=frameGeometryChanged)
    x = Property(float, lambda self: self._geometry().x(), notify=frameGeometryChanged)
    y = Property(float, lambda self: self._geometry().y(), notify=frameGeometryChanged)
    width = Property(float, lambda self: self._geometry().width(), notify=frameGeometryChanged)
    height = Property(float, lambda self: self._geometry().height(), notify=frameGeometryChanged)

    @Slot()
    def closeWindow(self):
        self.parent().mockClose(self)

    @Slot(bool, bool)
    def setMaximize(self, vertically, horizontally):
        workspace = self.parent()
        if vertically and horizontally:
            self._values.setdefault("restore", self._geometry())
            self.frameGeometry = workspace.clientArea(Workspace.ClientAreaOption.MaximizeArea, self)
            self.maximizeMode = 3
        else:
            self.frameGeometry = self._values.pop("restore", self._geometry())
            self.maximizeMode = 0
        self.maximizedChanged.emit()


class Workspace(Thing):
    """The few parts of KWin's Workspace that Meniscus talks to."""

    @QEnum
    class ClientAreaOption(IntEnum):
        PlacementArea = 0
        MovementArea = 1
        MaximizeArea = 2
        MaximizeFullArea = 3
        FullScreenArea = 4
        WorkArea = 5
        FullArea = 6
        ScreenArea = 7

    windowAdded = Signal(QObject)
    windowRemoved = Signal(QObject)
    windowActivated = Signal(QObject)
    currentDesktopChanged = Signal(QObject)
    desktopsChanged = Signal()
    windowsChanged = Signal()
    mockLog = Signal(str)
    mockShortcut = Signal(str)      # kglobalaccel firing a sequence: the ShortcutHandler stand-ins
    mockEdge = Signal(int)          # the pointer pushed into a screen edge or corner

    declare(locals(), "currentActivity", str, "")
    declare(locals(), "cursorPos", QPointF, QPointF())
    declare(locals(), "mockWallpaper", QUrl, QUrl())
    declare(locals(), "mockPanel", float, 0.0)     # height reserved by a bottom panel

    def __init__(self, width, height, config):
        super().__init__()
        self._config = config
        self._screen = Output(self, geometry=QRectF(0, 0, width, height))
        self._desktops = []
        self._windows = []
        self._current = None
        self._active = None
        self._serial = 0
        for name in ("Work", "Code", "Create", "Browse", "Play"):
            self.createDesktop(len(self._desktops), name)
        self._current = self._desktops[0]

    # ---- properties -------------------------------------------------------
    mockConfig = Property(QObject, lambda self: self._config, constant=True)
    desktops = Property("QVariantList", lambda self: list(self._desktops), notify=desktopsChanged)
    windows = Property("QVariantList", lambda self: list(self._windows), notify=windowsChanged)
    stackingOrder = Property(
        "QVariantList", lambda self: sorted(self._windows, key=lambda w: w.stackingOrder),
        notify=windowsChanged)
    screens = Property("QVariantList", lambda self: [self._screen], constant=True)
    activeScreen = Property(QObject, lambda self: self._screen, constant=True)
    virtualScreenGeometry = Property(QRectF, lambda self: self._screen.geometry, constant=True)
    virtualScreenSize = Property("QSizeF", lambda self: self._screen.geometry.size(), constant=True)

    def _set_current(self, desktop):
        if desktop is not None and desktop is not self._current:
            previous, self._current = self._current, desktop
            self.currentDesktopChanged.emit(previous)
            top = [w for w in self.stackingOrder if desktop in w.desktops and not w.dock and not w.minimized]
            self._activate(top[-1] if top else None)

    currentDesktop = Property(QObject, lambda self: self._current, _set_current,
                              notify=currentDesktopChanged)

    def _activate(self, window):
        if window is self._active:
            return
        if self._active is not None:
            self._active.active = False
        self._active = window
        if window is not None:
            window.active = True
            window.minimized = False
            self.raiseWindow(window)
        self.windowActivated.emit(window)

    activeWindow = Property(QObject, lambda self: self._active, _activate, notify=windowActivated)

    # ---- KWin API ---------------------------------------------------------
    @Slot(int, QObject, result=QRectF)
    @Slot(int, QObject, QObject, result=QRectF)
    def clientArea(self, option, target=None, desktop=None):
        area = QRectF(self._screen.geometry)
        if option in (self.ClientAreaOption.PlacementArea, self.ClientAreaOption.MovementArea,
                      self.ClientAreaOption.MaximizeArea, self.ClientAreaOption.WorkArea):
            area.setHeight(area.height() - self.mockPanel)
        return area

    @Slot(QObject)
    def raiseWindow(self, window):
        self._serial += 1
        window.stackingOrder = self._serial
        self.windowsChanged.emit()

    @Slot(int, str)
    def createDesktop(self, position, name):
        desktop = Desktop(self, id=str(uuid.uuid4()), name=name)
        self._desktops.insert(position, desktop)
        for number, each in enumerate(self._desktops, 1):
            each.x11DesktopNumber = number
        self.desktopsChanged.emit()

    @Slot(QObject)
    def removeDesktop(self, desktop):
        if desktop in self._desktops and len(self._desktops) > 1:
            self._desktops.remove(desktop)
            if self._current is desktop:
                self._set_current(self._desktops[0])
            self.desktopsChanged.emit()

    def _step(self, delta):
        index = self._desktops.index(self._current) + delta
        if 0 <= index < len(self._desktops):
            self._set_current(self._desktops[index])

    @Slot()
    def slotSwitchDesktopNext(self):
        self._step(1)

    @Slot()
    def slotSwitchDesktopPrevious(self):
        self._step(-1)

    @Slot()
    def slotWindowClose(self):
        if self._active is not None:
            self._active.closeWindow()

    @Slot(str, result=bool)
    def isEffectActive(self, plugin):
        return False

    @Slot(QPointF, result=QObject)
    def screenAt(self, position):
        return self._screen

    # ---- stand-in only ----------------------------------------------------
    @Slot(str, result=QObject)
    def mockWindow(self, internal_id):
        for window in self._windows:
            if window.internalId == internal_id:
                return window
        return None

    @Slot(str, result=str)
    def mockIcon(self, name):
        """A picture for an icon name from tools/mock/icons, a local cache kept out of git, or ''."""
        for suffix in (".svg", ".png"):
            path = MOCK / "icons" / f"{name}{suffix}"
            if name and path.is_file():
                return QUrl.fromLocalFile(str(path)).toString()
        return ""

    @Slot(str, str, str, float, float, float, float, result=QObject)
    @Slot(str, str, str, float, float, float, float, int, result=QObject)
    def mockOpen(self, caption, resource_class, kind, x, y, width, height, desktop=-1):
        """Opens a fake window; desktop is an index, -1 the current one."""
        home = self._current if desktop < 0 else self._desktops[desktop]
        dock = kind == "panel"
        colours = {"browser": "#e8eaed", "editor": "#1e1f29", "terminal": "#101418",
                   "files": "#f4f5f7", "player": "#17131f", "panel": "#15171a"}
        window = Window(
            self, internalId=str(uuid.uuid4()), caption=caption, resourceClass=resource_class,
            desktopFileName=resource_class, icon=resource_class, mockKind=kind,
            mockColor=colours.get(kind, "#f1f2f4"), desktops=[] if dock else [home],
            onAllDesktops=dock, dock=dock, normalWindow=not dock, output=self._screen,
            frameGeometry=QRectF(x, y, width, height))
        self._windows.append(window)
        self.raiseWindow(window)
        self.windowAdded.emit(window)
        if not dock and home is self._current:
            self._activate(window)
        return window

    def mockClose(self, window):
        if window not in self._windows:
            return
        self._windows.remove(window)
        window.deleted = True
        window.closed.emit()
        self.windowRemoved.emit(window)
        self.windowsChanged.emit()
        if self._active is window:
            self._active = None
            top = [w for w in self.stackingOrder
                   if self._current in w.desktops and not w.dock and not w.minimized]
            self._activate(top[-1] if top else None)

    @Slot(str)
    def mockSay(self, message):
        print("[mock]", message, flush=True)
        self.mockLog.emit(message)


class WindowModel(QAbstractListModel):
    """Windows in the order they were opened, as in KWin."""

    ROLES = {Qt.DisplayRole: b"display", Qt.UserRole + 1: b"window", Qt.UserRole + 2: b"output",
             Qt.UserRole + 3: b"desktop", Qt.UserRole + 4: b"activity"}

    def __init__(self, parent=None):
        super().__init__(parent)
        self._workspace = WORKSPACE
        self._rows = list(self._workspace._windows)
        self._workspace.windowAdded.connect(self._added)
        self._workspace.windowRemoved.connect(self._removed)

    def _added(self, window):
        self.beginInsertRows(QModelIndex(), len(self._rows), len(self._rows))
        self._rows.append(window)
        self.endInsertRows()

    def _removed(self, window):
        if window in self._rows:
            row = self._rows.index(window)
            self.beginRemoveRows(QModelIndex(), row, row)
            del self._rows[row]
            self.endRemoveRows()

    def roleNames(self):
        return self.ROLES

    def rowCount(self, parent=QModelIndex()):
        return 0 if parent.isValid() else len(self._rows)

    def data(self, index, role=Qt.DisplayRole):
        if not index.isValid() or index.row() >= len(self._rows):
            return None
        window = self._rows[index.row()]
        name = self.ROLES.get(role)
        if name == b"display":
            return window.caption
        if name == b"window":
            return window
        if name == b"output":
            return window.output
        return None


class WindowFilterModel(QSortFilterProxyModel):
    @QFlag
    class WindowType(IntFlag):
        Normal = 0x1
        Dialog = 0x2
        Dock = 0x4
        Desktop = 0x8
        Notification = 0x10
        CriticalNotification = 0x20

    changed = Signal()

    def __init__(self, parent=None):
        super().__init__(parent)
        self._values = {"windowModel": None, "activity": "", "desktop": None, "filter": "",
                        "screenName": "", "windowType": 0x3f, "minimizedWindows": True}
        self.changed.connect(self.invalidate)
        WORKSPACE.windowsChanged.connect(self.invalidate)
        WORKSPACE.windowAdded.connect(self._watch)

    def _watch(self, window):
        window.desktopsChanged.connect(self.invalidate)
        window.minimizedChanged.connect(self.invalidate)

    def _put(self, key, value):
        if self._values[key] != value:
            self._values[key] = value
            if key == "windowModel":
                self.setSourceModel(value)
                for window in WORKSPACE._windows:
                    self._watch(window)
            self.changed.emit()

    windowModel = Property(QObject, lambda s: s._values["windowModel"],
                           lambda s, v: s._put("windowModel", v), notify=changed)
    activity = Property(str, lambda s: s._values["activity"],
                        lambda s, v: s._put("activity", v), notify=changed)
    desktop = Property(QObject, lambda s: s._values["desktop"],
                       lambda s, v: s._put("desktop", v), notify=changed)
    filter = Property(str, lambda s: s._values["filter"],
                      lambda s, v: s._put("filter", v), notify=changed)
    screenName = Property(str, lambda s: s._values["screenName"],
                          lambda s, v: s._put("screenName", v), notify=changed)
    windowType = Property(int, lambda s: s._values["windowType"],
                          lambda s, v: s._put("windowType", v), notify=changed)
    minimizedWindows = Property(bool, lambda s: s._values["minimizedWindows"],
                                lambda s, v: s._put("minimizedWindows", v), notify=changed)

    def filterAcceptsRow(self, row, parent):
        source = self.sourceModel()
        if source is None:
            return False
        window = source._rows[row]
        values = self._values
        kind = 0x4 if window.dock else 0x2 if window.dialog else 0x8 if window.desktopWindow else 0x1
        if not values["windowType"] & kind:
            return False
        if values["desktop"] is not None and not window.onAllDesktops \
                and values["desktop"] not in window.desktops:
            return False
        if window.minimized and not values["minimizedWindows"]:
            return False
        needle = values["filter"].lower()
        return not needle or needle in window.caption.lower() or needle in window.resourceClass.lower()


class VirtualDesktopModel(QAbstractListModel):
    def __init__(self, parent=None):
        super().__init__(parent)
        WORKSPACE.desktopsChanged.connect(self._reset)

    def _reset(self):
        self.beginResetModel()
        self.endResetModel()

    def roleNames(self):
        return {Qt.DisplayRole: b"display", Qt.UserRole + 1: b"desktop"}

    def rowCount(self, parent=QModelIndex()):
        return 0 if parent.isValid() else len(WORKSPACE._desktops)

    def data(self, index, role=Qt.DisplayRole):
        if not index.isValid() or index.row() >= len(WORKSPACE._desktops):
            return None
        desktop = WORKSPACE._desktops[index.row()]
        return desktop.name if role == Qt.DisplayRole else desktop


@QmlAnonymous
class SceneViewAttached(QObject):
    screen = Property(QObject, lambda self: WORKSPACE._screen, constant=True)
    rootItem = Property(QObject, lambda self: HARNESS.view.contentItem(), constant=True)
    effect = Property(QObject, lambda self: HARNESS.view.rootObject(), constant=True)


@QmlElement
@QmlAttached(SceneViewAttached)
class SceneView(QObject):
    @staticmethod
    def qmlAttachedProperties(self, target):
        return SceneViewAttached(target)


APPS = (
    ("Firefox", "Web Browser", "firefox"), ("Files", "File Manager", "org.kde.dolphin"),
    ("Konsole", "Terminal", "org.kde.konsole"), ("Kate", "Advanced Text Editor", "org.kde.kate"),
    ("Steam", "Application for managing and playing games", "steam"),
    ("System Settings", "Configure your computer", "systemsettings"),
    ("Krita", "Digital Painting", "org.kde.krita"), ("Elisa", "Music Player", "org.kde.elisa"),
    ("Bazaar", "App store", "io.github.kolunmi.Bazaar"), ("Spectacle", "Screenshots", "org.kde.spectacle"),
    ("Lutris", "Game launcher", "lutris"), ("Okular", "Document Viewer", "org.kde.okular"),
    ("Blender", "3D modelling", "blender"), ("Inkscape", "Vector Graphics Editor", "org.inkscape.Inkscape"),
    ("Thunderbird", "Mail Client", "thunderbird"), ("OBS Studio", "Streaming and recording", "com.obsproject.Studio"),
)


class ResultsModel(QAbstractListModel):
    """org.kde.milou's results: here a fixed list of applications."""

    ROLES = {Qt.DisplayRole: b"display", Qt.DecorationRole: b"decoration",
             Qt.UserRole + 1: b"category", Qt.UserRole + 2: b"subtext", Qt.UserRole + 3: b"matchId",
             Qt.UserRole + 4: b"urls"}
    changed = Signal()

    def __init__(self, parent=None):
        super().__init__(parent)
        self._query = ""
        self._limit = 0
        self._rows = []

    def _search(self, query):
        if query == self._query:
            return
        self._query = query
        needle = query.strip().lower()
        rows = [app for app in APPS if needle and (needle in app[0].lower() or needle in app[1].lower())]
        rows.sort(key=lambda app: (not app[0].lower().startswith(needle), app[0]))
        self.beginResetModel()
        self._rows = rows[:self._limit] if self._limit else rows
        self.endResetModel()
        self.changed.emit()

    def _limit_to(self, limit):
        self._limit = limit

    queryString = Property(str, lambda self: self._query, _search, notify=changed)
    limit = Property(int, lambda self: self._limit, _limit_to, notify=changed)
    querying = Property(bool, lambda self: False, notify=changed)

    def roleNames(self):
        return self.ROLES

    def rowCount(self, parent=QModelIndex()):
        return 0 if parent.isValid() else len(self._rows)

    def data(self, index, role=Qt.DisplayRole):
        if not index.isValid() or index.row() >= len(self._rows):
            return None
        name, subtext, icon = self._rows[index.row()]
        return {b"display": name, b"decoration": icon, b"category": "Applications",
                b"subtext": subtext, b"matchId": icon,
                b"urls": [f"file:///usr/share/applications/{icon}.desktop"]}.get(self.ROLES.get(role))

    @Slot(QModelIndex, result=bool)
    def run(self, index):
        if not index.isValid():
            return False
        name, _, icon = self._rows[index.row()]
        WORKSPACE.mockSay(f"launch {name}")
        kind = {"firefox": "browser", "org.kde.dolphin": "files", "org.kde.konsole": "terminal",
                "org.kde.kate": "editor", "org.kde.elisa": "player"}.get(icon, "document")
        area = WORKSPACE._screen.geometry
        QTimer.singleShot(250, lambda: WORKSPACE.mockOpen(
            name, icon, kind, area.width() * 0.2, area.height() * 0.16,
            area.width() * 0.6, area.height() * 0.62))
        return True

    @Slot()
    def clear(self):
        self._search("")


class Harness(QObject):
    """What a scene script can do: press keys, move the pointer, save frames."""

    def __init__(self, view, out, sheet):
        super().__init__()
        self.view = view
        self.out = out
        self.sheet = sheet
        self.frames = []
        self.status = 0

    @Slot(str)
    def shot(self, name):
        path = self.out / f"{name}.png"
        if not self.view.grabWindow().save(str(path)):
            print(f"could not save {path}", flush=True)
            self.status = 1
            return
        self.frames.append(path)
        print(f"shot {path.relative_to(ROOT).as_posix()}", flush=True)

    def _key(self, kinds, key, modifiers, text):
        for kind in kinds:
            QCoreApplication.sendEvent(self.view, QKeyEvent(kind, key, Qt.KeyboardModifier(modifiers), text))

    def _named(self, kinds, name, modifiers):
        if len(name) == 1:
            self._key(kinds, ord(name.upper()), modifiers, name if not modifiers else "")
        else:
            self._key(kinds, getattr(Qt.Key, "Key_" + name).value, modifiers, "")

    @Slot(str)
    @Slot(str, int)
    def key(self, name, modifiers=0):
        """A named key such as Down, Return, Escape, Tab, Super_L, or one character."""
        self._named((QEvent.KeyPress, QEvent.KeyRelease), name, modifiers)

    @Slot(str)
    @Slot(str, int)
    def keyDown(self, name, modifiers=0):
        self._named((QEvent.KeyPress,), name, modifiers)

    @Slot(str)
    @Slot(str, int)
    def keyUp(self, name, modifiers=0):
        self._named((QEvent.KeyRelease,), name, modifiers)

    @Slot(str)
    @Slot(str, int)
    def shortcut(self, sequence, repeats=0):
        """A global shortcut as kglobalaccel fires it: once, then once per auto-repeat."""
        for _ in range(repeats + 1):
            WORKSPACE.mockShortcut.emit(sequence)

    @Slot(int)
    def corner(self, edge):
        WORKSPACE.mockEdge.emit(edge)

    @Slot(str)
    def type(self, text):
        for character in text:
            self._key((QEvent.KeyPress, QEvent.KeyRelease),
                      Qt.Key.Key_Space.value if character == " " else ord(character.upper()), 0, character)

    def _mouse(self, kind, x, y, button, buttons):
        position = QPointF(x, y)
        QCoreApplication.sendEvent(self.view, QMouseEvent(
            kind, position, self.view.mapToGlobal(position), button, buttons, Qt.NoModifier))
        WORKSPACE.cursorPos = position

    @Slot(float, float)
    def move(self, x, y):
        self._mouse(QEvent.MouseMove, x, y, Qt.NoButton, Qt.NoButton)

    @Slot(float, float)
    def press(self, x, y):
        self._mouse(QEvent.MouseButtonPress, x, y, Qt.LeftButton, Qt.LeftButton)

    @Slot(float, float)
    def drag(self, x, y):
        self._mouse(QEvent.MouseMove, x, y, Qt.NoButton, Qt.LeftButton)

    @Slot(float, float)
    def release(self, x, y):
        self._mouse(QEvent.MouseButtonRelease, x, y, Qt.LeftButton, Qt.NoButton)

    @Slot(float, float)
    def click(self, x, y):
        self.move(x, y)
        self.press(x, y)
        self.release(x, y)

    @Slot(str)
    def fail(self, message):
        print("FAIL", message, flush=True)
        self.status = 1

    @Slot()
    def done(self):
        if self.sheet and self.frames:
            make_sheet(self.frames, self.out / f"{self.sheet}.jpg")
        QCoreApplication.exit(self.status)


def make_sheet(frames, path, columns=3, cell=800):
    from PIL import Image, ImageDraw

    images = [Image.open(frame).convert("RGB") for frame in frames]
    width, height = images[0].size
    scale = cell / width
    size = (cell, round(height * scale))
    rows = -(-len(images) // columns)
    sheet = Image.new("RGB", (columns * size[0], rows * size[1]), "#000000")
    draw = ImageDraw.Draw(sheet)
    for index, image in enumerate(images):
        left, top = index % columns * size[0], index // columns * size[1]
        sheet.paste(image.resize(size, Image.LANCZOS), (left, top))
        draw.text((left + 8, top + 6), frames[index].stem, fill="#ffffff", stroke_width=2, stroke_fill="#000000")
    sheet.save(path, quality=88)
    print(f"sheet {path.relative_to(ROOT).as_posix()}", flush=True)


def make_config(values):
    """The effect's configuration as KWin hands it to the QML: a property per key and writeConfig."""
    def writeConfig(self):
        WORKSPACE.mockSay("writeConfig")

    namespace = {"writeConfig": Slot()(writeConfig)}
    for key, value in values.items():
        declare(namespace, key, type(value), value)
    return type("Config", (Thing,), namespace)(**values)


def read_config(overrides):
    """Defaults from the effect's kcfg, as KWin would hand them to the QML."""
    space = {"k": "http://www.kde.org/standards/kcfg/1.0"}
    values = {}
    for entry in ET.parse(UI.parent / "config" / "main.xml").getroot().iterfind(".//k:entry", space):
        default = entry.findtext("k:default", "", space)
        kind = entry.get("type")
        values[entry.get("name")] = (default == "true" if kind == "Bool"
                                     else int(default) if kind in ("Int", "UInt") else default)
    for item in overrides:
        key, _, value = item.partition("=")
        if key not in values:
            sys.exit(f"unknown setting {key}; known: {', '.join(values)}")
        known = values[key]
        values[key] = (value.lower() in ("1", "true", "yes", "on") if isinstance(known, bool)
                       else int(value) if isinstance(known, int) else value)
    return values


def main():
    parser = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    parser.add_argument("scene", help="script in tools/preview/scenes, without .qml")
    parser.add_argument("--root", default=str(UI / "main.qml"), help="QML shown in the window")
    parser.add_argument("--size", default="1600x900")
    parser.add_argument("--theme", help="shorthand for --set Theme=<id>")
    parser.add_argument("--set", action="append", default=[], metavar="Key=Value")
    parser.add_argument("--out", default=str(ROOT / "preview" / "out"))
    parser.add_argument("--sheet", metavar="NAME", help="also tile all frames into NAME.jpg")
    parser.add_argument("--keep", action="store_true", help="leave the window open afterwards")
    options = parser.parse_args()

    global WORKSPACE, HARNESS
    width, height = (int(part) for part in options.size.lower().split("x"))
    overrides = list(options.set) + ([f"Theme={options.theme}"] if options.theme else [])
    values = read_config(overrides)

    app = QGuiApplication(sys.argv[:1])
    config = make_config(values)

    WORKSPACE = Workspace(width, height, config)
    theme = values["Theme"] if values["Theme"] != "system" else "amethyst"
    WORKSPACE.mockWallpaper = QUrl.fromLocalFile(str(ROOT / "themes" / "wallpapers" / f"{theme}.jpg"))

    def follow_theme():
        if config.Theme != "system":
            WORKSPACE.mockWallpaper = QUrl.fromLocalFile(str(ROOT / "themes" / "wallpapers" / f"{config.Theme}.jpg"))

    config.ThemeChanged.connect(follow_theme)

    qmlRegisterSingletonInstance(Workspace, "org.kde.kwin", 1, 0, "Workspace", WORKSPACE)
    qmlRegisterType(WindowModel, "org.kde.kwin", 1, 0, "WindowModel")
    qmlRegisterType(WindowFilterModel, "org.kde.kwin", 1, 0, "WindowFilterModel")
    qmlRegisterType(VirtualDesktopModel, "org.kde.kwin", 1, 0, "VirtualDesktopModel")
    qmlRegisterType(ResultsModel, "org.kde.milou", 1, 0, "ResultsModel")
    for module, names in (("kwin", ("SceneEffect", "DesktopBackground", "WindowThumbnail",
                                    "ShortcutHandler", "ScreenEdgeHandler", "DBusCall")),
                          ("kirigami", ("Icon",))):
        for name in names:
            qmlRegisterType(QUrl.fromLocalFile(str(MOCK / module / f"{name}.qml")),
                            f"org.kde.{module}", 1, 0, name)
    for name in ("Theme", "Units"):
        qmlRegisterSingletonType(QUrl.fromLocalFile(str(MOCK / "kirigami" / f"{name}.qml")),
                                 "org.kde.kirigami", 1, 0, name)

    out = Path(options.out).resolve()
    out.mkdir(parents=True, exist_ok=True)
    view = QQuickView()
    HARNESS = Harness(view, out, options.sheet)
    view.setResizeMode(QQuickView.SizeRootObjectToView)
    view.setColor("#000000")
    view.resize(width, height)
    view.setPosition(0, 0)
    if not options.keep:
        # A frame would clamp it to the screen; the real pointer must not hover the scene.
        view.setFlags(Qt.FramelessWindowHint | Qt.WindowTransparentForInput)
    view.setTitle("Meniscus preview")
    view.rootContext().setContextProperty("harness", HARNESS)
    seen = set()

    def report(warnings):
        for warning in warnings:
            text = warning.toString()
            if text not in seen:        # a broken binding repeats for every instance
                seen.add(text)
                print("QML", text, flush=True)

    view.engine().setOutputWarningsToStandardError(False)
    view.engine().warnings.connect(report)
    view.setSource(QUrl.fromLocalFile(str(Path(options.root).resolve())))
    if view.status() != QQuickView.Ready:
        for error in view.errors():
            print("QML", error.toString(), flush=True)
        return 1
    view.show()
    # Keys reach the scene only once the window believes it has focus.
    QCoreApplication.sendEvent(view, QFocusEvent(QEvent.FocusIn, Qt.ActiveWindowFocusReason))

    script = QQmlComponent(view.engine(), QUrl.fromLocalFile(str(SCENES / f"{options.scene}.qml")))
    runner = script.createWithInitialProperties({"effect": view.rootObject(), "keep": options.keep})
    if runner is None:
        for error in script.errors():
            print("QML", error.toString(), flush=True)
        return 1
    runner.setParent(view.rootObject())
    status = app.exec()
    view.setSource(QUrl())      # take the QML down while the stand-ins still exist
    return status


WORKSPACE = None
HARNESS = None

if __name__ == "__main__":
    sys.exit(main())
