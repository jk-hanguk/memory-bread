import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

class LatexText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign textAlign;
  final double mathFontSize;

  const LatexText({
    super.key,
    required this.text,
    this.style,
    this.textAlign = TextAlign.center,
    this.mathFontSize = 24,
  });

  @override
  Widget build(BuildContext context) {
    // 텍스트에 $ 기호가 포함되어 있으면 LaTeX 렌더링 시도
    if (text.contains(r'$')) {
      final List<Widget> widgets = [];
      
      text.splitMapJoin(
        RegExp(r'\$(.+?)\$', dotAll: true),
        onMatch: (Match match) {
          final mathContent = match.group(1) ?? '';
          widgets.add(
            Math.tex(
              mathContent,
              textStyle: (style ?? Theme.of(context).textTheme.bodyMedium)?.copyWith(
                fontSize: mathFontSize,
              ),
              onErrorFallback: (err) {
                return Text(
                  '\$$mathContent\$',
                  style: const TextStyle(color: Colors.red),
                );
              },
            ),
          );
          return '';
        },
        onNonMatch: (String nonMatch) {
          if (nonMatch.isNotEmpty) {
            widgets.add(
              Text(
                nonMatch,
                textAlign: textAlign,
                style: style ?? Theme.of(context).textTheme.bodyMedium,
              ),
            );
          }
          return '';
        },
      );

      return Wrap(
        alignment: _getWrapAlignment(textAlign),
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 4,
        runSpacing: 4,
        children: widgets,
      );
    } else {
      // 일반 텍스트인 경우 기본 Text 위젯 반환
      return Text(
        text,
        textAlign: textAlign,
        style: style,
      );
    }
  }

  WrapAlignment _getWrapAlignment(TextAlign textAlign) {
    switch (textAlign) {
      case TextAlign.left:
      case TextAlign.start:
        return WrapAlignment.start;
      case TextAlign.right:
      case TextAlign.end:
        return WrapAlignment.end;
      case TextAlign.center:
      default:
        return WrapAlignment.center;
    }
  }
}
