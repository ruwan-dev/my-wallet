import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class QuotesCarousel extends StatefulWidget {
  const QuotesCarousel({super.key});

  @override
  State<QuotesCarousel> createState() => _QuotesCarouselState();
}

class _QuotesCarouselState extends State<QuotesCarousel> {
  final List<Map<String, String>> _quotes = [
    {'quote': 'Time is money.', 'author': 'Benjamin Franklin'},
    {'quote': 'Invest in what you know.', 'author': 'Peter Lynch'},
    {'quote': 'Every day is a bank account.', 'author': 'Christopher Morley'},
    {'quote': 'Before you spend, earn.', 'author': 'William Arthur Ward'},
    {'quote': 'Never depend on a single income.', 'author': 'Warren Buffett'},
    {'quote': 'Take decisions based on data, not emotions.', 'author': 'Dhammika Perera'},
  ];

  late PageController _pageController;
  int _currentIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 20), (timer) {
      if (_pageController.hasClients) {
        final nextIndex = (_currentIndex + 1) % _quotes.length;
        _pageController.animateToPage(nextIndex, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
      }
    });
  }

  void _nextQuote() {
    _startTimer();
    if (_pageController.hasClients) {
      final nextIndex = (_currentIndex + 1) % _quotes.length;
      _pageController.animateToPage(nextIndex, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.max,
      children: [
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentIndex = index),
            itemCount: _quotes.length,
            itemBuilder: (context, index) {
              final quote = _quotes[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.format_quote_rounded, size: 28, color: Color(0xFF50C8C8)),
                      const SizedBox(height: 8),
                      Text(
                        quote['quote']!,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.playfairDisplay(
                          textStyle: theme.textTheme.bodyMedium?.copyWith(color: Colors.black87, height: 1.4, fontSize: 15),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(width: 36, height: 2, color: const Color(0xFF50C8C8)),
                      const SizedBox(height: 10),
                      Text(
                        quote['author']!.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.labelSmall?.copyWith(color: Colors.black54, letterSpacing: 1.5, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  _quotes.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    height: 6,
                    width: _currentIndex == index ? 20 : 6,
                    decoration: BoxDecoration(
                      color: _currentIndex == index ? const Color(0xFF50C8C8) : Colors.black26,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: Colors.black12, shape: BoxShape.circle),
                child: IconButton(
                  iconSize: 14,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                  icon: const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF50C8C8), size: 14),
                  onPressed: _nextQuote,
                  tooltip: 'Next Quote',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
