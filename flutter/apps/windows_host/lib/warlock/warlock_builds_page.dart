import 'package:destiny2_bungie/destiny2_bungie.dart';
import 'package:flutter/material.dart';

import 'pilot_review_page.dart';
import 'warlock_build_row.dart';
import 'warlock_builds_controller.dart';

/// Read-only list of Warlock community builds, filtered by exotic.
class WarlockBuildsPage extends StatefulWidget {
  const WarlockBuildsPage({
    super.key,
    this.initialPath,
    this.http,
    this.controller,
  });

  /// Local matrix file. Empty until the user types a path or the host sets one.
  final String? initialPath;

  /// Optional GET-only client used when [controller] is null.
  final GetOnlyHttpClient? http;

  /// Preloaded controller for tests. The page does not dispose it.
  final WarlockBuildsController? controller;

  @override
  State<WarlockBuildsPage> createState() => _WarlockBuildsPageState();
}

class _WarlockBuildsPageState extends State<WarlockBuildsPage> {
  late final WarlockBuildsController _controller;
  late final bool _ownsController;
  late final TextEditingController _path;

  @override
  void initState() {
    super.initState();
    final injected = widget.controller;
    _ownsController = injected == null;
    _controller = injected ??
        WarlockBuildsController(
          http: widget.http,
          initialPath: widget.initialPath,
        );
    _controller.addListener(_onController);
    _path = TextEditingController(text: _controller.path);
    if (_ownsController && _controller.path.isNotEmpty) {
      _controller.load();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onController);
    _path.dispose();
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  void _onController() {
    if (mounted) setState(() {});
  }

  Future<void> _load() async {
    _controller.path = _path.text;
    await _controller.load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Warlock builds'),
        actions: const [
          _OpenPilotButton(),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PathBar(controller: _path, onLoad: _load),
          _ExoticFilter(controller: _controller),
          Expanded(child: _BuildList(controller: _controller)),
        ],
      ),
    );
  }
}

class _OpenPilotButton extends StatelessWidget {
  const _OpenPilotButton();

  @override
  Widget build(BuildContext context) {
    return TextButton(
      key: const Key('open_offline_pilot'),
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (context) => const PilotReviewLoader(),
          ),
        );
      },
      child: const Text('Offline pilot'),
    );
  }
}

class _PathBar extends StatelessWidget {
  const _PathBar({required this.controller, required this.onLoad});

  final TextEditingController controller;
  final Future<void> Function() onLoad;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Expanded(child: _pathField()),
          const SizedBox(width: 12),
          _loadButton(),
        ],
      ),
    );
  }

  Widget _pathField() {
    return TextField(
      key: const Key('warlock_matrix_path'),
      controller: controller,
      decoration: const InputDecoration(
        labelText: 'Matrix file',
        helperText: 'Read-only local path (WARLOCK_MATRIX_PATH)',
      ),
    );
  }

  Widget _loadButton() {
    return FilledButton(
      key: const Key('warlock_matrix_load'),
      onPressed: () => onLoad(),
      child: const Text('Load'),
    );
  }
}

class _ExoticFilter extends StatelessWidget {
  const _ExoticFilter({required this.controller});

  final WarlockBuildsController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DropdownButton<String>(
        key: const Key('warlock_exotic_filter'),
        isExpanded: true,
        value: controller.selectedExotic ?? '',
        items: _items(),
        onChanged:
            controller.exoticNames.isEmpty ? null : controller.selectExotic,
      ),
    );
  }

  List<DropdownMenuItem<String>> _items() {
    return [
      const DropdownMenuItem(value: '', child: Text('All exotics')),
      for (final name in controller.exoticNames)
        DropdownMenuItem(value: name, child: Text(name)),
    ];
  }
}

class _BuildList extends StatelessWidget {
  const _BuildList({required this.controller});

  final WarlockBuildsController controller;

  @override
  Widget build(BuildContext context) {
    if (controller.loading && controller.builds.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    final error = controller.error;
    if (error != null && controller.builds.isEmpty) {
      return _message(error, const Key('warlock_matrix_error'));
    }
    if (controller.visibleBuilds.isEmpty) {
      return _message(
          'No builds for this exotic.', const Key('warlock_builds_empty'));
    }
    return ListView(
      key: const Key('warlock_build_list'),
      children: [
        for (final entry in controller.visibleBuilds)
          WarlockBuildRow(entry: entry),
      ],
    );
  }

  Widget _message(String text, Key key) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(text, key: key, textAlign: TextAlign.center),
      ),
    );
  }
}
