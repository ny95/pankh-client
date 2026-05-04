part of 'account.dart';

const List<String> _authMethodOptions = [
  'No Authentication',
  'Normal password',
  'Encrypted password',
  'Kerberos / GSSAPI',
  'NTLM',
  'TLS Certificate',
  'OAuth2',
  'Exchange / OAuth2',
];

List<String> _authOptionsFor(String current) {
  return _authMethodOptions.contains(current)
      ? _authMethodOptions
      : [..._authMethodOptions, current];
}

class _EditableField extends StatefulWidget {
  final String label;
  final String initialValue;
  final bool isCompact;
  final ValueChanged<String> onSave;

  const _EditableField({
    required this.label,
    required this.initialValue,
    required this.isCompact,
    required this.onSave,
  });

  @override
  State<_EditableField> createState() => _EditableFieldState();
}

class _EditableFieldState extends State<_EditableField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _SettingsField(
      label: widget.label,
      isCompact: widget.isCompact,
      field: TextField(
        controller: _controller,
        decoration: InputDecoration(
          isDense: true,
          border: const OutlineInputBorder(),
          suffixIcon: IconButton(
            icon: const Icon(Icons.save),
            onPressed: () => widget.onSave(_controller.text),
          ),
        ),
        onSubmitted: widget.onSave,
      ),
    );
  }
}

class _MultilineField extends StatefulWidget {
  final String label;
  final String initialValue;
  final bool isCompact;
  final ValueChanged<String> onSave;

  const _MultilineField({
    required this.label,
    required this.initialValue,
    required this.isCompact,
    required this.onSave,
  });

  @override
  State<_MultilineField> createState() => _MultilineFieldState();
}

class _MultilineFieldState extends State<_MultilineField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _SettingsField(
      label: widget.label,
      isCompact: widget.isCompact,
      rowCrossAxisAlignment: CrossAxisAlignment.start,
      field: TextField(
        controller: _controller,
        minLines: 3,
        maxLines: 6,
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          suffixIcon: IconButton(
            icon: const Icon(Icons.save),
            onPressed: () => widget.onSave(_controller.text),
          ),
        ),
      ),
    );
  }
}

class _IntervalRow extends StatefulWidget {
  final String label;
  final int minutes;
  final bool enabled;
  final bool isCompact;
  final ValueChanged<bool?> onToggle;
  final ValueChanged<int> onMinutesChanged;

  const _IntervalRow({
    required this.label,
    required this.minutes,
    required this.enabled,
    required this.isCompact,
    required this.onToggle,
    required this.onMinutesChanged,
  });

  @override
  State<_IntervalRow> createState() => _IntervalRowState();
}

class _IntervalRowState extends State<_IntervalRow> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.minutes.toString());
  }

  @override
  void didUpdateWidget(_IntervalRow old) {
    super.didUpdateWidget(old);
    if (old.minutes != widget.minutes) {
      _controller.text = widget.minutes.toString();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: widget.isCompact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Checkbox(value: widget.enabled, onChanged: widget.onToggle),
                    Expanded(child: Text(widget.label)),
                  ],
                ),
                Row(
                  children: [
                    const SizedBox(width: 40),
                    SizedBox(
                      width: 80,
                      child: TextField(
                        controller: _controller,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: (value) {
                          final parsed = int.tryParse(value) ?? widget.minutes;
                          widget.onMinutesChanged(parsed.clamp(1, 120));
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('minutes'),
                  ],
                ),
              ],
            )
          : Row(
              children: [
                Checkbox(value: widget.enabled, onChanged: widget.onToggle),
                Expanded(child: Text(widget.label)),
                SizedBox(
                  width: 80,
                  child: TextField(
                    controller: _controller,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (value) {
                      final parsed = int.tryParse(value) ?? widget.minutes;
                      widget.onMinutesChanged(parsed.clamp(1, 120));
                    },
                  ),
                ),
                const SizedBox(width: 8),
                const Text('minutes'),
              ],
            ),
    );
  }
}

class _SettingsField extends StatelessWidget {
  final String label;
  final Widget field;
  final bool isCompact;
  final bool expandInRow;
  final CrossAxisAlignment rowCrossAxisAlignment;

  const _SettingsField({
    required this.label,
    required this.field,
    required this.isCompact,
    this.expandInRow = true,
    this.rowCrossAxisAlignment = CrossAxisAlignment.center,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: isCompact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label),
                const SizedBox(height: 4),
                field,
              ],
            )
          : Row(
              crossAxisAlignment: rowCrossAxisAlignment,
              children: [
                SizedBox(width: 140, child: Text(label)),
                const SizedBox(width: 8),
                if (expandInRow) Expanded(child: field) else field,
              ],
            ),
    );
  }
}
