import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:movielog/theme/app_colors.dart';

class ProfileMenu extends StatelessWidget {
  const ProfileMenu({
    super.key,
    required this.menuTitle,
    this.route = '/my/ratings',
  });
  final String menuTitle;
  final String route;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.primary200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => context.push(route),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: SizedBox(
            height: 56,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    menuTitle,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Icon(Icons.chevron_right, color: AppColors.primary600),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
