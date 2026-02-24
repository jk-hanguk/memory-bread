import 'dart:math';
import 'package:flutter/material.dart';
import 'latex_text.dart';

class FlashCard extends StatefulWidget {
  final String frontText;
  final String backText;

  const FlashCard({super.key, required this.frontText, required this.backText});

  @override
  State<FlashCard> createState() => _FlashCardState();
}

class _FlashCardState extends State<FlashCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isFront = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleCard() {
    if (_isFront) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
    setState(() {
      _isFront = !_isFront;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleCard,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final double angle = _animation.value * pi;
          return Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001) // 원근감 효과
              ..rotateY(angle),
            alignment: Alignment.center,
            child: angle < pi / 2
                ? _buildCardSide(widget.frontText, isFront: true)
                : Transform(
                    transform: Matrix4.identity()..rotateY(pi),
                    alignment: Alignment.center,
                    child: _buildCardSide(widget.backText, isFront: false),
                  ),
          );
        },
      ),
    );
  }

  Widget _buildCardSide(String text, {required bool isFront}) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isFront
          ? Theme.of(context).colorScheme.primaryContainer
          : Theme.of(context).colorScheme.secondaryContainer,
      child: Container(
        width: 300,
        height: 200,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(20),
        child: LatexText(
          text: text,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          mathFontSize: 24,
        ),
      ),
    );
  }
}
