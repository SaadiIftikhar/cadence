import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../theme/app_theme.dart';
import '../util/icon_catalog.dart';

/// Search over the full Material Symbols set. Pops the chosen icon name.
class IconPickerScreen extends StatefulWidget {
  const IconPickerScreen({super.key, this.selected});

  final String? selected;

  @override
  State<IconPickerScreen> createState() => _IconPickerScreenState();
}

class _IconPickerScreenState extends State<IconPickerScreen> {
  final _controller = TextEditingController();
  late List<String> _results = IconCatalog.suggested;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _search(String query) {
    setState(() => _results = IconCatalog.search(query));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Symbols.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            child: TextField(
              controller: _controller,
              onChanged: _search,
              autofocus: false,
              textInputAction: TextInputAction.search,
              style: const TextStyle(fontSize: 19),
              decoration: InputDecoration(
                hintText: 'Search',
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(left: 16, right: 12),
                  child: Icon(Symbols.search, size: 26),
                ),
                prefixIconConstraints:
                    const BoxConstraints(minWidth: 0, minHeight: 0),
                suffixIcon: IconButton(
                  icon: const Icon(Symbols.close, size: 26),
                  onPressed: () {
                    _controller.clear();
                    _search('');
                  },
                ),
              ),
            ),
          ),
          Expanded(
            child: _results.isEmpty
                ? const Center(
                    child: Text(
                      'No icons match that search.',
                      style: TextStyle(color: AppColors.onSurfaceVariant),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 84,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                    ),
                    itemCount: _results.length,
                    itemBuilder: (context, i) {
                      final name = _results[i];
                      final selected = name == widget.selected;
                      return _IconCell(
                        name: name,
                        selected: selected,
                        onTap: () => Navigator.pop(context, name),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _IconCell extends StatelessWidget {
  const _IconCell({
    required this.name,
    required this.selected,
    required this.onTap,
  });

  final String name;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: name.replaceAll('_', ' '),
      waitDuration: const Duration(milliseconds: 600),
      child: Material(
        color: selected ? AppColors.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Icon(
            IconCatalog.resolve(name),
            size: 28,
            color: selected ? AppColors.onPrimary : AppColors.onSurface,
          ),
        ),
      ),
    );
  }
}
