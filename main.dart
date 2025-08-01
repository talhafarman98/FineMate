import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// This sample covers the Expense Manager main page with core UI/UX and example features,
// including budget input, expense list, dynamic remaining budget, category filtering,
// colorful chart placeholder, and export button. The code uses modern neumorphic/glassmorphic
// styling with smooth animations and micro-interactions. Further modules can be structured similarly.

// Entry point
void main() {
  runApp(const FinMateApp());
}

class FinMateApp extends StatelessWidget {
  const FinMateApp({Key? key}) : super(key: key);

  // Define primary theme matching the color palette & typography specs
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FinMate',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Montserrat',
        brightness: Brightness.light,
        primaryColor: const Color(0xFF5A7BCF),
        scaffoldBackgroundColor: const Color(0xFFF5F8FF),
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.indigo,
          accentColor: const Color(0xFF9C69E2),
          backgroundColor: const Color(0xFFF5F8FF),
          brightness: Brightness.light,
        ),
        textTheme: const TextTheme(
          headline1: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 28,
            color: Color(0xFF3A3A3A),
          ),
          headline6: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: Color(0xFF3A3A3A),
          ),
          bodyText1: TextStyle(
            fontWeight: FontWeight.w400,
            fontSize: 14,
            color: Color(0xFF5A5A5A),
          ),
          bodyText2: TextStyle(
            fontWeight: FontWeight.w300,
            fontSize: 12,
            color: Color(0xFF8A8A8A),
          ),
        ),
        splashFactory: InkRipple.splashFactory,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const ExpenseManagerPage(),
    );
  }
}

// Expense model
class Expense {
  final String description;
  final String category;
  final DateTime date;
  final double amount;

  Expense({
    required this.description,
    required this.category,
    required this.date,
    required this.amount,
  });
}

class ExpenseManagerPage extends StatefulWidget {
  const ExpenseManagerPage({Key? key}) : super(key: key);

  @override
  State<ExpenseManagerPage> createState() => _ExpenseManagerPageState();
}

