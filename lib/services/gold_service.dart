import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/constants.dart';

class GoldPrice {
  final double price;
  final double prevClosePrice;
  final double openPrice;
  final double lowPrice;
  final double highPrice;
  final double change;
  final double changePercent;
  final DateTime timestamp;
  final String currency;
  final String symbol;

  GoldPrice({
    required this.price,
    required this.prevClosePrice,
    required this.openPrice,
    required this.lowPrice,
    required this.highPrice,
    required this.change,
    required this.changePercent,
    required this.timestamp,
    required this.currency,
    required this.symbol,
  });

  factory GoldPrice.fromJson(Map<String, dynamic> json) {
  return GoldPrice(
    price: (json['price'] ?? 0).toDouble(),
    prevClosePrice: (json['prev_close_price'] ?? 0).toDouble(),
    openPrice: (json['open_price'] ?? 0).toDouble(),
    lowPrice: (json['low_price'] ?? 0).toDouble(),
    highPrice: (json['high_price'] ?? 0).toDouble(),
    change: (json['ch'] ?? 0).toDouble(),
    changePercent: (json['chp'] ?? 0).toDouble(),
    timestamp: json['timestamp'] != null ? DateTime.parse(json['timestamp'].toString()) : DateTime.now(),
    currency: json['currency']?.toString() ?? 'USD',
    symbol: json['symbol']?.toString() ?? 'XAU',
  );
}

  Map<String, dynamic> toJson() {
    return {
      'price': price,
      'prev_close_price': prevClosePrice,
      'open_price': openPrice,
      'low_price': lowPrice,
      'high_price': highPrice,
      'ch': change,
      'chp': changePercent,
      'timestamp': timestamp.toIso8601String(),
      'currency': currency,
      'symbol': symbol,
    };
  }
}

class HistoricalPrice {
  final DateTime date;
  final double open;
  final double high;
  final double low;
  final double close;

  HistoricalPrice({
    required this.date,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
  });

  factory HistoricalPrice.fromJson(Map<String, dynamic> json) {
    return HistoricalPrice(
      date: DateTime.parse(json['date']),
      open: (json['open'] ?? 0.0).toDouble(),
      high: (json['high'] ?? 0.0).toDouble(),
      low: (json['low'] ?? 0.0).toDouble(),
      close: (json['close'] ?? 0.0).toDouble(),
    );
  }
}

class GoldService {
  static const String _baseUrl = AppConstants.goldApiBaseUrl;
  static const String _apiKey = AppConstants.goldApiKey;

  static Future<GoldPrice> getCurrentGoldPrice() async {
    // Simulate API call with realistic data
    await Future.delayed(const Duration(milliseconds: 500));
    return GoldPrice(
      price: 3320.50,
      prevClosePrice: 3305.00,
      openPrice: 3310.00,
      lowPrice: 3290.00,
      highPrice: 3335.00,
      change: 15.50,
      changePercent: 0.47,
      timestamp: DateTime.now(),
      currency: 'USD',
      symbol: 'XAU',
    );
  }

  static Future<List<HistoricalPrice>> getHistoricalPrices({
    String period = '1M',
    int limit = 30,
  }) async {
    try {
      // Since GoldAPI might not have historical endpoint, we'll simulate with mock data
      // In production, you might use a different API like Alpha Vantage or Yahoo Finance
      final List<HistoricalPrice> mockData = [];
      final now = DateTime.now();
      
      for (int i = 0; i < limit; i++) {
        final date = now.subtract(Duration(days: i));
        final basePrice = 2350.0 + (i * 2.5); // Simulated price trend
        final volatility = 50.0; // Daily volatility
        
        mockData.add(HistoricalPrice(
          date: date,
          open: basePrice - volatility,
          high: basePrice + volatility,
          low: basePrice - volatility * 2,
          close: basePrice + (i % 3 - 1) * 10,
        ));
      }
      
      return mockData.reversed.toList();
    } catch (e) {
      throw Exception('Error fetching historical prices: $e');
    }
  }

  static Future<List<GoldPrice>> getRealTimePrices() async {
    try {
      final currentPrice = await getCurrentGoldPrice();
      
      // Simulate multiple timeframes
      return [
        currentPrice,
        GoldPrice(
          price: currentPrice.price * 0.998,
          prevClosePrice: currentPrice.prevClosePrice * 0.998,
          openPrice: currentPrice.openPrice * 0.998,
          lowPrice: currentPrice.lowPrice * 0.998,
          highPrice: currentPrice.highPrice * 0.998,
          change: currentPrice.change * 0.998,
          changePercent: currentPrice.changePercent,
          timestamp: currentPrice.timestamp.subtract(const Duration(minutes: 5)),
          currency: 'USD',
          symbol: 'XAU',
        ),
        GoldPrice(
          price: currentPrice.price * 1.002,
          prevClosePrice: currentPrice.prevClosePrice * 1.002,
          openPrice: currentPrice.openPrice * 1.002,
          lowPrice: currentPrice.lowPrice * 1.002,
          highPrice: currentPrice.highPrice * 1.002,
          change: currentPrice.change * 1.002,
          changePercent: currentPrice.changePercent,
          timestamp: currentPrice.timestamp.subtract(const Duration(minutes: 10)),
          currency: 'USD',
          symbol: 'XAU',
        ),
      ];
    } catch (e) {
      throw Exception('Error fetching real-time prices: $e');
    }
  }

  static double calculatePriceChange(List<GoldPrice> prices) {
    if (prices.length < 2) return 0.0;
    return prices.last.price - prices.first.price;
  }

  static double calculatePercentageChange(List<GoldPrice> prices) {
    if (prices.length < 2) return 0.0;
    final change = calculatePriceChange(prices);
    return (change / prices.first.price) * 100;
  }
}
