import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/app_provider.dart';
import '../models/schedule_model.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  TimeOfDay _selectedTime = TimeOfDay.now();
  String _selectedActivity = 'Scanning';

  final List<Map<String, dynamic>> _activities = [
    {'name': 'Scanning', 'icon': Icons.qr_code_scanner_rounded, 'color': const Color(0xFF2E7D32)},
    {'name': 'Watering', 'icon': Icons.water_drop_rounded, 'color': Colors.blue},
    {'name': 'Pruning', 'icon': Icons.content_cut_rounded, 'color': const Color(0xFFFBC02D)},
    {'name': 'Fertilizing', 'icon': Icons.grain_rounded, 'color': Colors.brown},
    {'name': 'Pest Control', 'icon': Icons.bug_report_rounded, 'color': Colors.redAccent},
  ];

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _updateSelectedActivityToSuggestion(_focusedDay);
  }

  void _updateSelectedActivityToSuggestion(DateTime day) {
    final provider = Provider.of<AppProvider>(context, listen: false);
    final suggestion = provider.getSuggestedActivity(day);
    for (var act in _activities) {
      if (suggestion.toLowerCase().contains(act['name'].toLowerCase())) {
        setState(() => _selectedActivity = act['name']);
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            backgroundColor: const Color(0xFF2E7D32),
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            centerTitle: true,
            leading: Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: Text(
                provider.tr('Farm Planner').toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 10, letterSpacing: 3),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  Theme.of(context).brightness == Brightness.light ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: () => provider.toggleTheme(Theme.of(context).brightness == Brightness.light),
              ),
              const SizedBox(width: 8),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSmartHero(provider),
                  const SizedBox(height: 40),
                  _buildSectionLabel('SELECT DATE'),
                  const SizedBox(height: 16),
                  _buildCalendarCard(),
                  const SizedBox(height: 40),
                  _buildSectionLabel('SELECT TASK'),
                  const SizedBox(height: 16),
                  _buildActivityList(provider),
                  const SizedBox(height: 40),
                  _buildSchedulingControls(context, provider),
                  const SizedBox(height: 48),
                  _buildSectionLabel('UPCOMING FIELD WORK'),
                  const SizedBox(height: 16),
                  _buildUpcomingList(provider),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(text, style: TextStyle(color: const Color(0xFF1B5E20).withValues(alpha: 0.4), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5));
  }

  Widget _buildSmartHero(AppProvider provider) {
    final day = _selectedDay ?? DateTime.now();
    final suggestion = provider.getSuggestedActivity(day);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F8E9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2E7D32).withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('AI SMART SUGGESTION', style: TextStyle(color: const Color(0xFF2E7D32).withValues(alpha: 0.5), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
          const SizedBox(height: 12),
          Text(suggestion, style: const TextStyle(color: Color(0xFF1B5E20), fontSize: 20, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _buildCalendarCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F8E9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2E7D32).withValues(alpha: 0.05)),
      ),
      child: TableCalendar(
        firstDay: DateTime.now(),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        calendarFormat: CalendarFormat.week,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        onDaySelected: (selectedDay, focusedDay) {
          setState(() { _selectedDay = selectedDay; _focusedDay = focusedDay; });
          _updateSelectedActivityToSuggestion(selectedDay);
        },
        calendarStyle: CalendarStyle(
          defaultTextStyle: const TextStyle(color: Color(0xFF1B5E20), fontWeight: FontWeight.w600),
          weekendTextStyle: const TextStyle(color: Color(0xFF1B5E20), fontWeight: FontWeight.w600),
          selectedDecoration: const BoxDecoration(color: Color(0xFF2E7D32), shape: BoxShape.circle),
          selectedTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          todayDecoration: BoxDecoration(color: const Color(0xFFFBC02D).withValues(alpha: 0.3), shape: BoxShape.circle),
          todayTextStyle: const TextStyle(color: Color(0xFF1B5E20), fontWeight: FontWeight.bold),
        ),
        headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true, titleTextStyle: TextStyle(color: Color(0xFF1B5E20), fontWeight: FontWeight.w800)),
        daysOfWeekStyle: const DaysOfWeekStyle(weekdayStyle: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w700), weekendStyle: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _buildActivityList(AppProvider provider) {
    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _activities.length,
        itemBuilder: (context, index) {
          final act = _activities[index];
          final isSelected = _selectedActivity == act['name'];
          return GestureDetector(
            onTap: () => setState(() => _selectedActivity = act['name']),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 90,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF2E7D32) : const Color(0xFFF1F8E9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isSelected ? const Color(0xFF2E7D32) : Colors.black.withValues(alpha: 0.05)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(act['icon'], color: isSelected ? Colors.white : act['color'], size: 22),
                  const SizedBox(height: 8),
                  Text(provider.tr(act['name']), style: TextStyle(color: isSelected ? Colors.white : const Color(0xFF1B5E20).withValues(alpha: 0.6), fontSize: 11, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSchedulingControls(BuildContext context, AppProvider provider) {
    return Column(
      children: [
        InkWell(
          onTap: () async {
            final picked = await showTimePicker(
              context: context, 
              initialTime: _selectedTime,
              builder: (context, child) => Theme(
                data: ThemeData.light().copyWith(
                  colorScheme: const ColorScheme.light(primary: Color(0xFF2E7D32), onPrimary: Colors.white, surface: Colors.white),
                ),
                child: child!,
              ),
            );
            if (picked != null) setState(() => _selectedTime = picked);
          },
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F8E9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF2E7D32).withValues(alpha: 0.05)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(provider.tr('Reminder Time'), style: const TextStyle(color: Color(0xFF1B5E20), fontSize: 15, fontWeight: FontWeight.w600)),
                Text(_selectedTime.format(context), style: const TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.w800, fontSize: 18)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _scheduleActivity,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFBC02D),
            foregroundColor: Colors.black,
            minimumSize: const Size(double.infinity, 64),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 2,
          ),
          child: Text(provider.tr('Add to Schedule').toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1)),
        ),
      ],
    );
  }

  Widget _buildUpcomingList(AppProvider provider) {
    final upcoming = provider.schedules.where((s) => s.dateTime.isAfter(DateTime.now())).toList();
    if (upcoming.isEmpty) return const Center(child: Text('No tasks scheduled', style: TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.w500)));

    return Column(
      children: upcoming.map((item) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
        ),
        child: ListTile(
          leading: Icon(_getActivityIcon(item.activity), color: const Color(0xFF2E7D32), size: 22),
          title: Text(provider.tr(item.activity), style: const TextStyle(color: Color(0xFF1B5E20), fontWeight: FontWeight.w700, fontSize: 15)),
          subtitle: Text(DateFormat('MMM dd, hh:mm a').format(item.dateTime), style: TextStyle(color: Colors.black.withValues(alpha: 0.3), fontSize: 12, fontWeight: FontWeight.w600)),
          trailing: IconButton(icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20), onPressed: () => provider.deleteSchedule(item.id)),
        ),
      )).toList(),
    );
  }

  void _scheduleActivity() {
    final scheduledDateTime = DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day, _selectedTime.hour, _selectedTime.minute);
    if (scheduledDateTime.isBefore(DateTime.now())) return;
    final provider = Provider.of<AppProvider>(context, listen: false);
    final newSchedule = Schedule(id: DateTime.now().millisecondsSinceEpoch.toString(), activity: _selectedActivity, dateTime: scheduledDateTime);
    provider.addSchedule(newSchedule);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${provider.tr(_selectedActivity)} Scheduled!'), behavior: SnackBarBehavior.floating, backgroundColor: const Color(0xFF2E7D32)));
  }

  IconData _getActivityIcon(String activity) {
    switch (activity) {
      case 'Scanning': return Icons.qr_code_scanner_rounded;
      case 'Watering': return Icons.water_drop_rounded;
      case 'Pruning': return Icons.content_cut_rounded;
      case 'Fertilizing': return Icons.grain_rounded;
      case 'Pest Control': return Icons.bug_report_rounded;
      default: return Icons.event_note_rounded;
    }
  }
}
