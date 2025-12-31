import 'package:flutter/material.dart';

class LogsScreen extends StatelessWidget {
  const LogsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Logs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {},
          ),
        ],
      ),
      body: const _LogView(),
    );
  }
}

class _LogView extends StatelessWidget {
  const _LogView();

  @override
  Widget build(BuildContext context) {
    // Sample log entries
    final logs = [
      LogEntry(DateTime.now(), 'info', 'Router started'),
      LogEntry(DateTime.now(), 'info', 'Loading router keys'),
      LogEntry(DateTime.now(), 'info', 'Starting transports'),
      LogEntry(DateTime.now(), 'info', 'NTCP2 server started on port 29385'),
      LogEntry(DateTime.now(), 'info', 'SSU2 server started on port 29385'),
      LogEntry(DateTime.now(), 'info', 'Starting HTTP proxy on 127.0.0.1:4444'),
      LogEntry(DateTime.now(), 'info', 'Starting SOCKS proxy on 127.0.0.1:4447'),
      LogEntry(DateTime.now(), 'info', 'Starting SAM bridge on 127.0.0.1:7656'),
      LogEntry(DateTime.now(), 'info', 'Reseeding from https://reseed.i2p-projekt.de'),
      LogEntry(DateTime.now(), 'info', 'Got 75 RouterInfos from reseed'),
      LogEntry(DateTime.now(), 'warn', 'Network status: Firewalled'),
      LogEntry(DateTime.now(), 'info', 'Building exploratory tunnels'),
      LogEntry(DateTime.now(), 'info', 'Exploratory tunnel 1 created'),
      LogEntry(DateTime.now(), 'info', 'Exploratory tunnel 2 created'),
      LogEntry(DateTime.now(), 'info', 'Network status: Testing'),
      LogEntry(DateTime.now(), 'info', 'Received peer test response'),
      LogEntry(DateTime.now(), 'info', 'Network status: OK'),
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: logs.length,
      itemBuilder: (context, index) {
        final log = logs[index];
        return _LogEntryWidget(log: log);
      },
    );
  }
}

class LogEntry {
  final DateTime timestamp;
  final String level;
  final String message;

  LogEntry(this.timestamp, this.level, this.message);
}

class _LogEntryWidget extends StatelessWidget {
  final LogEntry log;

  const _LogEntryWidget({required this.log});

  @override
  Widget build(BuildContext context) {
    Color levelColor;
    switch (log.level) {
      case 'error':
        levelColor = Colors.red;
        break;
      case 'warn':
        levelColor = Colors.orange;
        break;
      case 'debug':
        levelColor = Colors.grey;
        break;
      default:
        levelColor = Colors.green;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 11,
          ),
          children: [
            TextSpan(
              text: '[${log.timestamp.toString().substring(11, 19)}] ',
              style: TextStyle(color: Colors.grey[600]),
            ),
            TextSpan(
              text: '[${log.level.toUpperCase().padRight(5)}] ',
              style: TextStyle(color: levelColor),
            ),
            TextSpan(
              text: log.message,
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}
