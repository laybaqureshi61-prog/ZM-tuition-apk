import 'package:flutter/material.dart';

class CustomPasswordField extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final String hintText;
  final IconData prefixIcon;
  final bool autofocus;
  final ValueChanged<String>? onSubmitted;

  const CustomPasswordField({
    super.key,
    required this.controller,
    this.labelText = 'Enter your password',
    this.hintText = 'Enter your password',
    this.prefixIcon = Icons.lock_outline,
    this.autofocus = false,
    this.onSubmitted,
  });

  @override
  State<CustomPasswordField> createState() => _CustomPasswordFieldState();
}

class _CustomPasswordFieldState extends State<CustomPasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      obscureText: _obscure,
      keyboardType: TextInputType.visiblePassword,
      autocorrect: false,
      enableSuggestions: false,
      autofocus: widget.autofocus,
      onSubmitted: widget.onSubmitted,
      decoration: InputDecoration(
        labelText: widget.labelText,
        hintText: widget.hintText,
        prefixIcon: Icon(widget.prefixIcon, size: 20, color: const Color(0xFF6B8A87)),
        suffixIcon: IconButton(
          icon: Icon(
            _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            size: 20,
            color: const Color(0xFF6B8A87),
          ),
          tooltip: _obscure ? 'Show password' : 'Hide password',
          splashRadius: 20,
          onPressed: () => setState(() => _obscure = !_obscure),
        ),
      ),
    );
  }
}
