import 'dart:math';
import 'package:flutter/material.dart';
import 'latex_text.dart';

class FlashCardController {
  void Function()? toggle;
}

class FlashCard extends StatefulWidget {
  final String frontText;
  final String backText;
  final FlashCardController? controller;

  const FlashCard({
    super.key,
    required this.frontText,
    required this.backText,
    this.controller,
  });

  @override
  State<FlashCard> createState() => FlashCardState();
}

class FlashCardState extends State<FlashCard>
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
    widget.controller?.toggle = toggleCard;
  }

  @override
  void didUpdateWidget(FlashCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller?.toggle = null;
      widget.controller?.toggle = toggleCard;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    if (widget.controller?.toggle == toggleCard) {
      widget.controller?.toggle = null;
    }
    super.dispose();
  }

  void toggleCard() {
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
    return AnimatedBuilder(
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
    );
  }

  Widget _buildCardSide(String text, {required bool isFront}) {
    final size = MediaQuery.of(context).size;
    
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isFront
          ? Theme.of(context).colorScheme.primaryContainer
          : Theme.of(context).colorScheme.secondaryContainer,
      child: Container(
        constraints: BoxConstraints(
          minWidth: min(size.width * 0.85, 300),
          maxWidth: size.width * 0.9,
          minHeight: 220,
          maxHeight: size.height * 0.45,
        ),
        padding: const EdgeInsets.all(24),
        child: Center(
          child: SingleChildScrollView(
            child: LatexText(
              text: text,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF5D4037),
              ),
              mathFontSize: 24,
            ),
          ),
        ),
      ),
    );
  }
}
