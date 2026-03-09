#!/data/data/com.termux/files/usr/bin/python

import os
import time
import subprocess
from textual.app import App, ComposeResult
from textual.widgets import Button, Static
from textual.containers import Vertical

# ------------------------------------------------------------
# Paths
# ------------------------------------------------------------

BASE_DIR = os.path.expanduser("~/.shortcuts")
START_SMB = os.path.join(BASE_DIR, "Start-SMB.sh")
STOP_SMB = os.path.join(BASE_DIR, "Stop-SMB.sh")

# ------------------------------------------------------------
# SMB helpers
# ------------------------------------------------------------

def smb_pid():
    try:
        return subprocess.check_output(["pgrep", "smbd"]).decode().splitlines()[0]
    except subprocess.CalledProcessError:
        return None


def smb_running():
    return smb_pid() is not None


def smb_activity():
    pid = smb_pid()
    if not pid:
        return False

    try:
        def io_bytes():
            total = 0
            with open(f"/proc/{pid}/io") as f:
                for line in f:
                    if line.startswith(("read_bytes", "write_bytes")):
                        total += int(line.split()[1])
            return total

        before = io_bytes()
        time.sleep(0.3)
        after = io_bytes()
        return after > before
    except Exception:
        return False

# ------------------------------------------------------------
# Textual App
# ------------------------------------------------------------

class SMBTUI(App):

    CSS = """
    Screen {
        background: black;
        align: center middle;
    }

    /* Main panel fills most of the screen */
    Vertical {
        width: 92%;
        height: auto;
        min-height: 60%;
        padding: 2;
        border: round white;
        align: center middle;
    }

    Static {
        content-align: center middle;
        margin-bottom: 2;
        text-style: bold;
    }

    Button {
        width: 100%;
        height: 5;
        margin: 1 0;
        content-align: center middle;
    }
    """

    def compose(self) -> ComposeResult:
        self.status = Static()
        self.toggle = Button("")
        self.exit_btn = Button("Exit")

        yield Vertical(
            self.status,
            self.toggle,
            self.exit_btn,
        )

    def on_mount(self):
        # No focus → no keyboard
        self.refresh_status()
        self.set_interval(1.0, self.refresh_status)

    def refresh_status(self):
        state = "ON" if smb_running() else "OFF"
        activity = "COPYING" if smb_running() and smb_activity() else "IDLE"
        self.status.update(f"SMB: {state}\nActivity: {activity}")
        self.toggle.label = "Stop SMB" if smb_running() else "Start SMB"

    def on_button_pressed(self, event: Button.Pressed):
        if event.button is self.exit_btn:
            self.exit()
        elif smb_running():
            subprocess.call([STOP_SMB])
        else:
            subprocess.call([START_SMB])
        self.refresh_status()


if __name__ == "__main__":
    SMBTUI().run()
