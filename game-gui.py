#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Game Launcher - roller-GUI voor de WINEPREFIX launcher-scripts.

De GUI scant template-scripts/game-launchers/*.sh, koppelt elk script aan zijn
icoon in game-launchers/gameicons/ en toont ze in een horizontale roller.
Een klik op een icoon start de launcher als QProcess; de output stroomt live
naar het status-frame rechts.
"""

import os
import platform
import re
import signal
import subprocess
import time
from pathlib import Path

from PySide6.QtCore import (QEasingCurve, QProcess, QPointF, QRect, QRectF, Qt,
                            QTimer, QVariantAnimation, Signal)
from PySide6.QtGui import (QAction, QColor, QFont, QFontDatabase, QFontMetrics,
                           QIcon, QLinearGradient, QPainter, QPainterPath, QPen,
                           QPixmap, QRadialGradient)
from PySide6.QtWidgets import (QApplication, QCheckBox, QFileDialog,
                               QFrame, QGraphicsObject, QGraphicsScene,
                               QGraphicsView, QGridLayout, QHBoxLayout, QLabel,
                               QLineEdit, QListWidget, QListWidgetItem,
                               QMainWindow, QMessageBox, QPlainTextEdit,
                               QPushButton, QSlider, QSplitter, QTabBar,
                               QVBoxLayout, QWidget)

BASE = Path(__file__).resolve().parent
TEMPLATE_ROOT = Path("/mnt/VG_00/PUBLIC-LIBRARY/PRE-INSTALLED-GAMES/WINEPREFIX/template-scripts")
LAUNCHERS_DIR = TEMPLATE_ROOT / "game-launchers"
LINUXLAUNCHERS = LAUNCHERS_DIR / "LINUXLAUNCHERS"

# Standaard icon-map (nieuwe centrale locatie) met fallback naar template-scripts
ICONS_ROOT_DEFAULT = Path("/mnt/VG_00/PUBLIC-LIBRARY/PICTURES/ICONS/GAMEICONS")
ICONS_DIR = ICONS_ROOT_DEFAULT

APP_VERSION = "1.9.9"
ICONS_CONF_KEY = "ICONS_ROOT"  # key in settings.conf voor gebruikers-icon-map

CARD_W = 200.0
CARD_H = 200.0
NAME_H = 40.0
CARD_CORNER = 18.0
SPACING = 195.0
SCENE_H = 470.0
CARD_Y = SCENE_H / 2.0 - 45.0

STYLE = """
QMainWindow, QWidget { background-color: #171a20; }
QFrame#header { background-color: transparent; }
QMenuBar { background-color: #1e222a; color: #cdd6e0; border-bottom: 1px solid #2a2f3a; }
QMenuBar::item { background: transparent; padding: 5px 10px; border-radius: 6px; }
QMenuBar::item:selected { background-color: #2c333f; }
QMenu { background-color: #1e222a; color: #cdd6e0; border: 1px solid #2a2f3a; }
QMenu::item { padding: 6px 22px; border-radius: 6px; }
QMenu::item:selected { background-color: #35404f; }
QLabel { color: #e8ecf2; }
QLabel#title { font-size: 22px; font-weight: 700; color: #ffffff; letter-spacing: 2px; }
QLabel#subtitle { color: #00ff88; font-size: 13px; font-weight: 600; }
QLabel#panelTitle { font-size: 14px; font-weight: 600; color: #ffffff; }
QFrame#optionsFrame {
    background-color: #1b202a; border-radius: 12px;
}
QCheckBox {
    color: #cdd6e0; font-size: 13px; spacing: 8px;
}
QMessageBox {
    background-color: #1e222a;
}
QMessageBox QLabel {
    color: #f2f5f9; font-size: 14px;
}
QPushButton {
    background-color: #3a4350; color: #ffffff;
    border: 1px solid #556279; border-radius: 6px;
    padding: 7px 18px; font-weight: 600; font-size: 13px;
}
QPushButton:hover { background-color: #48546a; }
QPushButton:pressed { background-color: #2c333f; }
QMessageBox QPushButton:default {
    background-color: #35608c; border-color: #6ba5d8;
}
QListWidget {
    background-color: #101318; color: #dbe0e8; border: 1px solid #2a2f3a;
    border-radius: 8px; padding: 4px;
}
QListWidget::item { padding: 7px 8px; border-radius: 5px; }
QListWidget::item:selected { background-color: #35404f; }
QPlainTextEdit {
    background-color: #0c0e12; color: #b9c4d4; border: 1px solid #2a2f3a;
    border-radius: 8px; padding: 6px; selection-background-color: #004422;
}
QSplitter::handle { background-color: #2a2f3a; }
"""


CONF_PATH = Path.home() / ".config" / "gamelauncher" / "installpaths.conf"
SETTINGS_PATH = Path.home() / ".config" / "gamelauncher" / "settings.conf"
GAMEPAD_STATUS_TOOL = TEMPLATE_ROOT / "tools" / "gamepad-status.sh"


def detect_os_name():
    """Robuuste OS-detectie voor zowel Linux (/etc/os-release) als Windows (platform)."""
    system = platform.system()
    if system == "Windows":
        try:
            win_ver = platform.win32_ver()
            edition = win_ver[2] or "Release"
            version_str = win_ver[0]
            if version_str == "10":
                build = win_ver[1]
                if build:
                    try:
                        build_num = int(build.split(".")[2])
                        if build_num >= 22000:
                            version_str = "11"
                    except (IndexError, ValueError):
                        pass
            return f"Windows {version_str} ({edition})"
        except Exception:
            return "Windows"
    elif system == "Linux":
        os_release = Path("/etc/os-release")
        if os_release.is_file():
            try:
                pretty = ""
                for line in os_release.read_text(encoding="utf-8").splitlines():
                    if line.startswith("PRETTY_NAME="):
                        return line.split("=", 1)[1].strip('"\'')
                    elif line.startswith("NAME=") and not pretty:
                        pretty = line.split("=", 1)[1].strip('"\'')
                if pretty:
                    return pretty
            except Exception:
                pass
        return "Linux"
    elif system == "Darwin":
        return f"macOS {platform.mac_ver()[0]}"
    return f"{system} OS"


def load_paths():
    paths = {}
    if not CONF_PATH.is_file():
        return paths
    try:
        for raw in CONF_PATH.read_text(encoding="utf-8").splitlines():
            raw = raw.strip()
            if not raw or "=" not in raw:
                continue
            key, value = raw.split("=", 1)
            key, value = key.strip(), value.strip()
            value = value.strip("\"'")
            if key.startswith("GAME_DIR_"):
                paths[key[len("GAME_DIR_"):].upper()] = value
    except OSError:
        return paths
    return paths


def save_paths(paths):
    try:
        CONF_PATH.parent.mkdir(parents=True, exist_ok=True)
        lines = [f'GAME_DIR_{k.upper()}="{v}"' for k, v in sorted(paths.items())]
        CONF_PATH.write_text("\n".join(lines) + ("\n" if lines else ""), encoding="utf-8")
    except OSError:
        return False
    return True


def load_settings():
    opts = {}
    if not SETTINGS_PATH.is_file():
        return opts
    try:
        for raw in SETTINGS_PATH.read_text(encoding="utf-8").splitlines():
            raw = raw.strip()
            if not raw or "=" not in raw:
                continue
            key, value = raw.split("=", 1)
            opts[key.strip()] = value.strip().strip("\"'")
    except OSError:
        return opts
    return opts


def save_settings(opts):
    try:
        SETTINGS_PATH.parent.mkdir(parents=True, exist_ok=True)
        lines = [f"{k}={v}" for k, v in sorted(opts.items())]
        SETTINGS_PATH.write_text("\n".join(lines) + ("\n" if lines else ""), encoding="utf-8")
    except OSError:
        return False
    return True


def get_icons_root() -> Path:
    """Haal de geconfigureerde icon-root op uit settings, met fallback naar default."""
    opts = load_settings()
    if ICONS_CONF_KEY in opts and opts[ICONS_CONF_KEY]:
        p = Path(opts[ICONS_CONF_KEY]).expanduser()
        if p.exists():
            return p
    return ICONS_ROOT_DEFAULT


def update_icon_dirs():
    """Update ICONS_DIR op basis van gebruikersconfiguratie."""
    global ICONS_DIR
    root = get_icons_root()
    ICONS_DIR = root


def validate_icon_structure(root: Path) -> tuple[bool, list[str]]:
    """Valideer of de icon-mapstructuur correct is.
    Returns: (is_valid, list_of_errors)"""
    errors = []
    required = {
        "gameicons (root)": root,
        "systems": root / "systems",
        "LINUXLAUNCHERS": root / "LINUXLAUNCHERS",
    }
    for name, path in required.items():
        if not path.exists() or not path.is_dir():
            errors.append(f"Ontbrekende map: {name} ({path})")
    # Check kritieke bestanden
    if not (root / "back.jpg").exists():
        errors.append("Ontbrekend bestand: back.jpg")
    # Check minimaal systeem-iconen
    systems_dir = root / "systems"
    if systems_dir.exists():
        sys_icons = {f.name for f in systems_dir.iterdir() if f.is_file()}
        expected = {"ps2.png", "n64.png", "snes.png", "linux.png", "windows.png"}
        missing = expected - sys_icons
        if missing:
            errors.append(f"Ontbrekende systeem-iconen: {', '.join(sorted(missing))}")
    return len(errors) == 0, errors


def _norm(name):
    return re.sub(r"[^a-z0-9]", "", name.lower())


def _read_launcher_meta(script_path):
    try:
        text = script_path.read_text(encoding="utf-8")
    except OSError:
        return None, None, False
    icon = None
    display = None
    is_native = False
    for line in text.splitlines():
        line = line.strip()
        if line.startswith("export GAME_ICON="):
            m = re.match(r'export\s+GAME_ICON="([^"]*)"', line)
            if m:
                icon = m.group(1)
        elif line.startswith("export GAME_DISPLAY_NAME="):
            m = re.match(r'export\s+GAME_DISPLAY_NAME="([^"]*)"', line)
            if m:
                display = m.group(1)
        elif line.startswith("export GAME_NATIVE="):
            m = re.match(r'export\s+GAME_NATIVE="([^"]*)"', line)
            if m:
                is_native = m.group(1) == "1"
        if icon and display:
            break
    return icon, display, is_native


class Game:
    def __init__(self, key, script_path):
        self.key = key
        self.script = script_path
        self._icon = None
        self._default_dir = None
        self._meta = None

    @property
    def _meta_cached(self):
        if self._meta is None:
            self._meta = _read_launcher_meta(self.script)
        return self._meta

    @property
    def is_native(self):
        return self._meta_cached[2]

    @property
    def default_dir(self):
        if self._default_dir is None:
            self._default_dir = self._extract_default_dir()
        return self._default_dir

    @property
    def stored_dir(self):
        return load_paths().get(self.key.upper())

    def _extract_default_dir(self):
        try:
            text = self.script.read_text(encoding="utf-8")
        except OSError:
            return None
        m = re.search(r'^export\s+GAME_DIR="(.*)"', text, re.MULTILINE)
        return m.group(1) if m else None

    @property
    def display_name(self):
        meta_display = self._meta_cached[1]
        if meta_display:
            return meta_display
        return self._prettify(self.key)

    @staticmethod
    def _prettify(key):
        parts = re.split(r"[-_]", key)
        parts = [p for p in parts if p]
        words = []
        for p in parts:
            sub = re.sub(r"([a-z])([A-Z])", r"\1 \2", p)
            words.extend(w for w in sub.split(" ") if w)
        return " ".join(w[:1].upper() + w[1:] for w in words)

    def pixmap(self):
        if self._icon is not None:
            return self._icon
        icon_file = self._resolve_icon()
        if icon_file and icon_file.suffix.lower() in (".png", ".jpg", ".jpeg", ".webp", ".bmp"):
            pm = QPixmap(str(icon_file))
            if not pm.isNull():
                self._icon = pm
                return pm
        self._icon = _placeholder_pixmap(self.display_name)
        return self._icon

    def _resolve_icon(self):
        meta_icon = self._meta_cached[0]
        if meta_icon:
            cand = ICONS_DIR / meta_icon
            if cand.exists():
                return cand
        if not ICONS_DIR.exists():
            return None
        files = list(ICONS_DIR.iterdir())
        norm_icons = {_norm(f.stem): f for f in files}
        key_norm = _norm(self.key)
        if key_norm in norm_icons:
            return norm_icons[key_norm]
        for stem, f in norm_icons.items():
            if stem in key_norm or key_norm in stem:
                return f
        return None


_PLACEHOLDER_CACHE = {}


def _placeholder_pixmap(name):
    if name in _PLACEHOLDER_CACHE:
        return _PLACEHOLDER_CACHE[name]
    pm = QPixmap(512, 512)
    pm.fill(Qt.transparent)
    painter = QPainter(pm)
    painter.setRenderHint(QPainter.Antialiasing)
    hue = sum(ord(c) for c in name) % 360
    g = QLinearGradient(0, 0, 512, 512)
    top = QColor.fromHsl(hue, 120, 58)
    bottom = QColor.fromHsl((hue + 40) % 360, 130, 34)
    g.setColorAt(0.0, top)
    g.setColorAt(1.0, bottom)
    painter.setPen(QPen(QColor(255, 255, 255, 40), 2))
    painter.setBrush(g)
    painter.drawRoundedRect(1, 1, 510, 510, 44, 44)
    words = [w for w in name.split() if w]
    letters = "".join(w[0] for w in words)[:2].upper()
    font = QFont()
    font.setBold(True)
    font.setPointSize(150 if len(letters) == 1 else 110)
    font.setFamily(QFontDatabase.systemFont(QFontDatabase.GeneralFont).family())
    painter.setFont(font)
    painter.setPen(QColor(255, 255, 255))
    painter.drawText(QRectF(0, 0, 512, 512), Qt.AlignCenter, letters)
    painter.end()
    _PLACEHOLDER_CACHE[name] = pm
    return pm


_SOUND_WAV = BASE / "scroll.wav"
_SOUND_PLAYERS = ("paplay", "pw-play", "aplay")
_sound_enabled = True
_sound_volume = 50
_sound_wav_volume = None
_sound_last_play = 0.0


def _ensure_sound_wav():
    global _sound_wav_volume
    if _SOUND_WAV.is_file() and _sound_wav_volume == _sound_volume:
        return _SOUND_WAV
    try:
        import math
        import struct
        import wave
        rate = 44100
        dur = 0.06
        n = int(rate * dur)
        amp = int(18000 * _sound_volume / 100)
        frames = bytearray()
        for i in range(n):
            t = i / rate
            env = math.exp(-t * 80.0)
            val = int(amp * env * math.sin(2 * math.pi * 1000 * t))
            frames += struct.pack("<h", val)
        with wave.open(str(_SOUND_WAV), "wb") as w:
            w.setnchannels(1)
            w.setsampwidth(2)
            w.setframerate(rate)
            w.writeframes(bytes(frames))
        _sound_wav_volume = _sound_volume
    except OSError:
        return None
    return _SOUND_WAV


def _play_scroll_sound():
    global _sound_last_play
    if not _sound_enabled or _sound_volume <= 0:
        return
    now = time.monotonic()
    if now - _sound_last_play < 0.06:
        return
    _sound_last_play = now
    wav = _ensure_sound_wav()
    if not wav:
        return
    for player in _SOUND_PLAYERS:
        try:
            subprocess.Popen(
                [player, str(wav)],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            )
            return
        except OSError:
            continue


_SOUNDTRACK_DIR = BASE / "soundtrack"
_soundtrack_enabled = False
_soundtrack_process = None


def _soundtrack_files():
    if not _SOUNDTRACK_DIR.is_dir():
        return []
    return sorted(_SOUNDTRACK_DIR.glob("st*.mp3"), key=lambda x: x.name.lower())


def _start_soundtrack():
    global _soundtrack_process
    _stop_soundtrack()
    files = _soundtrack_files()
    if not files:
        return
    try:
        _soundtrack_process = subprocess.Popen(
            ["cvlc", "--loop", "--no-video", "--quiet"]
            + [str(f) for f in files],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
    except OSError:
        _soundtrack_process = None


def _stop_soundtrack():
    global _soundtrack_process
    if _soundtrack_process is not None:
        try:
            _soundtrack_process.terminate()
        except OSError:
            pass
        _soundtrack_process = None


class CoverItem(QGraphicsObject):
    BADGE_SIZE = 24

    def __init__(self, game, index):
        super().__init__()
        self.game = game
        self.index = index
        self.selected = False
        self.pix = game.pixmap()
        badge_name = "penguin.png" if game.is_native else "windows.png"
        badge_path = ICONS_DIR / badge_name
        self.badge_pix = None
        if badge_path.exists():
            raw = QPixmap(str(badge_path))
            if not raw.isNull():
                self.badge_pix = raw.scaled(
                    self.BADGE_SIZE, self.BADGE_SIZE,
                    Qt.KeepAspectRatio, Qt.SmoothTransformation
                )
        self.setCursor(Qt.PointingHandCursor)

    def boundingRect(self):
        w = CARD_W + NAME_H * 0.6
        return QRectF(-w / 2, -CARD_H / 2, w, CARD_H + NAME_H)

    def paint(self, painter, option, widget=None):
        painter.setRenderHint(QPainter.Antialiasing)
        painter.setRenderHint(QPainter.SmoothPixmapTransform)
        card = QRectF(-CARD_W / 2, -CARD_H / 2, CARD_W, CARD_H)
        card_path = QPainterPath()
        card_path.addRoundedRect(card, CARD_CORNER, CARD_CORNER)

        pen = QPen(QColor(255, 255, 255, 60), 2.5) if self.selected else QPen(QColor(0, 0, 0, 90), 1.5)
        painter.setBrush(QColor(40, 46, 58))
        painter.setPen(pen)
        painter.drawPath(card_path)

        painter.save()
        painter.setClipPath(card_path)
        painter.drawPixmap(card.toRect(), self.pix)
        strip = QRectF(card.left(), card.bottom() - NAME_H, card.width(), NAME_H)
        grad = QLinearGradient(strip.topLeft(), strip.topLeft() + QPointF(0, NAME_H))
        grad.setColorAt(0.0, QColor(0, 0, 0, 40))
        grad.setColorAt(1.0, QColor(0, 0, 0, 200))
        painter.fillRect(strip, grad)
        painter.restore()

        if self.badge_pix and not self.badge_pix.isNull():
            margin = 4
            br = QRect(
                int(card.right() - self.BADGE_SIZE - margin),
                int(card.top() + margin),
                self.BADGE_SIZE, self.BADGE_SIZE
            )
            painter.drawPixmap(br, self.badge_pix)

        fm = QFontMetrics(self._name_font())
        painter.setFont(self._name_font())
        name = fm.elidedText(self.game.display_name, Qt.ElideRight, int(CARD_W - 20))
        strip = QRectF(card.left() + 10, card.bottom() - NAME_H, CARD_W - 20, NAME_H)
        painter.setPen(QColor(255, 255, 255))
        painter.drawText(strip, Qt.AlignVCenter | Qt.AlignLeft, name)
        painter.setPen(Qt.NoPen)

    def _name_font(self):
        font = QFont()
        font.setPointSize(10)
        font.setWeight(QFont.DemiBold)
        return font

    def mousePressEvent(self, event):
        if event.button() == Qt.LeftButton:
            view = self.scene().views()[0]
            view.on_card_clicked(self.index)
            event.accept()
        else:
            super().mousePressEvent(event)


class HaloBackdrop(QGraphicsObject):
    def __init__(self):
        super().__init__()
        self._rect = QRectF()

    def set_bounds(self, x, y, w, h):
        self._rect = QRectF(x, y, w, h)
        self.prepareGeometryChange()

    def boundingRect(self):
        return self._rect

    def paint(self, painter, option, widget=None):
        if self._rect.isNull() or self._rect.width() <= 0 or self._rect.height() <= 0:
            return
        painter.setRenderHint(QPainter.Antialiasing)
        painter.setPen(Qt.NoPen)
        w = self._rect.width()
        h = self._rect.height()
        painter.save()
        painter.translate(self._rect.center())
        painter.scale(1.0, h / w)
        grad = QRadialGradient(0.0, 0.0, w / 2.0)
        grad.setColorAt(0.0, QColor(255, 255, 255, 36))
        grad.setColorAt(0.35, QColor(255, 255, 255, 36))
        grad.setColorAt(0.7, QColor(255, 255, 255, 12))
        grad.setColorAt(1.0, QColor(255, 255, 255, 0))
        painter.setBrush(grad)
        painter.drawEllipse(QPointF(0.0, 0.0), w / 2.0, w / 2.0)
        painter.restore()


class CarouselView(QGraphicsView):
    index_changed = Signal(int)

    def __init__(self, games, parent=None):
        super().__init__(parent)
        self.games = games
        self.items = []
        self._target = 0.0
        self._t = 0.0
        self.index = 0
        self.carousel = self

        self.setFrameShape(QFrame.NoFrame)
        self.setHorizontalScrollBarPolicy(Qt.ScrollBarAlwaysOff)
        self.setVerticalScrollBarPolicy(Qt.ScrollBarAlwaysOff)
        self.setRenderHint(QPainter.Antialiasing)
        self.setRenderHint(QPainter.SmoothPixmapTransform)
        self.setBackgroundBrush(QColor(23, 26, 32))
        self.setAlignment(Qt.AlignCenter)
        self.setDragMode(QGraphicsView.NoDrag)

        self.scene = QGraphicsScene(self)
        self.setScene(self.scene)

        self._halo = HaloBackdrop()
        self.scene.addItem(self._halo)

        for i, game in enumerate(games):
            item = CoverItem(game, i)
            self.scene.addItem(item)
            self.items.append(item)
        if not games:
            return
        self.index = 0
        self.refresh()
        self._anim = QVariantAnimation(self)
        self._anim.valueChanged.connect(self._on_anim)
        self._anim.setEasingCurve(QEasingCurve.OutCubic)

    def resizeEvent(self, event):
        super().resizeEvent(event)
        if self.items:
            self._layout(self._t)

    def _width(self):
        return max(self.viewport().width(), 600)

    def _layout(self, t):
        cx = self._width() / 2.0
        cy = SCENE_H / 2.0 - 45.0
        half = int(len(self.items) / 2) + 1
        halo_h = CARD_H + NAME_H + 90
        self._halo.set_bounds(20, cy - halo_h / 2,
                              max(self._width() - 40, 0), halo_h)
        self._halo.setZValue(-half - 2)
        for item in self.items:
            d = item.index - t
            if abs(d) > half + 1:
                item.setVisible(False)
                continue
            item.setVisible(True)
            scale = max(0.5, 1.0 - 0.24 * abs(d))
            item.setScale(scale)
            item.setZValue(-abs(d))
            item.setPos(QPointF(cx + item.index * SPACING - t * SPACING, cy))
            item.setOpacity(1.0 if abs(d) < 2.6 else max(0.25, 1.0 - 0.25 * (abs(d) - 2.6)))
            item.selected = item.index == self.index
            item.update()

    def refresh(self):
        if self.items:
            self.scene.setSceneRect(0, 0, self._width(), SCENE_H)
            self._layout(self._t)

    def on_card_clicked(self, index):
        if not self.games:
            return
        if self.index != index:
            self.select_index(index)
        self.launch_selected(index)

    def select_index(self, index):
        self.move_to(float(index))

    def _set_index(self, new):
        if new != self.index:
            self.index = new
            self.index_changed.emit(new)

    def move_to(self, target):
        target = max(0.0, min(float(len(self.items) - 1), target))
        if not hasattr(self, "_anim"):
            self._target = target
            self._t = target
            self._set_index(int(round(target)))
            self.refresh()
            return
        self._anim.stop()
        self._target = target
        self._anim.setStartValue(self._t)
        self._anim.setEndValue(target)
        self._anim.setDuration(280)
        self._anim.start()

    def nudge(self, delta):
        if self.games:
            _play_scroll_sound()
            self.move_to(self._target + delta)

    def _on_anim(self, value):
        self._t = float(value)
        self._set_index(int(round(self._t)))
        self.refresh()

    def wheelEvent(self, event):
        steps = event.angleDelta().y() or event.angleDelta().x()
        if steps:
            self.nudge(-1 if steps > 0 else 1)
            event.accept()
            return
        super().wheelEvent(event)

    def keyPressEvent(self, event):
        key = event.key()
        if key == Qt.Key_Left:
            self.nudge(-1)
        elif key == Qt.Key_Right:
            self.nudge(1)
        elif key in (Qt.Key_Return, Qt.Key_Enter, Qt.Key_Space):
            if self.games:
                self.launch_selected(self.index)
        else:
            super().keyPressEvent(event)


class KnightRiderBar(QWidget):
    def __init__(self, parent=None):
        super().__init__(parent)
        self.setFixedHeight(6)
        self._pos = 0.0
        self._dir = 1.0
        self._timer = QTimer(self)
        self._timer.setInterval(16)
        self._timer.timeout.connect(self._tick)
        self.hide()

    def start(self):
        if not self._timer.isActive():
            self._timer.start()
        self.show()

    def stop(self):
        self._timer.stop()
        self.hide()

    def _tick(self):
        self._pos += self._dir * 0.014
        if self._pos >= 1.0:
            self._pos = 1.0
            self._dir = -1.0
        elif self._pos <= 0.0:
            self._pos = 0.0
            self._dir = 1.0
        self.update()

    def paintEvent(self, event):
        painter = QPainter(self)
        painter.setRenderHint(QPainter.Antialiasing)
        w = float(self.width())
        h = float(self.height())
        painter.fillRect(self.rect(), QColor(10, 15, 12))
        if w <= 0:
            return
        head_w = max(48.0, w * 0.16)
        cx = self._pos * (w - head_w) + head_w / 2.0
        left = cx - head_w / 2.0
        painter.setPen(Qt.NoPen)
        tail_len = w * 0.35
        if self._dir > 0:
            tail = QLinearGradient(cx - tail_len, 0.0, cx, 0.0)
            tail.setColorAt(0.0, QColor(0, 255, 136, 0))
            tail.setColorAt(1.0, QColor(0, 255, 136, 120))
            tail_rect = QRectF(cx - tail_len, 0.0, tail_len, h)
        else:
            tail = QLinearGradient(cx, 0.0, cx + tail_len, 0.0)
            tail.setColorAt(0.0, QColor(0, 255, 136, 120))
            tail.setColorAt(1.0, QColor(0, 255, 136, 0))
            tail_rect = QRectF(cx, 0.0, tail_len, h)
        painter.setBrush(tail)
        painter.drawRoundedRect(tail_rect, h / 2.0, h / 2.0)
        glow = QLinearGradient(left, 0.0, left + head_w, 0.0)
        glow.setColorAt(0.0, QColor(0, 255, 136, 0))
        glow.setColorAt(0.5, QColor(0, 255, 136, 150))
        glow.setColorAt(1.0, QColor(0, 255, 136, 0))
        painter.setBrush(glow)
        painter.drawRoundedRect(QRectF(left, 0.0, head_w, h), h / 2.0, h / 2.0)
        core_w = head_w * 0.4
        core_left = cx - core_w / 2.0
        core = QLinearGradient(core_left, 0.0, core_left + core_w, 0.0)
        core.setColorAt(0.0, QColor(0, 255, 136, 0))
        core.setColorAt(0.5, QColor(200, 255, 230, 255))
        core.setColorAt(1.0, QColor(0, 255, 136, 0))
        painter.setBrush(core)
        painter.drawRoundedRect(QRectF(core_left, 0.0, core_w, h), h / 2.0, h / 2.0)


class GameRun:
    _log_lines = 5000
    _GAME_START_MARKER = " [game] Starten:"

    def __init__(self, game, on_status, on_output, extra_env=None, banner=None, on_game_started=None):
        self.game = game
        self.status = "Starten..."
        self.proc = QProcess()
        self.log = []
        if banner:
            self.log.append(banner)
        self.on_status = on_status
        self.on_output = on_output
        self.on_game_started = on_game_started
        self._game_started_fired = False
        self.proc.setProcessChannelMode(QProcess.MergedChannels)
        self.proc.setProgram("bash")
        self.proc.setArguments([str(game.script)])
        if extra_env:
            env = dict(os.environ)
            env.update({k: str(v) for k, v in extra_env.items()})
            self.proc.setEnvironment([f"{k}={v}" for k, v in env.items()])
        self.proc.readyReadStandardOutput.connect(self._read)
        self.proc.started.connect(lambda: self._set_status("Actief"))
        self.proc.finished.connect(self._finished)

    def start(self):
        self.proc.start()
        self._set_status("Starten...")

    def _set_status(self, status):
        self.status = status
        self.on_status(self)

    def _read(self):
        data = bytes(self.proc.readAllStandardOutput()).decode("utf-8", "replace")
        if data:
            for line in data.splitlines():
                self.log.append(line.strip())
                if (not self._game_started_fired
                        and self.on_game_started
                        and self._GAME_START_MARKER in line):
                    self._game_started_fired = True
                    self.on_game_started()
            self.log = self.log[-self._log_lines:]
            self.on_output(self)

    def _finished(self, exit_code, status):
        if status == QProcess.CrashExit:
            self._set_status("Gecrasht")
        else:
            self._set_status(f"Gestopt (exit {exit_code})")

        if exit_code != 0 and exit_code != 130:
            QMessageBox.warning(
                self.window(),
                "Game start mislukt",
                "De game kon niet starten (exit code: {}).\n\n"
                "Probeer: vink in de opties aan:\n"
                "  ☑ 'SDL3-fallback aan (standaard SDL)'"
                "\nen start opnieuw.".format(exit_code)
            )

    def stop(self):
        pid = self.proc.processId() if self.proc else 0
        if pid and self.proc and self.proc.state() != QProcess.NotRunning:
            try:
                os.killpg(os.getpgid(pid), signal.SIGTERM)
                self._set_status("Stoppen...")
            except (ProcessLookupError, PermissionError):
                self.proc.terminate()
        elif self.proc:
            self.proc.terminate()


class MainWindow(QMainWindow):
    CAROUSEL_H = 430

    def __init__(self, games):
        super().__init__()
        update_icon_dirs()  # Initialiseer icon-mappen vanuit gebruikersconfiguratie
        self.games = games
        self.runs = {}
        self.current_run = None
        self.run_tabs = None
        self._dir_edits = {}
        self.setWindowTitle(f"Game Launcher v{APP_VERSION}")
        self.resize(1360, 840)
        self.setStyleSheet(STYLE)
        self._build_menu()

        root = QWidget()
        self.setCentralWidget(root)
        main_layout = QVBoxLayout(root)
        main_layout.setContentsMargins(10, 10, 10, 10)
        main_layout.setSpacing(8)

        main_layout.addWidget(self._build_header())
        main_layout.addWidget(self._build_carousel_banner())
        main_layout.addWidget(self._build_options())
        main_layout.addWidget(self._build_terminal(), 1)

        if games:
            self._select(0)
            self._sync_dir_field()
            self.setWindowIcon(QIcon(str(BASE / "gamelauncherv1.png")))

    def _build_menu(self):
        menubar = self.menuBar()
        help_menu = menubar.addMenu("Help")

        help_action = QAction("Help (bediening)", self)
        help_action.triggered.connect(self._show_help)
        about_action = QAction(f"Over Game Launcher v{APP_VERSION}", self)
        about_action.triggered.connect(self._show_about)
        help_menu.addAction(help_action)
        help_menu.addAction(about_action)

    def _show_help(self):
        QMessageBox.information(
            self, "Game Launcher",
            "Bediening:\n"
            " · Muiswiel / pijltjes: bladeren door de games\n"
            " · Klik op een icoon of Enter: starten\n"
            " · Installatiemap: eigen pad of leeg laten (standaard uit script)\n"
            " · Checkboxen: Desktop-icoon, Gamescope, SDL3, bevestigen, snapshot, gamepad, MangoHud, vkBasalt, wielmuis-geluid, soundtrack\n"
            " · Gamepad-modus: pad als SDL-joystick (DInput/SDL-games); XInput-only-\n"
            "   games krijgen de pad pas na de eenmalige udev/groep-rootstap (zie status)")

    def _show_about(self):
        QMessageBox.about(
            self, "Over Game Launcher",
            f"<b>Game Launcher</b> — versie {APP_VERSION}<br>"
            "Roller-GUI voor de WINEPREFIX launcher-scripts.<br><br>"
            "Scant template-scripts/game-launchers/*.sh en start games "
            "via de bijbehorende launcher.")

    def _build_header(self):
        header = QFrame()
        header.setObjectName("header")
        lay = QVBoxLayout(header)
        lay.setContentsMargins(0, 6, 0, 2)
        
        title = QLabel("WWN GAME LAUNCHER")
        title.setObjectName("title")
        title.setAlignment(Qt.AlignCenter)
        lay.addWidget(title)

        # Robuuste OS/distro-detectie label onder de header
        os_info = detect_os_name()
        subtitle = QLabel(f"Systeem: {os_info}")
        subtitle.setObjectName("subtitle")
        subtitle.setAlignment(Qt.AlignCenter)
        lay.addWidget(subtitle)

        return header

    def _build_carousel_banner(self):
        self.carousel = CarouselView(self.games)
        self.carousel.launch_selected = lambda i: self._on_launch(i)
        self.carousel.index_changed.connect(lambda i: self._on_carousel_changed(i))
        self.carousel.setFixedHeight(self.CAROUSEL_H)
        self.carousel.setMinimumWidth(600)

        hint = QLabel("Muiswiel / pijltjes: bladeren   ·   klik op een icoon of Enter: starten")
        hint.setAlignment(Qt.AlignCenter)
        hint.setStyleSheet("color: #5f6b7a; font-size: 11px;")

        banner = QFrame()
        banner.setObjectName("carouselBanner")
        bl = QVBoxLayout(banner)
        bl.setContentsMargins(0, 0, 0, 0)
        bl.setSpacing(6)
        bl.addWidget(self.carousel)
        bl.addWidget(hint)
        return banner

    def _build_options(self):
        frame = QFrame()
        frame.setObjectName("optionsFrame")
        lay = QVBoxLayout(frame)
        lay.setContentsMargins(12, 10, 12, 10)
        lay.setSpacing(8)

        self.cb_desktop = QCheckBox("Desktop-icoon op het bureaublad")
        self.cb_desktop.setChecked(True)
        self.cb_gamescope = QCheckBox("Start met Gamescope")
        self.cb_gamescope.setToolTip(
            "Isoleert de game op een vaste resolutie om Alt-Tab-crashes, "
            "muis-lekkage en resolutieproblemen op de desktop te voorkomen. "
            "Wayland support, X11 conflicts mogelijk"
        )
        self.cb_sdl3 = QCheckBox("SDL3-fallback aan (standaard SDL)")
        self.cb_sdl3.setChecked(True)
        self.cb_confirm = QCheckBox("Bevestigen vóór start")
        self.cb_confirm.setChecked(True)
        self.cb_snapshot = QCheckBox("Backup-snapshot vóór elke start (testzone)")
        self.cb_gamepad = QCheckBox("Gamepad-modus (SDL / non-standaard)")
        self.cb_gamepad.setChecked(load_settings().get("GPAD") == "1")
        self.cb_gamepad.toggled.connect(self._on_gamepad_toggled)
        self.cb_mangohud = QCheckBox("MangoHud overlay")
        self.cb_mangohud.setChecked(False)
        self.cb_vkbasalt = QCheckBox("vkBasalt (vibrance/deband)")
        self.cb_vkbasalt.setChecked(False)
        self.cb_vkbasalt.setToolTip(
            "Vulkan-postprocessing (Deband/Vibrance/Curves/Tonemap). "
            "Alleen via Proton; standaard uit."
        )

        self.cb_native_vulkan = QCheckBox("Vulkan (Zink)")
        self.cb_native_opengl = QCheckBox("OpenGL")
        self.cb_soundtrack = QCheckBox("Soundtrack")
        self.cb_soundtrack.toggled.connect(self._on_soundtrack_toggled)
        self.cb_soundtrack.setChecked(load_settings().get("SOUNDTRACK", "1") == "1")

        grid = QGridLayout()
        grid.setHorizontalSpacing(24)
        grid.setVerticalSpacing(6)
        checks = (self.cb_desktop, self.cb_gamescope, self.cb_sdl3,
                  self.cb_confirm, self.cb_snapshot, self.cb_gamepad,
                  self.cb_mangohud, self.cb_native_vulkan, self.cb_native_opengl)
        for i, cb in enumerate(checks):
            grid.addWidget(cb, i // 3, i % 3)
        grid.addWidget(self.cb_soundtrack, 3, 1)
        grid.addWidget(self.cb_vkbasalt, 3, 0)
        lay.addLayout(grid)

        vol_grid = QGridLayout()
        vol_grid.setHorizontalSpacing(6)
        vol_grid.setVerticalSpacing(2)
        self.cb_sound = QCheckBox("volume effect")
        self.cb_sound.toggled.connect(self._on_sound_toggled)
        self.cb_sound.setChecked(load_settings().get("SOUND", "1") == "1")
        self.sound_slider = QSlider(Qt.Horizontal)
        self.sound_slider.setRange(0, 100)
        self.sound_slider.setValue(int(load_settings().get("SOUND_VOL", "50")))
        self.sound_slider.setToolTip("Volume van het wielmuis-geluid")
        self.sound_slider.setFixedWidth(80)
        self.sound_slider.valueChanged.connect(self._on_sound_volume_changed)
        vol_grid.addWidget(self.cb_sound, 0, 0)
        vol_grid.addWidget(self.sound_slider, 0, 1)
        vol_grid.setRowMinimumHeight(0, 20)
        lay.addLayout(vol_grid)

        # Icon-map selectie
        icons_row = QHBoxLayout()
        icons_row.setSpacing(6)
        self.icons_label = QLabel("Icon-map")
        self.icons_edit = QLineEdit()
        self.icons_edit.setPlaceholderText(str(ICONS_ROOT_DEFAULT))
        self.icons_edit.setText(str(get_icons_root()))
        self.icons_edit.textChanged.connect(self._on_icons_dir_changed)
        self.icons_button = QPushButton("Bladeren…")
        self.icons_button.clicked.connect(self._browse_icons_dir)
        self.icons_validate_btn = QPushButton("Valideren")
        self.icons_validate_btn.clicked.connect(self._validate_icons_dir)
        self.icons_validate_btn.setFixedWidth(80)
        icons_row.addWidget(self.icons_label)
        icons_row.addWidget(self.icons_edit, 1)
        icons_row.addWidget(self.icons_button)
        icons_row.addWidget(self.icons_validate_btn)
        lay.addLayout(icons_row)

        dir_row = QHBoxLayout()
        dir_row.setSpacing(6)
        self.dir_label = QLabel("Installatiemap")
        self.dir_edit = QLineEdit()
        self.dir_edit.setPlaceholderText("(standaard uit launcher-script)")
        self.dir_edit.textChanged.connect(self._on_dir_edited)
        self.dir_button = QPushButton("Bladeren…")
        self.dir_button.clicked.connect(self._browse_dir)
        dir_row.addWidget(self.dir_label)
        dir_row.addWidget(self.dir_edit, 1)
        dir_row.addWidget(self.dir_button)
        lay.addLayout(dir_row)
        return frame

    def _on_carousel_changed(self, index):
        self._sync_dir_field()

    def _on_gamepad_toggled(self, state):
        opts = load_settings()
        opts["GPAD"] = "1" if state else "0"
        save_settings(opts)

    def _on_sound_toggled(self, state):
        global _sound_enabled
        _sound_enabled = bool(state)
        opts = load_settings()
        opts["SOUND"] = "1" if state else "0"
        save_settings(opts)

    def _on_sound_volume_changed(self, value):
        global _sound_volume
        _sound_volume = value
        opts = load_settings()
        opts["SOUND_VOL"] = str(value)
        save_settings(opts)

    def _on_soundtrack_toggled(self, state):
        global _soundtrack_enabled
        _soundtrack_enabled = bool(state)
        if state:
            _start_soundtrack()
        else:
            _stop_soundtrack()
        opts = load_settings()
        opts["SOUNDTRACK"] = "1" if state else "0"
        save_settings(opts)

    def _on_dir_edited(self, text):
        game = self._selected_game()
        if game is None:
            return
        if text.strip() == game.default_dir:
            self._dir_edits.pop(game.key, None)
        else:
            self._dir_edits[game.key] = text

    def _selected_game(self):
        if not self.games or self.carousel is None:
            return None
        idx = min(self.carousel.index, len(self.games) - 1)
        return self.games[idx]

    def _stored_dir(self, game):
        return game.stored_dir

    def _sync_dir_field(self):
        game = self._selected_game()
        if game is None:
            self.dir_label.setText("Installatiemap")
            self.dir_edit.clear()
            return
        self.dir_label.setText(f"Installatiemap {game.display_name}")
        value = self._dir_edits.get(
            game.key,
            self._stored_dir(game) or game.default_dir or "")
        if self.dir_edit.text() != (value or ""):
            self.dir_edit.setText(value or "")

    def _browse_dir(self):
        game = self._selected_game()
        start = self.dir_edit.text().strip() or (game.default_dir if game else "")
        chosen = QFileDialog.getExistingDirectory(self, "Kies installatiemap", start)
        if chosen:
            self.dir_edit.setText(chosen)

    def _on_icons_dir_changed(self, text):
        path = text.strip()
        if path:
            opts = load_settings()
            opts[ICONS_CONF_KEY] = path
            save_settings(opts)
            update_icon_dirs()

    def _browse_icons_dir(self):
        start = self.icons_edit.text().strip() or str(ICONS_ROOT_DEFAULT)
        chosen = QFileDialog.getExistingDirectory(self, "Kies icon-map (hoofdmap met gameicons/, emu-gameicons/, etc.)", start)
        if chosen:
            self.icons_edit.setText(chosen)

    def _validate_icons_dir(self):
        path = self.icons_edit.text().strip()
        if not path:
            QMessageBox.warning(self, "Valideren", "Geen map ingevuld.")
            return
        root = Path(path).expanduser()
        valid, errors = validate_icon_structure(root)
        if valid:
            QMessageBox.information(self, "Valideren", f"Mapstructuur is correct:\n{root}")
        else:
            msg = "Mapstructuur incomplete:\n\n" + "\n".join(f"• {e}" for e in errors)
            QMessageBox.warning(self, "Valideren", msg)

    def _build_terminal(self):
        frame = QFrame()
        frame.setObjectName("terminalFrame")
        lay = QVBoxLayout(frame)
        lay.setContentsMargins(6, 4, 6, 6)
        lay.setSpacing(4)

        self.run_tabs = QTabBar()
        self.run_tabs.setDrawBase(False)
        self.run_tabs.setExpanding(False)
        self.run_tabs.setMovable(True)
        self.run_tabs.setTabsClosable(True)
        self.run_tabs.tabCloseRequested.connect(self._close_run_tab)
        self.run_tabs.currentChanged.connect(self._on_tab_changed)
        self.run_tabs.hide()
        lay.addWidget(self.run_tabs)

        self.scanner = KnightRiderBar()
        lay.addWidget(self.scanner)

        self.terminal = QPlainTextEdit()
        self.terminal.setReadOnly(True)
        self.terminal.setMaximumBlockCount(GameRun._log_lines)
        mono = QFont(QFontDatabase.systemFont(QFontDatabase.FixedFont))
        mono.setPointSize(11)
        self.terminal.setFont(mono)
        self.terminal.setStyleSheet("""
            QPlainTextEdit {
                background-color: #0a0f0c;
                color: #00ff88;
                border: 1px solid #1a3a2a;
                border-radius: 8px;
                padding: 8px;
                selection-background-color: #004422;
            }
        """)
        lay.addWidget(self.terminal, 1)

        self._welcome()
        return frame

    def _welcome(self):
        self.terminal.appendPlainText("Game Launcher — terminal output")
        self.terminal.appendPlainText("Klik een game-icoon in de banner om te starten.")
        self.terminal.appendPlainText("")

    def _select(self, index):
        if self.games:
            self.carousel.select_index(index)

    def _on_launch(self, index):
        if not self.games or index is None or index >= len(self.games):
            return
        game = self.games[index]
        self.carousel.select_index(index)
        if game.key in self.runs and self.runs[game.key].proc.state() != QProcess.NotRunning:
            self._focus_run(self.runs[game.key])
            self._append_terminal(f"=> {game.display_name} draait al.")
            return
        if self.cb_confirm.isChecked():
            answer = QMessageBox.question(
                self, "Game Launcher",
                f"{game.display_name} starten?",
                QMessageBox.Yes | QMessageBox.No, QMessageBox.No)
            if answer != QMessageBox.Yes:
                return

        vulkan_checked = self.cb_native_vulkan.isChecked()
        opengl_checked = self.cb_native_opengl.isChecked()

        if vulkan_checked and opengl_checked:
            msg = QMessageBox(self)
            msg.setWindowTitle("Renderer Conflict")
            msg.setText("Both Vulkan and OpenGL are selected.\n\nWhat is your choice: Vulkan or OpenGL?")
            msg.setStandardButtons(QMessageBox.Yes | QMessageBox.No)
            msg.setButtonText(QMessageBox.Yes, "Vulkan (Zink)")
            msg.setButtonText(QMessageBox.No, "OpenGL")
            msg.setDefaultButton(QMessageBox.No)
            answer = msg.exec()
            if answer == QMessageBox.Yes:
                self.cb_native_opengl.setChecked(False)
                renderer = "vulkan"
            else:
                self.cb_native_vulkan.setChecked(False)
                renderer = "opengl"
        elif vulkan_checked:
            renderer = "vulkan"
        elif opengl_checked:
            renderer = "opengl"
        else:
            renderer = ""

        extra_env = {
            "GUI_DESKTOP_SHORTCUT": "1" if self.cb_desktop.isChecked() else "0",
            "GUI_GAMESCOPE": "1" if self.cb_gamescope.isChecked() else "0",
            "GUI_SDL3_DYNAMIC_API_OFF": "1" if self.cb_sdl3.isChecked() else "0",
            "SNAPSHOT_BACKUP": "1" if self.cb_snapshot.isChecked() else "0",
            "GUI_GAMEPAD": "1" if self.cb_gamepad.isChecked() else "0",
            "GUI_MANGOHUD": "1" if self.cb_mangohud.isChecked() else "0",
            "GUI_VKBASALT": "1" if self.cb_vkbasalt.isChecked() else "0",
            "GAME_GUI": "1",
            "GUI_NATIVE_RENDERER": renderer,
        }
        chosen_dir = self._dir_edits.get(game.key, "").strip()
        conf_key = game.key.upper()
        paths = load_paths()
        if chosen_dir and chosen_dir != game.default_dir:
            paths[conf_key] = chosen_dir
            extra_env["GUI_GAME_DIR"] = chosen_dir
        else:
            paths.pop(conf_key, None)
        self._dir_edits.pop(game.key, None)
        save_paths(paths)

        def _on_game_started():
            _stop_soundtrack()

        run = GameRun(game, self._run_status_changed, self._run_output,
                      extra_env=extra_env,
                      banner=f"== {game.display_name} — installatie wordt uitgevoerd ==",
                      on_game_started=_on_game_started)
        if self.cb_gamepad.isChecked():
            run.log.append("[gamepad] SDL-modus aan: pad als joystick voor SDL/DInput-games; toetsenbord kan uitvallen in de game. XInput-only-games (Ori/Cyberpunk) zien de pad pas ná de eenmalige root-setup (zie status hieronder).")
            self._attach_tool_output(run, GAMEPAD_STATUS_TOOL)
        self.runs[game.key] = run
        self._add_run_tab(run)
        self._focus_run(run)
        run.start()
        self._update_scanner()

    def _attach_tool_output(self, run, tool_path):
        if not tool_path.is_file():
            return
        proc = QProcess(self)
        proc.setProcessChannelMode(QProcess.MergedChannels)
        proc.setProgram("bash")
        proc.setArguments([str(tool_path)])

        def _on_read():
            data = bytes(proc.readAllStandardOutput()).decode("utf-8", "replace")
            if not data:
                return
            run.log.append(data.strip())
            run.log = run.log[-GameRun._log_lines:]
            if self.current_run is run:
                self._append_terminal(data.strip())

        proc.readyReadStandardOutput.connect(_on_read)
        proc.start()

    def _run_status_changed(self, run):
        tab_idx = self._tab_index_for(run.game.key)
        if tab_idx >= 0:
            self.run_tabs.setTabText(tab_idx, f"{run.game.display_name}  —  {run.status}")
        self._update_scanner()

    def _update_scanner(self):
        run = self.current_run
        active = (run is not None and run.proc is not None
                  and run.proc.state() != QProcess.NotRunning)
        if active:
            self.scanner.start()
        else:
            self.scanner.stop()

    def _run_output(self, run):
        if self.current_run is run:
            self._append_terminal(run.log[-1] if run.log else "")

    def _add_run_tab(self, run):
        idx = self.run_tabs.addTab(f"{run.game.display_name}  —  Starten...")
        self.run_tabs.setTabData(idx, run.game.key)
        self.run_tabs.setCurrentIndex(idx)
        if self.run_tabs.count() > 1:
            self.run_tabs.show()

    def _tab_index_for(self, game_key):
        for i in range(self.run_tabs.count()):
            if self.run_tabs.tabData(i) == game_key:
                return i
        return -1

    def _focus_run(self, run):
        self.current_run = run
        idx = self._tab_index_for(run.game.key)
        if idx >= 0:
            self.run_tabs.setCurrentIndex(idx)
        self.terminal.clear()
        self.terminal.setPlainText("\n".join(run.log))
        self._update_scanner()

    def _on_tab_changed(self, idx):
        if idx < 0:
            return
        key = self.run_tabs.tabData(idx)
        run = self.runs.get(key)
        if run:
            self._focus_run(run)

    def _close_run_tab(self, idx):
        key = self.run_tabs.tabData(idx)
        run = self.runs.get(key)
        if run and run.proc is not None and run.proc.state() != QProcess.NotRunning:
            run.stop()
        self.run_tabs.removeTab(idx)
        if self.run_tabs.count() <= 1:
            self.run_tabs.hide()
        if self.current_run and self.current_run.game.key == key:
            self.current_run = None
            self.terminal.clear()
            self._welcome()
        elif self.runs:
            self._focus_run(next(iter(self.runs.values())))
        self._update_scanner()

    def closeEvent(self, event):
        running = [r for r in self.runs.values()
                   if r.proc is not None and r.proc.state() != QProcess.NotRunning]
        if running:
            names = ", ".join(r.game.display_name for r in running)
            from PySide6.QtWidgets import QMessageBox
            answer = QMessageBox.question(
                self, "Game Launcher",
                f"Er draait nog een game ({names}).\nAfsluiten stopt die game. Toch afsluiten?",
                QMessageBox.Yes | QMessageBox.No, QMessageBox.No)
            if answer != QMessageBox.Yes:
                event.ignore()
                return
            for r in running:
                r.stop()
        _stop_soundtrack()
        event.accept()

    def _append_terminal(self, line):
        self.terminal.appendPlainText(line)
        sb = self.terminal.verticalScrollBar()
        sb.setValue(sb.maximum())


def scan_games():
    games = []
    if LINUXLAUNCHERS.exists():
        for f in sorted(LINUXLAUNCHERS.glob("*.sh"), key=lambda x: x.name.lower()):
            if ".notworking" in f.name:
                continue
            games.append(Game(f.name[:-3], f))
    return games


def _ensure_desktop_icon():
    desktop_dir = Path.home() / "Desktop"
    if not desktop_dir.is_dir():
        return
    target = desktop_dir / "GameLauncher.desktop"
    if target.exists():
        return
    icon = BASE / "gamelauncherv1.png"
    icon_line = str(icon) if icon.exists() else "preferences-desktop-gaming"
    content = (
        "[Desktop Entry]\n"
        "Type=Application\n"
        "Name=Game Launcher\n"
        "Comment=Start games via de launcher-GUI\n"
        f"Exec=python3 {BASE / 'game-gui.py'}\n"
        f"Icon={icon_line}\n"
        "Terminal=false\n"
        "Categories=Game;\n"
        "StartupNotify=true\n"
    )
    target.write_text(content, encoding="utf-8")
    target.chmod(0o755)


def main():
    app = QApplication.instance() or QApplication([])
    app.setApplicationName("Game Launcher")
    _ensure_desktop_icon()
    games = scan_games()
    window = MainWindow(games)
    if not games:
        from PySide6.QtWidgets import QMessageBox
        QMessageBox.warning(window, "Game Launcher",
                            f"Geen launcher-scripts gevonden in:\n{LAUNCHERS_DIR}")
    window.show()
    app.exec()


if __name__ == "__main__":
    main()
