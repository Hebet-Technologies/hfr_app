import 'package:flutter/material.dart';
import '../utils/routes/routes_name.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  DateTime _selectedDate = DateTime.now();
  int _currentMonth = DateTime.now().month;
  int _currentYear = DateTime.now().year;

  final List<Map<String, dynamic>> _attendanceRecords = [
    {
      'date': DateTime(2026, 3, 1),
      'status': 'present',
      'checkIn': '08:00',
      'checkOut': '17:00',
    },
    {
      'date': DateTime(2026, 3, 2),
      'status': 'present',
      'checkIn': '08:15',
      'checkOut': '17:00',
    },
    {
      'date': DateTime(2026, 3, 3),
      'status': 'present',
      'checkIn': '08:00',
      'checkOut': '17:00',
    },
    {
      'date': DateTime(2026, 3, 4),
      'status': 'late',
      'checkIn': '08:45',
      'checkOut': '17:00',
    },
    {
      'date': DateTime(2026, 3, 5),
      'status': 'present',
      'checkIn': '08:00',
      'checkOut': '17:00',
    },
    {
      'date': DateTime(2026, 3, 8),
      'status': 'present',
      'checkIn': '08:00',
      'checkOut': '17:00',
    },
    {
      'date': DateTime(2026, 3, 9),
      'status': 'absent',
      'checkIn': '-',
      'checkOut': '-',
    },
    {
      'date': DateTime(2026, 3, 10),
      'status': 'present',
      'checkIn': '08:00',
      'checkOut': '17:00',
    },
    {
      'date': DateTime(2026, 3, 11),
      'status': 'present',
      'checkIn': '08:00',
      'checkOut': '17:00',
    },
    {
      'date': DateTime(2026, 3, 12),
      'status': 'late',
      'checkIn': '08:30',
      'checkOut': '17:00',
    },
    {
      'date': DateTime(2026, 3, 15),
      'status': 'present',
      'checkIn': '08:00',
      'checkOut': '17:00',
    },
    {
      'date': DateTime(2026, 3, 16),
      'status': 'present',
      'checkIn': '08:00',
      'checkOut': '17:00',
    },
    {
      'date': DateTime(2026, 3, 17),
      'status': 'present',
      'checkIn': '08:00',
      'checkOut': '17:00',
    },
    {
      'date': DateTime(2026, 3, 18),
      'status': 'present',
      'checkIn': '08:00',
      'checkOut': '17:00',
    },
    {
      'date': DateTime(2026, 3, 19),
      'status': 'present',
      'checkIn': '08:00',
      'checkOut': '17:00',
    },
    {
      'date': DateTime(2026, 3, 22),
      'status': 'present',
      'checkIn': '08:00',
      'checkOut': '17:00',
    },
    {
      'date': DateTime(2026, 3, 23),
      'status': 'present',
      'checkIn': '08:00',
      'checkOut': '17:00',
    },
    {
      'date': DateTime(2026, 3, 24),
      'status': 'late',
      'checkIn': '08:30',
      'checkOut': '17:00',
    },
    {
      'date': DateTime(2026, 3, 25),
      'status': 'present',
      'checkIn': '08:00',
      'checkOut': '17:00',
    },
  ];

  int get _presentCount =>
      _attendanceRecords.where((r) => r['status'] == 'present').length;

  int get _absentCount =>
      _attendanceRecords.where((r) => r['status'] == 'absent').length;

  int get _lateCount =>
      _attendanceRecords.where((r) => r['status'] == 'late').length;

  Map<String, dynamic>? _getRecordForDate(DateTime date) {
    try {
      return _attendanceRecords.firstWhere((r) => r['date'] == date);
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A1A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Attendance',
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: () {
                          setState(() {
                            if (_currentMonth == 1) {
                              _currentMonth = 12;
                              _currentYear--;
                            } else {
                              _currentMonth--;
                            }
                          });
                        },
                      ),
                      Text(
                        '${_getMonthName(_currentMonth)} $_currentYear',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: () {
                          setState(() {
                            if (_currentMonth == 12) {
                              _currentMonth = 1;
                              _currentYear++;
                            } else {
                              _currentMonth++;
                            }
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildCalendarGrid(),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildStatistics(),
            const SizedBox(height: 24),
            _buildAttendanceList(),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: 1,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF43A047),
          unselectedItemColor: Colors.grey,
          showUnselectedLabels: true,
          onTap: (index) {
            switch (index) {
              case 0:
                Navigator.pushReplacementNamed(context, RoutesName.home);
                break;
              case 1:
                break;
              case 2:
                Navigator.pushReplacementNamed(context, RoutesName.tasks);
                break;
              case 3:
                Navigator.pushReplacementNamed(context, RoutesName.profile);
                break;
            }
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.check_circle_outline),
              activeIcon: Icon(Icons.check_circle),
              label: 'Attendance',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.task_outlined),
              activeIcon: Icon(Icons.task),
              label: 'Tasks',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final firstDayOfMonth = DateTime(_currentYear, _currentMonth, 1);
    final daysInMonth = DateTime(_currentYear, _currentMonth + 1, 0).day;
    final startingWeekday = firstDayOfMonth.weekday % 7;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
              .map(
                (day) => SizedBox(
                  width: 40,
                  child: Text(
                    day,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF757575),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 1,
          ),
          itemCount: 42,
          itemBuilder: (context, index) {
            final dayNumber = index - startingWeekday + 1;
            if (dayNumber < 1 || dayNumber > daysInMonth) {
              return const SizedBox();
            }

            final date = DateTime(_currentYear, _currentMonth, dayNumber);
            final record = _getRecordForDate(date);

            Color bgColor = Colors.transparent;
            Color textColor = const Color(0xFF1A1A1A);

            if (record != null) {
              switch (record['status']) {
                case 'present':
                  bgColor = const Color(0xFF43A047);
                  textColor = Colors.white;
                  break;
                case 'late':
                  bgColor = const Color(0xFFFFA726);
                  textColor = Colors.white;
                  break;
                case 'absent':
                  bgColor = const Color(0xFFE53935);
                  textColor = Colors.white;
                  break;
              }
            }

            return Container(
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  '$dayNumber',
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildStatistics() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Attendance',
            _attendanceRecords.length.toString(),
            const Color(0xFF43A047),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Present',
            _presentCount.toString(),
            const Color(0xFF43A047),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Absent',
            _absentCount.toString(),
            const Color(0xFFE53935),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Late',
            _lateCount.toString(),
            const Color(0xFFFFA726),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Color(0xFF757575)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Attendance Records',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _attendanceRecords.length,
          itemBuilder: (context, index) {
            final record = _attendanceRecords[index];
            Color statusColor;
            String statusText;

            switch (record['status']) {
              case 'present':
                statusColor = const Color(0xFF43A047);
                statusText = 'Present';
                break;
              case 'late':
                statusColor = const Color(0xFFFFA726);
                statusText = 'Late';
                break;
              default:
                statusColor = const Color(0xFFE53935);
                statusText = 'Absent';
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE0E0E0)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '${record['date'].day}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        Text(
                          _getMonthName(record['date'].month).substring(0, 3),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF757575),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Check In: ${record['checkIn']}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF757575),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              'Check Out: ${record['checkOut']}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF757575),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            statusText,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }
}
