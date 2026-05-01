import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/constants.dart';

class CurrencyService {
  static const String _exchangeRateApiUrl = 'https://api.exchangerate-api.com/v4/latest/USD';
  static const String _cachedRateKey = 'usd_to_tnd_rate';
  static const String _lastUpdateKey = 'currency_rate_last_update';
  
  static double _cachedRate = AppConstants.usdToTnd;
  static DateTime? _lastUpdate;

  /// Get the current USD to TND exchange rate
  /// Tries to fetch from API first, falls back to cached rate if offline
  static Future<double> getUsdToTndRate() async {
    try {
      // Try to fetch fresh rate from API
      final freshRate = await _fetchExchangeRate();
      if (freshRate > 0) {
        await _cacheRate(freshRate);
        _cachedRate = freshRate;
        _lastUpdate = DateTime.now();
        return freshRate;
      }
    } catch (e) {
      // If API fails, try to load cached rate
      print('Failed to fetch exchange rate: $e');
    }

    // Load from cache if API fails
    await _loadCachedRate();
    return _cachedRate;
  }

  /// Fetch exchange rate from API
  static Future<double> _fetchExchangeRate() async {
    try {
      final response = await http.get(
        Uri.parse(_exchangeRateApiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['rates'] != null && data['rates']['TND'] != null) {
          return double.parse(data['rates']['TND'].toString());
        }
      }
      throw Exception('Invalid response format');
    } catch (e) {
      throw Exception('Failed to fetch exchange rate: $e');
    }
  }

  /// Cache the exchange rate locally
  static Future<void> _cacheRate(double rate) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_cachedRateKey, rate);
      await prefs.setString(_lastUpdateKey, DateTime.now().toIso8601String());
    } catch (e) {
      print('Failed to cache exchange rate: $e');
    }
  }

  /// Load cached exchange rate from SharedPreferences
  static Future<void> _loadCachedRate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _cachedRate = prefs.getDouble(_cachedRateKey) ?? AppConstants.usdToTnd;
      
      final lastUpdateString = prefs.getString(_lastUpdateKey);
      if (lastUpdateString != null) {
        _lastUpdate = DateTime.parse(lastUpdateString);
      }
    } catch (e) {
      print('Failed to load cached exchange rate: $e');
      _cachedRate = AppConstants.usdToTnd;
    }
  }

  /// Convert USD to TND
  static double convertUsdToTnd(double usdAmount) {
    return usdAmount * _cachedRate;
  }

  /// Convert TND to USD
  static double convertTndToUsd(double tndAmount) {
    return tndAmount / _cachedRate;
  }

  /// Format USD amount with proper currency symbol
  static String formatUsd(double amount) {
    return '\$${amount.toStringAsFixed(2).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    )}';
  }

  /// Format TND amount with proper currency symbol
  static String formatTnd(double amount) {
    return 'د.ت ${amount.toStringAsFixed(2).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    )}';
  }

  /// Format both USD and TND amounts together
  static String formatBothCurrencies(double usdAmount) {
    final tndAmount = convertUsdToTnd(usdAmount);
    return '${formatUsd(usdAmount)} | ${formatTnd(tndAmount)}';
  }

  /// Get the last update time of the exchange rate
  static DateTime? get lastUpdate => _lastUpdate;

  /// Get the cached exchange rate
  static double get cachedRate => _cachedRate;

  /// Check if the cached rate is stale (older than 24 hours)
  static bool get isRateStale {
    if (_lastUpdate == null) return true;
    return DateTime.now().difference(_lastUpdate!).inHours > 24;
  }

  /// Force refresh the exchange rate from API
  static Future<double> refreshRate() async {
    try {
      final freshRate = await _fetchExchangeRate();
      if (freshRate > 0) {
        await _cacheRate(freshRate);
        _cachedRate = freshRate;
        _lastUpdate = DateTime.now();
        return freshRate;
      }
      throw Exception('Invalid rate received');
    } catch (e) {
      throw Exception('Failed to refresh exchange rate: $e');
    }
  }

  /// Initialize the service by loading cached rate
  static Future<void> initialize() async {
    await _loadCachedRate();
    
    // If rate is stale, try to refresh in background
    if (isRateStale) {
      try {
        await refreshRate();
      } catch (e) {
        print('Background refresh failed: $e');
        // Continue with cached rate
      }
    }
  }
}
