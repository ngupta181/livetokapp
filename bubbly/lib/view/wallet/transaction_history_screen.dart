import 'package:bubbly/api/api_service.dart';
import 'package:bubbly/custom_view/app_bar_custom.dart';
import 'package:bubbly/custom_view/common_ui.dart';
import 'package:bubbly/custom_view/data_not_found.dart';
import 'package:bubbly/languages/languages_keys.dart';
import 'package:bubbly/modal/wallet/transaction_history.dart';
import 'package:bubbly/utils/assert_image.dart';
import 'package:bubbly/utils/colors.dart';
import 'package:bubbly/utils/const_res.dart';
import 'package:bubbly/utils/font_res.dart';
import 'package:bubbly/utils/session_manager.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class TransactionHistoryScreen extends StatefulWidget {
  final String? transactionType;
  
  const TransactionHistoryScreen({Key? key, this.transactionType}) : super(key: key);
  
  @override
  _TransactionHistoryScreenState createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> with SingleTickerProviderStateMixin {
  List<Transaction>? _transactions;
  bool _isLoading = true;
  bool _isMoreLoading = false;
  int _total = 0;
  int _offset = 0;
  int _limit = 20;
  final _scrollController = ScrollController();
  String? _selectedType;
  late TabController _tabController;
  double _coinValue = 0.001; // Default value
  SessionManager sessionManager = SessionManager();
  
  final Map<String, String> _tabTypes = {
    'all': 'All',
    'gift': 'Gifts',
    'purchase': 'Purchases',
    'redeem': 'Payouts',
    'reward': 'Rewards'
  };
  
  @override
  void initState() {
    super.initState();
    _selectedType = widget.transactionType;
    _tabController = TabController(
      length: _tabTypes.length,
      vsync: this,
      initialIndex: _getInitialTabIndex()
    );
    
    _scrollController.addListener(_scrollListener);
    _loadSettings();
    _loadTransactions();
  }
  
  Future<void> _loadSettings() async {
    await sessionManager.initPref();
    final settingData = sessionManager.getSetting()?.data;
    if (settingData != null && settingData.coinValue != null) {
      setState(() {
        _coinValue = settingData.coinValue!; // Use the direct coin value from settings
        print('Coin value loaded: $_coinValue'); // Debug print to verify value
      });
    }
  }
  
  int _getInitialTabIndex() {
    if (_selectedType == null) return 0;
    
    int index = _tabTypes.keys.toList().indexOf(_selectedType!);
    return index >= 0 ? index : 0;
  }
  
  void _scrollListener() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      _loadMoreTransactions();
    }
  }
  
  Future<void> _loadTransactions() async {
    setState(() {
      _isLoading = true;
      _offset = 0;
      _transactions = [];
    });
    
    try {
      final response = await ApiService().getTransactionHistory(
        transactionType: _selectedType == 'all' ? null : _selectedType,
        limit: _limit,
        offset: _offset,
      );
      
      setState(() {
        _transactions = response.data;
        _total = response.total ?? 0;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      CommonUI.showToast(msg: LKey.somethingWentWrong.tr);
    }
  }
  
  Future<void> _loadMoreTransactions() async {
    if (_isMoreLoading || (_transactions?.length ?? 0) >= _total) return;
    
    setState(() {
      _isMoreLoading = true;
      _offset += _limit;
    });
    
    try {
      final response = await ApiService().getTransactionHistory(
        transactionType: _selectedType == 'all' ? null : _selectedType,
        limit: _limit,
        offset: _offset,
      );
      
      setState(() {
        _transactions?.addAll(response.data ?? []);
        _isMoreLoading = false;
      });
    } catch (e) {
      setState(() {
        _isMoreLoading = false;
      });
    }
  }
  
  @override
  void dispose() {
    _scrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          AppBarCustom(title: LKey.transactionHistory.tr),
          TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: ColorRes.colorPrimary,
            unselectedLabelColor: Colors.grey,
            tabs: _tabTypes.values.map((type) => Tab(text: type)).toList(),
            onTap: (index) {
              setState(() {
                _selectedType = index == 0 ? 'all' : _tabTypes.keys.toList()[index];
              });
              _loadTransactions();
            },
          ),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _transactions?.isEmpty ?? true
                    ? DataNotFound()
                    : RefreshIndicator(
                        onRefresh: _loadTransactions,
                        child: ListView.builder(
                          controller: _scrollController,
                          itemCount: (_transactions?.length ?? 0) + (_isMoreLoading ? 1 : 0),
                          padding: EdgeInsets.all(10),
                          itemBuilder: (context, index) {
                            if (index == _transactions!.length) {
                              return Center(
                                child: Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }
                            
                            return _buildTransactionItem(_transactions![index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTransactionItem(Transaction transaction) {
    print("Transaction: ${transaction.transactionId}, toUserId: ${transaction.toUserId}, userId: ${transaction.userId}, sessionUserId: ${SessionManager.userId}, isIncoming: ${transaction.toUserId.toString() == SessionManager.userId.toString()}");
    final isIncoming = transaction.toUserId.toString() == SessionManager.userId.toString();
    final isSelf = transaction.userId.toString() == SessionManager.userId && transaction.toUserId.toString() == SessionManager.userId;
    final formattedDate = transaction.createdAt != null 
        ? DateFormat('MMM dd, yyyy · hh:mm a').format(DateTime.parse(transaction.createdAt!)) 
        : '';
    
    Widget leadingIcon;
    Color? amountColor;
    String transactionTitle;
    String transactionSubtitle;
    String amount = '';
    
    // Convert coins to USD amount
    final usdAmount = ((transaction.coins ?? 0) * _coinValue).toStringAsFixed(2);
    
    // Format the amount to show both coins and USD
    if (transaction.coins != null && transaction.coins! > 0) {
      amount = '${transaction.coins} Coins (\$${usdAmount})';
    } else if (transaction.amount != null && transaction.amount! > 0) {
      amount = '\$${transaction.amount!.toStringAsFixed(2)}';
    } else {
      amount = '0 Coins (\$0.00)';
    }
    
    // Determine the type of transaction for display
    switch(transaction.transactionType) {
      case 'gift':
        leadingIcon = Icon(Icons.card_giftcard, color: Colors.pink);
        if (isIncoming) {
          transactionTitle = 'Gift Received';
          transactionSubtitle = 'From ${transaction.user?.fullName ?? 'a user'}';
          amountColor = Colors.green;
        } else {
          transactionTitle = 'Gift Sent';
          transactionSubtitle = 'To ${transaction.recipient?.fullName ?? 'a user'}';
          amountColor = Colors.red;
          if (amount.isNotEmpty && !amount.contains('-')) {
            amount = '- $amount';
          }
        }
        break;
        
      case 'purchase':
        leadingIcon = Icon(Icons.shopping_cart, color: Colors.blue);
        transactionTitle = 'Coin Purchase';
        transactionSubtitle = '${transaction.paymentMethod ?? 'Payment'}';
        amountColor = Colors.green;
        break;
        
      case 'redeem':
        // Check status
        bool isPending = transaction.status?.toLowerCase() == 'pending';
        
        if (isPending) {
          // Create a stack with money icon and pending indicator
          leadingIcon = Stack(
            children: [
              Icon(Icons.money, color: Colors.amber),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.hourglass_empty, size: 10, color: Colors.white),
                ),
              ),
            ],
          );
          transactionTitle = 'Payout (Pending)';
        } else {
          leadingIcon = Icon(Icons.money, color: Colors.amber);
          transactionTitle = 'Payout (Confirmed)';
        }
        
        transactionSubtitle = 'Via ${transaction.paymentMethod ?? 'Payment'}';
        amountColor = Colors.red;
        if (amount.isNotEmpty && !amount.contains('-')) {
          amount = '- $amount';
        }
        break;
        
      case 'reward':
        leadingIcon = Icon(Icons.star, color: Colors.amber);
        transactionTitle = 'Reward Earned';
        transactionSubtitle = 'From ${transaction.user?.fullName ?? 'a user'}';
        amountColor = Colors.green;
        break;
        
      default:
        leadingIcon = Icon(Icons.swap_horiz, color: Colors.grey);
        transactionTitle = 'Transfer';
        if (isIncoming) {
          transactionSubtitle = 'From ${transaction.user?.fullName ?? 'a user'}';
          amountColor = Colors.green;
        } else {
          transactionSubtitle = 'To ${transaction.recipient?.fullName ?? 'a user'}';
          amountColor = Colors.red;
          if (amount.isNotEmpty && !amount.contains('-')) {
            amount = '- $amount';
          }
        }
    }
    
    return Card(
      margin: EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.grey.shade200,
          child: leadingIcon,
        ),
        title: Text(
          transactionTitle,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(transactionSubtitle),
            Text(
              formattedDate,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        trailing: Text(
          amount,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: amountColor,
          ),
        ),
      ),
    );
  }
} 