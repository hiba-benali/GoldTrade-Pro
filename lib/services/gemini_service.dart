import 'package:google_generative_ai/google_generative_ai.dart';
import '../config/constants.dart';
import 'dart:async';

class ChatMessage {
  final String message;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.message,
    required this.isUser,
    required this.timestamp,
  });
}

class GeminiService {
  static late GenerativeModel _model;
  static List<ChatMessage> _chatHistory = [];

  static void initialize() {
    _model = GenerativeModel(
      model: 'gemini-2.0-flash',
      apiKey: AppConstants.geminiApiKey,
    );
  }

  static Future<String> sendMessage(String message) async {
    try {
      // Add user message to history
      _chatHistory.add(
        ChatMessage(
          message: message,
          isUser: true,
          timestamp: DateTime.now(),
        ),
      );

      // Create context-aware prompt
      String contextPrompt = _buildContextPrompt();
      String fullPrompt = '$contextPrompt\n\nUser: $message';

      // Generate response with retry logic
      String aiResponse = await _generateWithRetry(fullPrompt);

      // Add AI response to history
      _chatHistory.add(
        ChatMessage(
          message: aiResponse,
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );

      // Keep only last 20 messages to manage context
      if (_chatHistory.length > 20) {
        _chatHistory = _chatHistory.sublist(_chatHistory.length - 20);
      }

      return aiResponse;
    } catch (e) {
      if (e.toString().contains('quota') || e.toString().contains('rate limit')) {
        return 'Please wait a moment and try again...';
      }
      throw Exception('Error generating AI response: $e');
    }
  }

  static Future<String> _generateWithRetry(String prompt, {int maxRetries = 2}) async {
    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        final response = await _model.generateContent(
          [Content.text(prompt)],
        );
        return response.toString() ?? 'Sorry, I could not generate a response.';
      } catch (e) {
        if (attempt == maxRetries) {
          // Last attempt failed, rethrow the exception
          rethrow;
        }
        
        // Check if it's a quota/rate limit error
        if (e.toString().contains('quota') || 
            e.toString().contains('rate limit') || 
            e.toString().contains('429') ||
            e.toString().contains('resource exhausted')) {
          
          // Wait 20 seconds before retrying
          await Future.delayed(const Duration(seconds: 20));
          continue;
        } else {
          // Not a quota error, don't retry
          rethrow;
        }
      }
    }
    
