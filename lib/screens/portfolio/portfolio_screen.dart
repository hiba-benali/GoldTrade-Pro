import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../services/gold_service.dart';
import '../../services/supabase_service.dart';

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  List<Map<String, dynamic>> _portfolio = [];
  GoldPrice? _currentGoldPrice;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadPortfolioData();
  }

  Future<void> _loadPortfolioData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Load portfolio items
      final portfolio = await SupabaseService.getUserPortfolio();
      
      // Load current gold price
      final goldPrice = await GoldService.getCurrentGoldPrice();

      setState(() {
        _portfolio = portfolio;
        _currentGoldPrice = goldPrice;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load portfolio: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  double _calculateTotalValue() {
    if (_currentGoldPrice == null) return 0.0;
    
    double totalValue = 0.0;
    for (final item in _portfolio) {
      final weight = (item['weight'] ?? 0.0).toDouble();
      totalValue += weight * _currentGoldPrice!.price / 31.1035; // Convert to USD per gram
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

  double _calculateTotalProfitLoss() {
    if (_currentGoldPrice == null) return 0.0;
    
    double profitLoss = 0.0;
    for (final item in _portfolio) {
      final weight = (item['weight'] ?? 0.0).toDouble();
      final purchasePrice = (item['purchase_price'] ?? 0.0).toDouble();
      final currentValue = weight * _currentGoldPrice!.price / 31.1035;
      profitLoss += currentValue - purchasePrice;
    }
    return profitLoss;
  }

  double _calculateZakat() {
    final totalValue = _calculateTotalValue();
    return totalValue * AppConstants.zakatRate;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Portfolio',
          style: TextStyle(
            color: AppTheme.gold,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.plus),
            onPressed: _showAddGoldDialog,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadPortfolioData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Portfolio Summary Cards
              _buildPortfolioSummary(),
              const SizedBox(height: 24),
              
              // Zakat Calculator
              _buildZakatCalculator(),
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
              
              // Portfolio Items
              else ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Gold Holdings (${_portfolio.length})',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_portfolio.isNotEmpty)
                      TextButton.icon(
                        onPressed: _showSortOptions,
                        icon: const Icon(LucideIcons.arrowUpDown, size: 16),
                        label: const Text('Sort'),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                
                if (_portfolio.isEmpty)
                  _buildEmptyPortfolio()
                else
                  ..._portfolio.map((item) => _buildPortfolioItem(item)).toList(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPortfolioSummary() {
    final totalValue = _calculateTotalValue();
    final totalWeight = _calculateTotalWeight();
    final profitLoss = _calculateTotalProfitLoss();
    final profitLossPercent = totalValue > 0 ? (profitLoss / totalValue) * 100 : 0.0;
    
    return Column(
      children: [
        // Main Summary Card
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: AppTheme.premiumGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      LucideIcons.briefcase,
                      color: AppTheme.black,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Portfolio Value',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                          ),
                        ),
                        Text(
                          '\$${totalValue.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.displayMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.gold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSummaryItem(
                    'Total Weight',
                    '${totalWeight.toStringAsFixed(2)}g',
                    LucideIcons.scale,
                  ),
                  _buildSummaryItem(
                    'P&L',
                    '${profitLoss >= 0 ? '+' : ''}\$${profitLoss.abs().toStringAsFixed(2)}',
                    LucideIcons.trendingUp,
                    profitLoss >= 0 ? Colors.green : Colors.red,
                  ),
                  _buildSummaryItem(
                    'Return',
                    '${profitLossPercent >= 0 ? '+' : ''}${profitLossPercent.toStringAsFixed(2)}%',
                    LucideIcons.percent,
                    profitLossPercent >= 0 ? Colors.green : Colors.red,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon, [Color? color]) {
    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: color ?? AppTheme.gold,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color ?? AppTheme.gold,
          ),
        ),
      ],
    );
  }

  Widget _buildZakatCalculator() {
    final totalValue = _calculateTotalValue();
    final zakatAmount = _calculateZakat();
    final isAboveNisab = totalValue >= (AppConstants.nisabThreshold * (_currentGoldPrice?.price ?? 0));
    
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  LucideIcons.calculator,
                  color: Colors.green,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Zakat Calculator',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Zakat Details
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Gold Value',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      '\$${totalValue.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Zakat Rate (${(AppConstants.zakatRate * 100).toStringAsFixed(1)}%)',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      '\$${zakatAmount.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Nisab Status',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isAboveNisab ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isAboveNisab ? 'Above Nisab' : 'Below Nisab',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isAboveNisab ? Colors.green : Colors.orange,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Zakat Info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(
                  LucideIcons.info,
                  size: 16,
                  color: Colors.blue,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Zakat is payable on gold above the nisab threshold (${AppConstants.nisabThreshold}g) held for one lunar year.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.blue,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyPortfolio() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.gold.withOpacity(0.1),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Icon(
              LucideIcons.inbox,
              size: 48,
              color: AppTheme.gold,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No Gold Holdings Yet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start building your gold portfolio by adding your first gold item.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showAddGoldDialog,
            icon: const Icon(LucideIcons.plus),
            label: const Text('Add Gold Item'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.gold,
              foregroundColor: AppTheme.black,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPortfolioItem(Map<String, dynamic> item) {
    final weight = (item['weight'] ?? 0.0).toDouble();
    final purchasePrice = (item['purchase_price'] ?? 0.0).toDouble();
    final currentValue = _currentGoldPrice != null 
        ? weight * _currentGoldPrice!.price / 31.1035 
        : purchasePrice;
    final profitLoss = currentValue - purchasePrice;
    final profitLossPercent = purchasePrice > 0 ? (profitLoss / purchasePrice) * 100 : 0.0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['name'] ?? 'Unknown',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.gold.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            item['type'] ?? 'Other',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.gold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${weight.toStringAsFixed(2)}g',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton(
                icon: const Icon(LucideIcons.moreVertical),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    onTap: () => _editGoldItem(item),
                    child: const Row(
                      children: [
                        Icon(LucideIcons.edit, size: 16),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    onTap: () => _deleteGoldItem(item['id']),
                    child: const Row(
                      children: [
                        Icon(LucideIcons.trash2, size: 16, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Value',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  Text(
                    '\$${currentValue.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
                    'P&L',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  Row(
                    children: [
                      Icon(
                        profitLoss >= 0 ? LucideIcons.trendingUp : LucideIcons.trendingDown,
                        size: 16,
                        color: profitLoss >= 0 ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${profitLoss >= 0 ? '+' : ''}\$${profitLoss.abs().toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: profitLoss >= 0 ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${profitLossPercent >= 0 ? '+' : ''}${profitLossPercent.toStringAsFixed(2)}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: profitLoss >= 0 ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Purchased: ${DateFormat('MMM dd, yyyy').format(DateTime.parse(item['purchase_date']))}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddGoldDialog() {
    showDialog(
      context: context,
      builder: (context) => AddGoldDialog(
        onAdd: (goldData) async {
          try {
            await SupabaseService.addGoldToPortfolio(
  name: goldData['name'],
  type: goldData['type'],
  weight: goldData['weight'],
  purchasePrice: goldData['purchase_price'],
  purchaseDate: goldData['purchase_date'],
);
            _loadPortfolioData();
            if (mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Gold item added successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error adding gold: ${e.toString()}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }

  void _editGoldItem(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (context) => AddGoldDialog(
        goldData: item,
        onAdd: (goldData) async {
          try {
            await SupabaseService.updatePortfolioItem(item['id'], goldData);
            _loadPortfolioData();
            if (mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Gold item updated successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error updating gold: ${e.toString()}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }

  void _deleteGoldItem(String itemId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Gold Item'),
        content: const Text('Are you sure you want to delete this gold item from your portfolio?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await SupabaseService.deletePortfolioItem(itemId);
                _loadPortfolioData();
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Gold item deleted successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting gold: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showSortOptions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sort Portfolio'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('By Name'),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _portfolio.sort((a, b) => (a['name'] ?? '').compareTo(b['name'] ?? ''));
                });
              },
            ),
            ListTile(
              title: const Text('By Weight'),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _portfolio.sort((a, b) => (b['weight'] ?? 0.0).compareTo(a['weight'] ?? 0.0));
                });
              },
            ),
            ListTile(
              title: const Text('By Value'),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _portfolio.sort((a, b) => (b['purchase_price'] ?? 0.0).compareTo(a['purchase_price'] ?? 0.0));
                });
              },
            ),
            ListTile(
              title: const Text('By Date'),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _portfolio.sort((a, b) => DateTime.parse(b['purchase_date']).compareTo(DateTime.parse(a['purchase_date'])));
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}

class AddGoldDialog extends StatefulWidget {
  final Map<String, dynamic>? goldData;
  final Function(Map<String, dynamic>) onAdd;

  const AddGoldDialog({
    super.key,
    this.goldData,
    required this.onAdd,
  });

  @override
  State<AddGoldDialog> createState() => _AddGoldDialogState();
}

class _AddGoldDialogState extends State<AddGoldDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _weightController = TextEditingController();
  final _purchasePriceController = TextEditingController();
  final _purchaseDateController = TextEditingController();
  String _selectedType = 'coins';

  final List<String> _goldTypes = ['coins', 'bars', 'jewelry'];

  @override
  void initState() {
    super.initState();
    if (widget.goldData != null) {
      _nameController.text = widget.goldData!['name'] ?? '';
      _weightController.text = widget.goldData!['weight']?.toString() ?? '';
      _purchasePriceController.text = widget.goldData!['purchase_price']?.toString() ?? '';
      _purchaseDateController.text = widget.goldData!['purchase_date'] ?? '';
      _selectedType = widget.goldData!['type'] ?? 'coins';
    } else {
      _purchaseDateController.text = DateTime.now().toIso8601String().split('T')[0];
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _weightController.dispose();
    _purchasePriceController.dispose();
    _purchaseDateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.goldData == null ? 'Add Gold Item' : 'Edit Gold Item'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Item Name',
                  hintText: 'e.g., Gold Coin 1oz',
                  prefixIcon: Icon(LucideIcons.tag),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter item name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Gold Type',
                  prefixIcon: Icon(LucideIcons.layers),
                ),
                items: _goldTypes.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.capitalize()),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedType = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _weightController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Weight (grams)',
                  hintText: 'e.g., 31.1035',
                  prefixIcon: Icon(LucideIcons.scale),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter weight';
                  }
                  if (double.tryParse(value) == null || double.parse(value) <= 0) {
                    return 'Please enter a valid weight';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _purchasePriceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Purchase Price (\$)',
                  hintText: 'e.g., 2350.00',
                  prefixIcon: Icon(LucideIcons.dollarSign),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter purchase price';
                  }
                  if (double.tryParse(value) == null || double.parse(value) <= 0) {
                    return 'Please enter a valid price';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _purchaseDateController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Purchase Date',
                  hintText: 'Select purchase date',
                  prefixIcon: Icon(LucideIcons.calendar),
                ),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.tryParse(_purchaseDateController.text) ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    _purchaseDateController.text = date.toIso8601String().split('T')[0];
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select purchase date';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final goldData = {
                'name': _nameController.text.trim(),
                'weight': double.parse(_weightController.text),
                'purchase_price': double.parse(_purchasePriceController.text),
                'purchase_date': _purchaseDateController.text,
                'type': _selectedType,
              };
              widget.onAdd(goldData);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.gold,
            foregroundColor: AppTheme.black,
          ),
          child: Text(widget.goldData == null ? 'Add' : 'Update'),
        ),
      ],
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}
