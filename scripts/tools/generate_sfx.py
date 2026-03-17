#!/usr/bin/env python3
"""Generate 8-bit SFX WAV files for Probabimals."""

import math
import os
import struct
import wave

import numpy as np

OUT_DIR = os.path.join(os.path.dirname(__file__), "..", "..", "assets", "audio", "sfx")
SAMPLE_RATE = 22050
MAX_AMP = 0.8


def _note_freq(name: str) -> float:
    """Convert note name like 'C4', 'F#5' to frequency in Hz."""
    notes = {"C": -9, "D": -7, "E": -5, "F": -4, "G": -2, "A": 0, "B": 2}
    note = name[0]
    idx = 1
    sharp = 0
    if idx < len(name) and name[idx] == "#":
        sharp = 1
        idx += 1
    elif idx < len(name) and name[idx] == "b":
        sharp = -1
        idx += 1
    octave = int(name[idx:])
    semitone = notes[note] + sharp + (octave - 4) * 12
    return 440.0 * (2.0 ** (semitone / 12.0))


def square_wave(freq: float, duration: float, duty: float = 0.5) -> np.ndarray:
    t = np.linspace(0, duration, int(SAMPLE_RATE * duration), endpoint=False)
    phase = (t * freq) % 1.0
    return np.where(phase < duty, 1.0, -1.0)


def triangle_wave(freq: float, duration: float) -> np.ndarray:
    t = np.linspace(0, duration, int(SAMPLE_RATE * duration), endpoint=False)
    phase = (t * freq) % 1.0
    return 4.0 * np.abs(phase - 0.5) - 1.0


def sawtooth_wave(freq: float, duration: float) -> np.ndarray:
    t = np.linspace(0, duration, int(SAMPLE_RATE * duration), endpoint=False)
    phase = (t * freq) % 1.0
    return 2.0 * phase - 1.0


def noise(duration: float) -> np.ndarray:
    n = int(SAMPLE_RATE * duration)
    raw = np.random.uniform(-1.0, 1.0, n)
    step = SAMPLE_RATE // 8000
    if step > 1:
        raw = np.repeat(raw[::step], step)[:n]
    return raw


def _env_ad(samples: np.ndarray, attack_ms: float = 5, decay_ms: float = 50) -> np.ndarray:
    n = len(samples)
    att = min(int(SAMPLE_RATE * attack_ms / 1000), n)
    dec = min(int(SAMPLE_RATE * decay_ms / 1000), n)
    env = np.ones(n)
    if att > 0:
        env[:att] = np.linspace(0, 1, att)
    if dec > 0:
        env[-dec:] = np.linspace(1, 0, dec)
    return samples * env


def _env_custom(samples: np.ndarray, attack_ms: float, sustain_level: float, release_ms: float) -> np.ndarray:
    n = len(samples)
    att = min(int(SAMPLE_RATE * attack_ms / 1000), n)
    rel = min(int(SAMPLE_RATE * release_ms / 1000), n)
    env = np.ones(n) * sustain_level
    if att > 0:
        env[:att] = np.linspace(0, 1, att)
    if rel > 0:
        env[-rel:] = np.linspace(sustain_level, 0, rel)
    return samples * env


def _quantize_8bit(samples: np.ndarray) -> np.ndarray:
    """Quantize to 16 levels for crunchier 8-bit feel, then scale back."""
    levels = 16
    s = np.clip(samples, -1, 1)
    s = np.round(s * levels) / levels
    return s


def _save_wav(filename: str, samples: np.ndarray):
    os.makedirs(OUT_DIR, exist_ok=True)
    path = os.path.join(OUT_DIR, filename)
    samples = _quantize_8bit(samples) * MAX_AMP
    data = np.clip(samples * 32767, -32768, 32767).astype(np.int16)
    with wave.open(path, "w") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(SAMPLE_RATE)
        wf.writeframes(data.tobytes())
    print(f"  {filename}: {len(data)/SAMPLE_RATE:.2f}s ({os.path.getsize(path)} bytes)")


def gen_ui_click():
    sig = square_wave(_note_freq("C6"), 0.03) + triangle_wave(_note_freq("E6"), 0.03) * 0.5
    sig = _env_ad(sig, attack_ms=1, decay_ms=25)
    _save_wav("ui_click.wav", sig)


def gen_ui_hover():
    sig = triangle_wave(_note_freq("G5"), 0.04)
    sig = _env_ad(sig, attack_ms=2, decay_ms=35)
    _save_wav("ui_hover.wav", sig * 0.6)


