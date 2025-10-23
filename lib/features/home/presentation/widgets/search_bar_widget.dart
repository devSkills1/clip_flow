// ignore_for_file: public_member_api_docs
// 忽略公共成员API文档要求，因为这是内部UI组件，不需要对外暴露API文档
// Internal UI component that doesn't require public API documentation.
import 'package:clip_flow_pro/core/constants/clip_constants.dart';
import 'package:clip_flow_pro/core/constants/i18n_fallbacks.dart';
import 'package:clip_flow_pro/l10n/gen/s.dart';
import 'package:flutter/material.dart';

class SearchBarWidget extends StatelessWidget {
  const SearchBarWidget({
    required this.controller,
    required this.onSearchChanged,
    required this.onClear,
    super.key,
  });
  final TextEditingController controller;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ClipConstants.defaultPadding),
      child: TextField(
        controller: controller,
        onChanged: onSearchChanged,
        decoration: InputDecoration(
          hintText: S.of(context)?.searchHint ?? I18nFallbacks.home.searchHint,
          prefixIcon: const Icon(Icons.search),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(onPressed: onClear, icon: const Icon(Icons.clear))
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(ClipConstants.cardBorderRadius),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }
}