    // This should never be reached, but just in case
    return 'Sorry, I could not generate a response.';
  }

  static String _buildContextPrompt() {
    final recentHistory = _chatHistory.length > 5 
        ? _chatHistory.sublist(_chatHistory.length - 5)
        : _chatHistory;

    String historyContext = '';
    for (final msg in recentHistory) {
      historyContext += '${msg.isUser ? "User" : "Assistant"}: ${msg.message}\n';
    }

    return '''You are a professional gold trading and investment advisor with expertise in:
- Gold market analysis and trends
- Investment strategies for precious metals
- Risk management in gold trading
- Islamic finance principles (including zakat calculations)
- Technical and fundamental analysis
- Portfolio diversification with gold

Current conversation history:
$historyContext

Provide professional, accurate, and helpful advice about gold trading and investment. Always consider:
1. Market conditions and trends
2. Risk factors
3. Islamic finance principles when relevant
4. Practical investment advice
5. Educational explanations when needed

Be concise but thorough in your responses. If you're unsure about specific real-time data, acknowledge this and provide general guidance instead.''';
  }

  static Future<String> getMarketAnalysis() async {
    try {
      const prompt = '''Provide a comprehensive analysis of the current gold market including:
1. Recent price trends and patterns
2. Key market drivers (inflation, geopolitical events, etc.)
3. Technical analysis insights
4. Short-term and long-term outlook
5. Investment recommendations

Keep the analysis professional and data-driven. Acknowledge that this is not financial advice.''';

      final response = await _generateWithRetry(prompt);

      return response.toString() ?? 'Unable to generate market analysis at this time.';
    } catch (e) {
      if (e.toString().contains('quota') || e.toString().contains('rate limit')) {
        return 'Please wait a moment and try again...';
      }
      throw Exception('Error generating market analysis: $e');
    }
  }

  static Future<String> getInvestmentAdvice({
    required double investmentAmount,
    required String riskTolerance,
    required String investmentHorizon,
  }) async {
    try {
      final prompt = '''Provide personalized gold investment advice for the following profile:
- Investment Amount: \$${investmentAmount.toStringAsFixed(2)}
- Risk Tolerance: $riskTolerance
- Investment Horizon: $investmentHorizon

Include recommendations for:
1. Gold allocation percentage
2. Types of gold investments (physical, ETFs, mining stocks, etc.)
3. Diversification strategies
4. Risk management approaches
5. Rebalancing frequency

Consider Islamic finance principles and zakat implications where relevant.''';

      final response = await _generateWithRetry(prompt);

      return response.toString() ?? 'Unable to generate investment advice at this time.';
    } catch (e) {
      if (e.toString().contains('quota') || e.toString().contains('rate limit')) {
        return 'Please wait a moment and try again...';
      }
      throw Exception('Error generating investment advice: $e');
    }
  }

  static Future<String> calculateZakatAdvice({
    required double totalGoldValue,
    required double totalAssets,
  }) async {
    try {
      final prompt = '''Provide zakat calculation advice for:
- Total Gold Value: \$${totalGoldValue.toStringAsFixed(2)}
- Total Assets: \$${totalAssets.toStringAsFixed(2)}

Include:
1. Zakat calculation (2.5% of eligible assets)
2. Nisab threshold consideration
3. Payment recommendations
4. Timing considerations
5. Recipients of zakat

Base calculations on Islamic principles where zakat is 2.5% of assets held for one lunar year above the nisab threshold.''';

      final response = await _generateWithRetry(prompt);

      return response.toString() ?? 'Unable to generate zakat advice at this time.';
    } catch (e) {
      if (e.toString().contains('quota') || e.toString().contains('rate limit')) {
        return 'Please wait a moment and try again...';
      }
      throw Exception('Error generating zakat advice: $e');
    }
  }

  static Future<String> getRiskAnalysis() async {
    try {
      const prompt = '''Provide a comprehensive risk analysis for gold investing including:
1. Market risks (price volatility, liquidity)
2. Economic risks (inflation, currency fluctuations)
3. Geopolitical risks
4. Regulatory risks
5. Storage and security risks (for physical gold)
6. Counterparty risks (for ETFs, futures)

For each risk, provide:
- Description
- Likelihood
- Potential impact
- Mitigation strategies

Keep the analysis professional and balanced.''';

      final response = await _generateWithRetry(prompt);

      return response.toString() ?? 'Unable to generate risk analysis at this time.';
    } catch (e) {
      if (e.toString().contains('quota') || e.toString().contains('rate limit')) {
        return 'Please wait a moment and try again...';
      }
      throw Exception('Error generating risk analysis: $e');
    }
  }

  static List<ChatMessage> getChatHistory() {
    return List.from(_chatHistory);
  }

  static void clearChatHistory() {
    _chatHistory.clear();
  }

  static Future<String> explainGoldConcept(String concept) async {
    try {
      final prompt = '''Explain the following gold trading concept in simple, educational terms: "$concept"

Include:
1. Clear definition
2. How it works in practice
3. Why it's important for gold traders
4. Examples or scenarios
5. Key considerations

Make it easy to understand for both beginners and experienced traders.''';

      final response = await _generateWithRetry(prompt);

      return response.toString() ?? 'Unable to explain this concept at this time.';
    } catch (e) {
      if (e.toString().contains('quota') || e.toString().contains('rate limit')) {
        return 'Please wait a moment and try again...';
      }
      throw Exception('Error generating concept explanation: $e');
    }
  }
}
