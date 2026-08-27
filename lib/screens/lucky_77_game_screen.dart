import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../controllers/user_controller.dart';
import '../controllers/wallet_controller.dart';
import 'lucky_77_leaderboard_screen.dart';

class Lucky77GameScreen extends StatefulWidget {
  const Lucky77GameScreen({super.key});

  @override
  State<Lucky77GameScreen> createState() => _Lucky77GameScreenState();
}

class _Lucky77GameScreenState extends State<Lucky77GameScreen> with SingleTickerProviderStateMixin {
  // Game state and data
  int selectedChip = 2000;
  int betPlum = 0;
  int betSeven = 0;
  int betWatermelon = 0;

  // Track last bets for Repeat feature
  int lastBetPlum = 0;
  int lastBetSeven = 0;
  int lastBetWatermelon = 0;

  // Mock total table bets
  int totalTablePlum = 12500;
  int totalTableSeven = 5400;
  int totalTableWatermelon = 8900;

  bool isSpinning = false;
  bool isMuted = false;
  double wheelRotation = 0.0;
  String resultMessage = "اختر رقاقة ثم أضف رهانك!";

  late AnimationController _animationController;

  // Timer state
  int countdownSeconds = 10;
  Timer? _countdownTimer;

  // History mock data - Strictly 3 official symbols (Eggplant, 77, Watermelon)
  List<String> historyItems = ["🍆", "77", "🍉", "🍆", "🍆", "77", "🍉", "🍆"];

  // Wheel Segments Definition (8 slices) - Strictly 3 official symbols
  final List<Map<String, dynamic>> _segments = [
    {'type': 'seven', 'label': '77', 'asset': 'assets/icons/slazzer-preview-d4a4e.png'},
    {'type': 'plum', 'label': '🍆', 'asset': 'assets/icons/slazzer-preview-y0isr.png'},
    {'type': 'watermelon', 'label': '🍉', 'asset': 'assets/icons/slazzer-preview-v3kzu.png'},
    {'type': 'plum', 'label': '🍆', 'asset': 'assets/icons/slazzer-preview-y0isr.png'},
    {'type': 'seven', 'label': '77', 'asset': 'assets/icons/slazzer-preview-d4a4e.png'},
    {'type': 'plum', 'label': '🍆', 'asset': 'assets/icons/slazzer-preview-y0isr.png'},
    {'type': 'watermelon', 'label': '🍉', 'asset': 'assets/icons/slazzer-preview-v3kzu.png'},
    {'type': 'plum', 'label': '🍆', 'asset': 'assets/icons/slazzer-preview-y0isr.png'},
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _startCountdown();
    WalletController().addListener(_onWalletUpdate);
    UserController().addListener(_onWalletUpdate);
  }

