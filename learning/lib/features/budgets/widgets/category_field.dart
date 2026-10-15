import 'package:flutter/material.dart';

import '../../../core/utils/validators.dart';

/// Expense category input that suggests names already in use, so the
/// same category isn't typed several ways and budgets keep matching.
class CategoryField extends StatefulWidget {
  const CategoryField({
    super.key,
    required this.controller,
    required this.suggestions,
    this.label = 'Category',
    this.enabled = true,
  });

  final TextEditingController controller;
  final List<String> suggestions;
  final String label;
  final bool enabled;

  @override
  State<CategoryField> createState() => _CategoryFieldState();
}

class _CategoryFieldState extends State<CategoryField> {
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: RawAutocomplete<String>(
        textEditingController: widget.controller,
        focusNode: _focusNode,
        optionsBuilder: (value) {
          final query = value.text.trim().toLowerCase();
          return widget.suggestions.where(
            (s) => s.toLowerCase().contains(query) && s.toLowerCase() != query,
          );
        },
        fieldViewBuilder: (context, textController, focusNode, onSubmit) {
          return TextFormField(
            controller: textController,
            focusNode: focusNode,
            enabled: widget.enabled,
            textCapitalization: TextCapitalization.words,
            validator: FormValidators.required,
            onFieldSubmitted: (_) => onSubmit(),
            decoration: InputDecoration(
              labelText: widget.label,
              prefixIcon: const Icon(Icons.category, size: 20),
            ),
          );
        },
        optionsViewBuilder: (context, onSelected, options) {
          return Align(
            alignment: Alignment.topLeft,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(12),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxHeight: 220,
                  maxWidth: 320,
                ),
                child: ListView(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  children: [
                    for (final option in options)
                      ListTile(
                        dense: true,
                        title: Text(option),
                        onTap: () => onSelected(option),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