def gen_dice_roll():
    parts = []
    for i in range(12):
        freq = 200 + np.random.randint(0, 400)
        chunk = noise(0.03) * square_wave(freq, 0.03) * 0.5
        chunk = _env_ad(chunk, attack_ms=1, decay_ms=20)
        parts.append(chunk)
        parts.append(np.zeros(int(SAMPLE_RATE * 0.01)))
    sig = np.concatenate(parts)
    _save_wav("dice_roll.wav", sig)


def gen_dice_hold():
    notes = ["G5", "D5", "B4"]
    parts = []
    for n in notes:
        chunk = square_wave(_note_freq(n), 0.05)
        chunk = _env_ad(chunk, attack_ms=2, decay_ms=40)
        parts.append(chunk)
    sig = np.concatenate(parts)
    _save_wav("dice_hold.wav", sig)


def gen_dice_release():
    notes = ["B4", "D5", "G5"]
    parts = []
    for n in notes:
        chunk = square_wave(_note_freq(n), 0.05)
        chunk = _env_ad(chunk, attack_ms=2, decay_ms=40)
        parts.append(chunk)
    sig = np.concatenate(parts)
    _save_wav("dice_release.wav", sig)


def gen_combo_detect():
    notes = ["C5", "E5", "G5", "C6", "E6", "G6"]
    parts = []
    for i, n in enumerate(notes):
        dur = 0.06
        chunk = square_wave(_note_freq(n), dur, duty=0.25)
        chunk = _env_ad(chunk, attack_ms=2, decay_ms=45)
        parts.append(chunk)
    sig = np.concatenate(parts)
    _save_wav("combo_detect.wav", sig)


def gen_score_tick():
    sig = triangle_wave(_note_freq("A5"), 0.03)
    sig = _env_ad(sig, attack_ms=1, decay_ms=25)
    _save_wav("score_tick.wav", sig)


def gen_purchase():
    notes = ["E5", "G5", "B5", "E6"]
    parts = []
    for n in notes:
        chunk = triangle_wave(_note_freq(n), 0.08)
        chunk = _env_ad(chunk, attack_ms=3, decay_ms=60)
        parts.append(chunk)
    tail = square_wave(_note_freq("E6"), 0.15, duty=0.25)
    tail = _env_custom(tail, attack_ms=2, sustain_level=0.7, release_ms=120)
    parts.append(tail)
    sig = np.concatenate(parts)
    _save_wav("purchase.wav", sig)


def gen_shop_refresh():
    sweep_dur = 0.25
    t = np.linspace(0, sweep_dur, int(SAMPLE_RATE * sweep_dur), endpoint=False)
    freq_start, freq_end = 300, 2000
    freq = freq_start + (freq_end - freq_start) * (t / sweep_dur)
    phase = np.cumsum(freq / SAMPLE_RATE)
    sig = np.sign(np.sin(2 * np.pi * phase))
    sig = _env_ad(sig, attack_ms=5, decay_ms=100)
    _save_wav("shop_refresh.wav", sig * 0.7)


def gen_coin_clink():
    sig1 = triangle_wave(_note_freq("E6"), 0.04)
    gap = np.zeros(int(SAMPLE_RATE * 0.02))
    sig2 = triangle_wave(_note_freq("G6"), 0.06)
    sig = np.concatenate([
        _env_ad(sig1, attack_ms=1, decay_ms=30),
        gap,
        _env_ad(sig2, attack_ms=1, decay_ms=50),
    ])
    _save_wav("coin_clink.wav", sig)


def gen_round_win():
    melody = [
        ("C5", 0.12), ("E5", 0.12), ("G5", 0.12),
        ("C6", 0.15), ("E6", 0.15),
        ("G6", 0.35),
    ]
    parts = []
    for note, dur in melody:
        chunk = square_wave(_note_freq(note), dur, duty=0.25)
        chunk = _env_ad(chunk, attack_ms=3, decay_ms=int(dur * 500))
        parts.append(chunk)
    sig = np.concatenate(parts)
    _save_wav("round_win.wav", sig)


def gen_game_over():
    melody = [
        ("E5", 0.18), ("C5", 0.18), ("A4", 0.22),
        ("F4", 0.25), ("D4", 0.30),
        ("C4", 0.50),
    ]
    parts = []
    for note, dur in melody:
        chunk = sawtooth_wave(_note_freq(note), dur)
        chunk = _env_ad(chunk, attack_ms=5, decay_ms=int(dur * 600))
        parts.append(chunk)
    sig = np.concatenate(parts)
    _save_wav("game_over.wav", sig * 0.7)


if __name__ == "__main__":
    print("Generating 8-bit SFX...")
    gen_ui_click()
    gen_ui_hover()
    gen_dice_roll()
    gen_dice_hold()
    gen_dice_release()
    gen_combo_detect()
    gen_score_tick()
    gen_purchase()
    gen_shop_refresh()
    gen_coin_clink()
    gen_round_win()
    gen_game_over()
    print("Done!")
