import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:lottie/lottie.dart';
import 'package:svgaplayer_flutter/svgaplayer_flutter.dart';
import '../../models/mic_seat.dart';
import '../../controllers/user_controller.dart';
import '../../utils/image_utils.dart';
import '../../services/svga_asset_service.dart';

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
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5, // Exactly 5 mics per row
          mainAxisSpacing: 4.0,
          crossAxisSpacing: 4.0,
          mainAxisExtent: 90, // Increased height for larger seat circles (52px avatar + frame)
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

    // Source frame from equippedFramePath
    final String? equippedFramePath = seat.avatarFrame;

    // Spec: Enlarged mic seat circles for better visibility (increased by ~62.5%)
    const double avatarSize = 52.0; // Increased from 32px to 52px
    const double frameSize = 70.0; // Frame size = avatarSize * 1.35

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
                        : (seat.isSpeaking ? Colors.transparent : Colors.white.withValues(alpha: 0.12)),
                      width: 1.0,
                    ),
                  ),
                  child: isEmpty
                      ? _buildEmptySeatAsset(isLocked)
                      : ClipOval(
                          child: _buildSafeImage(seat.userProfilePic),
                        ),
                ),
                
                if (!isEmpty && seat.isSpeaking)
                  _SpeakingAura(size: avatarSize),
                
                // 2. Frame Overlay Logic: Check if user has active equipped frame URL
                // Wrap User Avatar with Stack widget and add frame image as layer above avatar
                // Frame size is slightly larger than avatar circle (size * 1.35) and centered to align with mic border
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
                if (seat.isLocked)
                  Positioned(
                    bottom: isEmpty ? 0 : 0,
                    left: 0,
                    child: Container(
                      padding: const EdgeInsets.all(0.4),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade800,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 0.4),
                      ),
                      child: const Icon(Icons.lock, color: Colors.white, size: 6.5),
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
    if (path.startsWith('http')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Image.asset(fallback, fit: BoxFit.cover),
      );
    }
    return Image.asset(path.startsWith('assets/') ? path : fallback, fit: BoxFit.cover);
  }

  Widget _buildSafeAvatarFrame(String? path) {
    if (path == null || path.isEmpty) return const SizedBox.shrink();
    
    // Check if it's an SVGA file - check for .svga anywhere in URL (Cloudinary may add query params)
    final lowerPath = path.toLowerCase();
    final cleanUrl = lowerPath.split('?').first;
    if (cleanUrl.endsWith('.svga') || lowerPath.contains('.svga')) {
      return _SvgaFrameWidget(path: path);
    }
    
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
              color: Colors.greenAccent.withValues(alpha: 0.7 + (0.3 * _controller.value)),
              width: 1.0,
            ),
            color: Colors.greenAccent.withValues(alpha: 0.1 + (0.1 * _controller.value)),
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

class _SvgaFrameWidget extends StatefulWidget {
  final String path;
  const _SvgaFrameWidget({required this.path});

  @override
  State<_SvgaFrameWidget> createState() => _SvgaFrameWidgetState();
}

class _SvgaFrameWidgetState extends State<_SvgaFrameWidget> with SingleTickerProviderStateMixin {
  SVGAAnimationController? _controller;

  @override
  void initState() {
    super.initState();
    _controller = SVGAAnimationController(vsync: this);
    _load();
  }

  Future<void> _load() async {
    try {
      final resolved = await SvgaAssetService.instance.resolve(widget.path);
      final parser = SVGAParser();
      final videoItem = ImageUtils.isHttpUrl(resolved)
          ? await parser.decodeFromURL(resolved)
          : await parser.decodeFromAssets(resolved);
      if (mounted && _controller != null) {
        _controller!.videoItem = videoItem;
        _controller!.repeat();
      }
    } catch (e) {
      debugPrint('SVGA frame load error: $e');
    }
  }

  @override
  void dispose() {
    _controller?.stop();
    _controller?.dispose();
    _controller = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || _controller!.videoItem == null) {
      // Fallback: try showing static image if SVGA didn't load
      if (widget.path.startsWith('http')) {
        return Image.network(widget.path, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const SizedBox.shrink());
      }
      return Image.asset(widget.path, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const SizedBox.shrink());
    }
    return SVGAImage(_controller!, fit: BoxFit.contain);
  }
}
