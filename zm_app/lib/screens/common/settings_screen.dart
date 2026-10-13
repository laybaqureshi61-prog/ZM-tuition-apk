import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../auth/login_screen.dart';

class SettingsScreen extends StatelessWidget {
  final UserModel user;
  const SettingsScreen({super.key, required this.user});

  Future<void> _handleLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to sign out of your account?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerRed, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ApiService.logout();
      if (!context.mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  void _showChangePasswordDialog(BuildContext context) {
    final newPassCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();
    bool obscureNew = true;
    bool obscureConfirm = true;
    bool isSaving = false;
    String? errorText;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.brandBlue.withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.lock_reset_rounded, color: AppTheme.brandBlue, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Change Password',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Enter your new password below (min 6 characters):',
                      style: TextStyle(fontSize: 13, color: AppTheme.inkSecondary),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: newPassCtrl,
                      obscureText: obscureNew,
                      decoration: InputDecoration(
                        labelText: 'New Password',
                        hintText: 'Enter new password',
                        prefixIcon: const Icon(Icons.lock_outline, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(obscureNew ? Icons.visibility_off : Icons.visibility, size: 20),
                          onPressed: () => setDialogState(() => obscureNew = !obscureNew),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: confirmPassCtrl,
                      obscureText: obscureConfirm,
                      decoration: InputDecoration(
                        labelText: 'Confirm New Password',
                        hintText: 'Re-enter new password',
                        prefixIcon: const Icon(Icons.lock_clock_outlined, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(obscureConfirm ? Icons.visibility_off : Icons.visibility, size: 20),
                          onPressed: () => setDialogState(() => obscureConfirm = !obscureConfirm),
                        ),
                      ),
                    ),
                    if (errorText != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        errorText!,
                        style: const TextStyle(color: AppTheme.dangerRed, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(dialogCtx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.brandBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: isSaving
                      ? null
                      : () async {
                          final newPass = newPassCtrl.text.trim();
                          final confirmPass = confirmPassCtrl.text.trim();

                          if (newPass.length < 6) {
                            setDialogState(() => errorText = 'Password must be at least 6 characters.');
                            return;
                          }
                          if (newPass != confirmPass) {
                            setDialogState(() => errorText = 'Passwords do not match.');
                            return;
                          }

                          setDialogState(() {
                            isSaving = true;
                            errorText = null;
                          });

                          final res = await ApiService.changePassword(newPassword: newPass);

                          if (!dialogCtx.mounted) return;

                          if (res['success'] == true) {
                            Navigator.pop(dialogCtx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: AppTheme.successGreen,
                                content: Text(res['message'] ?? 'Password changed successfully!'),
                              ),
                            );
                          } else {
                            setDialogState(() {
                              isSaving = false;
                              errorText = res['message'] ?? 'Failed to update password.';
                            });
                          }
                        },
                  child: isSaving
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Save Password'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showChangePasskeyDialog(BuildContext context) {
    final passkeyCtrl = TextEditingController();
    bool obscure = false;
    bool isSaving = false;
    String? currentKey;
    String? errorText;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            if (currentKey == null) {
              ApiService.getAdminPasskey().then((k) {
                if (dialogCtx.mounted) {
                  setDialogState(() {
                    currentKey = k;
                    passkeyCtrl.text = k;
                  });
                }
              });
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.accentYellow.withAlpha(50),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.vpn_key_rounded, color: Colors.orange, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Faculty Passkey',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'This security passkey is required to unlock the Admin / Teacher portal on the welcome screen:',
                      style: TextStyle(fontSize: 13, color: AppTheme.inkSecondary),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: passkeyCtrl,
                      obscureText: obscure,
                      decoration: InputDecoration(
                        labelText: 'Faculty Passkey',
                        hintText: 'e.g. ZM@2026',
                        prefixIcon: const Icon(Icons.key_rounded, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(obscure ? Icons.visibility_off : Icons.visibility, size: 20),
                          onPressed: () => setDialogState(() => obscure = !obscure),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      children: [
                        ActionChip(
                          avatar: const Icon(Icons.refresh, size: 14),
                          label: const Text('Reset to ZM@2026', style: TextStyle(fontSize: 11)),
                          onPressed: () => setDialogState(() => passkeyCtrl.text = 'ZM@2026'),
                        ),
                      ],
                    ),
                    if (errorText != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        errorText!,
                        style: const TextStyle(color: AppTheme.dangerRed, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(dialogCtx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade800,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: isSaving
                      ? null
                      : () async {
                          final newKey = passkeyCtrl.text.trim();
                          if (newKey.length < 4) {
                            setDialogState(() => errorText = 'Passkey must be at least 4 characters.');
                            return;
                          }
                          setDialogState(() {
                            isSaving = true;
                            errorText = null;
                          });

                          final res = await ApiService.updateAdminPasskey(newKey);

                          if (!dialogCtx.mounted) return;

                          if (res['success'] == true) {
                            Navigator.pop(dialogCtx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: AppTheme.successGreen,
                                content: Text('Faculty Passkey updated to "$newKey"!'),
                              ),
                            );
                          } else {
                            setDialogState(() {
                              isSaving = false;
                              errorText = res['message'] ?? 'Failed to update passkey.';
                            });
                          }
                        },
                  child: isSaving
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Save Passkey'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings & Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Profile Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.line),
                    boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: AppTheme.brandBlue,
                        child: Text(
                          user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                          style: const TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.name,
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.ink),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: user.role == 'admin' ? AppTheme.accentYellow.withAlpha(80) : AppTheme.brandBlueSoft,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                user.role == 'admin' ? 'Teacher / Admin (${user.department ?? "General"})' : 'Student (Roll: ${user.rollNo ?? "ZM-101"})',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: user.role == 'admin' ? AppTheme.ink : AppTheme.brandBlue,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(user.batch ?? 'Class 10 (Maths & Science)', style: const TextStyle(fontSize: 13, color: AppTheme.inkSecondary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Account Details
                const Text('Account Information', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.ink)),
                const SizedBox(height: 10),
                _buildInfoTile(Icons.phone_outlined, 'Registered Mobile', user.phone),
                _buildInfoTile(Icons.email_outlined, 'Email Address', user.email.isNotEmpty ? user.email : 'Not set'),
                _buildInfoTile(Icons.school_outlined, 'Assigned Batch', user.batch ?? 'General'),
                if (user.role == 'student')
                  _buildInfoTile(Icons.badge_outlined, 'Student Roll No', user.rollNo ?? 'ZM-101'),
                if (user.role == 'admin')
                  _buildInfoTile(Icons.admin_panel_settings_outlined, 'Department Lead', user.department ?? 'Commerce / Science'),

                const SizedBox(height: 20),

                // Security & Password Management
                const Text('Security & Password', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.ink)),
                const SizedBox(height: 10),
                InkWell(
                  onTap: () => _showChangePasswordDialog(context),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.line),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.brandBlue.withAlpha(20),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.lock_outline, size: 20, color: AppTheme.brandBlue),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Change Account Password', style: TextStyle(fontSize: 14, color: AppTheme.ink, fontWeight: FontWeight.w700)),
                              SizedBox(height: 2),
                              Text('Set a new login password for this account', style: TextStyle(fontSize: 12, color: AppTheme.inkSecondary)),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppTheme.inkSecondary),
                      ],
                    ),
                  ),
                ),

                if (user.role == 'admin') ...[
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () => _showChangePasskeyDialog(context),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.line),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.orange.withAlpha(25),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.vpn_key_rounded, size: 20, color: Colors.orange),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Faculty Portal Passkey', style: TextStyle(fontSize: 14, color: AppTheme.ink, fontWeight: FontWeight.w700)),
                                SizedBox(height: 2),
                                Text('Change the security passkey required to enter Admin portal', style: TextStyle(fontSize: 12, color: AppTheme.inkSecondary)),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppTheme.inkSecondary),
                        ],
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Appearance & Theme Section
                const Text('Appearance & Theme', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.ink)),
                const SizedBox(height: 10),
                ValueListenableBuilder<ThemeMode>(
                  valueListenable: AppTheme.themeModeNotifier,
                  builder: (context, mode, _) {
                    final isDark = mode == ThemeMode.dark;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.line),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.amber.withAlpha(40) : AppTheme.brandBlueSoft,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              isDark ? Icons.dark_mode : Icons.light_mode,
                              color: isDark ? Colors.amber : AppTheme.brandBlue,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Dark Mode Theme', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                Text(
                                  isDark ? 'Dark theme enabled for low-light' : 'Light theme enabled',
                                  style: const TextStyle(fontSize: 12, color: AppTheme.inkSecondary),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: isDark,
                            activeThumbColor: AppTheme.brandBlueLight,
                            onChanged: (_) => AppTheme.toggleTheme(),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 14),

                // Security & Privacy
                const Text('Tuition Center Information', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.ink)),
                const SizedBox(height: 10),
                _buildInfoTile(Icons.location_on_outlined, 'Center Location', 'ZM Tuition Center, Main Road'),
                _buildInfoTile(Icons.security_outlined, 'Access Security', 'Strict Phone & OTP Encrypted'),

                const SizedBox(height: 30),

                // Logout Button
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.dangerRed,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => _handleLogout(context),
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Sign Out of ZM Tuition', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.line),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.brandBlue),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.inkSecondary, fontWeight: FontWeight.w500)),
              Text(value, style: const TextStyle(fontSize: 14, color: AppTheme.ink, fontWeight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    );
  }
}
