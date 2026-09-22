import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// The three beeps that say a step's countdown has run out.
///
/// The phone is usually in a pocket when a step timer ends, so a vibration on
/// its own is easy to miss. This is a plain local asset, not the notification
/// system: the app is open and in front of the user, and a notification for
/// something they are already looking at would be noise.
class Chime {
  Chime._();
  static final instance = Chime._();

  static const _asset = 'sounds/timer_done.wav';

  AudioPlayer? _player;

  Future<void> timerFinished() async {
    try {
      final player = _player ??= AudioPlayer()
        // Treated as an alarm so it is audible when the ringer is down, and
        // so it ducks music rather than mixing into it.
        ..setReleaseMode(ReleaseMode.stop);

      await player.setAudioContext(
        AudioContext(
          android: const AudioContextAndroid(
            contentType: AndroidContentType.sonification,
            usageType: AndroidUsageType.alarm,
            audioFocus: AndroidAudioFocus.gainTransientMayDuck,
          ),
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
            options: const {AVAudioSessionOptions.duckOthers},
          ),
        ),
      );
      await player.play(AssetSource(_asset));
    } catch (error) {
      // A step that finishes silently is a far smaller problem than one that
      // throws, so a device that will not play this is simply let be.
      debugPrint('Could not play the timer chime: $error');
    }
  }

  Future<void> dispose() async {
    await _player?.dispose();
    _player = null;
  }
}
