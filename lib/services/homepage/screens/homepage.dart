import 'dart:async';
import 'package:flutter/material.dart';
import 'package:casharoo/helpers/toast_builder.dart';
import 'package:casharoo/api_exception.dart';
import 'package:casharoo/services/cashbook_operations/screens/cashbook_entries_page.dart';

import '../models/cashbook.dart';
import '../utils/utils.dart';
import './widgets/adaptive_scaffold.dart';
import './widgets/cashbook_card.dart';
import './widgets/cashbook_filter_sheet.dart';
import './widgets/add_cashbook_dialog.dart';
import './widgets/search_delegate.dart' as cbsearch;

class CashbookHomePage extends StatefulWidget {
  const CashbookHomePage({super.key});

  @override
  State<CashbookHomePage> createState() => _CashbookHomePageState();
}

class _CashbookHomePageState extends State<CashbookHomePage> {
  final _utility = CashbookUtils();

  List<Cashbook> _cashbooks = [];
  final Set<String> _selectedIds = <String>{};
  bool get _selectionMode => _selectedIds.isNotEmpty;
  bool _isLoading = false;

  final List<String> _banners = const [
    'Feature Upgrades Are Coming Soon!',
    'Allow data operator to edit entries for faster corrections.',
    'More Custom Field types: Number and Dropdown.',
  ];

  final PageController _bannerCtrl = PageController(viewportFraction: 0.95);
  Timer? _autoTimer;
  bool _showBanner = true;

  CashbookSort _sort = CashbookSort.lastUpdated;

  @override
  void initState() {
    super.initState();
    _load();
    _startAutoBanner();
  }

