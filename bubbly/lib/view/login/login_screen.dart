import 'package:flutter/material.dart';
import 'package:bubbly/view/login/login_sheet.dart';
import 'package:bubbly/utils/colors.dart';
import 'package:bubbly/utils/my_loading/my_loading.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<MyLoading>(
      builder: (context, myLoading, child) {
        return Scaffold(
          backgroundColor: myLoading.isDark ? ColorRes.colorPrimaryDark : ColorRes.white,
          body: SafeArea(
            child: LoginSheet(isFullScreen: true),
          ),
        );
      },
    );
  }
} 