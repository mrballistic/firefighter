"""Convert source audio to Playdate-ready WAVs.

    python3 scripts/prep_sounds.py [SRC_DIR]     # default SRC_DIR: source/sounds

For each <name>.<mp3|aif|aiff|m4a> in SRC_DIR, writes source/sounds/<name>.wav:
16-bit mono 44.1 kHz PCM (via macOS afconvert), with leading silence trimmed so
it fires on the frame, the silent tail trimmed, and a 10 ms fade-out so the cut
doesn't click. "Silence" = more than 40 dB below the clip's peak (10 ms windows).

Existing .wav files in SRC_DIR are never used as input (they're outputs).
"""
import glob
import math
import os
import struct
import subprocess
import sys
import tempfile
import wave

SRC = sys.argv[1] if len(sys.argv) > 1 else "source/sounds"
DST = "source/sounds"
INPUT_EXTS = (".mp3", ".aif", ".aiff", ".m4a")
THRESHOLD_DB = 40
WINDOW_S = 0.01
FADE_S = 0.01

os.makedirs(DST, exist_ok=True)
for src in sorted(glob.glob(os.path.join(SRC, "*"))):
    name, ext = os.path.splitext(os.path.basename(src))
    if ext.lower() not in INPUT_EXTS:
        continue
    with tempfile.TemporaryDirectory() as tmp:
        full = os.path.join(tmp, "full.wav")
        subprocess.run(["afconvert", "-f", "WAVE", "-d", "LEI16@44100", "-c", "1", src, full], check=True)
        with wave.open(full) as w:
            rate, n = w.getframerate(), w.getnframes()
            samples = list(struct.unpack(f"<{n}h", w.readframes(n)))

    win = int(rate * WINDOW_S)
    rms = []
    for i in range(0, n, win):
        chunk = samples[i:i + win]
        rms.append(math.sqrt(sum(s * s for s in chunk) / len(chunk)))
    floor = max(rms) * 10 ** (-THRESHOLD_DB / 20)
    loud = [i for i, r in enumerate(rms) if r > floor]
    start, end = loud[0] * win, min(n, (loud[-1] + 1) * win)
    out = samples[start:end]

    fade = min(len(out), int(rate * FADE_S))
    for k in range(fade):
        i = len(out) - fade + k
        out[i] = int(out[i] * (1 - (k + 1) / fade))

    dst = os.path.join(DST, name + ".wav")
    with wave.open(dst, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(rate)
        w.writeframes(struct.pack(f"<{len(out)}h", *out))
    print(f"{src} -> {dst}: {n / rate:.2f}s -> {len(out) / rate:.2f}s "
          f"(trimmed {start / rate * 1000:.0f} ms lead, {(n - end) / rate * 1000:.0f} ms tail)")
