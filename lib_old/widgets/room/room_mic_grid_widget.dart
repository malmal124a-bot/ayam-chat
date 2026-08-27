import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../../models/mic_seat.dart';
import '../../controllers/user_controller.dart';
import '../../controllers/agora_controller.dart';

class RoomMicGridWidget extends StatelessWidget {
  final List<MicSeat> seats;
  final Map<int, String>? seatReactions; 
  final Function(MicSeat) onSeatTap;
  final Function(MicSeat) onSeatLongPress;
  final Function(int index)? onJoinMic;
  final Function(int index)? onLeaveMic;
  final Function(int index)? onToggleMute;
  final Function(int index)? onLockSeat;
  final Function(int index)? onInviteToMic;
  final Function(int index)? onKickFromMic;
  final Function(int index)? onKickToAudience;
  
  final bool isCurrentUserOwner;
  final bool isCurrentUserAdmin;

  const RoomMicGridWidget({
    super.key,
    required this.seats,
    this.seatReactions,
    required this.onSeatTap,
    required this.onSeatLongPress,
    this.onJoinMic,
    this.onLeaveMic,
    this.onToggleMute,
    this.onLockSeat,
    this.onInviteToMic,
    this.onKickFromMic,
    this.onKickToAudience,
    this.isCurrentUserOwner = false,
    this.isCurrentUserAdmin = false,
  });

  @override
  Widget build(BuildContext context) {
    if (seats.isEmpty) return const SizedBox.shrink();

    // Spec: 5x4 Grid Layout (Exactly 5 mics per row, 4 rows for 20 mics)
    return Directionality(
      textDirection: TextDirection.rtl,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(), // No scrolling allowed
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5, // Exactly 5 mics per row
          mainAxisSpacing: 4.0,
          crossAxisSpacing: 4.0,
          mainAxisExtent: 83, // Enlarged height for bigger seat circles (18% increase)
        ),
        itemCount: seats.length, 
        itemBuilder: (context, index) {
          final seat = seats[index];
          return RoomMicSeatWidget(
            seat: seat,
            onTap: onSeatTap,
            onLongPress: onSeatLongPress,
            isCurrentUserOwner: isCurrentUserOwner,
            isCurrentUserAdmin: isCurrentUserAdmin,
            seatReactions: seatReactions,
          );
        },
      ),
    );
  }
}

class RoomMicSeatWidget extends StatelessWidget {
  final MicSeat seat;
  final Function(MicSeat) onTap;
  final Function(MicSeat) onLongPress;
  final bool isCurrentUserOwner;
  final bool isCurrentUserAdmin;
  final Map<int, String>? seatReactions;

  const RoomMicSeatWidget({
    super.key,
    required this.seat,
    required this.onTap,
    required this.onLongPress,
    this.isCurrentUserOwner = false,
    this.isCurrentUserAdmin = false,
    this.seatReactions,
  });

  @override
  Widget build(BuildContext context) {
    final userController = UserController();
    
    final bool isEmpty = seat.userName == null || seat.userName!.isEmpty;
    final bool isLocked = seat.isLocked;
    final bool isMe = !isEmpty && seat.userId == userController.id;
    final bool isOwner = !isEmpty && seat.userRole == 'owner';
    final bool isAdmin = !isEmpty && seat.userRole == 'admin';

    // Source frame from equippedFramePath or fetch from Firestore
    final String? equippedFramePath = seat.avatarFrame;
    
    // If frame is null and user is seated, fetch from Firestore for frame and avatar
    // Avatar sync: Fetch photoUrl directly from Firestore for real-time avatar updates
    if (!isEmpty && seat.userId != null) {
      return StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(seat.userId).snapshots(),
        builder: (context, snapshot) {
          String? firestoreFramePath;
          String? firestoreAvatarUrl;
          
          if (snapshot.hasData && snapshot.data!.exists) {
            final data = snapshot.data!.data() as Map<String, dynamic>?;
            firestoreFramePath = data?['activeFrame'] as String?;
            // Fetch avatar photoUrl for real-time avatar rendering (supports GIF/WebP)
            firestoreAvatarUrl = data?['photoUrl'] as String? ?? data?['profilePic'] as String?;
          }
          
          // Update seat with Firestore avatar if available
          final updatedSeat = firestoreAvatarUrl != null 
              ? MicSeat(
                  index: seat.index,
                  userName: seat.userName,
                  userId: seat.userId,
                  userProfilePic: firestoreAvatarUrl,
                  avatarFrame: seat.avatarFrame,
                  userLevel: seat.userLevel,
                  contributionScore: seat.contributionScore,
                  isVip: seat.isVip,
                  isSvip: seat.isSvip,
                  isLocked: seat.isLocked,
                  isMuted: seat.isMuted,
                  isSpeaking: seat.isSpeaking,
                  hasRequest: seat.hasRequest,
                  isOwner: seat.isOwner,
                  userRole: seat.userRole,
                  badges: seat.badges,
                )
              : seat;
          
          return _buildMicSeatContent(
            context,
            userController,
            updatedSeat,
            isEmpty,
            isLocked,
            isMe,
            isOwner,
            isAdmin,
            firestoreFramePath ?? equippedFramePath,
          );
        },
      );
    }

