import 'package:flutter/material.dart';
import 'package:movielog/widget/common/common_app_bar.dart';
import 'package:movielog/widget/profile/favorite_genre_chip_container.dart';
import 'package:movielog/widget/profile/my_info.dart';
import 'package:movielog/widget/profile/stat_card_container.dart';

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
            children: const [
              MyInfo(),
              StatCardContainer(),
              FavoriteGenreChipContainer(),
            ],
          ),
        ),
      ),
    );
  }
}
