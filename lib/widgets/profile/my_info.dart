import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:movielog/theme/app_theme.dart';

class MyInfo extends StatelessWidget {
  const MyInfo({super.key, required this.name, required this.email, this.profileImageUrl});
  final String name;
  final String email;
  final String? profileImageUrl;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorTheme = Theme.of(context).colorScheme;

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
          email,
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
