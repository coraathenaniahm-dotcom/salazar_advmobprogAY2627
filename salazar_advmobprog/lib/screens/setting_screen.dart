import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:salazar_advmobprog/widgets/custom_text.dart';

import '../providers/theme_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: CustomText(text: 'Settings', fontSize: 18.sp, fontWeight: FontWeight.bold),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(text: 'Appearance', fontSize: 16.sp, fontWeight: FontWeight.w700),
              SizedBox(height: 12.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CustomText(text: 'Dark mode', fontSize: 14.sp),
                  Switch(
                    value: theme.isDark,
                    onChanged: (v) => theme.toggleTheme(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
