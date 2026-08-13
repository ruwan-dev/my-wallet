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
    {
      'quote': 'Rule No. 1: Never lose money.\nRule No. 2: Never forget rule No. 1.',
      'author': 'Warren Buffett'
    },
    {
      'quote': 'Invest in what you know.',
      'author': 'Peter Lynch'
    },
    {
      'quote': 'The essence of investment management is the management of risks, not the management of returns.',
      'author': 'Benjamin Graham'
    },
    {
      'quote': 'Don\'t look for the needle in the haystack. Just buy the haystack.',
      'author': 'John Bogle'
    },
    {
      'quote': 'It\'s not whether you\'re right or wrong that\'s important, but how much money you make when you\'re right and how much you lose when you\'re wrong.',
      'author': 'George Soros'
    },
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
        _pageController.animateToPage(
          nextIndex,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _nextQuote() {
    _startTimer(); // Reset timer on manual interaction
    if (_pageController.hasClients) {
      final nextIndex = (_currentIndex + 1) % _quotes.length;
      _pageController.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
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
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 230,
          child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemCount: _quotes.length,
              itemBuilder: (context, index) {
                final quote = _quotes[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Center(
                    child: SingleChildScrollView(
                      physics: const NeverScrollableScrollPhysics(),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.format_quote_rounded,
                            size: 40,
                            color: Color(0xFF7C3AED),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            quote['quote']!,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.playfairDisplay(
                              textStyle: theme.textTheme.titleLarge?.copyWith(
                                color: Colors.white,
                                height: 1.3,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            width: 48,
                            height: 2,
                            color: const Color(0xFF7C3AED),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            quote['author']!.toUpperCase(),
                            textAlign: TextAlign.center,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: Colors.white70,
                              letterSpacing: 2.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    _quotes.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: 8,
                      width: _currentIndex == index ? 24 : 8,
                      decoration: BoxDecoration(
                        color: _currentIndex == index 
                            ? const Color(0xFF7C3AED) 
                            : Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.play_arrow_rounded, color: Color(0xFF7C3AED)),
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
