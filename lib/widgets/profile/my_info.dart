import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:movielog/theme/app_theme.dart';

class MyInfo extends StatelessWidget {
  const MyInfo({super.key, required this.name, this.profileImageUrl});
  final String name;
  final String? profileImageUrl;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorTheme = Theme.of(context).colorScheme;
    final imgUrl = profileImageUrl?.trim();

    return Column(
      spacing: 8,
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 62,
          //사진이 있으면 사진이 아이콘을 덮는 아이디어
          foregroundImage:
              profileImageUrl != null && profileImageUrl!.isNotEmpty
              ? NetworkImage(profileImageUrl!)
              : null,
          child: const Icon(Icons.person, size: 80),
        ),
        Text(name, style: textTheme.titleLarge),
        Text(
          '매주 주말엔 영화관으로 출근하는 프로 관람객. \n좋은 영화를 보고 기록하는 것을 좋아합니다.',
          style: textTheme.bodyLarge,
        ),
        TextButton(
          onPressed: () {
            context.push('/my/profile/edit');
          },
          style: TextButton.styleFrom(
            foregroundColor: colorTheme.primary,
            side: BorderSide(color: colorTheme.primary),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radius),
            ),
          ),
          child: const Text('프로필 수정'),
        ),
      ],
    );
  }
}
