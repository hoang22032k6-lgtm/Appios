import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyLoveApp());
}

class MyLoveApp extends StatelessWidget {
  const MyLoveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Love',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xffe85d75),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xfffff8f8),
        useMaterial3: true,
        fontFamily: 'Avenir',
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const _dateKey = 'relationship_start_date';
  final _notifications = FlutterLocalNotificationsPlugin();
  DateTime? _startDate;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDate();
  }

  Future<void> _loadDate() async {
    final preferences = await SharedPreferences.getInstance();
    final savedDate = preferences.getString(_dateKey);
    if (savedDate != null) {
      _startDate = DateTime.tryParse(savedDate);
    }
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    tz.initializeTimeZones();
    await _notifications.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _pickStartDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(1970),
      lastDate: DateTime.now(),
      helpText: 'Chọn ngày đầu tiên quen nhau',
      confirmText: 'Lưu ngày',
    );
    if (selected == null) return;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_dateKey, selected.toIso8601String());
    setState(() => _startDate = selected);
    await _scheduleLoveReminders();
  }

  Future<void> _scheduleLoveReminders() async {
    final details = const NotificationDetails(
      iOS: DarwinNotificationDetails(),
      android: AndroidNotificationDetails(
        'love_dates',
        'Ngày tình yêu',
        channelDescription: 'Nhắc các ngày đặc biệt của hai bạn',
        importance: Importance.high,
        priority: Priority.high,
      ),
    );
    await _notifications.cancelAll();
    final now = tz.TZDateTime.now(tz.local);
    var notificationId = 1;
    for (final event in _events) {
      var date = tz.TZDateTime(tz.local, now.year, event.date.month, event.date.day, 9);
      if (!date.isAfter(now)) date = tz.TZDateTime(tz.local, now.year + 1, event.date.month, event.date.day, 9);
      await _notifications.zonedSchedule(
        notificationId++,
        event.name,
        'Hôm nay là một ngày đặc biệt của hai bạn.',
        date,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
    if (_startDate != null) {
      var anniversary = tz.TZDateTime(tz.local, now.year, _startDate!.month, _startDate!.day, 9);
      if (!anniversary.isAfter(now)) anniversary = tz.TZDateTime(tz.local, now.year + 1, _startDate!.month, _startDate!.day, 9);
      await _notifications.zonedSchedule(
        99,
        'Ngày kỷ niệm của hai bạn',
        'Chúc mừng thêm một năm yêu thương bên nhau.',
        anniversary,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  int get _daysTogether {
    if (_startDate == null) return 0;
    final today = DateTime.now();
    final start = DateTime(_startDate!.year, _startDate!.month, _startDate!.day);
    final current = DateTime(today.year, today.month, today.day);
    return current.difference(start).inDays;
  }

  String _dateText(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  List<_LoveEvent> get _events {
    final year = DateTime.now().year;
    return [
      _LoveEvent('Valentine', DateTime(year, 2, 14), Icons.favorite),
      _LoveEvent('Ngày Quốc tế Phụ nữ', DateTime(year, 3, 8), Icons.local_florist),
      _LoveEvent('White Day', DateTime(year, 3, 14), Icons.card_giftcard),
      _LoveEvent('Ngày của phái mạnh', DateTime(year, 11, 19), Icons.stars),
      _LoveEvent('Giáng sinh', DateTime(year, 12, 25), Icons.celebration),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final hasDate = _startDate != null;
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader()),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildDateCard(hasDate),
                  if (hasDate) ...[
                    const SizedBox(height: 20),
                    _buildDurationCard(),
                    const SizedBox(height: 28),
                    _buildSectionTitle('Những ngày đáng nhớ'),
                    const SizedBox(height: 10),
                    ..._events.map(_buildEventTile),
                  ],
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 30, 24, 22),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xffffdce3),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.favorite, color: Color(0xffd94763), size: 28),
          ),
          const SizedBox(width: 14),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('My Love', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
              Text('Mỗi ngày bên nhau đều đáng nhớ', style: TextStyle(color: Colors.black54)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateCard(bool hasDate) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xffff6f8c), Color(0xffdf4664)]),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [BoxShadow(color: Color(0x33df4664), blurRadius: 18, offset: Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Ngày bắt đầu câu chuyện', style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 8),
          Text(
            hasDate ? _dateText(_startDate!) : 'Chưa chọn ngày',
            style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: _pickStartDate,
            style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xffd94763)),
            icon: const Icon(Icons.edit_calendar),
            label: Text(hasDate ? 'Đổi ngày' : 'Chọn ngày đầu quen nhau'),
          ),
        ],
      ),
    );
  }

  Widget _buildDurationCard() {
    final years = _daysTogether ~/ 365;
    final months = (_daysTogether % 365) ~/ 30;
    final days = (_daysTogether % 365) % 30;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xffffe1e5))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Chúng mình đã bên nhau', style: TextStyle(color: Colors.black54)),
          const SizedBox(height: 8),
          Text('$_daysTogether ngày', style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: Color(0xffd94763))),
          const SizedBox(height: 14),
          Row(children: [
            _stat('$years', 'năm'),
            _stat('$months', 'tháng'),
            _stat('$days', 'ngày'),
          ]),
        ],
      ),
    );
  }

  Widget _stat(String value, String label) {
    return Expanded(child: Column(children: [Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)), Text(label, style: const TextStyle(color: Colors.black54))]));
  }

  Widget _buildSectionTitle(String title) => Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800));

  Widget _buildEventTile(_LoveEvent event) {
    final today = DateTime.now();
    final eventDate = DateTime(today.year, event.date.month, event.date.day);
    var daysLeft = eventDate.difference(DateTime(today.year, today.month, today.day)).inDays;
    if (daysLeft < 0) daysLeft += DateTime(today.year + 1, event.date.month, event.date.day).difference(eventDate).inDays;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      color: Colors.white,
      child: ListTile(
        leading: CircleAvatar(backgroundColor: const Color(0xffffe2e7), foregroundColor: const Color(0xffd94763), child: Icon(event.icon)),
        title: Text(event.name, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text('${event.date.day}/${event.date.month}  •  còn $daysLeft ngày'),
        trailing: const Icon(Icons.notifications_none, color: Color(0xffd94763)),
      ),
    );
  }
}

class _LoveEvent {
  const _LoveEvent(this.name, this.date, this.icon);
  final String name;
  final DateTime date;
  final IconData icon;
}
