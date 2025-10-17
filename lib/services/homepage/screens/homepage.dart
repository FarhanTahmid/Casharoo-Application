import 'dart:async';
import 'package:flutter/material.dart';
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
  final _utility = CashbookUtils(); // <-- plug your API here later
  List<Cashbook> _cashbooks = [];
  List<String> _banners = [
    'Feature Upgrades Are Coming Soon!',
    'Allow data operator to edit entries for faster corrections.',
    'More Custom Field types: Number and Dropdown.'
  ];

  // banners
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

  Future<void> _load() async {
    // Replace with API call
    final items = await _utility.fetchCashbooks();
    setState(() {
      _cashbooks = _utility.sort(items, _sort);
    });
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
    if (chosen != null) {
      // Example action: open details later
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Selected: ${chosen.name}')),
      );
    }
  }

  Future<void> _openAddDialog() async {
    final created = await showDialog<Cashbook>(
      context: context,
      builder: (_) => const AddCashbookDialog(),
    );
    if (created != null) {
      // TODO: call API to create
      await _utility.createCashbook(created);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cashbook created')),
        );
      }
    }
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _bannerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      selectedIndex: 0,
      onDestinationSelected: (i) {
        // TODO: Navigate to other tabs/pages
      },
      appBar: AppBar(
        title: const Text('Cashbooks'),
        actions: [
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
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add New Book'),
      ),
      body: RefreshIndicator(
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
            Text('Your Books', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 12),
            ..._cashbooks.map((c) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: CashbookCard(
                    cashbook: c,
                    onRename: () {
                      // TODO open rename flow
                    },
                    onMove: () {
                      // TODO move to group/business
                    },
                    onDelete: () async {
                      // TODO delete via API
                      await _utility.deleteCashbook(c.id);
                      await _load();
                    },
                  ),
                )),
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
                    colors: [cs.secondary.withOpacity(.18), cs.tertiary.withOpacity(.18)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lightbulb_circle_rounded, color: cs.secondary, size: 34),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        banners[i],
                        style: Theme.of(context).textTheme.titleLarge,
                        maxLines: 2, overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          right: 8, top: 8,
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
