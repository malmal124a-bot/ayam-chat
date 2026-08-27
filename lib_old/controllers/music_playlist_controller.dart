import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class MusicTrack {
  final String title;
  final String artist;
  final Duration duration;

  const MusicTrack({required this.title, required this.artist, required this.duration});
}

class MusicPlaylistController extends ChangeNotifier {
  static final MusicPlaylistController _instance = MusicPlaylistController._internal();
  factory MusicPlaylistController() => _instance;

  MusicPlaylistController._internal() {
    debugPrint('Initializing: MusicPlaylistController');
  }

  final List<MusicTrack> tracks = const [
    MusicTrack(title: 'Royal Lounge', artist: 'Ayam Studio', duration: Duration(minutes: 3, seconds: 24)),
    MusicTrack(title: 'Night Party', artist: 'PK Beats', duration: Duration(minutes: 2, seconds: 58)),
    MusicTrack(title: 'Golden Mood', artist: 'VIP Session', duration: Duration(minutes: 4, seconds: 10)),
    MusicTrack(title: 'Arabesque Room', artist: 'Live Mix', duration: Duration(minutes: 3, seconds: 46)),
  ];

  int currentIndex = 0;
  bool isPlaying = false;
  double volume = 0.7;
  bool soundEffects = true;
  bool _isDisposed = false;

  MusicTrack get currentTrack => tracks[currentIndex];

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  void safeNotify() {
    if (_isDisposed) return;
    if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (!_isDisposed) notifyListeners();
      });
    } else {
      notifyListeners();
    }
  }

  void togglePlay() {
    isPlaying = !isPlaying;
    safeNotify();
  }

  void nextTrack() {
    currentIndex = (currentIndex + 1) % tracks.length;
    isPlaying = true;
    safeNotify();
  }

  void previousTrack() {
    currentIndex = currentIndex == 0 ? tracks.length - 1 : currentIndex - 1;
    isPlaying = true;
    safeNotify();
  }

  void setTrack(int index) {
    currentIndex = index;
    isPlaying = true;
    safeNotify();
  }

  void setVolume(double value) {
    volume = value;
    safeNotify();
  }

  void toggleEffects() {
    soundEffects = !soundEffects;
    safeNotify();
  }
}
