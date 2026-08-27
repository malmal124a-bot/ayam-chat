import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class AgoraController extends GetxController {
  static const String appId = "d77bd2f955d44051a16e35d16e66f7e6";
  
  RtcEngine? _engine;
  final isJoined = false.obs;
  final isMuted = false.obs;
  final remoteUsers = <int>[].obs;
  final speakingUsers = <int, int?>{}.obs; // uid -> volume level

  @override
  void onInit() {
    debugPrint('Initializing: AgoraController');
    super.onInit();
    initEngine();
  }

  Future<void> initEngine() async {
    await setupAgoraEngine();
  }

  Future<void> setupAgoraEngine() async {
    try {
      _engine = createAgoraRtcEngine();
      
      await _engine!.initialize(const RtcEngineContext(
        appId: appId,
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
      ));

      _engine!.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            isJoined.value = true;
            debugPrint("Successfully joined channel: ${connection.channelId}");
          },
          onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
            remoteUsers.add(remoteUid);
            debugPrint("User joined: $remoteUid");
          },
          onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
            remoteUsers.remove(remoteUid);
            speakingUsers.remove(remoteUid);
            debugPrint("User offline: $remoteUid, reason: $reason");
          },
          onLeaveChannel: (RtcConnection connection, RtcStats stats) {
            isJoined.value = false;
            remoteUsers.clear();
            speakingUsers.clear();
            debugPrint("Left channel");
          },
          onError: (ErrorCodeType err, String msg) {
            debugPrint("Agora Error: $err, $msg");
          },
          onAudioVolumeIndication: (RtcConnection connection, List<AudioVolumeInfo> speakers, int totalVolume, int speakerNumber) {
            // MIC SPEAKING VIBRATION: Track speaking users with volume > 5
            for (final speaker in speakers) {
              final volume = speaker.volume ?? 0;
              final uid = speaker.uid;
              if (uid != null && volume > 5) {
                speakingUsers[uid] = volume;
              } else if (uid != null) {
                speakingUsers.remove(uid);
              }
            }
            debugPrint("Audio volume indication: ${speakers.length} speakers, total: $totalVolume, speakerNumber: $speakerNumber");
          },
        ),
      );

      // HARDENED AUDIO CONFIGURATION: High-quality voice streaming
      await _engine!.enableAudio();
      await _engine!.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
      
      // Ensure remote audio is not muted
      await _engine!.muteAllRemoteAudioStreams(false);
      
      await _engine!.enableAudioVolumeIndication(
        interval: 150,
        smooth: 4, reportVad: true,
      );
      
      debugPrint("Agora engine initialized successfully with enhanced audio configuration");
    } catch (e) {
      debugPrint("Error initializing Agora: $e");
    }
  }

  Future<void> joinRoom(String channelName, {int uid = 0}) async {
    if (_engine == null) await setupAgoraEngine();
    
    if (appId.isEmpty) {
      debugPrint("Warning: Agora App ID is not set. Voice features will not work.");
      return;
    }

    // Request permissions
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      debugPrint("Microphone permission not granted");
      return;
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
      
      // HARDENED AUDIO: Ensure audio is enabled and unmuted for voice transmission
      await _engine!.enableAudio();
      await _engine!.muteLocalAudioStream(false);
      await _engine!.adjustPlaybackSignalVolume(100); // Max volume for incoming audio
      
      debugPrint("Joining Agora channel: $channelName with UID: $uid (Audio enabled, unmuted, max volume)");
    } catch (e) {
      debugPrint("Error joining Agora channel: $e");
    }
  }

  Future<void> leaveRoom() async {
    try {
      await _engine?.leaveChannel();
      isJoined.value = false;
      remoteUsers.clear();
      debugPrint("Left Agora channel");
    } catch (e) {
      debugPrint("Error leaving Agora channel: $e");
    }
  }

  void toggleMute() {
    isMuted.value = !isMuted.value;
    _engine?.muteLocalAudioStream(isMuted.value);
    debugPrint("Mute toggled: ${isMuted.value}");
  }

  Future<void> setMute(bool mute) async {
    isMuted.value = mute;
    await _engine?.muteLocalAudioStream(mute);
    debugPrint("Mute set to: $mute");
  }

  RtcEngine? getEngine() => _engine;
  RtcEngine? getAgoraEngine() => _engine;
  bool get isAudioMuted => isMuted.value;
  List<int> get connectedUsers => remoteUsers.toList();

  @override
  void onClose() {
    _engine?.release();
    super.onClose();
  }
}
