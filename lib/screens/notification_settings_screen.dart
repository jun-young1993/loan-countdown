import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  final NotificationService _notificationService = NotificationService();

  bool _paymentNotifications = true;
  bool _ddayNotifications = true;
  bool _prepaymentNotifications = true;
  int _paymentDaysBefore = 7;
  int _ddayDaysBefore = 7;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _paymentNotifications = prefs.getBool('payment_notifications') ?? true;
      _ddayNotifications = prefs.getBool('dday_notifications') ?? true;
      _prepaymentNotifications =
          prefs.getBool('prepayment_notifications') ?? true;
      _paymentDaysBefore = prefs.getInt('payment_days_before') ?? 7;
      _ddayDaysBefore = prefs.getInt('dday_days_before') ?? 7;
      _soundEnabled = prefs.getBool('sound_enabled') ?? true;
      _vibrationEnabled = prefs.getBool('vibration_enabled') ?? true;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('payment_notifications', _paymentNotifications);
    await prefs.setBool('dday_notifications', _ddayNotifications);
    await prefs.setBool('prepayment_notifications', _prepaymentNotifications);
    await prefs.setInt('payment_days_before', _paymentDaysBefore);
    await prefs.setInt('dday_days_before', _ddayDaysBefore);
    await prefs.setBool('sound_enabled', _soundEnabled);
    await prefs.setBool('vibration_enabled', _vibrationEnabled);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('알림 설정이 저장되었습니다.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('알림 설정'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 알림 종류 설정
            _buildSectionCard(
              title: '알림 종류',
              children: [
                SwitchListTile(
                  title: const Text('대출 납부 알림'),
                  subtitle: const Text('납부일 전에 알림을 받습니다'),
                  value: _paymentNotifications,
                  onChanged: (value) {
                    setState(() {
                      _paymentNotifications = value;
                    });
                  },
                ),
                SwitchListTile(
                  title: const Text('D-Day 알림'),
                  subtitle: const Text('대출 시작일 전에 알림을 받습니다'),
                  value: _ddayNotifications,
                  onChanged: (value) {
                    setState(() {
                      _ddayNotifications = value;
                    });
                  },
                ),
                SwitchListTile(
                  title: const Text('중도금 상환 알림'),
                  subtitle: const Text('중도금 상환 기회를 알려줍니다'),
                  value: _prepaymentNotifications,
                  onChanged: (value) {
                    setState(() {
                      _prepaymentNotifications = value;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 알림 시점 설정
            _buildSectionCard(
              title: '알림 시점',
              children: [
                ListTile(
                  title: const Text('납부일 알림'),
                  subtitle: Text('납부일 $_paymentDaysBefore일 전'),
                  trailing: DropdownButton<int>(
                    value: _paymentDaysBefore,
                    items: [1, 3, 7, 14, 30].map((days) {
                      return DropdownMenuItem(
                        value: days,
                        child: Text('$days일 전'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _paymentDaysBefore = value;
                        });
                      }
                    },
                  ),
                ),
                ListTile(
                  title: const Text('D-Day 알림'),
                  subtitle: Text('D-Day $_ddayDaysBefore일 전'),
                  trailing: DropdownButton<int>(
                    value: _ddayDaysBefore,
                    items: [1, 3, 7, 14, 30].map((days) {
                      return DropdownMenuItem(
                        value: days,
                        child: Text('$days일 전'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _ddayDaysBefore = value;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 알림 효과 설정
            _buildSectionCard(
              title: '알림 효과',
              children: [
                SwitchListTile(
                  title: const Text('소리'),
                  subtitle: const Text('알림 시 소리를 재생합니다'),
                  value: _soundEnabled,
                  onChanged: (value) {
                    setState(() {
                      _soundEnabled = value;
                    });
                  },
                ),
                SwitchListTile(
                  title: const Text('진동'),
                  subtitle: const Text('알림 시 진동을 울립니다'),
                  value: _vibrationEnabled,
                  onChanged: (value) {
                    setState(() {
                      _vibrationEnabled = value;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 알림 정보
            _buildSectionCard(
              title: '알림 정보',
              children: [
                ListTile(
                  leading: const Icon(Icons.info),
                  title: const Text('알림 권한'),
                  subtitle: const Text('알림을 받으려면 권한이 필요합니다'),
                  trailing: IconButton(
                    onPressed: () async {
                      // 권한 요청 로직
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool('permission_requested', true);

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('알림 권한을 요청했습니다.'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.settings),
                  ),
                ),
                // ListTile(
                //   leading: const Icon(Icons.schedule),
                //   title: const Text('예약된 알림'),
                //   subtitle: const Text('현재 예약된 알림을 확인합니다'),
                //   trailing: IconButton(
                //     onPressed: () async {
                //       final notifications = await _notificationService.getPendingNotifications();

                //       if (mounted) {
                //         showDialog(
                //           context: context,
                //           builder: (context) => AlertDialog(
                //             title: const Text('예약된 알림'),
                //             content: SizedBox(
                //               width: double.maxFinite,
                //               child: ListView.builder(
                //                 shrinkWrap: true,
                //                 itemCount: notifications.length,
                //                 itemBuilder: (context, index) {
                //                   final notification = notifications[index];
                //                   return ListTile(
                //                     title: Text(notification.title ?? '제목 없음'),
                //                     subtitle: Text(notification.body ?? '내용 없음'),
                //                   );
                //                 },
                //               ),
                //             ),
                //             actions: [
                //               TextButton(
                //                 onPressed: () => Navigator.pop(context),
                //                 child: const Text('확인'),
                //               ),
                //             ],
                //           ),
                //         );
                //       }
                //     },
                //     icon: const Icon(Icons.list),
                //   ),
                // ),
              ],
            ),
            const SizedBox(height: 32),

            // 저장 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveSettings,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text(
                  '설정 저장',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}