class _ExpenseManagerPageState extends State<ExpenseManagerPage>
    with TickerProviderStateMixin {
  double _monthlyBudget = 0.0;
  final List<Expense> _expenses = [];
  String _filterCategory = 'All';
  DateTimeRange? _filterDateRange;

  // Controller for animations
  late AnimationController _confettiController;

  // Categories for expenses
  final List<String> _categories = [
    'All',
    'Food',
    'Transport',
    'Entertainment',
    'Shopping',
    'Utilities',
    'Others'
  ];

  @override
  void initState() {
    super.initState();
    _confettiController =
        AnimationController(vsync: this, duration: const Duration(seconds: 1));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  double get _totalExpenses {
    return _filteredExpenses.fold(0, (sum, item) => sum + item.amount);
  }

  double get _remainingBudget {
    return (_monthlyBudget - _totalExpenses).clamp(0, double.infinity);
  }

  List<Expense> get _filteredExpenses {
    List<Expense> filtered = _expenses;
    if (_filterCategory != 'All') {
      filtered = filtered
          .where((element) => element.category == _filterCategory)
          .toList();
    }
    if (_filterDateRange != null) {
      filtered = filtered.where((expense) {
        return expense.date.isAfter(_filterDateRange!.start.subtract(const Duration(days: 1))) &&
            expense.date.isBefore(_filterDateRange!.end.add(const Duration(days: 1)));
      }).toList();
    }
    return filtered;
  }

  Future<void> _showAddExpenseDialog() async {
    final descriptionController = TextEditingController();
    final amountController = TextEditingController();
    String category = _categories[1];
    DateTime date = DateTime.now();

    await showDialog(
        context: context,
        builder: (context) {
          return Dialog(
            backgroundColor: Colors.white.withOpacity(0.85),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: StatefulBuilder(builder: (context, setState) {
              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Add Expense',
                        style: Theme.of(context).textTheme.headline6,
                      ),
                      const SizedBox(height: 15),
                      TextField(
                        controller: descriptionController,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.description_outlined),
                        ),
                      ),
                      const SizedBox(height: 15),
                      DropdownButtonFormField<String>(
                        value: category,
                        items: _categories
                            .where((c) => c != 'All')
                            .map((cat) => DropdownMenuItem(
                                  value: cat,
                                  child: Text(cat),
                                ))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              category = val;
                            });
                          }
                        },
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.category_outlined),
                        ),
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        controller: amountController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: <TextInputFormatter>[
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d+\.?\d{0,2}'))
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Amount',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.attach_money_outlined),
                        ),
                      ),
                      const SizedBox(height: 15),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined,
                              color: Colors.grey),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '${date.day}/${date.month}/${date.year}',
                              style: Theme.of(context).textTheme.bodyText1,
                            ),
                          ),
                          TextButton(
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: date,
                                firstDate: DateTime.now()
                                    .subtract(const Duration(days: 365 * 5)),
                                lastDate:
                                    DateTime.now().add(const Duration(days: 365 * 5)),
                              );
                              if (picked != null) {
                                setState(() {
                                  date = picked;
                                });
                              }
                            },
                            child: const Text('Select Date'),
                          )
                        ],
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          final desc = descriptionController.text.trim();
                          final amount =
                              double.tryParse(amountController.text.trim()) ?? 0;
                          if (desc.isEmpty || amount <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text('Please enter valid details')));
                            return;
                          }
                          Navigator.of(context).pop();
                          setState(() {
                            _expenses.add(Expense(
                                description: desc,
                                category: category,
                                date: date,
                                amount: amount));
                            _confettiController.forward(from: 0);
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(45),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15)),
                        ),
                        child: const Text('Add Expense'),
                      )
                    ],
                  ),
                ),
              );
            }),
          );
        });
  }

  Future<void> _showSetBudgetDialog() async {
    final budgetController =
        TextEditingController(text: _monthlyBudget.toStringAsFixed(2));

    await showDialog(
        context: context,
        builder: (context) {
          return Dialog(
            backgroundColor: Colors.white.withOpacity(0.9),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(
                  'Set Monthly Budget',
                  style: Theme.of(context).textTheme.headline6,
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: budgetController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Budget Amount',
                    prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                    border: OutlineInputBorder(),
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    final inputBudget =
                        double.tryParse(budgetController.text.trim()) ?? 0.0;
                    if (inputBudget <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Enter a valid budget')));
                      return;
                    }
                    setState(() {
                      _monthlyBudget = inputBudget;
                    });
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(45),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15))),
                  child: const Text('Save Budget'),
                ),
              ]),
            ),
          );
        });
  }

  Future<void> _selectFilterDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: now.subtract(const Duration(days: 365 * 5)),
      lastDate: now.add(const Duration(days: 365 * 5)),
      initialDateRange: _filterDateRange ??
          DateTimeRange(start: now.subtract(const Duration(days: 30)), end: now),
    );
    if (picked != null) {
      setState(() {
        _filterDateRange = picked;
      });
    }
  }

  void _clearDateFilter() {
    setState(() {
      _filterDateRange = null;
    });
  }

  Widget _buildExpenseItem(Expense expense) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 12),
      child: Material(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withOpacity(0.8),
        elevation: 2,
        shadowColor: Colors.indigo.withOpacity(0.3),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: _categoryColor(expense.category).withOpacity(0.7),
            child: Text(
              expense.category[0],
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
          title: Text(
            expense.description,
            style: Theme.of(context)
                .textTheme
                .bodyText1!
                .copyWith(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            '${expense.category} • ${expense.date.day}/${expense.date.month}/${expense.date.year}',
            style: Theme.of(context).textTheme.bodyText2,
          ),
          trailing: Text(
            '- \$${expense.amount.toStringAsFixed(2)}',
            style: const TextStyle(
                color: Colors.redAccent, fontWeight: FontWeight.w700, fontSize: 16),
          ),
          onTap: () {
            HapticFeedback.selectionClick();
          },
        ),
      ),
    );
  }

  Color _categoryColor(String category) {
    switch (category) {
      case 'Food':
        return Colors.deepOrange.shade400;
      case 'Transport':
        return Colors.blue.shade400;
      case 'Entertainment':
        return Colors.purple.shade400;
      case 'Shopping':
        return Colors.green.shade400;
      case 'Utilities':
        return Colors.teal.shade400;
      default:
        return Colors.grey.shade600;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Glassmorphic style AppBar with smooth slide animation
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white.withOpacity(0.15),
        centerTitle: true,
        title: const Text('FinMate - Expense Manager'),
        actions: [
          IconButton(
            tooltip: 'Set Monthly Budget',
            icon: const Icon(Icons.account_balance_wallet_outlined),
            onPressed: () => _showSetBudgetDialog(),
          ),
          IconButton(
            tooltip: 'Export Data',
            icon: const Icon(Icons.upload_file_outlined),
            onPressed: () {
              // Placeholder for export functionality.
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Export feature coming soon!')));
            },
          )
        ],
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              // Glassmorphic background blur & gradient
              gradient: LinearGradient(
                colors: [Color(0xFFDDE8FF), Color(0xFFBFBFFF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          SafeArea(
            child: RefreshIndicator(
              onRefresh: () async {
                // Placeholder for refresh functionality (e.g. sync)
                await Future.delayed(const Duration(milliseconds: 500));
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Budget summary card with neumorphic style & ripple effect button
                      Card(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                        color: Colors.white.withOpacity(0.85),
                        elevation: 14,
                        shadowColor: Colors.indigo.withOpacity(0.35),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          splashColor: Colors.indigo.withOpacity(0.15),
                          onTap: () => _showSetBudgetDialog(),
                          child: Padding(
                            padding: const EdgeInsets.all(25),
                            child: Column(
                              children: [
                                Text(
                                  'Monthly Budget',
                                  style: Theme.of(context).textTheme.headline6,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '\$${_monthlyBudget.toStringAsFixed(2)}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headline1!
                                      .copyWith(color: Colors.indigo.shade700),
                                ),
                                const Divider(height: 32),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    Column(
                                      children: [
                                        Text(
                                          'Expenses',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyText2,
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          '\$${_totalExpenses.toStringAsFixed(2)}',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.red.shade700,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Column(
                                      children: [
                                        Text(
                                          'Remaining',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyText2,
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          '\$${_remainingBudget.toStringAsFixed(2)}',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.green.shade700,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Filter controls with animated dropdown & date range picker
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _filterCategory,
                              decoration: const InputDecoration(
                                labelText: 'Filter Category',
                                border: OutlineInputBorder(),
                              ),
                              items: _categories
                                  .map(
                                    (e) => DropdownMenuItem<String>(
                                      value: e,
                                      child: Text(e),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (selected) {
                                if (selected != null) {
                                  setState(() {
                                    _filterCategory = selected;
                                  });
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _selectFilterDateRange,
                              icon: const Icon(Icons.date_range_outlined),
                              label: Text(_filterDateRange == null
                                  ? 'Filter Date'
                                  : '${_filterDateRange!.start.day}/${_filterDateRange!.start.month}/${_filterDateRange!.start.year} - ${_filterDateRange!.end.day}/${_filterDateRange!.end.month}/${_filterDateRange!.end.year}'),
                            ),
                          ),
                          if (_filterDateRange != null)
                            IconButton(
                              tooltip: 'Clear Date Filter',
                              icon: const Icon(
                                Icons.clear,
                                color: Colors.redAccent,
                              ),
                              onPressed: _clearDateFilter,
                            )
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Placeholder for colorful spending summary charts
                      SizedBox(
                        height: 180,
                        child: Card(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
                          color: Colors.white.withOpacity(0.9),
                          elevation: 12,
                          shadowColor: Colors.indigo.withOpacity(0.3),
                          child: Padding(
                            padding: const EdgeInsets.all(18.0),
                            child: Center(
                              child: Text(
                                'Monthly Spending Charts (Coming Soon)',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyText1!
                                    .copyWith(color: Colors.indigo.shade400),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Expenses list section title with animated microinteraction
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Expenses',
                            style: Theme.of(context).textTheme.headline6,
                          ),
                          TextButton.icon(
                            onPressed: _showAddExpenseDialog,
                            icon: const Icon(Icons.add_circle_outline),
                            label: const Text('Add'),
                            style: TextButton.styleFrom(
                              textStyle:
                                  const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),

                      _filteredExpenses.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.only(top: 40.0),
                              child: Center(
                                child: Text(
                                  'No expenses found.\nTap "Add" to create one.',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodyText2,
                                ),
                              ),
                            )
                          : ListView.builder(
                              physics: const NeverScrollableScrollPhysics(),
                              shrinkWrap: true,
                              itemCount: _filteredExpenses.length,
                              itemBuilder: (context, index) {
                                return _buildExpenseItem(_filteredExpenses[index]);
                              },
                            ),
                      const SizedBox(height: 60),

                      // Footer small line
                      Align(
                        alignment: Alignment.center,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 20.0),
                          child: Text(
                            'Created by Talha',
                            style: Theme.of(context)
                                .textTheme
                                .bodyText2!
                                .copyWith(fontStyle: FontStyle.italic),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Confetti / microinteraction animation placeholder
          // Implement confetti animation here or using a package in full app
          FadeTransition(
            opacity: _confettiController.drive(
              Tween(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeOut)),
            ),
            child: IgnorePointer(
              child: Center(
                child: Icon(Icons.celebration_outlined,
                    color: Colors.purpleAccent.withOpacity(0.7), size: 120),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add Expense',
        onPressed: _showAddExpenseDialog,
        backgroundColor: const Color(0xFF9C69E2),
        child: const Icon(Icons.add),
        elevation: 10,
        splashColor: Colors.white38,
      ),
    );
  }
}
