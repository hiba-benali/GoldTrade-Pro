import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/constants.dart';

class SupabaseService {
  static final SupabaseClient _client = Supabase.instance.client;

  // Authentication methods
  static Future<AuthResponse> signInWithEmail(String email, String password) async {
    try {
      return await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw Exception('Sign in failed: $e');
    }
  }

  static Future<AuthResponse> signUpWithEmail(String email, String password) async {
    try {
      return await _client.auth.signUp(
        email: email,
        password: password,
      );
    } catch (e) {
      throw Exception('Sign up failed: $e');
    }
  }

  static Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (e) {
      throw Exception('Sign out failed: $e');
    }
  }

  static Future<void> resetPassword(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
    } catch (e) {
      throw Exception('Password reset failed: $e');
    }
  }

  static User? get currentUser => _client.auth.currentUser;

  // Portfolio methods
  static Future<List<Map<String, dynamic>>> getUserPortfolio() async {
    try {
      final userId = currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _client
          .from('portfolio')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch portfolio: $e');
    }
  }

  static Future<Map<String, dynamic>> addGoldToPortfolio({
    required String name,
    required double weight,
    required double purchasePrice,
    required String purchaseDate,
    required String type, // 'coins', 'bars', 'jewelry'
  }) async {
    try {
      final userId = currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _client.from('portfolio').insert({
        'user_id': userId,
        'name': name,
        'weight': weight,
        'purchase_price': purchasePrice,
        'purchase_date': purchaseDate,
        'type': type,
        'created_at': DateTime.now().toIso8601String(),
      }).select();

      return response.first;
    } catch (e) {
      throw Exception('Failed to add gold to portfolio: $e');
    }
  }

  static Future<void> updatePortfolioItem(String itemId, Map<String, dynamic> updates) async {
    try {
      final userId = currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      await _client
          .from('portfolio')
          .update(updates)
          .eq('id', itemId)
          .eq('user_id', userId);
    } catch (e) {
      throw Exception('Failed to update portfolio item: $e');
    }
  }

  static Future<void> deletePortfolioItem(String itemId) async {
    try {
      final userId = currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      await _client
          .from('portfolio')
          .delete()
          .eq('id', itemId)
          .eq('user_id', userId);
    } catch (e) {
      throw Exception('Failed to delete portfolio item: $e');
    }
  }

  // User profile methods
  static Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final userId = currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      return response;
    } catch (e) {
      throw Exception('Failed to fetch user profile: $e');
    }
  }

  static Future<void> updateUserProfile(Map<String, dynamic> updates) async {
    try {
      final userId = currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      await _client
          .from('profiles')
          .update(updates)
          .eq('id', userId);
    } catch (e) {
      throw Exception('Failed to update user profile: $e');
    }
  }

  // Gold shops methods
  static Future<List<Map<String, dynamic>>> getNearbyGoldShops({
    required double latitude,
    required double longitude,
    double radius = 10.0, // km
  }) async {
    try {
      // For now, return mock data. In production, you'd use PostGIS or similar
      return [
        {
          'id': '1',
          'name': 'Golden Jewels',
          'address': '123 Main Street, City Center',
          'latitude': latitude + 0.01,
          'longitude': longitude + 0.01,
          'rating': 4.5,
          'phone': '+1234567890',
          'hours': '9:00 AM - 8:00 PM',
          'services': ['Gold Buying', 'Gold Selling', 'Jewelry'],
        },
        {
          'id': '2',
          'name': 'Precious Metals Exchange',
          'address': '456 Market Avenue',
          'latitude': latitude - 0.01,
          'longitude': longitude + 0.01,
          'rating': 4.8,
          'phone': '+0987654321',
          'hours': '10:00 AM - 6:00 PM',
          'services': ['Gold Trading', 'Silver Trading', 'Appraisal'],
        },
        {
          'id': '3',
          'name': 'Royal Gold Gallery',
          'address': '789 Palace Road',
          'latitude': latitude + 0.01,
          'longitude': longitude - 0.01,
          'rating': 4.2,
          'phone': '+1122334455',
          'hours': '11:00 AM - 7:00 PM',
          'services': ['Gold Jewelry', 'Custom Design', 'Repair'],
        },
      ];
    } catch (e) {
      throw Exception('Failed to fetch nearby gold shops: $e');
    }
  }

  // Watchlist methods
  static Future<List<Map<String, dynamic>>> getWatchlist() async {
    try {
      final userId = currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _client
          .from('watchlist')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch watchlist: $e');
    }
  }

  static Future<void> addToWatchlist(String symbol, String name) async {
    try {
      final userId = currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      await _client.from('watchlist').insert({
        'user_id': userId,
        'symbol': symbol,
        'name': name,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to add to watchlist: $e');
    }
  }

  static Future<void> removeFromWatchlist(String watchlistId) async {
    try {
      final userId = currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      await _client
          .from('watchlist')
          .delete()
          .eq('id', watchlistId)
          .eq('user_id', userId);
    } catch (e) {
      throw Exception('Failed to remove from watchlist: $e');
    }
  }
}
