import 'package:flutter/material.dart';
import 'package:movielog/widget/profile/stat_card.dart';

class StatCardContainer extends StatelessWidget {
  const StatCardContainer({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: StatCard(label: "본 영화", value: '342'),
        ),

        Expanded(
          child: StatCard(label: "평점", value: '4.2'),
        ),
        Expanded(
          child: StatCard(label: "즐겨찾기", value: '58'),
        ),
      ],
    );
  }
}
