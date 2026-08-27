import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class AgoraService {
  static const String appId = "d77bd2f955d44051a16e35d16e66f7e6";

  AgoraService._();
  static final AgoraService instance = AgoraService._();
  factory AgoraService() => instance;

  RtcEngine? _engine;
  bool _isJoined = false;
  bool _isMuted = false;
  bool _isInitialized = false;
  int? _localAgoraUid;
  final List<int> _remoteUsers = [];
  final Map<int, int?> _speakingUsers = {};
  final Map<int, String> _uidToUserId = {};

  Future<void> initEngine() async {
    await setupAgoraEngine();
  }

  bool _isInitializing = false;

  Future<void> setupAgoraEngine() async {
    if (_isInitializing) return;
    _isInitializing = true;
    try {
      // Release old engine first if it exists
      if (_engine != null) {
        try {
          await _engine!.leaveChannel();
        } catch (_) {}
        try {
          await _engine!.release();
        } catch (_) {}
        _engine = null;
        _isInitialized = false;
        _isJoined = false;
        _remoteUsers.clear();
        _speakingUsers.clear();
      }

      _engine = createAgoraRtcEngine();

      await _engine!.initialize(RtcEngineContext(
        appId: appId,
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
      ));

      _engine!.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            _isJoined = true;
            _localAgoraUid = connection.localUid;
            debugPrint("Successfully joined channel: ${connection.channelId}, local UID: ${connection.localUid}");
          },
          onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
            _remoteUsers.add(remoteUid);
            debugPrint("User joined: $remoteUid");
          },
          onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
            _remoteUsers.remove(remoteUid);
            _speakingUsers.remove(remoteUid);
            debugPrint("User offline: $remoteUid, reason: $reason");
          },
          onLeaveChannel: (RtcConnection connection, RtcStats stats) {
            _isJoined = false;
            _remoteUsers.clear();
            _speakingUsers.clear();
            debugPrint("Left channel");
          },
          onError: (ErrorCodeType err, String msg) {
            debugPrint("Agora Error: $err, $msg");
          },
          onAudioVolumeIndication: (RtcConnection connection, List<AudioVolumeInfo> speakers, int totalVolume, int speakerNumber) {
            for (final speaker in speakers) {
              final volume = speaker.volume ?? 0;
              final uid = speaker.uid;
              if (uid != null && volume > 5) {
                _speakingUsers[uid] = volume;
              } else if (uid != null) {
                _speakingUsers.remove(uid);
              }
            }
          },
        ),
      );

      await _engine!.enableAudio();
      await _engine!.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
      await _engine!.muteAllRemoteAudioStreams(false);
      await _engine!.enableAudioVolumeIndication(
        interval: 150,
        smooth: 4, reportVad: true,
      );

      _isInitialized = true;
      debugPrint("Agora engine initialized successfully");
    } catch (e) {
      debugPrint("Error initializing Agora: $e");
      _isInitialized = false;
    } finally {
      _isInitializing = false;
    }
  }

  Future<void> joinRoom(String channelName, {int uid = 0}) async {
    if (!_isInitialized || _engine == null) {
      await setupAgoraEngine();
    }

    if (appId.isEmpty) {
      debugPrint("Warning: Agora App ID is not set. Voice features will not work.");
      return;
    }

    if (!kIsWeb) {
      final status = await Permission.microphone.request();
      if (!status.isGranted) {
        debugPrint("Microphone permission not granted");
        return;
      }
    }

    try {
      await _engine!.joinChannel(
        token: "",
        channelId: channelName,
        uid: uid,
        options: const ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          publishMicrophoneTrack: true,
          autoSubscribeAudio: true,
        ),
      );

      await _engine!.enableAudio();
      await _engine!.muteLocalAudioStream(false);
      await _engine!.adjustPlaybackSignalVolume(100);

      debugPrint("Joining Agora channel: $channelName with UID: $uid");
    } catch (e) {
      debugPrint("Error joining Agora channel: $e");
    }
  }

  Future<void> leaveRoom() async {
    try {
      await _engine?.leaveChannel();
      _isJoined = false;
      _remoteUsers.clear();
      _speakingUsers.clear();
      debugPrint("Left Agora channel");
    } catch (e) {
      debugPrint("Error leaving Agora channel: $e");
    }
  }

  Future<void> releaseEngine() async {
    try {
      if (_engine != null) {
        try {
          await _engine!.leaveChannel();
        } catch (_) {}
        await _engine!.release();
        _engine = null;
        _isInitialized = false;
        _isJoined = false;
        _isMuted = false;
        _localAgoraUid = null;
        _remoteUsers.clear();
        _speakingUsers.clear();
        debugPrint("Agora engine released");
      }
    } catch (e) {
      debugPrint("Error releasing Agora engine: $e");
    }
  }

  void toggleMute() {
    _isMuted = !_isMuted;
    if (_isInitialized && _isJoined) {
      _engine?.muteLocalAudioStream(_isMuted);
    }
    debugPrint("Mute toggled: $_isMuted");
  }

  Future<void> setMute(bool mute) async {
    _isMuted = mute;
    if (_isInitialized && _isJoined) {
      await _engine?.muteLocalAudioStream(mute);
    }
    debugPrint("Mute set to: $mute");
  }

  Future<void> muteRemoteUser(int remoteUid, bool mute) async {
    try {
      await _engine?.muteRemoteAudioStream(uid: remoteUid, mute: mute);
      debugPrint("Remote user $remoteUid muted: $mute");
    } catch (e) {
      debugPrint("Error muting remote user $remoteUid: $e");
    }
  }

  List<int> get remoteUsers => List.from(_remoteUsers);
  Map<int, int?> get speakingUsers => Map.from(_speakingUsers);
  int? get localAgoraUid => _localAgoraUid;

  void registerUserMapping(int agoraUid, String supabaseUserId) {
    _uidToUserId[agoraUid] = supabaseUserId;
    debugPrint("Registered Agora UID $agoraUid -> Supabase $supabaseUserId");
  }

  String? getUserIdByAgoraUid(int agoraUid) => _uidToUserId[agoraUid];

  int? getAgoraUidByUserId(String supabaseUserId) {
    for (final entry in _uidToUserId.entries) {
      if (entry.value == supabaseUserId) return entry.key;
    }
    return null;
  }

  void dispose() {
    _engine?.release();
    _engine = null;
    _isInitialized = false;
  }
}
