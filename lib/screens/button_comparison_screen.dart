import 'package:flutter/material.dart';
import 'package:movielog/theme/app_colors.dart';
import 'package:movielog/widgets/common/custom_button.dart';

class ButtonComparisonScreen extends StatelessWidget {
  const ButtonComparisonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('버튼 크기 비교')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'CustomButton',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                '같은 문구·같은 높이에서 너비만 비교합니다.\n'
                '옅은 배경은 부모가 허용하는 전체 너비입니다.',
                style: TextStyle(height: 1.6),
              ),
              const SizedBox(height: 32),
              _example(context, 'width: null', '글자와 버튼 여백에 맞춘 너비', null),
              const SizedBox(height: 32),
              _example(
                context,
                'width: double.infinity',
                '부모가 허용하는 전체 너비',
                double.infinity,
              ),
              const SizedBox(height: 32),
              _example(context, 'width: 160', '고정 너비 160', 160),
            ],
          ),
        ),
      ),
    );
  }

  Widget _example(
    BuildContext context,
    String title,
    String description,
    double? width,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(description),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.primary100,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: CustomButton(
              width: width,
              content: const Text(
                '확인',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(SnackBar(content: Text('$title 버튼을 눌렀습니다.')));
              },
            ),
          ),
        ),
      ],
    );
  }
}
