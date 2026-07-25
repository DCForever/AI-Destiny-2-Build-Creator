import 'package:destiny2_manifest/destiny2_manifest.dart';
import 'package:flutter/material.dart';

import '../host_bootstrap.dart';

/// Offline catalog browse: facets + free-text, no inventory (DART-020).
class CatalogPage extends StatefulWidget {
  const CatalogPage({
    super.key,
    required this.services,
  });

  final AppServices services;

  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  bool _loading = true;
  String? _error;
  CatalogEmptyReason _emptyReason = CatalogEmptyReason.none;
  String? _version;
  List<CatalogItem> _results = const [];

  final _queryController = TextEditingController();
  FacetFilter _elements = emptyFacet();
  FacetFilter _ammos = emptyFacet();
  bool? _exotic; // null = off, true = only, false = exclude

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await widget.services.offlineCatalog.loadBase();
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = result.error;
        _emptyReason = result.emptyReason;
        _version = result.version;
        _results = _applyFilters();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
        _results = const [];
      });
    }
  }

  List<CatalogItem> _applyFilters() {
    return widget.services.offlineCatalog.browse(
      CatalogClientFilters(
        query: _queryController.text,
        elements: _elements,
        ammos: _ammos,
        exotic: _exotic,
      ),
    );
  }

  void _refilter() {
    setState(() {
      _results = _applyFilters();
    });
  }

  void _cycleElement(String value) {
    setState(() {
      _elements = cycleFacetValue(_elements, value);
      _results = _applyFilters();
    });
  }

  void _cycleAmmo(String value) {
    setState(() {
      _ammos = cycleFacetValue(_ammos, value);
      _results = _applyFilters();
    });
  }

  void _cycleExotic() {
    setState(() {
      // off → only exotic → exclude exotic → off
      if (_exotic == null) {
        _exotic = true;
      } else if (_exotic == true) {
        _exotic = false;
      } else {
        _exotic = null;
      }
      _results = _applyFilters();
    });
  }

  String _exoticLabel() {
    if (_exotic == true) return 'Exotic only';
    if (_exotic == false) return 'No exotic';
    return 'Exotic: any';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catalog'),
        actions: [
          IconButton(
            key: const Key('catalog_reload'),
            tooltip: 'Reload from entity stores',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              key: const Key('catalog_query'),
              controller: _queryController,
              decoration: const InputDecoration(
                labelText: 'Search',
                hintText: 'Name, type, element…',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (_) => _refilter(),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                for (final el in catalogElements)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: FilterChip(
                      key: Key('element_chip_$el'),
                      label: Text(el),
                      selected: facetChipState(_elements, el) != FacetChipState.off,
                      onSelected: (_) => _cycleElement(el),
                      avatar: _facetAvatar(facetChipState(_elements, el)),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                for (final ammo in catalogAmmoTypes)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: FilterChip(
                      key: Key('ammo_chip_$ammo'),
                      label: Text(ammo),
                      selected: facetChipState(_ammos, ammo) != FacetChipState.off,
                      onSelected: (_) => _cycleAmmo(ammo),
                      avatar: _facetAvatar(facetChipState(_ammos, ammo)),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FilterChip(
                    key: const Key('exotic_chip'),
                    label: Text(_exoticLabel()),
                    selected: _exotic != null,
                    onSelected: (_) => _cycleExotic(),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              _statusLine(),
              key: const Key('catalog_status'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget? _facetAvatar(FacetChipState state) {
    switch (state) {
      case FacetChipState.include:
        return const Icon(Icons.add, size: 16);
      case FacetChipState.exclude:
        return const Icon(Icons.remove, size: 16);
      case FacetChipState.off:
        return null;
    }
  }

  String _statusLine() {
    if (_loading) return 'Loading entity stores…';
    if (_error != null) return 'Error: $_error';
    final v = _version ?? 'none';
    final base = widget.services.offlineCatalog.baseItems.length;
    return 'Version $v · ${_results.length} shown / $base base · offline (no inventory)';
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(key: Key('catalog_loading')),
      );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Failed to load catalog:\n$_error',
            key: const Key('catalog_error'),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    if (_results.isEmpty) {
      final message = switch (_emptyReason) {
        CatalogEmptyReason.noVersion =>
          'No entity cache version. Open Settings and refresh the manifest when an API key is configured.',
        CatalogEmptyReason.noStores =>
          'Entity stores are empty for this version. Rebuild entities from Settings refresh.',
        CatalogEmptyReason.none =>
          'No items match the current filters.',
      };
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            message,
            key: const Key('catalog_empty'),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return ListView.builder(
      key: const Key('catalog_list'),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final item = _results[index];
        final subtitle = [
          if (item.slot != null) item.slot!,
          if (item.element != null) item.element!,
          if (item.ammo != null) item.ammo!,
          if (item.itemTypeName != null) item.itemTypeName!,
          if (item.classType != null) item.classType!,
          if (item.isExotic) 'Exotic',
        ].join(' · ');
        return ListTile(
          key: Key('catalog_item_${item.hash}'),
          title: Text(item.name),
          subtitle: Text(subtitle),
          dense: true,
        );
      },
    );
  }
}