  void _startAutoBanner() {
    _autoTimer?.cancel();
    _autoTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_showBanner || _bannerCtrl.positions.isEmpty) return;
      final next = (_bannerCtrl.page ?? 0).round() + 1;
      _bannerCtrl.animateToPage(
        next % _banners.length,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );
    });
  }

  /// Load cashbooks with comprehensive error handling
  Future<void> _load() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final items = await _utility.fetchCashbooks();
      if (!mounted) return;

      setState(() {
        _cashbooks = _utility.sort(items, _sort);
        // if items changed, clear invalid selections
        _selectedIds.removeWhere((id) => !_cashbooks.any((c) => c.id == id));
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);

      // Show error toast based on exception type
      await _showErrorToast(e);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);

      await AppToast.show(
        context,
        message: 'An unexpected error occurred. Please try again.',
        type: AppToastType.error,
        seconds: 4,
      );
    }
  }

  void _openFilter() async {
    final result = await showModalBottomSheet<CashbookSort>(
      context: context,
      showDragHandle: true,
      builder: (_) => CashbookFilterSheet(selected: _sort),
    );
    if (result != null && result != _sort) {
      setState(() {
        _sort = result;
        _cashbooks = _utility.sort(_cashbooks, _sort);
      });
    }
  }

  void _openSearch() async {
    final chosen = await showSearch<Cashbook?>(
      context: context,
      delegate: cbsearch.CashbookSearchDelegate(data: _cashbooks),
    );
    if (chosen != null && mounted) {
      // TODO: navigate to details if you add a details page
    }
  }

  /// Open add cashbook dialog with error handling
  Future<void> _openAddDialog() async {
    final created = await showDialog<Cashbook>(
      context: context,
      builder: (_) => const AddCashbookDialog(),
    );

    if (created != null) {
      // Show success toast
      await AppToast.show(
        context,
        message: 'Cashbook created successfully!',
        type: AppToastType.success,
        seconds: 3,
      );
      await _load(); // silently reload
    }
  }

  void _toggleSelect(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _clearSelection() {
    setState(() => _selectedIds.clear());
  }

  /// Bulk delete with comprehensive error handling
  Future<void> _bulkDelete() async {
    final count = _selectedIds.length;
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete selected?'),
        content: Text('This will permanently delete $count cashbook(s).'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      await _utility.bulkDeleteCashbooks(_selectedIds.toList());

      if (!mounted) return;

      // Show success toast
      final message = count > 1
          ? '$count cashbooks deleted successfully!'
          : 'Cashbook deleted successfully!';

      await AppToast.show(
        context,
        message: message,
        type: AppToastType.success,
        seconds: 3,
      );

      _clearSelection();
      await _load(); // silent refresh
    } on ApiException catch (e) {
      if (!mounted) return;
      await _showErrorToast(e);
    } catch (e) {
      if (!mounted) return;
      await AppToast.show(
        context,
        message: 'Failed to delete cashbooks. Please try again.',
        type: AppToastType.error,
        seconds: 4,
      );
    }
  }

  /// Helper method to show error toasts based on exception type
  Future<void> _showErrorToast(ApiException e) async {
    AppToastType toastType;
    int seconds;

    switch (e.type) {
      case ApiExceptionType.network:
        toastType = AppToastType.error;
        seconds = 5;
        break;
      case ApiExceptionType.authentication:
        toastType = AppToastType.error;
        seconds = 5;
        break;
      case ApiExceptionType.permission:
        toastType = AppToastType.warning;
        seconds = 4;
        break;
      case ApiExceptionType.validation:
        toastType = AppToastType.warning;
        seconds = 4;
        break;
      case ApiExceptionType.notFound:
        toastType = AppToastType.info;
        seconds = 3;
        break;
      default:
        toastType = AppToastType.error;
        seconds = 4;
    }

    await AppToast.show(
      context,
      message: e.message,
      type: toastType,
      seconds: seconds,
    );
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _bannerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return AdaptiveScaffold(
      selectedIndex: 0,
      onDestinationSelected: (i) {
        // TODO: navigate to Help/Settings
      },
      appBar: AppBar(
        leading: _selectionMode
            ? IconButton(
                tooltip: 'Cancel selection',
                icon: const Icon(Icons.close_rounded),
                onPressed: _clearSelection,
              )
            : null,
        title: _selectionMode
            ? Text('${_selectedIds.length} selected')
            : const Text('Casharooo'),
        actions: [
          if (!_selectionMode) ...[
            IconButton(
              tooltip: 'Sort / Filter',
              onPressed: _openFilter,
              icon: const Icon(Icons.filter_list_rounded),
            ),
            IconButton(
              tooltip: 'Search',
              onPressed: _openSearch,
              icon: const Icon(Icons.search_rounded),
            ),
          ] else ...[
            IconButton(
              tooltip: 'Select all',
              onPressed: () {
                setState(
                  () => _selectedIds
                    ..clear()
                    ..addAll(_cashbooks.map((e) => e.id)),
                );
              },
              icon: const Icon(Icons.select_all_rounded),
            ),
            IconButton(
              tooltip: 'Delete selected',
              onPressed: _bulkDelete,
              icon: const Icon(Icons.delete_forever_rounded),
            ),
          ],
        ],
      ),
      floatingActionButton: _selectionMode
          ? null
          : FloatingActionButton.extended(
              onPressed: _openAddDialog,
              icon: const Icon(Icons.add),
              label: const Text('Add New Book'),
            ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                children: [
                  if (_showBanner) ...[
                    _BannerCarousel(
                      banners: _banners,
                      controller: _bannerCtrl,
                      onClose: () => setState(() => _showBanner = false),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Text('Your Books', style: t.headlineMedium),
                  const SizedBox(height: 12),
                  if (_cashbooks.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(48.0),
                        child: Column(
                          children: [
                            Icon(
                              Icons.book_outlined,
                              size: 64,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.3),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No cashbooks yet',
                              style: t.titleLarge?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap the button below to create your first cashbook',
                              textAlign: TextAlign.center,
                              style: t.bodyMedium?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ..._cashbooks.map((c) {
                      final selected = _selectedIds.contains(c.id);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: CashbookCard(
                          cashbook: c,
                          // Selection-specific flags & callbacks:
                          selectionMode: _selectionMode,
                          selected: selected,
                          onCardTap: () {
                            if (_selectionMode) {
                              _toggleSelect(c.id);
                            } else {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CashbookEntriesPage(
                                    cashbookId: c.id,
                                    cashbookName: c.name,
                                  ),
                                ),
                              );
                            }
                          },
                          onCardLongPress: () {
                            if (!_selectionMode) {
                              setState(() => _selectedIds.add(c.id));
                            } else {
                              _toggleSelect(c.id);
                            }
                          },
                          // Keep single-delete path inside each card
                          onDelete: () async {
                            try {
                              if (!mounted) return;
                              await AppToast.show(
                                context,
                                message: 'Cashbook deleted successfully!',
                                type: AppToastType.success,
                                seconds: 3,
                              );

                              await _load();
                            } on ApiException catch (e) {
                              if (!mounted) return;
                              await _showErrorToast(e);
                            } catch (e) {
                              if (!mounted) return;
                              await AppToast.show(
                                context,
                                message: 'Failed to delete cashbook.',
                                type: AppToastType.error,
                                seconds: 4,
                              );
                            }
                          },
                          onRename: () async {
                            // After rename dialog closes with new name
                            await AppToast.show(
                              context,
                              message: 'Cashbook renamed successfully!',
                              type: AppToastType.success,
                              seconds: 3,
                            );
                            await _load();
                          },
                          onMove: () {
                            /* optional */
                          },
                        ),
                      );
                    }),
                  const SizedBox(height: 48),
                ],
              ),
            ),
    );
  }
}

class _BannerCarousel extends StatelessWidget {
  final List<String> banners;
  final PageController controller;
  final VoidCallback onClose;
  const _BannerCarousel({
    required this.banners,
    required this.controller,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Stack(
      children: [
        SizedBox(
          height: 110,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: PageView.builder(
              controller: controller,
              itemCount: banners.length,
              itemBuilder: (_, i) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      cs.secondary.withOpacity(.18),
                      cs.tertiary.withOpacity(.18),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lightbulb_circle_rounded,
                      color: cs.secondary,
                      size: 34,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        banners[i],
                        style: Theme.of(context).textTheme.titleLarge,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          right: 8,
          top: 8,
          child: IconButton(
            tooltip: 'Dismiss',
            icon: const Icon(Icons.close_rounded),
            onPressed: onClose,
          ),
        ),
      ],
    );
  }
}
