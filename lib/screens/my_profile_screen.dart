import 'package:flutter/material.dart';
import 'package:movielog/view_models/auth_view_model.dart';
import 'package:movielog/widgets/common/common_app_bar.dart';
import 'package:movielog/widgets/profile/favorite_genre_chip_container.dart';
import 'package:movielog/widgets/profile/my_info.dart';
import 'package:movielog/widgets/profile/profile_menu.dart';
import 'package:movielog/widgets/profile/stat_card_container.dart';
import 'package:provider/provider.dart';

class MyProfileScreen extends StatelessWidget {
  const MyProfileScreen({super.key});
  /*먼저 '내 정보를 받아와야 하는 건데, 내 정보는 세션에 저장되어 있다. */

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final member = auth.member;

    return Scaffold(
      appBar: CommonAppBar(
        title: "내 프로필",
        actions: [
          TextButton(
            child: Text('로그아웃 하기'),
            onPressed: () async {
              await context.read<AuthViewModel>().logout();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Column(
            spacing: 24,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              MyInfo(
                name: member?.nickname ?? '내 정보 확인 중',
                email: member?.email ?? '이메일을 확인할 수 없습니다.',
              ),
              const StatCardContainer(),
              const Column(
                spacing: 8,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ProfileMenu(menuTitle: '내가 등록한 평점'),
                  ProfileMenu(menuTitle: '내 즐겨찾기', route: '/my/favorites'),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: FavoriteGenreChipContainer(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
