import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../config/theme.dart';
import '../../services/gemini_service.dart';
import '../../services/gold_service.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<ChatMessage> _messages = <ChatMessage>[];
  bool _isLoading = false;
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    GeminiService.initialize();
    _loadChatHistory();
    _sendWelcomeMessage();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _loadChatHistory() {
    setState(() {
      _messages = GeminiService.getChatHistory();
    });
  }

  void _sendWelcomeMessage() {
    final welcomeMessage = ChatMessage(
      message: '''Welcome to GoldTrade Pro AI Assistant! I'm here to help you with:

*Gold Market Analysis*
- Real-time price trends and patterns
- Market drivers and economic factors
- Technical analysis insights

*Investment Guidance*
- Portfolio diversification strategies
- Risk management approaches
- Islamic finance principles

*Educational Support*
- Gold trading concepts explained
- Zakat calculations
- Market terminology

Feel free to ask me anything about gold trading and investment!''',
      isUser: false,
      timestamp: DateTime.now(),
    );
    
    setState(() {
      _messages.add(welcomeMessage);
    });
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    // Add user message
    final userMessage = ChatMessage(
      message: message,
      isUser: true,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMessage);
      _isLoading = true;
      _isTyping = true;
    });

    _messageController.clear();
    _scrollToBottom();

    try {
      // Get AI response
      final response = await GeminiService.sendMessage(message);
      
      setState(() {
        _isLoading = false;
        _isTyping = false;
      });
      
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isTyping = false;
      });
      
      _showErrorMessage('Failed to get AI response: ${e.toString()}');
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
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
                LucideIcons.bot,
                color: AppTheme.black,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'AI Gold Advisor',
              style: TextStyle(
                color: AppTheme.gold,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.trash2),
            onPressed: _clearChat,
          ),
          IconButton(
            icon: const Icon(LucideIcons.info),
            onPressed: _showInfoDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Quick Actions
          _buildQuickActions(),
          
          // Messages List
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState()
                : _buildMessagesList(),
          ),
          
          // Typing Indicator
          if (_isTyping) _buildTypingIndicator(),
          
          // Message Input
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Questions',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildQuickActionChip('Market Analysis', _askMarketAnalysis),
                _buildQuickActionChip('Investment Tips', _askInvestmentTips),
                _buildQuickActionChip('Zakat Calculator', _askZakatCalculation),
                _buildQuickActionChip('Risk Analysis', _askRiskAnalysis),
                _buildQuickActionChip('Gold Basics', _askGoldBasics),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionChip(String label, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: ActionChip(
        label: Text(label),
        onPressed: onTap,
        backgroundColor: AppTheme.gold.withOpacity(0.2),
        side: BorderSide(color: AppTheme.gold.withOpacity(0.3)),
        labelStyle: TextStyle(
          color: AppTheme.gold,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              gradient: AppTheme.premiumGradient,
              borderRadius: BorderRadius.circular(40),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.gold.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(
              LucideIcons.messageSquare,
              size: 60,
              color: AppTheme.black,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'AI Gold Assistant',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.gold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Ask me anything about gold trading,\ninvestment strategies, and market analysis.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildFeatureCard('Market Insights', LucideIcons.trendingUp),
              _buildFeatureCard('Investment Advice', LucideIcons.lightbulb),
              _buildFeatureCard('Risk Analysis', LucideIcons.shield),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(String title, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.gold.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.gold.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 24,
            color: AppTheme.gold,
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.gold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        return _buildMessageBubble(message);
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.isUser;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: AppTheme.premiumGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                LucideIcons.bot,
                color: AppTheme.black,
                size: 20,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isUser 
                    ? AppTheme.gold.withOpacity(0.9)
                    : Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: isUser 
                    ? null 
                    : Border.all(
                        color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                      ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.message,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isUser ? AppTheme.black : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.timestamp),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isUser 
                          ? AppTheme.black.withOpacity(0.7)
                          : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.gold.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                LucideIcons.user,
                color: AppTheme.gold,
                size: 20,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: AppTheme.premiumGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              LucideIcons.bot,
              color: AppTheme.black,
              size: 20,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                _buildTypingDot(0),
                const SizedBox(width: 4),
                _buildTypingDot(1),
                const SizedBox(width: 4),
                _buildTypingDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingDot(int index) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 400 + (index * 200)),
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: AppTheme.gold,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Ask about gold trading...',
                prefixIcon: const Icon(LucideIcons.messageCircle),
                suffixIcon: IconButton(
                  icon: const Icon(LucideIcons.mic),
                  onPressed: _voiceInput,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(
                    color: AppTheme.gold.withOpacity(0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: AppTheme.gold, width: 2),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 12),
          FloatingActionButton(
            onPressed: _isLoading ? null : _sendMessage,
            backgroundColor: AppTheme.gold,
            foregroundColor: AppTheme.black,
            mini: true,
            child: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.black,
                    ),
                  )
                : const Icon(LucideIcons.send),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  void _clearChat() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Chat History'),
        content: const Text('Are you sure you want to clear all chat history?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              GeminiService.clearChatHistory();
              setState(() {
                _messages.clear();
              });
              _sendWelcomeMessage();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('AI Gold Advisor'),
        content: const SingleChildScrollView(
          child: Text(
            '''About AI Gold Advisor:

This AI assistant is powered by Google's Gemini AI and provides expert guidance on gold trading and investment.

Capabilities:
* Real-time market analysis and insights
* Investment strategy recommendations
* Risk assessment and management
* Islamic finance guidance (including zakat)
* Educational content on gold trading

Important Notes:
* This is for informational purposes only
* Not financial advice - consult professionals
* Market data may have delays
* Always do your own research

Privacy:
* Chat history is stored locally
* No personal financial data is shared
* Anonymous usage analytics may be collected

For the best experience, be specific with your questions and provide context about your investment goals and risk tolerance.''',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _voiceInput() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Voice input feature coming soon!'),
        backgroundColor: AppTheme.gold,
      ),
    );
  }

  // Quick action methods
  void _askMarketAnalysis() {
    _messageController.text = 'What is the current gold market analysis?';
    _sendMessage();
  }

  void _askInvestmentTips() {
    _messageController.text = 'What are your top investment tips for gold beginners?';
    _sendMessage();
  }

  void _askZakatCalculation() {
    _messageController.text = 'How do I calculate zakat on my gold investments?';
    _sendMessage();
  }

  void _askRiskAnalysis() {
    _messageController.text = 'What are the main risks in gold trading?';
    _sendMessage();
  }

  void _askGoldBasics() {
    _messageController.text = 'Explain the basics of gold trading for beginners';
    _sendMessage();
  }
}