    return _buildMicSeatContent(
      context,
      userController,
      seat,
      isEmpty,
      isLocked,
      isMe,
      isOwner,
      isAdmin,
      equippedFramePath,
    );
  }

  Widget _buildMicSeatContent(
    BuildContext context,
    UserController userController,
    MicSeat seat,
    bool isEmpty,
    bool isLocked,
    bool isMe,
    bool isOwner,
    bool isAdmin,
    String? equippedFramePath,
  ) {
    // Spec: Enlarged mic seat circles for better visibility (18% increase)
    const double avatarSize = 38.0; // Increased from 32.0
    const double frameSize = 52.0; // Increased from 44.0

    // MIC SPEAKING VIBRATION: Integrate with AgoraController for real-time speaking detection
    final agoraController = Get.find<AgoraController>();
    final int? userIdInt = seat.userId != null ? int.tryParse(seat.userId!) : null;
    final bool isSpeaking = userIdInt != null && (agoraController.speakingUsers[userIdInt] != null && agoraController.speakingUsers[userIdInt]! > 3);

    return GestureDetector(
      onTap: () => onTap(seat),
      onLongPress: () => onLongPress(seat),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // 1. Wrap the seated user's avatar image in a Stack centered layout.
          SizedBox(
            width: frameSize,
            height: frameSize,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                // Profile Picture Circle (Centered in Stack)
                Container(
                  width: avatarSize,
                  height: avatarSize, 
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.1),
                    border: Border.all(
                      color: isMe 
                        ? Colors.blueAccent 
                        : (isSpeaking ? Colors.transparent : Colors.white.withValues(alpha: 0.12)),
                      width: 1.0,
                    ),
                  ),
                  child: isEmpty
                      ? _buildEmptySeatAsset(isLocked)
                      : ClipOval(
                          child: _buildSafeImage(seat.userProfilePic),
                        ),
                ),
                
                if (!isEmpty && isSpeaking)
                  _SpeakingAura(size: avatarSize),
                
                // 2. If the user has an equipped avatar frame (equippedFramePath), 
                // render the frame image directly over their profile picture circle on the mic seat.
                // 3. Ensure proper scaling so the frame fits perfectly around the seated avatar.
                if (!isEmpty && equippedFramePath != null && equippedFramePath.isNotEmpty)
                  IgnorePointer(
                    child: SizedBox(
                      width: frameSize, 
                      height: frameSize,
                      child: _buildSafeAvatarFrame(equippedFramePath),
                    ),
                  ),
                // 4. SVIP Seat Badge Logic: Show RED badge for SVIP users, YELLOW for normal users
                if (!isEmpty && (equippedFramePath == null || equippedFramePath.isEmpty))
                  IgnorePointer(
                    child: SizedBox(
                      width: frameSize, 
                      height: frameSize,
                      child: _buildSvipSeatBadge(seat.isSvip, seat.userLevel),
                    ),
                  ),
                
                if (seatReactions != null && seatReactions!.containsKey(seat.index))
                  MicReactionOverlay(
                    key: ValueKey('mic_reaction_${seat.index}_${seatReactions![seat.index]}'),
                    emoji: seatReactions![seat.index]!.split('|')[0],
                    size: avatarSize,
                  ),
                if (isOwner || isAdmin)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(0.4),
                      decoration: BoxDecoration(
                        color: isOwner ? Colors.red : const Color(0xFFFFD700),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 0.4),
                      ),
                      child: const Icon(Icons.star, color: Colors.white, size: 6.5),
                    ),
                  ),
                if (!isEmpty && seat.isMuted)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(0.4),
                      decoration: BoxDecoration(
                        color: Colors.red, 
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 0.4),
                      ),
                      child: const Icon(Icons.mic_off, color: Colors.white, size: 6.5),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 1),
          Text(
            isEmpty ? '${seat.index}' : (seat.userName ?? ''),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isEmpty ? Colors.white.withValues(alpha: 0.38) : Colors.white,
              fontSize: 10,
              fontWeight: isEmpty ? FontWeight.normal : FontWeight.bold,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSafeImage(String? path) {
    const String fallback = 'assets/Asad/room.jpg';
    if (path == null || path.isEmpty) {
      return Image.asset(fallback, fit: BoxFit.cover);
    }
    
    // Handle network images (supports GIF/WebP for animated avatars)
    if (path.startsWith('http')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        gaplessPlayback: false, // Allow GIF animation
        errorBuilder: (context, error, stackTrace) => Image.asset(fallback, fit: BoxFit.cover),
      );
    }
    
    // Handle Base64 encoded images (supports GIF/WebP)
    if (path.startsWith('data:image/')) {
      try {
        final base64String = path.split(',').last;
        final bytes = base64Decode(base64String);
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          gaplessPlayback: false, // Allow GIF animation
          errorBuilder: (context, error, stackTrace) => Image.asset(fallback, fit: BoxFit.cover),
        );
      } catch (e) {
        debugPrint('Error loading Base64 image: $e');
        return Image.asset(fallback, fit: BoxFit.cover);
      }
    }
    
    // Handle asset images
    return Image.asset(path.startsWith('assets/') ? path : fallback, fit: BoxFit.cover);
  }

  Widget _buildSafeAvatarFrame(String? path) {
    if (path == null || path.isEmpty) return const SizedBox.shrink();
    if (path.startsWith('http')) {
      return Image.network(path, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const SizedBox.shrink());
    }
    return Image.asset(path, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const SizedBox.shrink());
  }

  Widget _buildEmptySeatAsset(bool isLocked) {
    // Use golden chair/seat frame asset for empty seats
    final String assetPath = isLocked 
        ? 'assets/Asad/ic_wheat_lock_mic.png' 
        : 'assets/Asad/icon_room_up_micro_b.png';
    
    return Image.asset(
      assetPath,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        // Fallback to icon if asset not found
        return Icon(
          isLocked ? Icons.lock_outline_rounded : Icons.mic_none_rounded,
          color: Colors.white.withValues(alpha: 0.38),
          size: 13,
        );
      },
    );
  }

  Widget _buildSvipSeatBadge(bool isSvip, int userLevel) {
    // SVIP Seat Badge Logic: RED for SVIP users, YELLOW for normal users
    if (isSvip) {
      // Premium RED mic badge for SVIP users - use golden asset with red glow
      return Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.red, width: 2),
          boxShadow: [
            BoxShadow(color: Colors.red.withValues(alpha: 0.5), blurRadius: 4),
          ],
        ),
        child: Image.asset(
          'assets/Asad/icon_seat_lock_vip6.png',
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
        ),
      );
    } else if (userLevel >= 10) {
      // Yellow mic frame for normal users with level 10+
      return Image.asset(
        'assets/Asad/cp_entry.png',
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      );
    }
    return const SizedBox.shrink();
  }
}

