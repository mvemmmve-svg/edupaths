import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class OnboardingStartScreen extends StatelessWidget {
  const OnboardingStartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final name = GoRouterState.of(context).uri.queryParameters['name'] ?? 'there';

    return Scaffold(
      backgroundColor: const Color(0xFFF0EFFF),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),
              Text(
                'Great choice,\n$name! 🎉',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E),
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "We'll ask you a few quick questions to find your perfect pathway.",
                style: TextStyle(fontSize: 16, color: Color(0xFF555577)),
              ),
              const SizedBox(height: 40),
              _StepCard(
                icon: Icons.bolt,
                title: '"This or That" quiz',
                subtitle: '15 quick taps — no wrong answers',
              ),
              const SizedBox(height: 12),
              _StepCard(
                icon: Icons.star_border,
                title: 'What do you enjoy?',
                subtitle: '20 questions — about 2 minutes',
              ),
              const SizedBox(height: 12),
              _StepCard(
                icon: Icons.smart_toy_outlined,
                title: 'AI builds your profile',
                subtitle: 'Instant!',
              ),
              const SizedBox(height: 32),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.play_circle_outline,
                    color: Color(0xFFE89C5A)),
                label: const Text(
                  'How do I use EduPath?',
                  style: TextStyle(color: Color(0xFFE89C5A)),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFE89C5A)),
                  shape: const StadiumBorder(),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.push('/onboarding/interests'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5B4FE9),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Let's Go!",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(width: 8),
                      Text('🚀', style: TextStyle(fontSize: 18)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _StepCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF5B4FE9), size: 28),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: Color(0xFF1A1A2E))),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: const TextStyle(
                      fontSize: 13, color: Color(0xFF888AAA))),
            ],
          ),
        ],
      ),
    );
  }
}