  void _onWalletUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    WalletController().removeListener(_onWalletUpdate);
    UserController().removeListener(_onWalletUpdate);
    _animationController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _playSoundEffect(String soundName) {
    if (isMuted) return;
    debugPrint("Playing sound: $soundName");
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    setState(() => countdownSeconds = 10);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (countdownSeconds > 0) {
        setState(() {
          countdownSeconds--;
        });
      } else {
        timer.cancel();
        _startSpin();
      }
    });
  }

  void _startSpin() {
    if (isSpinning) return;

    _playSoundEffect("spin.mp3");
    setState(() {
      isSpinning = true;
      resultMessage = "العجلة تدور الآن...";
      _countdownTimer?.cancel();
    });

    final random = Random();
    int winningIndex = random.nextInt(_segments.length);

    double segmentAngle = (2 * pi) / _segments.length;
    double targetAngle = (3 * pi / 2) - (winningIndex * segmentAngle + segmentAngle / 2);

    double currentRotation = wheelRotation;
    double minRotations = 10 * 2 * pi;
    double targetRotation = currentRotation + minRotations;

    double currentAngleMod = targetRotation % (2 * pi);
    targetRotation = targetRotation - currentAngleMod + targetAngle;

    if (targetRotation <= currentRotation + (5 * 2 * pi)) {
      targetRotation += 2 * pi;
    }

    _animationController.reset();
    final animation = Tween<double>(begin: currentRotation, end: targetRotation).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    animation.addListener(() {
      setState(() {
        wheelRotation = animation.value;
      });
    });

    _animationController.forward().then((_) {
      _calculateWin(winningIndex);
      _startCountdown();
    });
  }

  void _calculateWin(int winningIndex) {
    final segment = _segments[winningIndex];
    String type = segment['type'];
    int winAmount = 0;
    String outcomeName = "";

    if (type == 'plum') {
      outcomeName = "باذنجان (x2)";
      winAmount = betPlum * 2;
    } else if (type == 'seven') {
      outcomeName = "77 (x8)";
      winAmount = betSeven * 8;
    } else {
      outcomeName = "بطيخ (x2)";
      winAmount = betWatermelon * 2;
    }

    bool hadBet = (betPlum + betSeven + betWatermelon) > 0;

    if (winAmount > 0) {
      _playSoundEffect("win.mp3");
      WalletController().addDiamonds(winAmount);
    } else if (hadBet) {
      _playSoundEffect("lose.mp3");
    }

    if (hadBet) {
      _showResultDialog(winAmount, segment['label'], winAmount > 0);
    }

    setState(() {
      isSpinning = false;
      if (winAmount > 0) {
        resultMessage = "النتيجة: $outcomeName! ربحت: $winAmount";
      } else {
        resultMessage = "النتيجة: ${segment['label']}. حظ أوفر!";
      }

      historyItems.insert(0, segment['label']);
      if (historyItems.length > 8) historyItems.removeLast();

      lastBetPlum = betPlum;
      lastBetSeven = betSeven;
      lastBetWatermelon = betWatermelon;

      betPlum = 0;
      betSeven = 0;
      betWatermelon = 0;
    });
  }

  void _showResultDialog(int winAmount, String symbol, bool isWin) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        Timer(const Duration(seconds: 4), () {
          if (Navigator.canPop(context)) Navigator.pop(context);
        });

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 40),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isWin
                    ? [const Color(0xFF6A11CB), const Color(0xFF2575FC)]
                    : [const Color(0xFF232526), const Color(0xFF414345)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: isWin ? Colors.amber : Colors.grey, width: 4),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isWin ? "تهانينا للمفازين!" : "حظاً سعيداً",
                  style: TextStyle(
                    color: isWin ? Colors.amber : Colors.white70,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white24, width: 2),
                  ),
                  child: Text(
                    symbol,
                    style: const TextStyle(fontSize: 48),
                  ),
                ),
                const SizedBox(height: 20),
                if (isWin) ...[
                  const Text(
                    "لقد ربحت",
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.diamond, color: Colors.blueAccent, size: 28),
                      const SizedBox(width: 8),
                      Text(
                        "$winAmount",
                        style: const TextStyle(
                          color: Colors.greenAccent,
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ] else
                  const Text(
                    "لم يحالفك الحظ هذه المرة، حاول مجدداً!",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white54, fontSize: 16),
                  ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isWin ? Colors.amber : Colors.white24,
                      foregroundColor: isWin ? Colors.white : Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      "إغلاق",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _addBet(String type) {
    if (isSpinning) return;

    List<String> activeOptions = [];
    if (betPlum > 0) activeOptions.add('plum');
    if (betSeven > 0) activeOptions.add('seven');
    if (betWatermelon > 0) activeOptions.add('watermelon');

    if (!activeOptions.contains(type) && activeOptions.length >= 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("مسموح بالرهان على خانتين فقط", textAlign: TextAlign.right),
          backgroundColor: Colors.redAccent,
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }

    if (WalletController().diamonds < selectedChip) {
      _showRechargeDialog();
      return;
    }

    _playSoundEffect("chip_click.mp3");
    if (WalletController().spendDiamonds(selectedChip)) {
      setState(() {
        if (type == 'plum') {
          betPlum += selectedChip;
          totalTablePlum += selectedChip;
        } else if (type == 'seven') {
          betSeven += selectedChip;
          totalTableSeven += selectedChip;
        } else if (type == 'watermelon') {
          betWatermelon += selectedChip;
          totalTableWatermelon += selectedChip;
        }
      });
    }
  }

  void _repeatLastBet() {
    if (isSpinning) return;
    int totalRepeat = lastBetPlum + lastBetSeven + lastBetWatermelon;
    if (totalRepeat == 0) return;

    if (WalletController().diamonds < totalRepeat) {
      _showRechargeDialog();
      return;
    }

    _playSoundEffect("chip_click.mp3");
    if (WalletController().spendDiamonds(totalRepeat)) {
      setState(() {
        betPlum = lastBetPlum;
        betSeven = lastBetSeven;
        betWatermelon = lastBetWatermelon;
        totalTablePlum += lastBetPlum;
        totalTableSeven += lastBetSeven;
        totalTableWatermelon += lastBetWatermelon;
        resultMessage = "تم تكرار الرهان السابق!";
      });
      _startCountdown();
    }
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A0045),
        title: const Text("كيف ألعاب", style: TextStyle(color: Colors.amber), textAlign: TextAlign.right),
        content: const Text(
          "1. اختر قيمة الرقاقة من الأسفل.\n"
              "2. ضع رهاناتك على الرموز الثلاثة (بطيخ، 77، باذنجان).\n"
              "3. مسموح بالرهان على خانتين فقط في الجولة الواحدة.\n"
              "4. انتظر انتهاء الوقت لتدور العجلة.\n"
              "5. 77 يضاعف الربح x8، والبطيخ والباذنجان x2.",
          style: TextStyle(color: Colors.white, fontSize: 14),
          textAlign: TextAlign.right,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("موافق", style: TextStyle(color: Colors.amber)),
          ),
        ],
      ),
    );
  }

  void _showHistoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A0045),
        title: const Text("سجل النتائج", style: TextStyle(color: Colors.amber), textAlign: TextAlign.right),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: historyItems.map((symbol) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Text("النتيجة السابقة: $symbol", style: const TextStyle(color: Colors.white70)),
            )).toList(),
          ),
        ),
      ),
    );
  }

  void _showLeaderboard() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const Lucky77LeaderboardScreen()));
  }

  void _showRechargeDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2A0045),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        height: 180,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text("رصيدك غير كافٍ!", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const Spacer(),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
              onPressed: () => Navigator.pop(context),
              child: const Text("شحن الرصيد", style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Reduced height to expose Room Mic seats at the top
    final panelHeight = screenHeight * 0.63;

    return Material(
      color: Colors.transparent, // Top region remains transparent for room mics
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          height: panelHeight,
          width: screenWidth,
          decoration: const BoxDecoration(
            color: Color(0xFF2A0045),
            image: DecorationImage(
              image: AssetImage('assets/icons/slazzer-preview-zcm73.png'),
              fit: BoxFit.cover,
            ),
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                _buildPanelHeader(context),

                // TOP: Wheel Stack
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      physics: const NeverScrollableScrollPhysics(),
                      child: _buildWheelSystem(screenWidth),
                    ),
                  ),
                ),

                // MID-TOP: Result Bar & Mini History Row
                _buildResultHistoryBar(),

                // MID-BOTTOM: Betting Cards Frame
                _buildBettingCards(screenWidth),

                // BOTTOM-MOST: Unified Bottom Bar
                _buildBottomBar(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultHistoryBar() {
    return Container(
      width: double.infinity,
      color: const Color(0xFF2A0045),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Win Status Bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              border: const Border(
                top: BorderSide(color: Colors.white10, width: 0.5),
                bottom: BorderSide(color: Colors.white10, width: 0.5),
              ),
            ),
            child: Text(
              resultMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          // History strip
          Container(
            width: double.infinity,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF1A0033).withValues(alpha: 0.6),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: historyItems.map((symbol) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6.0),
                    child: Text(symbol, style: const TextStyle(fontSize: 16)),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPanelHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6), // Tight header padding
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Top Left: Back button & Sound toggle button
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.maybePop(context),
                child: CircleAvatar(
                  radius: 14,
                  backgroundColor: Colors.purple.shade800,
                  child: const Icon(Icons.arrow_back, color: Colors.white, size: 16),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => setState(() => isMuted = !isMuted),
                child: CircleAvatar(
                  radius: 14,
                  backgroundColor: Colors.purple.shade800,
                  child: Icon(isMuted ? Icons.volume_off : Icons.volume_up, color: Colors.white, size: 16),
                ),
              ),
            ],
          ),
          // Center: Online users count
          Row(
            children: [
              const Icon(Icons.wifi, color: Colors.greenAccent, size: 14),
              const SizedBox(width: 4),
              const Text(
                "1,245",
                style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          // Top Right: Online list, Help button & History button
          Row(
            children: [
              GestureDetector(
                onTap: () {},
                child: CircleAvatar(
                  radius: 14,
                  backgroundColor: Colors.purple.shade800,
                  child: const Icon(Icons.people_alt, color: Colors.white, size: 14),
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: _showHelpDialog,
                child: CircleAvatar(
                  radius: 14,
                  backgroundColor: Colors.purple.shade800,
                  child: const Text("?", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: _showHistoryDialog,
                child: CircleAvatar(
                  radius: 14,
                  backgroundColor: Colors.purple.shade800,
                  child: const Icon(Icons.assignment, color: Colors.white, size: 14),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWheelSystem(double maxWidth) {
    const double baseSize = 175.0; // Reduced to 175.0 to fit assembly comfortably
    const double propWidth = baseSize * 1.5;
    const double propHeight = 245.0; // Fixed height to fit all components including decor

    return Container(
      margin: const EdgeInsets.only(top: 28), // Shifted wheel down (~10-15px more) for perfect alignment
      width: propWidth,
      height: propHeight,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // 1. Golden Side Pillars and Stand Base
          Image.asset(
            'assets/icons/slazzer-preview-7mgd7.png',
            width: propWidth,
            height: propHeight,
            fit: BoxFit.contain,
          ),
          // 2. Golden Wheel Frame
          Image.asset(
            'assets/icons/slazzer-preview-gvd2t.png',
            width: baseSize * 1.25,
            fit: BoxFit.contain,
          ),
          // 3. Spinning Inner Disk
          Transform.rotate(
            angle: wheelRotation,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Image.asset('assets/icons/slazzer-preview-qedbd.png', width: baseSize * 0.95, fit: BoxFit.contain),
                ...List.generate(_segments.length, (index) {
                  double angle = (index * 2 * pi / _segments.length) + (pi / _segments.length);
                  return Transform.rotate(
                    angle: angle,
                    child: Transform.translate(
                      offset: Offset(0, -baseSize * 0.31), // Set to strictly -baseSize * 0.31
                      child: Image.asset(
                        _segments[index]['asset'],
                        width: baseSize * 0.20, // Icons sized at baseSize * 0.20
                        height: baseSize * 0.20,
                        fit: BoxFit.contain,
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          // 4. Crown Decor - Set top position to 15
          Positioned(
            top: 15,
            child: Image.asset('assets/icons/slazzer-preview-u2hl5.png', width: baseSize * 0.45, fit: BoxFit.contain),
          ),
          // 5. Golden Winning Chopstick Pointers - Set top position to 38
          Positioned(
            top: 38,
            child: Image.asset(
              'assets/icons/slazzer-preview-8e1uh.png',
              width: baseSize * 0.22,
              fit: BoxFit.contain,
            ),
          ),
          // 6. Timer Circle
          Container(
            width: baseSize * 0.22,
            height: baseSize * 0.22,
            decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
            child: Center(
              child: Text(
                "$countdownSeconds",
                style: TextStyle(color: Colors.white, fontSize: baseSize * 0.09, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          // REPEAT BUTTON
          Positioned(
            right: 0,
            bottom: 30,
            child: GestureDetector(
              onTap: _repeatLastBet,
              child: Image.asset('assets/icons/slazzer-preview-cmxuq.png', width: baseSize * 0.35, fit: BoxFit.contain),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBettingCards(double maxWidth) {
    return Container(
      width: maxWidth,
      height: 105,
      margin: EdgeInsets.zero,
      padding: EdgeInsets.zero,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/icons/slazzer-preview-f11g1.png'),
          fit: BoxFit.fill,
        ),
      ),
      child: Row(
        children: [
          Expanded(child: _buildBetSlot(
            mainAsset: 'assets/icons/slazzer-preview-v3kzu.png',
            multiplierAsset: 'assets/icons/slazzer-preview-2ryyx.png',
            userBet: betWatermelon,
            totalTableBet: totalTableWatermelon,
            onTap: () => _addBet('watermelon'),
            mainSize: 40,
          )),
          Expanded(child: _buildBetSlot(
            mainAsset: 'assets/icons/slazzer-preview-d4a4e.png',
            multiplierAsset: 'assets/icons/slazzer-preview-21c59.png',
            userBet: betSeven,
            totalTableBet: totalTableSeven,
            onTap: () => _addBet('seven'),
            mainSize: 48,
          )),
          Expanded(child: _buildBetSlot(
            mainAsset: 'assets/icons/slazzer-preview-y0isr.png',
            multiplierAsset: 'assets/icons/slazzer-preview-2ryyx.png',
            userBet: betPlum,
            totalTableBet: totalTablePlum,
            onTap: () => _addBet('plum'),
            mainSize: 40,
          )),
        ],
      ),
    );
  }

  Widget _buildBetSlot({
    required String mainAsset,
    required String multiplierAsset,
    required int userBet,
    required int totalTableBet,
    required VoidCallback onTap,
    double mainSize = 100,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        color: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "$totalTableBet",
              style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
            ),
            Image.asset(mainAsset, width: mainSize, height: mainSize, fit: BoxFit.contain),
            Image.asset(multiplierAsset, height: 14, fit: BoxFit.contain),
            const SizedBox(height: 1),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: userBet > 0 ? Colors.amber.withValues(alpha: 0.3) : Colors.black26,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: userBet > 0 ? Colors.amber : Colors.transparent, width: 0.5),
              ),
              child: Text(
                userBet > 0 ? "$userBet" : "رهانك",
                style: TextStyle(
                  color: userBet > 0 ? Colors.white : Colors.white38,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(12, 4, 12, 4 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: const Color(0xFF1A0033).withValues(alpha: 0.95),
        border: Border(top: BorderSide(color: Colors.white10, width: 0.8)),
      ),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // LEFT: User Profile Section
            _buildUserSection(),
            // RIGHT: 4 Betting Chips + Trophy Icon
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildChipBtn(2000, 'assets/icons/slazzer-preview-wyd1k.png'),
                _buildChipBtn(10000, 'assets/icons/slazzer-preview-yk247.png'),
                _buildChipBtn(50000, 'assets/icons/slazzer-preview-xa3j6.png'),
                _buildChipBtn(100000, 'assets/icons/slazzer-preview-psp1a.png'),
                const SizedBox(width: 8),
                // Trophy / Leaderboard Icon restored to Bottom Right
                GestureDetector(
                  onTap: _showLeaderboard,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.amber.withOpacity(0.5), width: 1),
                    ),
                    child: const Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 20),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserSection() {
    String pic = UserController().profilePic;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 13,
            backgroundColor: Colors.amber.withValues(alpha: 0.2),
            backgroundImage: pic.startsWith('http')
                ? NetworkImage(pic) as ImageProvider
                : AssetImage(pic),
          ),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "${UserController().name} (ID: ${UserController().id})",
                style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
              ),
              GestureDetector(
                onTap: _showRechargeDialog,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.diamond, size: 10, color: Colors.blueAccent),
                    const SizedBox(width: 2),
                    Text(
                      "${WalletController().diamonds}",
                      style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 9),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChipBtn(int amount, String assetPath) {
    bool isSelected = selectedChip == amount;
    return GestureDetector(
      onTap: () {
        _playSoundEffect("chip_select");
        setState(() {
          selectedChip = amount;
        });
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: isSelected ? [
            BoxShadow(
              color: Colors.amber.withValues(alpha: 0.8),
              blurRadius: 8,
              spreadRadius: 1,
            )
          ] : null,
        ),
        child: Image.asset(assetPath, fit: BoxFit.contain),
      ),
    );
  }
}