class _SpeakingAura extends StatefulWidget {
  final double size;
  const _SpeakingAura({required this.size});

  @override
  State<_SpeakingAura> createState() => _SpeakingAuraState();
}

class _SpeakingAuraState extends State<_SpeakingAura> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this, 
      duration: const Duration(milliseconds: 1000)
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.amber.withValues(alpha: 0.8 + (0.2 * _controller.value)),
              width: 4.0,
            ),
            color: Colors.amber.withValues(alpha: 0.15 + (0.15 * _controller.value)),
            boxShadow: [
              BoxShadow(
                color: Colors.amber.withValues(alpha: 0.4 + (0.3 * _controller.value)),
                blurRadius: 8 + (6 * _controller.value),
                spreadRadius: 2 + (2 * _controller.value),
              ),
            ],
          ),
        );
      },
    );
  }
}

class MicReactionOverlay extends StatefulWidget {
  final String emoji;
  final double size;
  const MicReactionOverlay({super.key, required this.emoji, required this.size});

  @override
  State<MicReactionOverlay> createState() => _MicReactionOverlayState();
}

class _MicReactionOverlayState extends State<MicReactionOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    
    _opacity = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 75),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.0), weight: 25),
    ]).animate(_controller);
    
    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeOut)), weight: 30),
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 70),
    ]).animate(_controller);
    
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final bool isAsset = widget.emoji.contains('/');
        final bool isLottie = widget.emoji.toLowerCase().endsWith('.json');

        Widget emojiWidget;
        if (isLottie) {
          emojiWidget = Lottie.asset(
            widget.emoji,
            width: widget.size, 
            height: widget.size,
            fit: BoxFit.cover,
            alignment: Alignment.center,
            errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
          );
        } else if (isAsset) {
          emojiWidget = Image.asset(
            widget.emoji, 
            width: widget.size, 
            height: widget.size,
            fit: BoxFit.cover,
            alignment: Alignment.center,
            errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
          );
        } else {
          emojiWidget = Center(
            child: Text(
              widget.emoji, 
              style: TextStyle(fontSize: widget.size * 0.6)
            )
          );
        }

        return Opacity(
          opacity: _opacity.value,
          child: ScaleTransition(
            scale: _scale,
            alignment: Alignment.center,
            child: ClipOval(
              child: SizedBox(
                width: widget.size,
                height: widget.size,
                child: emojiWidget,
              ),
            ),
          ),
        );
      },
    );
  }
}
