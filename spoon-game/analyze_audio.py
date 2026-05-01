import librosa
import json
import sys

def analyze(audio_path):
    print("Loading audio...", file=sys.stderr)
    y, sr = librosa.load(audio_path, sr=None)
    
    print("Running beat tracking...", file=sys.stderr)
    tempo, beat_frames = librosa.beat.beat_track(y=y, sr=sr)
    beat_times = librosa.frames_to_time(beat_frames, sr=sr)
    
    print("Detecting onsets...", file=sys.stderr)
    onset_frames = librosa.onset.onset_detect(y=y, sr=sr)
    onset_times = librosa.frames_to_time(onset_frames, sr=sr)
    onset_env = librosa.onset.onset_strength(y=y, sr=sr)
    
    # We want to pick some beats.
    # To make it interesting, we'll use a mix of strong onsets and beats.
    # We will pick onsets that are strong, and if they align with beats, they might be D (Red), else K (Blue).
    
    # Let's collect all onsets that have a strength above a certain threshold (e.g., top 40%)
    import numpy as np
    onset_strengths = onset_env[onset_frames]
    if len(onset_strengths) == 0:
        return "[]"
        
    threshold = np.percentile(onset_strengths, 60) # Top 40% strongest onsets
    strong_onsets = onset_times[onset_strengths >= threshold]
    
    # Filter to avoid too dense notes (minimum 0.15s between notes)
    filtered_onsets = []
    last_time = -1.0
    for t in strong_onsets:
        if t - last_time > 0.15:
            filtered_onsets.append(t)
            last_time = t
            
    # Assign type based on whether it's close to a main beat
    notes = []
    for t in filtered_onsets:
        # Check distance to nearest beat
        dist_to_beat = np.min(np.abs(beat_times - t))
        is_on_beat = dist_to_beat < 0.1 # Within 100ms of a beat
        
        # Red (0) for on-beat (strong), Blue (1) for off-beat
        note_type = 0 if is_on_beat else 1
        
        # Add a random variation to make it interesting
        if np.random.rand() < 0.2:
            note_type = 1 - note_type
            
        notes.append([float(round(t, 2)), note_type])
        
    # Formatting output for GDScript
    # Group in an array to match [[time, type], ...] structure
    return json.dumps([notes])

if __name__ == '__main__':
    result = analyze("raspberry_jam.ogg")
    print(result)
