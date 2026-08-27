import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import '../controllers/admin_auth_controller.dart';
import '../controllers/admin_rbac_controller.dart';

class AdminAIConfigScreen extends StatefulWidget {
  final AdminAuthController adminAuthController;
  final int initialTab;
  
  const AdminAIConfigScreen({
    super.key,
    required this.adminAuthController,
    this.initialTab = 0,
  });

  @override
  State<AdminAIConfigScreen> createState() => _AdminAIConfigScreenState();
}

class _AdminAIConfigScreenState extends State<AdminAIConfigScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _rbacController = AdminRBACController();
  
  final _systemPromptController = TextEditingController();
  final _faqRulesController = TextEditingController();
  final _greetingController = TextEditingController();
  final _securityPolicyController = TextEditingController();
  final _moderationRulesController = TextEditingController();
  
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadAIConfig();
  }

  @override
  void dispose() {
    _systemPromptController.dispose();
    _faqRulesController.dispose();
    _greetingController.dispose();
    _securityPolicyController.dispose();
    _moderationRulesController.dispose();
    super.dispose();
  }

  Future<void> _loadAIConfig() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final doc = await _firestore
          .collection('system_config')
          .doc('ai_support')
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _systemPromptController.text = data['systemPrompt'] ?? '';
          _faqRulesController.text = data['faqRules'] ?? '';
          _greetingController.text = data['greeting'] ?? '';
          _securityPolicyController.text = data['securityPolicy'] ?? '';
          _moderationRulesController.text = data['moderationRules'] ?? '';
          _isLoading = false;
        });
      } else {
        setState(() {
          _systemPromptController.text = _getDefaultSystemPrompt();
          _faqRulesController.text = _getDefaultFAQRules();
          _greetingController.text = _getDefaultGreeting();
          _securityPolicyController.text = _getDefaultSecurityPolicy();
          _moderationRulesController.text = _getDefaultModerationRules();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading AI config: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveAIConfig() async {
    if (!_rbacController.hasPermission(
      widget.adminAuthController.currentUserRole!,
      RBACAction.configureAI,
    )) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Insufficient permissions to configure AI'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await _firestore
          .collection('system_config')
          .doc('ai_support')
          .set({
        'systemPrompt': _systemPromptController.text,
        'faqRules': _faqRulesController.text,
        'greeting': _greetingController.text,
        'securityPolicy': _securityPolicyController.text,
        'moderationRules': _moderationRulesController.text,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': widget.adminAuthController.currentUserId,
      }, SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('AI configuration saved successfully'),
          backgroundColor: Colors.green,
        ),
      );
      setState(() {
        _isSaving = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save AI config: $e'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isSaving = false;
      });
    }
  }

  String _getDefaultSystemPrompt() {
    return '''You are an AI customer support assistant for Ayam Chat, a social voice chat application. Your role is to help users with:

1. Account issues (login, registration, profile settings)
2. VIP and SVIP membership questions
3. Gift and virtual currency inquiries
4. Room creation and management
5. Agency and agent-related questions
6. Technical troubleshooting

Always be polite, helpful, and professional. If you cannot resolve an issue, escalate to human support. Never share sensitive user information or system internals.

Current App Version: 1.0.0
Supported Languages: English, Arabic, Spanish, French, German, Turkish, Indonesian, Hindi, Portuguese, Russian''';
  }

  String _getDefaultFAQRules() {
    return '''FAQ Rules:

1. VIP Membership:
   - VIP levels 1-7 provide increasing benefits
   - SVIP provides premium features
   - Membership durations: 7 days, 30 days, 90 days, 365 days
   - Cannot transfer VIP status between accounts

2. Virtual Currency:
   - Coins are used for gifts and purchases
   - Gems are premium currency
   - Recharge through official channels only
   - Report unauthorized transactions immediately

3. Room Management:
   - Maximum 20 users per room
   - 8 mic seats available
   - Host can mute/kick users
   - Room categories: Social, Gaming, Music, Dating

4. Agency:
   - Agents earn commission on gifts
   - Agency approval required
   - Commission rates vary by level
   - Daily payout processing

5. Account Security:
   - Never share password
   - Enable 2FA when available
   - Report suspicious activity
   - Use official app only''';
  }

  String _getDefaultGreeting() {
    return '''Welcome to Ayam Chat Support! 👋

I'm here to help you with any questions or issues you might have. Please select a topic or describe your problem:

📱 Account & Login
💎 VIP & Membership
🎁 Gifts & Currency
🎤 Rooms & Voice Chat
🏢 Agency & Earnings
🔧 Technical Support

How can I assist you today?''';
  }

  String _getDefaultSecurityPolicy() {
    return '''Security Policy & Rules:

1. Account Safety:
   - Never share your password or personal information
   - Report suspicious activity immediately
   - Use official app versions only

2. Prohibited Content:
   - Hate speech, harassment, or discrimination
   - Explicit or inappropriate content
   - Spam or fraudulent activities
   - Threats or violent content

3. Privacy:
   - Respect other users' privacy
   - Do not share personal information without consent
   - Report privacy violations

4. Fair Play:
   - No cheating or exploiting bugs
   - No automated bots or scripts
   - Report bugs to support team

5. Consequences:
   - Warning for first offense
   - Temporary ban for repeated violations
   - Permanent ban for severe violations''';
  }

  String _getDefaultModerationRules() {
    return '''AI Moderation Authority:

The AI Support Assistant has the following moderation capabilities:

1. Automated Content Analysis:
   - Analyze uploaded screenshots for offensive content
   - Review video clips for policy violations
   - Detect inappropriate language in reports

2. User Complaint Processing:
   - Review user-submitted complaints
   - Analyze evidence provided
   - Determine severity of violations

3. Automatic Banning Authority:
   - Can ban users for severe violations
   - Can issue temporary bans for moderate violations
   - Can flag users for human review

4. Ban Criteria:
   - Severe: Immediate permanent ban (hate speech, threats, explicit content)
   - Moderate: 7-30 day ban (harassment, repeated offenses)
   - Minor: Warning and monitoring

5. Appeal Process:
   - Users can appeal AI decisions
   - Human admin reviews appeals
   - Decision can be overturned''';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ai_security_center'.tr()),
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveAIConfig,
              tooltip: 'Save Configuration',
            ),
        ],
      ),
      body: Container(
        color: Colors.grey.shade100,
        child: DefaultTabController(
          initialIndex: widget.initialTab,
          length: 2,
          child: Column(
            children: [
              Container(
                color: Colors.white,
                child: TabBar(
                  labelColor: Colors.blue.shade900,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Colors.blue.shade900,
                  tabs: [
                    Tab(text: 'ai_config'.tr()),
                    Tab(text: 'security_policy'.tr()),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildAIConfigTab(),
                    _buildSecurityPolicyTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAIConfigTab() {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // System Prompt
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.psychology, color: Colors.blue.shade700),
                            const SizedBox(width: 8),
                            Text(
                              'system_prompt'.tr(),
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _systemPromptController,
                          maxLines: 15,
                          decoration: InputDecoration(
                            hintText: 'Enter system prompt for AI...',
                            border: const OutlineInputBorder(),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'This prompt defines the AI\'s personality and capabilities.',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // FAQ Rules
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.rule, color: Colors.green.shade700),
                            const SizedBox(width: 8),
                            Text(
                              'faq_rules'.tr(),
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _faqRulesController,
                          maxLines: 15,
                          decoration: InputDecoration(
                            hintText: 'Enter FAQ rules and guidelines...',
                            border: const OutlineInputBorder(),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Rules that the AI follows when answering FAQ questions.',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Greeting
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.waving_hand, color: Colors.orange.shade700),
                            const SizedBox(width: 8),
                            Text(
                              'Greeting Message',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _greetingController,
                          maxLines: 8,
                          decoration: InputDecoration(
                            hintText: 'Enter initial greeting message...',
                            border: const OutlineInputBorder(),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'The AI\'s welcome message when users start a conversation.',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Reset Button
                Center(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _systemPromptController.text = _getDefaultSystemPrompt();
                        _faqRulesController.text = _getDefaultFAQRules();
                        _greetingController.text = _getDefaultGreeting();
                      });
                    },
                    icon: const Icon(Icons.refresh),
                    label: Text('Reset to Defaults'),
                  ),
                ),
              ],
            ),
          );
  }

  Widget _buildSecurityPolicyTab() {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Security Policy
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.security, color: Colors.red.shade700),
                            const SizedBox(width: 8),
                            Text(
                              'security_policy'.tr(),
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _securityPolicyController,
                          maxLines: 15,
                          decoration: InputDecoration(
                            hintText: 'Enter security policy and rules...',
                            border: const OutlineInputBorder(),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Security rules that the AI enforces.',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Moderation Rules
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.gavel, color: Colors.purple.shade700),
                            const SizedBox(width: 8),
                            Text(
                              'moderation_rules'.tr(),
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _moderationRulesController,
                          maxLines: 15,
                          decoration: InputDecoration(
                            hintText: 'Enter AI moderation authority rules...',
                            border: const OutlineInputBorder(),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Rules for automated banning and content moderation.',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Reset Button
                Center(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _securityPolicyController.text = _getDefaultSecurityPolicy();
                        _moderationRulesController.text = _getDefaultModerationRules();
                      });
                    },
                    icon: const Icon(Icons.refresh),
                    label: Text('Reset to Defaults'),
                  ),
                ),
              ],
            ),
          );
  }
}
