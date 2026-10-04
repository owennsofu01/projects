import 'dart:async';

import 'package:just_audio/just_audio.dart';

/// Short one-shot gameplay sound effects. See assets/audio/ for the files.
enum SfxSound { tap, correct, wrong, complete }

/// Plain static service (not a Riverpod provider) so game session notifiers
/// can call `SoundService.play(...)` directly without needing a `Ref` —
/// every notifier in this app is constructed without one. [configure] is
/// called from the app root whenever Settings change, keeping playback in
/// sync with the user's Sound/Music toggles.
class SoundService {
  SoundService._();

  static const _sfxAsset = {
    SfxSound.tap: 'assets/audio/tap.wav',
    SfxSound.correct: 'assets/audio/correct.wav',
    SfxSound.wrong: 'assets/audio/wrong.wav',
    SfxSound.complete: 'assets/audio/complete.wav',
  };

  static bool _soundEnabled = true;
  static bool _musicEnabled = true;
  static AudioPlayer? _musicPlayer;
  static bool _musicLoaded = false;
  static String? _customMusicPath;

  /// [customMusicPath] is a local file path to music the user picked from
  /// their own device (Settings > Music); null uses the bundled default
  /// track. Passing a different path than last time reloads the player.
  static Future<void> configure({required bool soundOn, required bool musicOn, String? customMusicPath}) async {
    _soundEnabled = soundOn;
    _musicEnabled = musicOn;
    if (customMusicPath != _customMusicPath) {
      _customMusicPath = customMusicPath;
      _musicLoaded = false;
    }
    if (musicOn) {
      await _resumeMusic();
    } else {
      await _musicPlayer?.pause();
    }
  }

  /// Fire-and-forget SFX playback. Failures (e.g. a missing asset) are
  /// swallowed — sound is decoration and must never break gameplay.
  static void play(SfxSound sound) {
    if (!_soundEnabled) return;
    unawaited(_play(sound));
  }

  static Future<void> _play(SfxSound sound) async {
    final player = AudioPlayer();
    try {
      await player.setAsset(_sfxAsset[sound]!);
      unawaited(player.play());
      // Wait for the clip to actually finish before disposing the player —
      // disposing mid-playback would cut the sound off. The timeout is a
      // safety net in case processingState never reaches `completed`.
      await player.playerStateStream
          .firstWhere((s) => s.processingState == ProcessingState.completed)
          .timeout(const Duration(seconds: 3), onTimeout: () => player.playerState);
    } catch (_) {
      // Ignored — see [play].
    } finally {
      unawaited(player.dispose());
    }
  }

  static Future<void> pauseMusic() async {
    await _musicPlayer?.pause();
  }

  static Future<void> _resumeMusic() async {
    if (!_musicEnabled) return;
    final player = _musicPlayer ??= AudioPlayer();
    if (player.playing && _musicLoaded) return;
    try {
      if (!_musicLoaded) {
        final customPath = _customMusicPath;
        if (customPath != null) {
          await player.setFilePath(customPath);
        } else {
          await player.setAsset('assets/audio/music_loop.wav');
        }
        await player.setLoopMode(LoopMode.one);
        await player.setVolume(0.35);
        _musicLoaded = true;
      }
      await player.play();
    } catch (_) {
      // Background music is best-effort — e.g. a custom file the user
      // picked may have since been deleted from device storage.
    }
  }
}
