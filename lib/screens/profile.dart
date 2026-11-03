import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:movielog/widgets/common/common_app_bar.dart';
import 'package:movielog/widgets/profile/favorite_genre_chip_container.dart';
import 'package:movielog/widgets/profile/my_info.dart';
import 'package:movielog/widgets/profile/stat_card_container.dart';

class Profile extends StatelessWidget {
  const Profile({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(title: "내 프로필"),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Column(
            spacing: 24,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const MyInfo(),
              const StatCardContainer(),
              const FavoriteGenreChipContainer(),
              ListTile(
                title: const Text('내가 등록한 평점'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/my/ratings'),
              ),
              ListTile(
                title: const Text('회원가입'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/register'),
              ),
              ListTile(
                title: const Text('버튼 너비 비교'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/button-comparison'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
