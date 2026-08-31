import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:provider/provider.dart';
import '../services/app_provider.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  double _lat = 6.6666;
  double _lon = -1.6163;
  String _locationName = 'Kumasi';
  
  Map<String, dynamic>? _currentWeather;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initWeather();
  }

  Future<void> _initWeather() async {
    setState(() => _isLoading = true);
    await _getCurrentLocation();
    await _fetchWeather();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint("Location services disabled");
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint("Location permission denied");
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        debugPrint("Location permission permanently denied");
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 10),
      );
      
      if (mounted) {
        setState(() {
          _lat = position.latitude;
          _lon = position.longitude;
        });
      }
      
      if (!kIsWeb) {
        try {
          List<Placemark> placemarks = await placemarkFromCoordinates(_lat, _lon);
          if (placemarks.isNotEmpty && mounted) {
            setState(() {
              _locationName = placemarks[0].locality ?? placemarks[0].administrativeArea ?? 'My Farm';
            });
          }
        } catch (e) {
          debugPrint("Geocoding error: $e");
          if (mounted) setState(() => _locationName = 'Current Location');
        }
      } else {
        if (mounted) setState(() => _locationName = 'Browser Location');
      }
    } catch (e) {
      debugPrint("Error getting location: $e");
    }
  }

  Future<void> _fetchWeather() async {
    try {
      final url = 'https://api.open-meteo.com/v1/forecast?latitude=$_lat&longitude=$_lon&current=temperature_2m,relative_humidity_2m,wind_speed_10m,weather_code&hourly=temperature_2m,relative_humidity_2m&past_days=3&timezone=auto';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200 && mounted) {
        setState(() {
          _currentWeather = json.decode(response.body)['current'];
          _isLoading = false;
        });
      } else if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32), strokeWidth: 2))
          : RefreshIndicator(
              onRefresh: _initWeather,
              color: const Color(0xFF2E7D32),
              backgroundColor: Colors.white,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                slivers: [
                  _buildWeatherHeader(),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 32, 24, 100),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionLabel('FIELD CONDITIONS'),
                          const SizedBox(height: 16),
                          _buildAdviceCards(),
                          const SizedBox(height: 48),
                          _buildSectionLabel('TEMPERATURE TREND'),
                          const SizedBox(height: 16),
                          _buildTrendChart(),
                          const SizedBox(height: 48),
                          _buildSectionLabel('ATMOSPHERIC DETAILS'),
                          const SizedBox(height: 16),
                          _buildDetailsGrid(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildWeatherHeader() {
    final temp = _currentWeather?['temperature_2m'] ?? 0;
    final code = _currentWeather?['weather_code'] ?? 0;
    final desc = _getWeatherDescription(code);

    return SliverAppBar(
      expandedHeight: 280,
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
      actions: [
        IconButton(
          icon: Icon(
            Theme.of(context).brightness == Brightness.light ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => context.read<AppProvider>().toggleTheme(Theme.of(context).brightness == Brightness.light),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 22),
            onPressed: _initWeather,
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: Text(
          'Weather'.toUpperCase(),
          style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 10, letterSpacing: 3),
        ),
        background: Container(
          color: const Color(0xFF2E7D32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.location_on_rounded, color: Colors.white38, size: 16),
                  const SizedBox(width: 4),
                  Text(_locationName, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 16),
              Text('${temp.toInt()}°', style: const TextStyle(color: Colors.white, fontSize: 80, fontWeight: FontWeight.w800, letterSpacing: -2)),
              Text(desc.toUpperCase(), style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12, letterSpacing: 2, fontWeight: FontWeight.w900)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(text, style: TextStyle(color: const Color(0xFF1B5E20).withValues(alpha: 0.4), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5));
  }

  Widget _buildAdviceCards() {
    final temp = _currentWeather?['temperature_2m'] ?? 0;
    final humidity = _currentWeather?['relative_humidity_2m'] ?? 0;
    
    List<Map<String, dynamic>> advice = [
      {
        'title': 'Moisture Alert',
        'msg': humidity > 80 ? 'High humidity ($humidity%) increases Black Rot risk.' : 'Conditions are stable for cabbage health.',
        'icon': Icons.water_drop_rounded,
        'color': humidity > 80 ? Colors.redAccent : Colors.blue,
      },
      {
        'title': 'Heat Monitoring',
        'msg': temp > 30 ? 'Heat stress likely. Water base early or late.' : 'Temperature is ideal for cabbage growth.',
        'icon': Icons.wb_sunny_rounded,
        'color': temp > 30 ? const Color(0xFFFBC02D) : const Color(0xFF2E7D32),
      }
    ];

    return Column(
      children: advice.map((a) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F8E9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF2E7D32).withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            Icon(a['icon'], color: a['color'], size: 24),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(a['title'], style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFF1B5E20))),
                  const SizedBox(height: 4),
                  Text(a['msg'], style: TextStyle(fontSize: 13, color: Colors.black.withValues(alpha: 0.4), height: 1.4, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildTrendChart() {
    return Container(
      height: 180,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F8E9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2E7D32).withValues(alpha: 0.05)),
      ),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: List.generate(10, (i) => FlSpot(i.toDouble(), 25 + (i % 5).toDouble())),
              isCurved: true,
              color: const Color(0xFF2E7D32),
              barWidth: 3,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(show: true, color: const Color(0xFF2E7D32).withValues(alpha: 0.05)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        _detailBox('HUMIDITY', '${_currentWeather?['relative_humidity_2m'] ?? 0}%'),
        _detailBox('WIND SPEED', '${_currentWeather?['wind_speed_10m'] ?? 0}km/h'),
        _detailBox('STATUS', 'ONLINE'),
        _detailBox('FORECAST', '7 DAYS'),
      ],
    );
  }

  Widget _detailBox(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F8E9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2E7D32).withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: TextStyle(color: const Color(0xFF1B5E20).withValues(alpha: 0.4), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF1B5E20))),
        ],
      ),
    );
  }

  String _getWeatherDescription(int code) {
    if (code == 0) return 'Clear Skies';
    if (code <= 3) return 'Partly Cloudy';
    if (code <= 67) return 'Rainy';
    return 'Stormy';
  }
}
