import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const SalaryCounterApp());
}

class SalaryCounterApp extends StatelessWidget {
  const SalaryCounterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Salary Counter',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF080B18),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00E5FF),
          brightness: Brightness.dark,
        ),
        fontFamily: 'Roboto',
      ),
      home: const SalaryHomePage(),
    );
  }
}

class SalaryHomePage extends StatefulWidget {
  const SalaryHomePage({super.key});

  @override
  State<SalaryHomePage> createState() => _SalaryHomePageState();
}

class _SalaryHomePageState extends State<SalaryHomePage>
    with SingleTickerProviderStateMixin {
  final _baseController = TextEditingController();
  final _residentController = TextEditingController();
  final _travelController = TextEditingController();
  final _medicalController = TextEditingController();
  final _taxController = TextEditingController();
  final _otherController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  double baseSalary = 50000;
  double residentAllowance = 5000;
  double travelAllowance = 3000;
  double medicalAllowance = 2000;
  double taxValue = 5000;
  double otherDeduction = 0;

  bool taxIsPercentage = false;

  double animatedNetSalary = 0;

  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _syncControllers();
    _calculate();
  }

  @override
  void dispose() {
    _animationController.dispose();

    _baseController.dispose();
    _residentController.dispose();
    _travelController.dispose();
    _medicalController.dispose();
    _taxController.dispose();
    _otherController.dispose();

    super.dispose();
  }

  void _syncControllers() {
    _baseController.text = baseSalary.toStringAsFixed(0);
    _residentController.text = residentAllowance.toStringAsFixed(0);
    _travelController.text = travelAllowance.toStringAsFixed(0);
    _medicalController.text = medicalAllowance.toStringAsFixed(0);
    _taxController.text = taxValue.toStringAsFixed(0);
    _otherController.text = otherDeduction.toStringAsFixed(0);
  }

  double get grossSalary =>
      baseSalary + residentAllowance + travelAllowance + medicalAllowance;

  double get taxAmount {
    if (taxIsPercentage) {
      return grossSalary * (taxValue / 100);
    }
    return taxValue;
  }

  double get totalDeductions => taxAmount + otherDeduction;

  double get netSalary {
    final value = grossSalary - totalDeductions;
    return value < 0 ? 0 : value;
  }

  void _calculate() {
    final oldValue = animatedNetSalary;
    final newValue = netSalary;

    _animationController.reset();

    final animation = Tween<double>(begin: oldValue, end: newValue).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    animation.addListener(() {
      if (mounted) {
        setState(() {
          animatedNetSalary = animation.value;
        });
      }
    });

    _animationController.forward();
  }

  void _updateValue({
    required TextEditingController controller,
    required void Function(double) onChanged,
  }) {
    final value = double.tryParse(controller.text.trim());

    if (value == null || value < 0) {
      onChanged(0);
    } else {
      onChanged(value);
    }

    _calculate();
  }

  void _reset() {
    setState(() {
      baseSalary = 50000;
      residentAllowance = 5000;
      travelAllowance = 3000;
      medicalAllowance = 2000;
      taxValue = 5000;
      otherDeduction = 0;
      taxIsPercentage = false;

      _syncControllers();
    });

    _calculate();
  }

  void _addToBase(double amount) {
    setState(() {
      baseSalary += amount;
      _baseController.text = baseSalary.toStringAsFixed(0);
    });

    _calculate();
  }

  void _openInputSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return _InputBottomSheet(
          formKey: _formKey,
          baseController: _baseController,
          residentController: _residentController,
          travelController: _travelController,
          medicalController: _medicalController,
          taxController: _taxController,
          otherController: _otherController,
          taxIsPercentage: taxIsPercentage,
          onTaxModeChanged: (value) {
            setState(() {
              taxIsPercentage = value;
            });
            _calculate();
          },
          onChanged: () {
            setState(() {
              baseSalary = double.tryParse(_baseController.text) ?? 0;
              residentAllowance =
                  double.tryParse(_residentController.text) ?? 0;
              travelAllowance = double.tryParse(_travelController.text) ?? 0;
              medicalAllowance = double.tryParse(_medicalController.text) ?? 0;
              taxValue = double.tryParse(_taxController.text) ?? 0;
              otherDeduction = double.tryParse(_otherController.text) ?? 0;
            });

            _calculate();
          },
          onClose: () => Navigator.pop(context),
        );
      },
    );
  }

  Future<void> _shareSummary() async {
    final summary =
        '''
SALARY COUNTER & PAYROLL SUMMARY
──────────────────────────────

Base Salary:       ${_money(baseSalary)}
Resident Allowance:${_money(residentAllowance)}
Travel Allowance:  ${_money(travelAllowance)}
Medical Allowance: ${_money(medicalAllowance)}

Gross Earnings:    ${_money(grossSalary)}

Tax Deduction:     ${_money(taxAmount)}
Other Deductions:  ${_money(otherDeduction)}

Total Deductions:  ${_money(totalDeductions)}

NET PAYABLE:       ${_money(netSalary)}

Generated by Salary Counter
''';
  }

  String _money(double value) {
    return 'Rs. ${value.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isTablet = width >= 700;

    return Scaffold(
      body: Stack(
        children: [
          const _BackgroundGlow(),

          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 60 : 20,
                vertical: 20,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 24),

                      _buildNetSalaryCard(),

                      const SizedBox(height: 18),

                      if (isTablet)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildBreakdownCard()),
                            const SizedBox(width: 18),
                            Expanded(child: _buildQuickInputCard()),
                          ],
                        )
                      else
                        Column(
                          children: [
                            _buildBreakdownCard(),
                            const SizedBox(height: 18),
                            _buildQuickInputCard(),
                          ],
                        ),

                      const SizedBox(height: 18),

                      _buildActionButtons(),

                      const SizedBox(height: 30),

                      Center(
                        child: Text(
                          'Salary Counter • Payroll Calculator',
                          style: TextStyle(
                            color: Colors.white.withOpacity(.35),
                            fontSize: 12,
                            letterSpacing: .8,
                          ),
                        ),
                      ),

                      const SizedBox(height: 15),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openInputSheet,
        backgroundColor: const Color(0xFF00D9FF),
        foregroundColor: Colors.black,
        icon: const Icon(Icons.edit_rounded),
        label: const Text(
          'Edit Salary',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          height: 52,
          width: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [Color(0xFF00E5FF), Color(0xFF7C4DFF)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00E5FF).withOpacity(.25),
                blurRadius: 25,
              ),
            ],
          ),
          child: const Icon(
            Icons.account_balance_wallet_rounded,
            color: Colors.white,
            size: 27,
          ),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Salary Counter',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.5,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Smart Payroll Calculator',
                style: TextStyle(color: Colors.white54, fontSize: 13),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Reset',
          onPressed: _reset,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
    );
  }

  Widget _buildNetSalaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF171B3D), Color(0xFF101A2F)],
        ),
        border: Border.all(color: const Color(0xFF00E5FF).withOpacity(.25)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00E5FF).withOpacity(.08),
            blurRadius: 35,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF00E5FF).withOpacity(.1),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.auto_graph_rounded,
                      size: 15,
                      color: Color(0xFF00E5FF),
                    ),
                    SizedBox(width: 6),
                    Text(
                      'CURRENT NET PAY',
                      style: TextStyle(
                        color: Color(0xFF00E5FF),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: animatedNetSalary),
            duration: const Duration(milliseconds: 300),
            builder: (_, value, __) {
              return FittedBox(
                alignment: Alignment.centerLeft,
                fit: BoxFit.scaleDown,
                child: Text(
                  _money(value),
                  style: const TextStyle(
                    fontSize: 46,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -2,
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 8),

          Text(
            'After taxes and deductions',
            style: TextStyle(color: Colors.white.withOpacity(.5), fontSize: 13),
          ),

          const SizedBox(height: 22),

          Row(
            children: [
              Expanded(
                child: _miniStat(
                  'Gross',
                  _money(grossSalary),
                  Icons.trending_up_rounded,
                  const Color(0xFF00E5FF),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _miniStat(
                  'Deductions',
                  _money(totalDeductions),
                  Icons.trending_down_rounded,
                  const Color(0xFFFF6B9D),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.035),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(.07)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  alignment: Alignment.centerLeft,
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
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

  Widget _buildBreakdownCard() {
    final total = grossSalary + totalDeductions;

    final basePercent = total == 0 ? 0.0 : baseSalary / total;
    final allowancePercent = total == 0
        ? 0.0
        : (residentAllowance + travelAllowance + medicalAllowance) / total;
    final deductionPercent = total == 0 ? 0.0 : totalDeductions / total;

    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Salary Breakdown',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          const Text(
            'Understand where your salary goes',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),

          const SizedBox(height: 24),

          _progressRow(
            'Base Salary',
            baseSalary,
            basePercent,
            const Color(0xFF00E5FF),
          ),

          _progressRow(
            'Allowances',
            residentAllowance + travelAllowance + medicalAllowance,
            allowancePercent,
            const Color(0xFF7C4DFF),
          ),

          _progressRow(
            'Deductions',
            totalDeductions,
            deductionPercent,
            const Color(0xFFFF5C8A),
          ),

          const SizedBox(height: 14),

          const Divider(color: Colors.white10),

          const SizedBox(height: 12),

          _breakdownLine(
            Icons.payments_rounded,
            'Base Salary',
            _money(baseSalary),
          ),
          _breakdownLine(
            Icons.home_work_rounded,
            'Resident Allowance',
            _money(residentAllowance),
          ),
          _breakdownLine(
            Icons.directions_car_rounded,
            'Travel Allowance',
            _money(travelAllowance),
          ),
          _breakdownLine(
            Icons.medical_services_rounded,
            'Medical Allowance',
            _money(medicalAllowance),
          ),
          _breakdownLine(
            Icons.receipt_long_rounded,
            'Tax',
            _money(taxAmount),
            negative: true,
          ),
          _breakdownLine(
            Icons.remove_circle_outline_rounded,
            'Other Deductions',
            _money(otherDeduction),
            negative: true,
          ),
        ],
      ),
    );
  }

  Widget _progressRow(String title, double value, double percent, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 17),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
              const Spacer(),
              Text(
                '${(percent * 100).toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: percent.clamp(0, 1),
              minHeight: 7,
              backgroundColor: Colors.white.withOpacity(.06),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _breakdownLine(
    IconData icon,
    String title,
    String value, {
    bool negative = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: negative ? const Color(0xFFFF6B9D) : Colors.white54,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
          Text(
            negative ? '- $value' : value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: negative ? const Color(0xFFFF6B9D) : Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickInputCard() {
    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Base Pay',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          const Text(
            'Tap a preset or enter your own salary',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),

          const SizedBox(height: 20),

          TextField(
            controller: _baseController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (_) {
              _updateValue(
                controller: _baseController,
                onChanged: (value) {
                  baseSalary = value;
                },
              );
              setState(() {});
            },
            decoration: _inputDecoration(
              'Base Salary',
              Icons.account_balance_wallet_rounded,
              prefix: 'Rs. ',
            ),
          ),

          const SizedBox(height: 16),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _presetButton('+ 5K', 5000),
              _presetButton('+ 10K', 10000),
              _presetButton('+ 50K', 50000),
              _presetButton('Reset', -baseSalary + 50000),
            ],
          ),

          const SizedBox(height: 22),

          Text(
            'Base Pay Range',
            style: TextStyle(color: Colors.white.withOpacity(.6), fontSize: 12),
          ),

          Slider(
            value: baseSalary.clamp(10000, 500000),
            min: 10000,
            max: 500000,
            divisions: 98,
            activeColor: const Color(0xFF00E5FF),
            inactiveColor: Colors.white12,
            onChanged: (value) {
              setState(() {
                baseSalary = value.roundToDouble();
                _baseController.text = baseSalary.toStringAsFixed(0);
              });
              _calculate();
            },
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                '10K',
                style: TextStyle(color: Colors.white38, fontSize: 11),
              ),
              Text(
                '500K',
                style: TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _presetButton(String label, double amount) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        if (label == 'Reset') {
          setState(() {
            baseSalary = 50000;
            _baseController.text = '50000';
          });
        } else {
          _addToBase(amount);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(.045),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(.08)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Color(0xFF00E5FF),
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: _actionButton(
            label: 'Calculate',
            icon: Icons.calculate_rounded,
            primary: true,
            onTap: () {
              if (_formKey.currentState?.validate() ?? true) {
                _calculate();

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Salary calculated successfully.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _actionButton(
            label: 'Share',
            icon: Icons.ios_share_rounded,
            onTap: _shareSummary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _actionButton(
            label: 'Reset',
            icon: Icons.restart_alt_rounded,
            onTap: _reset,
          ),
        ),
      ],
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    bool primary = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: primary
                ? const LinearGradient(
                    colors: [Color(0xFF00E5FF), Color(0xFF7C4DFF)],
                  )
                : null,
            color: primary ? null : Colors.white.withOpacity(.045),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: primary
                  ? Colors.transparent
                  : Colors.white.withOpacity(.08),
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 21,
                color: primary ? Colors.white : const Color(0xFF00E5FF),
              ),
              const SizedBox(height: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: primary ? Colors.white : Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _glassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(.045),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(.09)),
          ),
          child: child,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(
    String label,
    IconData icon, {
    String? prefix,
  }) {
    return InputDecoration(
      labelText: label,
      prefixText: prefix,
      prefixIcon: Icon(icon, size: 20),
      filled: true,
      fillColor: Colors.white.withOpacity(.04),
      labelStyle: const TextStyle(color: Colors.white54, fontSize: 13),
      prefixStyle: const TextStyle(
        color: Color(0xFF00E5FF),
        fontWeight: FontWeight.bold,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: Colors.white.withOpacity(.08)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Color(0xFF00E5FF), width: 1.5),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// INPUT BOTTOM SHEET
// ─────────────────────────────────────────────

class _InputBottomSheet extends StatelessWidget {
  final GlobalKey<FormState> formKey;

  final TextEditingController baseController;
  final TextEditingController residentController;
  final TextEditingController travelController;
  final TextEditingController medicalController;
  final TextEditingController taxController;
  final TextEditingController otherController;

  final bool taxIsPercentage;

  final ValueChanged<bool> onTaxModeChanged;
  final VoidCallback onChanged;
  final VoidCallback onClose;

  const _InputBottomSheet({
    required this.formKey,
    required this.baseController,
    required this.residentController,
    required this.travelController,
    required this.medicalController,
    required this.taxController,
    required this.otherController,
    required this.taxIsPercentage,
    required this.onTaxModeChanged,
    required this.onChanged,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 720),
        decoration: const BoxDecoration(
          color: Color(0xFF101426),
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 25),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      height: 4,
                      width: 45,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Payroll Inputs',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: onClose,
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),

                  const SizedBox(height: 5),

                  const Text(
                    'Enter your monthly salary details',
                    style: TextStyle(color: Colors.white54, fontSize: 13),
                  ),

                  const SizedBox(height: 22),

                  _field(
                    context,
                    baseController,
                    'Monthly Base Salary',
                    Icons.account_balance_wallet_rounded,
                  ),

                  _field(
                    context,
                    residentController,
                    'Resident Allowance',
                    Icons.home_work_rounded,
                  ),

                  _field(
                    context,
                    travelController,
                    'Travel Allowance',
                    Icons.directions_car_rounded,
                  ),

                  _field(
                    context,
                    medicalController,
                    'Medical Allowance',
                    Icons.medical_services_rounded,
                  ),

                  const SizedBox(height: 6),

                  Row(
                    children: [
                      const Text(
                        'Tax Deduction',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            _taxMode('Amount', !taxIsPercentage),
                            _taxMode('%', taxIsPercentage),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  _field(
                    context,
                    taxController,
                    taxIsPercentage ? 'Tax Percentage' : 'Tax Amount',
                    Icons.receipt_long_rounded,
                    suffix: taxIsPercentage ? '%' : null,
                  ),

                  _field(
                    context,
                    otherController,
                    'Other Deductions',
                    Icons.remove_circle_outline_rounded,
                  ),

                  const SizedBox(height: 10),

                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        if (formKey.currentState!.validate()) {
                          onChanged();
                          onClose();
                        }
                      },
                      icon: const Icon(Icons.check_circle_rounded),
                      label: const Text(
                        'Apply & Calculate',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF00D9FF),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _taxMode(String text, bool selected) {
    return GestureDetector(
      onTap: () {
        onTaxModeChanged(text == '%');
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF00E5FF).withOpacity(.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: selected ? const Color(0xFF00E5FF) : Colors.white54,
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
        ),
      ),
    );
  }

  Widget _field(
    BuildContext context,
    TextEditingController controller,
    String label,
    IconData icon, {
    String? suffix,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: TextFormField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
        ],
        onChanged: (_) => onChanged(),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Please enter a value';
          }

          final number = double.tryParse(value);

          if (number == null || number < 0) {
            return 'Enter a valid number';
          }

          return null;
        },
        decoration: InputDecoration(
          labelText: label,
          suffixText: suffix,
          prefixIcon: Icon(icon, size: 20),
          filled: true,
          fillColor: Colors.white.withOpacity(.04),
          labelStyle: const TextStyle(color: Colors.white54, fontSize: 13),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.white.withOpacity(.08)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Color(0xFF00E5FF), width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Colors.redAccent),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// BACKGROUND
// ─────────────────────────────────────────────

class _BackgroundGlow extends StatelessWidget {
  const _BackgroundGlow();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF5146FF).withOpacity(.16),
              ),
            ),
          ),
          Positioned(
            top: 300,
            right: -120,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF00E5FF).withOpacity(.08),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
