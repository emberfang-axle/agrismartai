import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'admin_confirmation_dialog.dart';

/// Admin logout confirmation — Yes / No buttons.
class AdminLogoutDialog {
  AdminLogoutDialog._();

  static Future<bool> show(BuildContext context) {
    return AdminConfirmationDialog.show(
      context,
      title: 'Logout Confirmation',
      message: 'Are you sure you want to logout from AgriSmartAI Admin?',
      info: 'You will need to sign in again to access the dashboard.',
      icon: Icons.logout_rounded,
      iconColor: AppColors.danger,
      yesColor: AppColors.danger,
      yesLabel: 'Yes',
      noLabel: 'No',
    );
  }
}
