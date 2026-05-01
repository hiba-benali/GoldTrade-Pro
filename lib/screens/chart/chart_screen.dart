import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../services/gold_service.dart';

class ChartScreen extends StatefulWidget {
  const ChartScreen({super.key});

  @override
  State<ChartScreen> createState() => _ChartScreenState();
}

class _ChartScreenState extends State<ChartScreen> {
  List<HistoricalPrice> _historicalData = [];
  String _selectedTimeRange = '1M';
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadChartData();
  }

  Future<void> _loadChartData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final data = await GoldService.getHistoricalPrices(
        period: _selectedTimeRange,
        limit: _getDataPoints(),
      );
      
      setState(() {
        _historicalData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load chart data: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  int _getDataPoints() {
    switch (_selectedTimeRange) {
      case '1D':
        return 24;
      case '1W':
        return 7;
      case '1M':
        return 30;
      case '3M':
        return 90;
      case '6M':
        return 180;
      case '1Y':
        return 365;
      default:
        return 30;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Price Charts',
          style: TextStyle(
            color: AppTheme.gold,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.download),
            onPressed: _exportChart,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Time Range Selector
            _buildTimeRangeSelector(),
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
            
            // Chart Content
            else ...[
              // Price Summary
              _buildPriceSummary(),
              const SizedBox(height: 24),
              
              // Main Chart
              _buildMainChart(),
              const SizedBox(height: 24),
              
              // Volume Chart
              _buildVolumeChart(),
              const SizedBox(height: 24),
              
              // Technical Indicators
              _buildTechnicalIndicators(),
              const SizedBox(height: 24),
              
              // Statistics
              _buildStatistics(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimeRangeSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: AppConstants.chartTimeRanges.map((range) {
          final isSelected = range == _selectedTimeRange;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTimeRange = range;
                });
                _loadChartData();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.gold : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  range,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected ? AppTheme.black : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPriceSummary() {
    if (_historicalData.isEmpty) return const SizedBox.shrink();
    
    final latest = _historicalData.last;
    final oldest = _historicalData.first;
    final change = latest.close - oldest.open;
    final changePercent = (change / oldest.open) * 100;
    final isPositive = change >= 0;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.gold.withOpacity(0.1),
            Colors.transparent,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.gold.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Price',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  Text(
                    '\$${latest.close.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.gold,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _selectedTimeRange + ' Change',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  Row(
                    children: [
                      Icon(
                        isPositive ? LucideIcons.trendingUp : LucideIcons.trendingDown,
                        size: 20,
                        color: isPositive ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${isPositive ? '+' : ''}\$${change.abs().toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isPositive ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${isPositive ? '+' : ''}${changePercent.toStringAsFixed(2)}%',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isPositive ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem('Open', '\$${oldest.open.toStringAsFixed(2)}'),
              _buildSummaryItem('High', '\$${_historicalData.map((e) => e.high).reduce((a, b) => a > b ? a : b).toStringAsFixed(2)}'),
              _buildSummaryItem('Low', '\$${_historicalData.map((e) => e.low).reduce((a, b) => a < b ? a : b).toStringAsFixed(2)}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildMainChart() {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 50,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: (_getDataPoints() ~/ 6).toDouble(),
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= _historicalData.length || value.toInt() < 0) {
                    return const SizedBox.shrink();
                  }
                  final date = _historicalData[value.toInt()].date;
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(
                      DateFormat('MMM dd').format(date),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 50,
                getTitlesWidget: (value, meta) {
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(
                      '\$${value.toInt()}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: (_historicalData.length - 1).toDouble(),
          minY: _historicalData.map((e) => e.low).reduce((a, b) => a < b ? a : b) - 50,
          maxY: _historicalData.map((e) => e.high).reduce((a, b) => a > b ? a : b) + 50,
          lineBarsData: [
            LineChartBarData(
              spots: _historicalData.asMap().entries.map((entry) {
                return FlSpot(entry.key.toDouble(), entry.value.close);
              }).toList(),
              isCurved: true,
              gradient: LinearGradient(
                colors: [
                  AppTheme.gold.withOpacity(0.8),
                  AppTheme.gold,
                ],
              ),
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    AppTheme.gold.withOpacity(0.3),
                    AppTheme.gold.withOpacity(0.1),
                    Colors.transparent,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
                            tooltipRoundedRadius: 8,
              getTooltipItems: (spots) {
                return spots.map((spot) {
                  final index = spot.x.toInt();
                  if (index >= _historicalData.length) return null;
                  
                  final data = _historicalData[index];
                  return LineTooltipItem(
                    '${DateFormat('MMM dd, yyyy').format(data.date)}\n'
                    'Open: \$${data.open.toStringAsFixed(2)}\n'
                    'High: \$${data.high.toStringAsFixed(2)}\n'
                    'Low: \$${data.low.toStringAsFixed(2)}\n'
                    'Close: \$${data.close.toStringAsFixed(2)}',
                    TextStyle(
                      color: Theme.of(context).colorScheme.onInverseSurface,
                      fontSize: 12,
                    ),
                  );
                }).toList();
              },
            ),
            handleBuiltInTouches: true,
          ),
        ),
      ),
    );
  }

  Widget _buildVolumeChart() {
    return Container(
      height: 150,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Volume',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: BarChart(
              BarChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: _historicalData.asMap().entries.map((entry) {
                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: (entry.key + 1) * 1000, // Mock volume data
                        color: AppTheme.gold.withOpacity(0.6),
                        width: 8,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTechnicalIndicators() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Technical Indicators',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildIndicator('RSI (14)', '65.4', 'Neutral', Colors.orange),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildIndicator('MACD', 'Bullish', 'Buy', Colors.green),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildIndicator('MA (50)', 'Above', 'Bullish', Colors.green),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildIndicator('BB', 'Middle', 'Hold', Colors.orange),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIndicator(String name, String value, String signal, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              signal,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatistics() {
    if (_historicalData.isEmpty) return const SizedBox.shrink();
    
    final prices = _historicalData.map((e) => e.close).toList();
    final avg = prices.reduce((a, b) => a + b) / prices.length;
    final max = prices.reduce((a, b) => a > b ? a : b);
    final min = prices.reduce((a, b) => a < b ? a : b);
    final volatility = _calculateVolatility(prices);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.gold.withOpacity(0.1),
            Colors.transparent,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.gold.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Statistics',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem('Average', '\$${avg.toStringAsFixed(2)}'),
              ),
              Expanded(
                child: _buildStatItem('Maximum', '\$${max.toStringAsFixed(2)}'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatItem('Minimum', '\$${min.toStringAsFixed(2)}'),
              ),
              Expanded(
                child: _buildStatItem('Volatility', '${volatility.toStringAsFixed(2)}%'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.gold,
          ),
        ),
      ],
    );
  }

  double _calculateVolatility(List<double> prices) {
    if (prices.length < 2) return 0.0;
    
    final returns = <double>[];
    for (int i = 1; i < prices.length; i++) {
      returns.add((prices[i] - prices[i - 1]) / prices[i - 1]);
    }
    
    final mean = returns.reduce((a, b) => a + b) / returns.length;
    final variance = returns.map((r) => (r - mean) * (r - mean)).reduce((a, b) => a + b) / returns.length;
    
    return (variance * 100).isNaN ? 0.0 : (variance * 100);
  }

  void _exportChart() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Chart export feature coming soon!'),
        backgroundColor: AppTheme.gold,
      ),
    );
  }
}
