import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Demo onboarding screen shown BEFORE the sign-in screen.
/// Gives users a taste of EduPaths without needing an account.
///
/// Flow: DemoOnboardingScreen → AuthScreen (sign-in/sign-up)
///
/// Upload to: lib/screens/onboarding/demo_onboarding_screen.dart
///
/// ROUTER: In your router config, set the initial route to '/demo'
/// (or whatever path you choose). After completing/skipping, push to '/auth'.
///
/// The screen is a 3-step mini activity:
///   Step 1 – "Pick your vibe" (choose 1 of 4 interest tiles)
///   Step 2 – Reveal a matching career teaser card
///   Step 3 – Unlock screen: show a blurred list of more matches + CTA

class DemoOnboardingScreen extends StatefulWidget {
  const DemoOnboardingScreen({super.key});

  @override
  State<DemoOnboardingScreen> createState() => _DemoOnboardingScreenState();
}

class _DemoOnboardingScreenState extends State<DemoOnboardingScreen>
    with TickerProviderStateMixin {
  int _step = 0; // 0 = pick vibe, 1 = reveal, 2 = unlock CTA
  String? _chosenVibe;

  late final AnimationController _cardController;
  late final Animation<double> _cardScale;
  late final Animation<double> _cardOpacity;

  // ── Static demo data ─────────────────────────────────────────────────
  static const _vibes = [
    {'label': 'Tech & AI', 'emoji': '💻', 'color': 0xFF4F46E5},
    {'label': 'Health & Care', 'emoji': '🏥', 'color': 0xFF059669},
    {'label': 'Business', 'emoji': '📈', 'color': 0xFF0891B2},
    {'label': 'Creative', 'emoji': '🎨', 'color': 0xFFDB2777},
  ];

  static const _matchData = {
    'Tech & AI': {
      'career': 'Software Engineer',
      'emoji': '👨‍💻',
      'salary': '£45k–£90k',
      'fact': 'UK tech jobs grew 40% in 3 years',
      'routes': ['Computer Science degree', 'Degree Apprenticeship', 'Bootcamp + self-study'],
      'color': 0xFF4F46E5,
    },
    'Health & Care': {
      'career': 'Registered Nurse',
      'emoji': '👩‍⚕️',
      'salary': '£28k–£50k',
      'fact': 'NHS employs 1.2 million people',
      'routes': ['Nursing degree', 'Nursing Degree Apprenticeship', 'Access to HE + degree'],
      'color': 0xFF059669,
    },
    'Business': {
      'career': 'Marketing Manager',
      'emoji': '📊',
      'salary': '£35k–£70k',
      'fact': '500k+ marketing roles in the UK',
      'routes': ['Business/Marketing degree', 'Level 3–6 Apprenticeship', 'CIM qualifications'],
      'color': 0xFF0891B2,
    },
    'Creative': {
      'career': 'UX Designer',
      'emoji': '✏️',
      'salary': '£30k–£65k',
      'fact': 'Design skills are in the top 10 most in-demand',
      'routes': ['Graphic Design / HCI degree', 'Design Apprenticeship', 'Portfolio + self-study'],
      'color': 0xFFDB2777,
    },
  };

  // Blurred "more matches" to tease behind the unlock screen
  static const _blurredCareers = [
    'Data Scientist', 'Cybersecurity Analyst', 'Product Manager',
    'Game Developer', 'AI Researcher', 'Cloud Architect',
  ];

  @override
  void initState() {
    super.initState();
    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _cardScale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _cardController, curve: Curves.easeOutBack),
    );
    _cardOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _cardController, curve: Curves.easeIn),
    );
  }

  @override
  void dispose() {
    _cardController.dispose();
    super.dispose();
  }

  void _pickVibe(String vibe) {
    setState(() {
      _chosenVibe = vibe;
      _step = 1;
    });
    _cardController.forward(from: 0);
  }

  void _goToUnlock() => setState(() => _step = 2);

  void _goToSignUp() => context.go('/auth');

  // ── Build ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FF),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.05, 0),
                end: Offset.zero,
              ).animate(anim),
              child: child,
            ),
          ),
          child: _step == 0
              ? _buildPickVibe()
              : _step == 1
                  ? _buildReveal()
                  : _buildUnlock(),
        ),
      ),
    );
  }

  // ── Step 0: Pick your vibe ────────────────────────────────────────────
  Widget _buildPickVibe() {
    return Column(
      key: const ValueKey('pick'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Spacer(flex: 1),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF6C63FF).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '✨ Try EduPaths — no sign-up needed',
                  style: TextStyle(
                    color: Color(0xFF6C63FF),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'What\'s your vibe?',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Tap one and we\'ll instantly show you where it could take you.',
                style: TextStyle(fontSize: 15, color: Colors.black54, height: 1.5),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        // 2×2 grid of vibe tiles
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 1.2,
            children: _vibes.map((v) => _VibeTile(
              label: v['label'] as String,
              emoji: v['emoji'] as String,
              color: Color(v['color'] as int),
              onTap: () => _pickVibe(v['label'] as String),
            )).toList(),
          ),
        ),
        const Spacer(flex: 2),
        // Already have account
        Center(
          child: TextButton(
            onPressed: _goToSignUp,
            child: const Text(
              'Already have an account? Sign in',
              style: TextStyle(color: Colors.black45, fontSize: 14),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // ── Step 1: Reveal matching career ────────────────────────────────────
  Widget _buildReveal() {
    final match = _matchData[_chosenVibe]!;
    final color = Color(match['color'] as int);
    final routes = match['routes'] as List<String>;

    return ScaleTransition(
      scale: _cardScale,
      child: FadeTransition(
        opacity: _cardOpacity,
        child: Column(
          key: const ValueKey('reveal'),
          children: [
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  Text(
                    'Your vibe → Your future',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${_chosenVibe ?? ''} could lead to...',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Match card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withOpacity(0.75)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.35),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      match['emoji'] as String,
                      style: const TextStyle(fontSize: 44),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      match['career'] as String,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.payments_outlined,
                            color: Colors.white70, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          match['salary'] as String,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.lightbulb_outline,
                              color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              match['fact'] as String,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Routes to get there:',
                      style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    ...routes.map((r) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              const Icon(Icons.arrow_right,
                                  color: Colors.white70, size: 18),
                              const SizedBox(width: 4),
                              Text(r,
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 14)),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  onPressed: _goToUnlock,
                  child: const Text(
                    'See all my matches →',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _goToSignUp,
              child: const Text('Sign in instead',
                  style: TextStyle(color: Colors.black45)),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ── Step 2: Unlock / CTA ──────────────────────────────────────────────
  Widget _buildUnlock() {
    final match = _matchData[_chosenVibe ?? 'Tech & AI']!;
    final color = Color(match['color'] as int);

    return Column(
      key: const ValueKey('unlock'),
      children: [
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your matches are ready 🔓',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const Text(
                'Create a free account to unlock your full career roadmap, routes, and EduBot AI.',
                style: TextStyle(fontSize: 15, color: Colors.black54, height: 1.5),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // Blurred career list
        SizedBox(
          height: 220,
          child: Stack(
            children: [
              ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _blurredCareers.length,
                itemBuilder: (context, i) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.work_outline, color: color, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        _blurredCareers[i],
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w500),
                      ),
                      const Spacer(),
                      const Icon(Icons.arrow_forward_ios,
                          size: 14, color: Colors.black26),
                    ],
                  ),
                ),
              ),
              // Blur overlay — bottom 2/3 is obscured
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 160,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        const Color(0xFFF8F7FF).withOpacity(0),
                        const Color(0xFFF8F7FF),
                      ],
                    ),
                  ),
                ),
              ),
              // Lock icon
              const Positioned(
                bottom: 10,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock_outline, size: 20, color: Colors.black38),
                    SizedBox(width: 6),
                    Text(
                      '+ many more matches waiting for you',
                      style: TextStyle(color: Colors.black38, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        // CTA buttons
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  onPressed: _goToSignUp,
                  child: const Text(
                    'Create Free Account',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side:
                        const BorderSide(color: Color(0xFF6C63FF), width: 1.5),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _goToSignUp,
                  child: const Text(
                    'Sign In',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6C63FF)),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
      ],
    );
  }
}

// ── Supporting widget ─────────────────────────────────────────────────────
class _VibeTile extends StatelessWidget {
  final String label;
  final String emoji;
  final Color color;
  final VoidCallback onTap;

  const _VibeTile({
    required this.label,
    required this.emoji,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: color.withOpacity(0.3), width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.12),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
