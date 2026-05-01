import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/theme.dart';
import '../../services/gold_service.dart';
import '../../services/currency_service.dart';
import '../../services/supabase_service.dart';
import '../../widgets/gold_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  GoldPrice? _currentPrice;
  List<GoldPrice> _priceHistory = [];
  List<Map<String, dynamic>> _portfolio = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Load current gold price
      final currentPrice = await GoldService.getCurrentGoldPrice();
      
      // Load real-time prices for history
      final priceHistory = await GoldService.getRealTimePrices();
      
      // Load user portfolio
      List<Map<String, dynamic>> portfolio = [];
      try {
        portfolio = await SupabaseService.getUserPortfolio();
      } catch (e) {
        // Portfolio might be empty or user not authenticated
      }

      setState(() {
        _currentPrice = currentPrice;
        _priceHistory = priceHistory;
        _portfolio = portfolio;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load data: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshData() async {
    await _loadData();
  }

  double _calculatePortfolioValue() {
    if (_currentPrice == null || _portfolio.isEmpty) return 0.0;
    
    double totalValue = 0.0;
    for (final item in _portfolio) {
      final weight = (item['weight'] ?? 0.0).toDouble();
      totalValue += weight * _currentPrice!.price / 31.1035; // Convert to USD per gram
    }
    return totalValue;
  }

  double _calculateTotalWeight() {
    double totalWeight = 0.0;
    for (final item in _portfolio) {
      totalWeight += (item['weight'] ?? 0.0).toDouble();
    }
    return totalWeight;
  }

  double _calculateProfitLoss() {
    if (_currentPrice == null || _portfolio.isEmpty) return 0.0;
    
    double profitLoss = 0.0;
    for (final item in _portfolio) {
      final weight = (item['weight'] ?? 0.0).toDouble();
      final purchasePrice = (item['purchase_price'] ?? 0.0).toDouble();
      final currentValue = weight * _currentPrice!.price / 31.1035;
      profitLoss += currentValue - purchasePrice;
    }
    return profitLoss;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: AppTheme.premiumGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                LucideIcons.coins,
                size: 20,
                color: AppTheme.black,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'GoldTrade Pro',
              style: TextStyle(
                color: AppTheme.gold,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw),
            onPressed: _refreshData,
          ),
          IconButton(
            icon: const Icon(LucideIcons.logOut),
            onPressed: () async {
              await SupabaseService.signOut();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.gold.withOpacity(0.2),
                      AppTheme.gold.withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.gold.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome back!',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Track your gold investments in real-time',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.gold,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        LucideIcons.sparkles,
                        color: AppTheme.black,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Loading State
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              
              // Error State
              else if (_errorMessage.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.alertCircle, color: Colors.red),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                )
              
              // Content
              else ...[
                // Current Gold Price Card
                if (_currentPrice != null) ...[
                  GoldPriceCard(
                    goldPrice: _currentPrice!,
                    priceChange: _priceHistory.isNotEmpty 
                        ? GoldService.calculatePriceChange(_priceHistory)
                        : null,
                    percentageChange: _priceHistory.isNotEmpty
                        ? GoldService.calculatePercentageChange(_priceHistory)
                        : null,
                    onTap: () {
                      // Navigate to chart screen
                    },
                  ),
                  const SizedBox(height: 24),
                ],
                
                // Quick Stats
                _buildQuickStats(context),
                const SizedBox(height: 24),
                
                // Portfolio Summary
                if (_portfolio.isNotEmpty) ...[
                  PortfolioSummaryCard(
                    totalValue: _calculatePortfolioValue(),
                    totalWeight: _calculateTotalWeight(),
                    profitLoss: _calculateProfitLoss(),
                    profitLossPercentage: _calculatePortfolioValue() > 0 
                        ? (_calculateProfitLoss() / _calculatePortfolioValue()) * 100
                        : 0.0,
                    itemCount: _portfolio.length,
                    onTap: () {
                      // Navigate to portfolio screen
                    },
                  ),
                  const SizedBox(height: 24),
                ],
                
                // Market Insights
                _buildMarketInsights(context),
                const SizedBox(height: 24),
                
                // Quick Actions
                _buildQuickActions(context),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Market Overview',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                '24h Change',
                _priceHistory.isNotEmpty
                    ? '${GoldService.calculatePercentageChange(_priceHistory).toStringAsFixed(2)}%'
                    : '0.00%',
                GoldService.calculatePercentageChange(_priceHistory) >= 0,
                LucideIcons.trendingUp,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                context,
                'Market Cap',
                CurrencyService.formatBothCurrencies(14200000000000),
                true,
                LucideIcons.dollarSign,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                'Volume 24h',
                CurrencyService.formatBothCurrencies(125800000000),
                true,
                LucideIcons.barChart3,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                context,
                'Volatility',
                'Medium',
                false,
                LucideIcons.activity,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    bool isPositive,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: isPositive ? Colors.green : Colors.orange,
              ),
              const SizedBox(width: 4),
              Text(
                title,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isPositive ? Colors.green : Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarketInsights(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Market Insights',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.gold.withOpacity(0.1),
                Colors.transparent,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.gold.withOpacity(0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.gold.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      LucideIcons.trendingUp,
                      size: 16,
                      color: AppTheme.gold,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Bullish Momentum',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.gold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Gold prices are showing strong upward momentum driven by inflation concerns and geopolitical tensions. Technical indicators suggest continued strength in the short term.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildInsightTag('Strong Buy', Colors.green),
                  const SizedBox(width: 8),
                  _buildInsightTag('RSI: 65', AppTheme.gold),
                  const SizedBox(width: 8),
                  _buildInsightTag('Volume: High', Colors.blue),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInsightTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                context,
                'Buy Gold',
                LucideIcons.plusCircle,
                AppTheme.gold,
                () {
                  // Navigate to buy gold screen
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                context,
                'Price Alert',
                LucideIcons.bell,
                Colors.blue,
                () {
                  // Navigate to price alert screen
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                context,
                'News',
                LucideIcons.newspaper,
                Colors.purple,
                () {
                  // Navigate to news screen
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                context,
                'Calculator',
                LucideIcons.calculator,
                Colors.green,
                () {
                  // Navigate to calculator screen
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.3),
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
