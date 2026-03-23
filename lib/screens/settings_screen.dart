// ignore_for_file: use_build_context_synchronously, curly_braces_in_flow_control_structures, prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/theme_provider.dart';
import '../providers/auth_provider_provider.dart';
import '../services/user_preferences_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final themeNotifier = ref.read(themeModeProvider.notifier);

    bool isDarkModeEnabled() {
      return themeMode == ThemeMode.dark;
    }

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Account Section
            _buildSectionTitle('Account'),
            _buildSettingsTile(
              context,
              'Profile',
              'Manage your profile information',
              Icons.person,
              () => _showProfileDialog(context, ref),
            ),
            _buildSettingsTile(
              context,
              'Change Password',
              'Update your password',
              Icons.lock,
              () => _showChangePasswordDialog(context),
            ),
            _buildSettingsTile(
              context,
              'Email Preferences',
              'Manage email notifications',
              Icons.email,
              () => _showEmailPreferencesDialog(context),
            ),
            const Divider(),
            // Notifications Section
            _buildSectionTitle('Notifications'),
            _buildSwitchTile(
              context,
              'Notifications',
              'Get reminders for your habits and goals',
              true,
              (value) async {
                try {
                  final userPreferencesService = UserPreferencesService();
                  await userPreferencesService.updateNotificationSettings(enabled: value);
                  
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(value ? 'Notifications enabled' : 'Notifications disabled')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              },
            ),
            // Appearance Section
            const Divider(),
            _buildSectionTitle('Appearance'),
            _buildSwitchTile(
              context,
              'Dark Mode',
              'Enable dark theme',
              isDarkModeEnabled(),
              (value) {
                themeNotifier.setDarkMode(value);
              },
            ),
            // Data Section
            const Divider(),
            _buildSectionTitle('Data'),
            _buildSettingsTile(
              context,
              'Export Data',
              'Export your habits and goals',
              Icons.download,
              () => _exportData(context),
            ),
            _buildSettingsTile(
              context,
              'Import Data',
              'Import data from backup',
              Icons.upload,
              () => _importData(context),
            ),
            _buildSettingsTile(
              context,
              'Clear Cache',
              'Free up storage space',
              Icons.delete,
              () => _clearCache(context),
            ),
            const Divider(),
            // About Section
            _buildSectionTitle('About'),
            _buildSettingsTile(
              context,
              'Version',
              '2.0.0',
              Icons.info,
              () {},
              trailing: false,
            ),
            _buildSettingsTile(
              context,
              'Help & Support',
              'Get help and contact support',
              Icons.help,
              () => _showHelpDialog(context),
            ),
            _buildSettingsTile(
              context,
              'Privacy Policy',
              'Read our privacy policy',
              Icons.privacy_tip,
              () => _showPrivacyPolicy(context),
            ),
            const Divider(),
            // Logout Button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _showLogoutConfirmation(context, ref),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'Sign Out',
                    style: TextStyle(color: Colors.white),
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

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap, {
    bool trailing = true,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryColor),
      title: Text(title),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color),
      ),
      trailing: trailing ? const Icon(Icons.arrow_forward_ios, size: 16) : null,
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile(
    BuildContext context,
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return ListTile(
      title: Text(title),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: AppTheme.primaryColor,
      ),
    );
  }

  void _showProfileDialog(BuildContext context, WidgetRef ref) {
    final authState = ref.read(authProvider);
    final user = authState.user;
    
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not authenticated')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Profile'),
        content: FutureBuilder(
          future: AuthService().getUserData(user.uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            
            if (snapshot.hasError) {
              return Text('Error loading profile: ${snapshot.error}');
            }
            
            final userData = snapshot.data?.data() as Map<String, dynamic>?;
            final name = userData?['name'] ?? 'No name';
            final email = userData?['email'] ?? user.email ?? 'No email';
            final createdAt = userData?['createdAt'] as Timestamp?;
            final memberSince = createdAt?.toDate().toString().split(' ')[0] ?? 'Unknown';
            
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: AppTheme.primaryColor,
                  child: user.photoURL != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(40),
                          child: Image.network(user.photoURL!),
                        )
                      : const Icon(Icons.person, size: 40, color: Colors.white),
                ),
                const SizedBox(height: 16),
                Text(
                  name, 
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
                const SizedBox(height: 8),
                Text('Member since: $memberSince'),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final authService = AuthService();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldPasswordController,
              decoration: const InputDecoration(
                labelText: 'Current Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newPasswordController,
              decoration: const InputDecoration(
                labelText: 'New Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmPasswordController,
              decoration: const InputDecoration(
                labelText: 'Confirm New Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (newPasswordController.text != confirmPasswordController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Passwords do not match')),
                );
                return;
              }
              
              if (newPasswordController.text.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Password must be at least 6 characters')),
                );
                return;
              }
              
              try {
                Navigator.pop(context);
                
                // Note: Firebase doesn't have a direct "change password" method
                // You would typically need to re-authenticate the user first
                // For now, we'll show a message directing to password reset
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Password reset email sent. Please check your inbox.'),
                    duration: Duration(seconds: 3),
                  ),
                );
                
                // Send password reset email as an alternative
                final user = authService.currentUser;
                if (user?.email != null) {
                  await authService.resetPassword(user!.email!);
                }
              } catch (e) {
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            child: const Text('Change Password'),
          ),
        ],
      ),
    );
  }

  void _showEmailPreferencesDialog(BuildContext context) {
    final userPreferencesService = UserPreferencesService();
    bool dailyReminders = true;
    bool weeklySummary = false;
    bool goalUpdates = true;
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Email Preferences'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isLoading)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                )
              else
                Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Daily Reminders'),
                      subtitle: const Text('Get daily habit reminders'),
                      value: dailyReminders,
                      onChanged: (value) => setState(() => dailyReminders = value),
                    ),
                    SwitchListTile(
                      title: const Text('Weekly Summary'),
                      subtitle: const Text('Receive weekly progress reports'),
                      value: weeklySummary,
                      onChanged: (value) => setState(() => weeklySummary = value),
                    ),
                    SwitchListTile(
                      title: const Text('Goal Updates'),
                      subtitle: const Text('Notifications about goal milestones'),
                      value: goalUpdates,
                      onChanged: (value) => setState(() => goalUpdates = value),
                    ),
                  ],
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isLoading ? null : () async {
                setState(() => isLoading = true);
                
                try {
                  await userPreferencesService.updateEmailPreferences(
                    dailyReminders: dailyReminders,
                    weeklySummary: weeklySummary,
                    goalUpdates: goalUpdates,
                  );
                  
                  Navigator.pop(context);
                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Email preferences saved!')),
                  );
                } catch (e) {
                  setState(() => isLoading = false);
                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              },
              child: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  // _showLanguageDialog removed - language switcher functionality deleted

  void _exportData(BuildContext context) {
    final userPreferencesService = UserPreferencesService();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Export Data'),
          content: isLoading
              ? const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Exporting your data...'),
                    ],
                  ),
                )
              : const Text(
                  'Your habits and goals data will be exported as a JSON file. This can be used to backup your data or import it to another device.'),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isLoading ? null : () async {
                setState(() => isLoading = true);
                
                try {
                  final data = await userPreferencesService.exportUserData();
                  
                  Navigator.pop(context);
                  
                  // Show success dialog with data preview
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Export Successful'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Data exported successfully!'),
                          const SizedBox(height: 8),
                          Text('Goals: ${data['goals']?.length ?? 0}'),
                          Text('Habits: ${data['habits']?.length ?? 0}'),
                          const SizedBox(height: 8),
                          const Text(
                            'Note: In a real app, this would download as a file. For demo purposes, the data has been prepared.',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                } catch (e) {
                  setState(() => isLoading = false);
                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Export failed: $e')),
                  );
                }
              },
              child: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Export'),
            ),
          ],
        ),
      ),
    );
  }

  void _importData(BuildContext context) {
    final userPreferencesService = UserPreferencesService();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Import Data'),
          content: isLoading
              ? const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Importing your data...'),
                    ],
                  ),
                )
              : const Text(
                  'Select a backup file to import your habits and goals. This will replace your current data.'),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isLoading ? null : () async {
                setState(() => isLoading = true);
                
                try {
                  // For demo purposes, we'll create sample import data
                  // In a real app, this would read from a file picker
                  final sampleData = {
                    'goals': [
                      {
                        'title': 'Imported Goal',
                        'description': 'This goal was imported',
                        'currentProgress': 5.0,
                        'targetProgress': 10.0,
                        'unit': 'units',
                        'icon': 'star',
                        'color': 'blue',
                        'action': 'Imported action',
                      }
                    ],
                    'habits': [],
                  };
                  
                  await userPreferencesService.importUserData(sampleData);
                  
                  Navigator.pop(context);
                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Data imported successfully!'),
                      duration: Duration(seconds: 3),
                    ),
                  );
                } catch (e) {
                  setState(() => isLoading = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Import failed: $e')),
                  );
                }
              },
              child: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Import'),
            ),
          ],
        ),
      ),
    );
  }

  void _clearCache(BuildContext context) {
    final userPreferencesService = UserPreferencesService();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Clear Cache'),
          content: isLoading
              ? const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Clearing cache...'),
                    ],
                  ),
                )
              : const Text(
                  'This will free up storage space by clearing temporary files and cached data. Your habits and goals will not be affected.'),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isLoading ? null : () async {
                setState(() => isLoading = true);
                
                try {
                  await userPreferencesService.clearCache();
                  
                  Navigator.pop(context);
                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Cache cleared successfully!')),
                  );
                } catch (e) {
                  setState(() => isLoading = false);
                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to clear cache: $e')),
                  );
                }
              },
              child: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Clear'),
            ),
          ],
        ),
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help & Support'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Need help? Here are some resources:', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('• User Guide: Available in the app menu'),
            Text('• FAQ: Visit our website'),
            Text('• Email Support: support@habitat.app'),
            Text('• Community Forum: forum.habitat.app'),
            SizedBox(height: 12),
            Text('For urgent issues, please contact our support team directly.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Last updated: January 2024', style: TextStyle(fontStyle: FontStyle.italic)),
              SizedBox(height: 12),
              Text('Data Collection:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('We collect only the data necessary to provide our services, including your habits, goals, and usage patterns.'),
              SizedBox(height: 8),
              Text('Data Usage:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Your data is used to personalize your experience and improve our services.'),
              SizedBox(height: 8),
              Text('Data Protection:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('We use industry-standard encryption to protect your data and never share it with third parties without your consent.'),
              SizedBox(height: 8),
              Text('Your Rights:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('You can request, modify, or delete your data at any time through the settings menu.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out? Your progress will be saved.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext); // Close dialog first
              
              final authNotifier = ref.read(authProvider.notifier);
              await authNotifier.signOut();
              
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Signed out successfully!')),
                );
                // AuthGate will automatically show LoginScreen when auth state changes
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}
