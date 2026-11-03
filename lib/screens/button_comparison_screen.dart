import 'package:flutter/material.dart';
import 'package:movielog/widgets/movielog_button.dart';

class ButtonComparisonScreen extends StatelessWidget {
  const ButtonComparisonScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text(
        '버튼 너비 비교',
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
      ),
      centerTitle: true,
    ),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'MovieLogButton',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  '같은 문구·같은 높이에서 너비만 비교합니다.\n옅은 배경은 부모가 허용하는 전체 너비입니다.',
                ),
                const SizedBox(height: 28),
                _example(context, 'width: null', '글자와 버튼 여백에 맞춘 너비', null),
                const SizedBox(height: 24),
                _example(
                  context,
                  'width: double.infinity',
                  '부모가 허용하는 전체 너비',
                  double.infinity,
                ),
                const SizedBox(height: 24),
                _example(context, 'width: 160', '고정 너비 160px', 160),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  Widget _example(
    BuildContext context,
    String title,
    String description,
    double? width,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 4),
      Text(description),
      const SizedBox(height: 12),
      Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFEDE7F4),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: MovieLogButton(
            label: '확인',
            width: width,
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$title 버튼을 눌렀습니다.'),
                duration: const Duration(seconds: 1),
              ),
            ),
          ),
        ),
      ),
    ],
  );
}
