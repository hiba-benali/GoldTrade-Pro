class AppConstants {
  // API Keys
  static const String goldApiKey = 'goldapi-3q0jfsmo5l03is-io';
  static const String supabaseUrl = 'https://hofoskvuibhzbgqzijcq.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhvZm9za3Z1aWJoemJncXppamNxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY3MDUxMzEsImV4cCI6MjA5MjI4MTEzMX0.Yqf1cmaY24oH1njWJM6nFBK-j4y1yOaMVwYQWP6yD4Q';
  static const String geminiApiKey = 'AIzaSyA09rxboR6SR8X4In6uADiNhVvWm7NdLKc';

  // API Endpoints
  static const String goldApiBaseUrl = 'https://www.goldapi.io/api';
  static const String xauUsdEndpoint = '/XAU/USD';

  // App Configuration
  static const String appName = 'GoldTrade Pro';
  static const String appVersion = '1.0.0';

  // Zakat Configuration
  static const double zakatRate = 0.025; // 2.5%
  static const double nisabThreshold = 87.48; // grams of gold

  // Map Configuration
  static const double defaultZoom = 13.0;
  static const double searchRadius = 10.0; // km

  // Chart Configuration
  static const int maxChartDataPoints = 30;
  static const List<String> chartTimeRanges = ['1D', '1W', '1M', '3M', '6M', '1Y'];

  // Cache Duration (in minutes)
  static const int goldPriceCacheDuration = 5;
  static const int portfolioCacheDuration = 30;

  // Currency Configuration
  static const String defaultCurrency = 'TND';
  static const double usdToTnd = 3.15;
  static const List<String> supportedCurrencies = ['USD', 'TND'];
}
