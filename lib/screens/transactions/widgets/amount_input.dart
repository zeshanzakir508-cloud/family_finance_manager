// lib/screens/transactions/widgets/amount_input.dart
import 'package:flutter/material.dart';

class AmountInput extends StatefulWidget {
  final double? initialAmount;
  final ValueChanged<double> onAmountChanged;
  final String currency;
  final String label;

  const AmountInput({
    Key? key,
    this.initialAmount,
    required this.onAmountChanged,
    required this.currency,
    this.label = 'Amount',
  }) : super(key: key);

  @override
  State<AmountInput> createState() => _AmountInputState();
}

class _AmountInputState extends State<AmountInput> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialAmount != null && widget.initialAmount! > 0) {
      _controller.text = widget.initialAmount!.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
        ),
      ),
      child: Row(
        children: [
          Text(
            widget.currency,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
              decoration: InputDecoration(
                hintText: '0.00',
                border: InputBorder.none,
                hintStyle: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.grey[600] : Colors.grey[400],
                ),
              ),
              onChanged: (value) {
                final amount = double.tryParse(value);
                if (amount != null) {
                  widget.onAmountChanged(amount);
                } else {
                  widget.onAmountChanged(0.0);
                }
              },
            ),
          ),
          // Quick amount buttons
          Column(
            children: [
              _buildQuickButton(10),
              _buildQuickButton(50),
              _buildQuickButton(100),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickButton(double amount) {
    return InkWell(
      onTap: () {
        final currentValue = double.tryParse(_controller.text) ?? 0.0;
        final newValue = currentValue + amount;
        _controller.text = newValue.toStringAsFixed(2);
        widget.onAmountChanged(newValue);
      },
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        margin: const EdgeInsets.symmetric(vertical: 1),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          '+${widget.currency}$amount',
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
