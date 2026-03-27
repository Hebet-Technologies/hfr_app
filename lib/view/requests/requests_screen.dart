import 'package:flutter/material.dart';

class RequestsScreen extends StatelessWidget {
  const RequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Requests'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildRequestCard(
            context,
            title: 'Leave Request',
            status: 'Pending',
            date: 'Mar 20, 2026',
            description: 'Annual leave for 5 days',
            statusColor: Colors.orange,
            icon: Icons.event_available,
          ),
          _buildRequestCard(
            context,
            title: 'Overtime Request',
            status: 'Approved',
            date: 'Mar 18, 2026',
            description: 'Weekend overtime - 8 hours',
            statusColor: Colors.green,
            icon: Icons.access_time,
          ),
          _buildRequestCard(
            context,
            title: 'Training Request',
            status: 'Pending',
            date: 'Mar 15, 2026',
            description: 'Advanced medical training',
            statusColor: Colors.orange,
            icon: Icons.school,
          ),
          _buildRequestCard(
            context,
            title: 'Equipment Request',
            status: 'Rejected',
            date: 'Mar 10, 2026',
            description: 'New laptop for work',
            statusColor: Colors.red,
            icon: Icons.laptop,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showNewRequestDialog(context);
        },
        icon: const Icon(Icons.add),
        label: const Text('New Request'),
      ),
    );
  }

  Widget _buildRequestCard(
    BuildContext context, {
    required String title,
    required String status,
    required String date,
    required String description,
    required Color statusColor,
    required IconData icon,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: statusColor, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        date,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNewRequestDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'New Request',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            _buildRequestOption(
              context,
              icon: Icons.event_available,
              title: 'Leave Request',
              onTap: () {},
            ),
            _buildRequestOption(
              context,
              icon: Icons.access_time,
              title: 'Overtime Request',
              onTap: () {},
            ),
            _buildRequestOption(
              context,
              icon: Icons.school,
              title: 'Training Request',
              onTap: () {},
            ),
            _buildRequestOption(
              context,
              icon: Icons.laptop,
              title: 'Equipment Request',
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).primaryColor),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}
