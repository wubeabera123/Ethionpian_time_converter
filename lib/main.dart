import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'ethiopian_calendar_converter.dart';

void main() {
  runApp(const EthiopianTimeApp());
}

class EthiopianTimeApp extends StatelessWidget {
  const EthiopianTimeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ethiopian Time Converter',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        useMaterial3: true,
      ),
      home: const ConverterScreen(),
    );
  }
}

class ConverterScreen extends StatefulWidget {
  const ConverterScreen({super.key});

  @override
  State<ConverterScreen> createState() => _ConverterScreenState();
}

class _ConverterScreenState extends State<ConverterScreen> {
  String _selectedTimeZone = 'Africa/Addis_Ababa';
  DateTime? _currentTime;
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';

  final List<String> _allTimeZones = [
    'Africa/Addis_Ababa', 'Africa/Nairobi', 'Africa/Lagos', 'Africa/Johannesburg', 'Africa/Cairo',
    'Europe/London', 'Europe/Paris', 'Europe/Berlin', 'Europe/Moscow', 'Europe/Istanbul',
    'America/New_York', 'America/Chicago', 'America/Los_Angeles', 'America/Sao_Paulo', 'America/Toronto',
    'Asia/Tokyo', 'Asia/Shanghai', 'Asia/Dubai', 'Asia/Kolkata', 'Asia/Seoul', 'Asia/Singapore',
    'Australia/Sydney', 'Pacific/Auckland'
  ];

  List<String> get _filteredTimeZones => _allTimeZones
      .where((tz) => tz.toLowerCase().contains(_searchQuery.toLowerCase()))
      .toList();

  Future<void> _fetchTime() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final url = Uri.parse('https://timeapi.io/api/Time/current/zone?timeZone=$_selectedTimeZone');
      final response = await http.get(url).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _currentTime = DateTime.parse(data['dateTime']);
          _isLoading = false;
        });
      } else {
        throw Exception('Primary API failed');
      }
    } catch (e) {
      _fetchFallbackTime();
    }
  }

  Future<void> _fetchFallbackTime() async {
    try {
      final url = Uri.parse('https://worldtimeapi.org/api/timezone/$_selectedTimeZone');
      final response = await http.get(url).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _currentTime = DateTime.parse(data['datetime']);
          _isLoading = false;
        });
      } else {
        _useSystemTime('API unavailable. Used device time.');
      }
    } catch (e) {
      _useSystemTime('Connection error. Used device time.');
    }
  }

  void _useSystemTime([String? message]) {
    setState(() {
      _currentTime = DateTime.now();
      _error = message;
      _isLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _fetchTime();
  }

  @override
  Widget build(BuildContext context) {
    EthiopianDate? etDate;
    String? etTime;
    String? gregDateStr;
    String? gregTimeStr;

    if (_currentTime != null) {
      etDate = EthiopianCalendarConverter.convertToEthiopian(_currentTime!);
      etTime = EthiopianCalendarConverter.convertToEthiopianTime(_currentTime!);
      gregDateStr = DateFormat('yyyy-MM-dd').format(_currentTime!);
      gregTimeStr = DateFormat('HH:mm:ss').format(_currentTime!);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ethiopian Converter'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showAboutDialog(context),
          )
        ],
      ),
      body: Column(
        children: [
          // 1. Search Field
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search city/timezone...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),

          // 2. City List
          Expanded(
            child: _filteredTimeZones.isEmpty 
              ? const Center(child: Text('No cities found.'))
              : ListView.builder(
                  itemCount: _filteredTimeZones.length,
                  itemBuilder: (context, index) {
                    final tz = _filteredTimeZones[index];
                    return ListTile(
                      title: Text(tz),
                      selected: _selectedTimeZone == tz,
                      trailing: _selectedTimeZone == tz ? const Icon(Icons.check_circle, color: Colors.deepOrange) : null,
                      onTap: () {
                        setState(() => _selectedTimeZone = tz);
                        _fetchTime();
                      },
                    );
                  },
                ),
          ),

          // 3. Results Panel (Sticky Bottom)
          if (_currentTime != null) 
            _buildResultsPanel(etDate!, etTime!, gregDateStr!, gregTimeStr!)
        ],
      ),
    );
  }

  Widget _buildResultsPanel(EthiopianDate etDate, String etTime, String gDate, String gTime) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, spreadRadius: 2)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isLoading) const Padding(padding: EdgeInsets.only(bottom: 10), child: LinearProgressIndicator()),
          if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 11)),
          
          Row(
            children: [
              _resultBox('Gregorian', '$gDate\n$gTime', Colors.blue.shade900),
              const SizedBox(width: 15),
              _resultBox('Ethiopian', '${etDate.day} ${etDate.monthName} ${etDate.year}\n$etTime', Colors.green.shade900),
            ],
          ),
          const SizedBox(height: 10),
          Text('Location: $_selectedTimeZone', style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }

  Widget _resultBox(String title, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Ethiopian Time Converter',
      applicationVersion: '1.0.0',
      children: [const Text('Converts Gregorian time to Ethiopian Calendar (13 months) and the Ethiopian 12-hour clock system.')],
    );
  }
}
