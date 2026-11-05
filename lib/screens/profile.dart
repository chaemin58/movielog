import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:movielog/theme/app_colors.dart';
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
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.primary200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: InkWell(
                  onTap: () => context.push('/my/ratings'),
                  borderRadius: BorderRadius.circular(8),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      height: 56,
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '내가 등록한 평점',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            color: AppColors.primary600,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: FavoriteGenreChipContainer(),
              ),

              InkWell(
                onTap: () => context.push('/register'),
                borderRadius: BorderRadius.circular(8),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    height: 56,
                    child: Row(
                      children: [
                        Expanded(child: Text('회원가입 화면')),
                        Icon(Icons.chevron_right),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
