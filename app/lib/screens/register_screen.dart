import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../api.dart';
import '../brand.dart';
import '../file_pick.dart';
import '../l10n.dart';
import '../picked_file.dart';
import '../registration_spec.dart';
import '../session_scope.dart';
import '../theme.dart';
import '../widgets.dart';

/// Page frame for the screens anyone can open without signing in.
class PublicFrame extends StatelessWidget {
  const PublicFrame({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final copy = LocaleScope.copy(context);
    final narrow = MediaQuery.sizeOf(context).width < kPhoneBreakpoint;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(narrow ? AppSpacing.lg : AppSpacing.xl),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 920),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const BrandLockup(size: 36),
                      const Spacer(),
                      const LanguageSwitch(),
                      const SizedBox(width: AppSpacing.sm),
                      TextButton(
                        key: const Key('register-to-login'),
                        onPressed: () => context.go('/login'),
                        child: Text(copy.signInButton),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  child,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key, this.kind});

  /// `developer`, `bank`, or null while the person is still choosing.
  final String? kind;

  @override
  Widget build(BuildContext context) {
    return PublicFrame(
      child: kind == 'developer' || kind == 'bank'
          ? RegisterForm(key: ValueKey(kind), kind: kind!)
          : const _KindChooser(),
    );
  }
}

class _KindChooser extends StatelessWidget {
  const _KindChooser();

  @override
  Widget build(BuildContext context) {
    final copy = LocaleScope.copy(context);
    final theme = Theme.of(context);
    final wide = MediaQuery.sizeOf(context).width >= 700;
    final cards = [
      _KindCard(
        cardKey: const Key('register-kind-developer'),
        icon: Icons.apartment_outlined,
        title: copy.kindDeveloper,
        body: copy.kindDeveloperBody,
        onTap: () => context.go('/register?kind=developer'),
      ),
      _KindCard(
        cardKey: const Key('register-kind-bank'),
        icon: Icons.account_balance_outlined,
        title: copy.kindBank,
        body: copy.kindBankBody,
        onTap: () => context.go('/register?kind=bank'),
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(copy.registerTitle, style: theme.textTheme.headlineMedium),
        const SizedBox(height: AppSpacing.sm),
        Text(
          copy.registerPick,
          style: theme.textTheme.bodyLarge?.copyWith(color: context.colors.inkMuted),
        ),
        const SizedBox(height: AppSpacing.xl),
        if (wide)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: cards[0]),
                const SizedBox(width: AppSpacing.lg),
                Expanded(child: cards[1]),
              ],
            ),
          )
        else ...[
          cards[0],
          const SizedBox(height: AppSpacing.lg),
          cards[1],
        ],
        const SizedBox(height: AppSpacing.xl),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: () => context.go('/login'),
            child: Text(copy.haveAccount),
          ),
        ),
      ],
    );
  }
}

class _KindCard extends StatelessWidget {
  const _KindCard({
    required this.cardKey,
    required this.icon,
    required this.title,
    required this.body,
    required this.onTap,
  });

  final Key cardKey;
  final IconData icon;
  final String title;
  final String body;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    return Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.card),
        side: BorderSide(color: colors.outline),
      ),
      child: InkWell(
        key: cardKey,
        borderRadius: BorderRadius.circular(AppRadii.card),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 36, color: colors.accent),
              const SizedBox(height: AppSpacing.lg),
              Text(title, style: theme.textTheme.titleLarge),
              if (body.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(body, style: theme.textTheme.bodyMedium?.copyWith(color: colors.inkMuted)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('998') && digits.length > 9) digits = digits.substring(3);
    if (digits.length > 9) digits = digits.substring(0, 9);
    return TextEditingValue(
      text: digits,
      selection: TextSelection.collapsed(offset: digits.length),
    );
  }
}

class _OwnerRow {
  String kind = 'person';
  final name = TextEditingController();
  final taxId = TextEditingController();
  final share = TextEditingController();

  void dispose() {
    name.dispose();
    taxId.dispose();
    share.dispose();
  }
}

class _LicenseRow {
  final activity = TextEditingController();
  final number = TextEditingController();
  final issuedText = TextEditingController();
  final untilText = TextEditingController();
  String issued = '';
  String until = '';

  bool get isEmpty =>
      activity.text.trim().isEmpty && number.text.trim().isEmpty && issued.isEmpty && until.isEmpty;

  void dispose() {
    activity.dispose();
    number.dispose();
    issuedText.dispose();
    untilText.dispose();
  }
}

const _pastDateKeys = {
  'reg_date',
  'dir_passport_issued',
  'permit_date',
  'expertise_date',
  'license_date',
};

String _shown(DateTime day) =>
    '${day.day.toString().padLeft(2, '0')}.${day.month.toString().padLeft(2, '0')}.${day.year}';

String _iso(DateTime day) =>
    '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';

final _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');

class RegisterForm extends StatefulWidget {
  const RegisterForm({super.key, required this.kind});

  final String kind;

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  final _controllers = <String, TextEditingController>{};
  final _choice = <String, String>{};
  final _owners = <_OwnerRow>[_OwnerRow()];
  final _licenses = <_LicenseRow>[];
  final _interests = <String>{};
  final _files = <String, List<PickedFile>>{};
  final _errors = <String, String>{};
  final _anchors = <String, GlobalKey>{};
  var _consentData = false;
  var _consentTruth = false;
  var _busy = false;
  String? _progress;
  String? _banner;
  ({String id, String code, String token, bool docsFailed})? _sent;

  bool get _isBank => widget.kind == 'bank';

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    for (final row in _owners) {
      row.dispose();
    }
    for (final row in _licenses) {
      row.dispose();
    }
    super.dispose();
  }

  TextEditingController _ctl(String key) => _controllers.putIfAbsent(key, TextEditingController.new);

  GlobalKey _anchor(String key) => _anchors.putIfAbsent(key, GlobalKey.new);

  bool _usesController(RegField field) =>
      field.kind != RegKind.choice && field.kind != RegKind.yesNo && field.kind != RegKind.date;

  String _value(RegField field) {
    if (_usesController(field)) return _ctl(field.key).text.trim();
    return _choice[field.key] ?? '';
  }

  String? _problem(RegField field, AppCopy copy) {
    final value = _value(field);
    if (value.isEmpty) {
      final needed = field.required || (field.key == 'pdl_note' && _choice['pdl'] == 'yes');
      return needed ? copy.fieldRequired : null;
    }
    switch (field.kind) {
      case RegKind.digits:
        if (!RegExp(r'^\d+$').hasMatch(value) || (field.length > 0 && value.length != field.length)) {
          return copy.fieldInvalid;
        }
      case RegKind.phone:
        if (value.length != 9) return copy.fieldInvalid;
      case RegKind.email:
        if (value.length > 64 || !_emailPattern.hasMatch(value)) return copy.fieldInvalid;
      case RegKind.money:
        final number = double.tryParse(value);
        if (number == null || number <= 0) return copy.fieldInvalid;
      case RegKind.number:
        final number = double.tryParse(value);
        if (number == null || (field.required && number <= 0)) return copy.fieldInvalid;
      case RegKind.percent:
        final number = double.tryParse(value);
        if (number == null || number < 0 || number > 100) return copy.fieldInvalid;
      case RegKind.text:
        if (field.key == 'dir_passport' &&
            !RegExp(r'^[A-Za-z]{2}\d{7}$').hasMatch(value.replaceAll(' ', ''))) {
          return copy.fieldInvalid;
        }
      default:
        break;
    }
    return null;
  }

  double _shareTotal() {
    var total = 0.0;
    for (final row in _owners) {
      total += double.tryParse(row.share.text.trim()) ?? 0;
    }
    return total;
  }

  Map<String, String> _validate(AppCopy copy) {
    final errors = <String, String>{};
    for (final field in allFields(widget.kind)) {
      final problem = _problem(field, copy);
      if (problem != null) errors[field.key] = problem;
    }
    if (_isBank) {
      if (_interests.isEmpty) errors['interests'] = copy.needInterest;
    } else {
      var ownersOk = _owners.isNotEmpty;
      for (final row in _owners) {
        final taxId = row.taxId.text.trim();
        final share = double.tryParse(row.share.text.trim());
        if (row.name.text.trim().isEmpty ||
            !RegExp(r'^(\d{9}|\d{14})$').hasMatch(taxId) ||
            share == null ||
            share <= 0 ||
            share > 100) {
          ownersOk = false;
        }
      }
      if (_owners.isEmpty) {
        errors['owners'] = copy.needOwner;
      } else if (!ownersOk) {
        errors['owners'] = copy.fieldInvalid;
      } else if (_shareTotal() > 100.0001) {
        errors['owners'] = copy.sharesTooBig;
      }
      for (final row in _licenses) {
        if (row.isEmpty) continue;
        if (row.activity.text.trim().isEmpty || row.number.text.trim().isEmpty || row.issued.isEmpty) {
          errors['licenses'] = copy.fieldInvalid;
        }
      }
    }
    if (!_consentData || !_consentTruth) errors['consents'] = copy.consentsNeeded;
    return errors;
  }

  Map<String, Object?> _collect() {
    final data = <String, Object?>{};
    for (final field in allFields(widget.kind)) {
      var value = _value(field);
      if (value.isEmpty) continue;
      if (field.kind == RegKind.phone) value = '+998$value';
      data[field.key] = value;
    }
    if (_isBank) {
      data['interests'] = _interests.toList();
    } else {
      data['owners'] = [
        for (final row in _owners)
          {
            'kind': row.kind,
            'name': row.name.text.trim(),
            'tax_id': row.taxId.text.trim(),
            'share': row.share.text.trim(),
          },
      ];
      data['licenses'] = [
        for (final row in _licenses)
          if (!row.isEmpty)
            {
              'activity': row.activity.text.trim(),
              'number': row.number.text.trim(),
              'issued_on': row.issued,
              if (row.until.isNotEmpty) 'valid_until': row.until,
            },
      ];
    }
    return data;
  }

  void _scrollToFirstError() {
    final order = <String>[
      for (final section in sectionsFor(widget.kind)) ...[
        if (section.extra == RegExtra.owners) 'owners',
        if (section.extra == RegExtra.licenses) 'licenses',
        if (section.extra == RegExtra.interests) 'interests',
        for (final field in section.fields) field.key,
      ],
      'consents',
    ];
    for (final key in order) {
      if (!_errors.containsKey(key)) continue;
      final context = _anchors[key]?.currentContext;
      if (context != null) {
        Scrollable.ensureVisible(
          context,
          duration: Duration.zero,
          alignment: 0.1,
        );
      }
      return;
    }
  }

  Future<void> _submit() async {
    final copy = LocaleScope.copy(context);
    final api = SessionScope.of(context).api;
    final errors = _validate(copy);
    if (errors.isNotEmpty) {
      setState(() {
        _errors
          ..clear()
          ..addAll(errors);
        _banner = copy.fixFields;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToFirstError());
      return;
    }
    setState(() {
      _errors.clear();
      _banner = null;
      _busy = true;
    });
    try {
      final receipt = await api.submitApplication(kind: widget.kind, data: _collect());
      final queue = <(String, PickedFile)>[
        for (final entry in _files.entries)
          for (final file in entry.value) (entry.key, file),
      ];
      var failed = false;
      for (var i = 0; i < queue.length; i++) {
        if (!mounted) return;
        setState(() => _progress = copy.uploadingProgress(i + 1, queue.length));
        try {
          await api.uploadApplicationDocument(
            id: receipt.id,
            token: receipt.token,
            type: queue[i].$1,
            fileName: queue[i].$2.name,
            bytes: queue[i].$2.bytes,
          );
        } on ApiException {
          failed = true;
        }
      }
      if (!mounted) return;
      setState(() {
        _busy = false;
        _progress = null;
        _sent = (id: receipt.id, code: receipt.code, token: receipt.token, docsFailed: failed);
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _progress = null;
        _banner = copy.known(error.message);
        final field = error.field;
        if (field != null) _errors[field] = copy.fieldInvalid;
      });
      if (error.field != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToFirstError());
      }
    }
  }

  Future<void> _addFile(String type) async {
    final picked = await pickRequestFile();
    if (picked == null || !mounted) return;
    setState(() => _files.putIfAbsent(type, () => []).add(picked));
  }

  Future<void> _pickDate({
    required TextEditingController display,
    required void Function(String iso) set,
    required bool past,
  }) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(1950),
      lastDate: past ? now : DateTime(2100),
    );
    if (picked == null || !mounted) return;
    setState(() {
      display.text = _shown(picked);
      set(_iso(picked));
    });
  }

  @override
  Widget build(BuildContext context) {
    final copy = LocaleScope.copy(context);
    final theme = Theme.of(context);
    final colors = context.colors;
    final sent = _sent;
    if (sent != null) return _SentView(receipt: sent, bank: _isBank);

    final sections = sectionsFor(widget.kind);
    var required = 0;
    var done = 0;
    for (final field in allFields(widget.kind)) {
      if (!field.required) continue;
      required++;
      if (_value(field).isNotEmpty) done++;
    }
    if (_isBank) {
      required++;
      if (_interests.isNotEmpty) done++;
    } else {
      required++;
      if (_owners.any((row) => row.name.text.trim().isNotEmpty && row.share.text.trim().isNotEmpty)) {
        done++;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            key: const Key('register-change-kind'),
            style: backLinkStyle,
            onPressed: () => context.go('/register'),
            icon: const Icon(Icons.arrow_back, size: 18),
            label: Text(copy.changeKind),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          _isBank ? copy.kindBank : copy.kindDeveloper,
          style: theme.textTheme.headlineMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          _isBank ? copy.prepareBank : copy.prepareDeveloper,
          style: theme.textTheme.bodyLarge?.copyWith(color: colors.inkMuted),
        ),
        const SizedBox(height: AppSpacing.lg),
        IBuildCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(copy.whyTitle, style: theme.textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              Text(
                _isBank ? copy.whyBank : copy.whyDeveloper,
                style: theme.textTheme.bodyMedium?.copyWith(color: colors.inkMuted),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        for (var i = 0; i < sections.length; i++) ...[
          _sectionCard(context, copy, i + 1, sections[i]),
          const SizedBox(height: AppSpacing.lg),
        ],
        _documentsCard(context, copy),
        const SizedBox(height: AppSpacing.lg),
        _submitCard(context, copy, done, required),
      ],
    );
  }

  Widget _sectionCard(BuildContext context, AppCopy copy, int number, RegSection section) {
    final theme = Theme.of(context);
    final colors = context.colors;
    return IBuildCard(
      key: Key('register-section-${section.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: colors.accent,
                child: Text(
                  '$number',
                  style: theme.textTheme.labelLarge?.copyWith(color: colors.onAccent),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: Text(copy.say(section.title), style: theme.textTheme.titleLarge)),
            ],
          ),
          if (section.intro != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              copy.say(section.intro!),
              style: theme.textTheme.bodyMedium?.copyWith(color: colors.inkMuted),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          if (section.extra == RegExtra.owners) ...[
            _ownersEditor(context, copy),
            const SizedBox(height: AppSpacing.lg),
          ],
          if (section.extra == RegExtra.licenses) _licensesEditor(context, copy),
          if (section.extra == RegExtra.interests) ...[
            _interestsEditor(context, copy),
            const SizedBox(height: AppSpacing.lg),
          ],
          if (section.fields.isNotEmpty)
            LayoutBuilder(
              builder: (context, constraints) {
                const gap = AppSpacing.lg;
                final columns = constraints.maxWidth >= 640 ? 2 : 1;
                final half = (constraints.maxWidth - gap * (columns - 1)) / columns;
                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    for (final field in section.fields)
                      SizedBox(
                        width: field.wide ? constraints.maxWidth : half,
                        child: KeyedSubtree(
                          key: _anchor(field.key),
                          child: _fieldWidget(context, copy, field),
                        ),
                      ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  String _label(AppCopy copy, RegField field) {
    final text = copy.say(field.label);
    return field.required ? text : '$text (${copy.optionalMark})';
  }

  Widget _fieldWidget(BuildContext context, AppCopy copy, RegField field) {
    final error = _errors[field.key];
    final helper = field.help == null ? null : copy.say(field.help!);
    switch (field.kind) {
      case RegKind.choice:
        return DropdownButtonFormField<String>(
          key: Key('reg-${field.key}'),
          initialValue: _choice[field.key],
          isExpanded: true,
          decoration: InputDecoration(
            labelText: _label(copy, field),
            helperText: helper,
            helperMaxLines: 3,
            errorText: error,
          ),
          items: [
            for (final choice in field.choices)
              DropdownMenuItem(value: choice.code, child: Text(copy.say(choice.label))),
          ],
          onChanged: (value) => setState(() {
            if (value != null) _choice[field.key] = value;
            _errors.remove(field.key);
          }),
        );
      case RegKind.yesNo:
        final theme = Theme.of(context);
        return Column(
          key: Key('reg-${field.key}'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_label(copy, field), style: theme.textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.sm),
            SegmentedButton<String>(
              emptySelectionAllowed: true,
              showSelectedIcon: false,
              segments: [
                for (final choice in field.choices)
                  ButtonSegment(
                    value: choice.code,
                    label: Text(copy.say(choice.label)),
                  ),
              ],
              selected: {if (_choice[field.key] != null) _choice[field.key]!},
              onSelectionChanged: (selection) => setState(() {
                if (selection.isEmpty) {
                  _choice.remove(field.key);
                } else {
                  _choice[field.key] = selection.first;
                }
                _errors.remove(field.key);
              }),
            ),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Text(error, style: theme.textTheme.bodySmall?.copyWith(color: context.colors.danger)),
              ),
          ],
        );
      case RegKind.date:
        final display = _ctl('${field.key}__shown');
        return TextField(
          key: Key('reg-${field.key}'),
          controller: display,
          readOnly: true,
          onTap: () => _pickDate(
            display: display,
            past: _pastDateKeys.contains(field.key),
            set: (iso) {
              _choice[field.key] = iso;
              _errors.remove(field.key);
            },
          ),
          decoration: InputDecoration(
            labelText: _label(copy, field),
            hintText: copy.pickDate,
            errorText: error,
            suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
          ),
        );
      default:
        final controller = _ctl(field.key);
        final isNumber = field.kind == RegKind.money ||
            field.kind == RegKind.number ||
            field.kind == RegKind.percent;
        return TextField(
          key: Key('reg-${field.key}'),
          controller: controller,
          minLines: field.kind == RegKind.long ? 3 : 1,
          maxLines: field.kind == RegKind.long ? 6 : 1,
          keyboardType: switch (field.kind) {
            RegKind.digits => TextInputType.number,
            RegKind.phone => TextInputType.phone,
            RegKind.email => TextInputType.emailAddress,
            RegKind.money || RegKind.number || RegKind.percent => const TextInputType.numberWithOptions(decimal: true),
            _ => TextInputType.text,
          },
          inputFormatters: switch (field.kind) {
            RegKind.digits => [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(field.length),
            ],
            RegKind.phone => [_PhoneFormatter()],
            _ when isNumber => [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              LengthLimitingTextInputFormatter(field.kind == RegKind.percent ? 6 : 18),
            ],
            _ => [LengthLimitingTextInputFormatter(field.max)],
          },
          onChanged: (_) => setState(() => _errors.remove(field.key)),
          decoration: InputDecoration(
            labelText: _label(copy, field),
            helperText: helper,
            helperMaxLines: 3,
            errorText: error,
            prefixText: field.kind == RegKind.phone ? '+998 ' : null,
            suffixText: field.suffix == null ? null : copy.say(field.suffix!),
          ),
        );
    }
  }

  Widget _ownersEditor(BuildContext context, AppCopy copy) {
    final theme = Theme.of(context);
    final colors = context.colors;
    final error = _errors['owners'];
    return KeyedSubtree(
      key: _anchor('owners'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < _owners.length; i++) ...[
            _ownerRow(context, copy, i),
            const SizedBox(height: AppSpacing.md),
          ],
          Row(
            children: [
              OutlinedButton.icon(
                key: const Key('add-owner'),
                onPressed: _owners.length >= 20
                    ? null
                    : () => setState(() => _owners.add(_OwnerRow())),
                icon: const Icon(Icons.add, size: 18),
                label: Text(copy.addOwner),
              ),
              const SizedBox(width: AppSpacing.lg),
              Text(
                copy.sharesTotal(_shareTotal().toStringAsFixed(_shareTotal() % 1 == 0 ? 0 : 2)),
                style: theme.textTheme.bodyMedium?.copyWith(color: colors.inkMuted),
              ),
            ],
          ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Text(error, style: theme.textTheme.bodySmall?.copyWith(color: colors.danger)),
            ),
        ],
      ),
    );
  }

  Widget _ownerRow(BuildContext context, AppCopy copy, int index) {
    final row = _owners[index];
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: context.colors.outline),
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SegmentedButton<String>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(value: 'person', label: Text(copy.ownerPerson)),
                ButtonSegment(value: 'company', label: Text(copy.ownerCompany)),
              ],
              selected: {row.kind},
              onSelectionChanged: (selection) => setState(() => row.kind = selection.first),
            ),
            SizedBox(
              width: 280,
              child: TextField(
                key: Key('owner-name-$index'),
                controller: row.name,
                onChanged: (_) => setState(() => _errors.remove('owners')),
                decoration: InputDecoration(labelText: copy.ownerName),
              ),
            ),
            SizedBox(
              width: 180,
              child: TextField(
                key: Key('owner-tax-$index'),
                controller: row.taxId,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(14),
                ],
                onChanged: (_) => setState(() => _errors.remove('owners')),
                decoration: InputDecoration(labelText: copy.ownerTaxId),
              ),
            ),
            SizedBox(
              width: 110,
              child: TextField(
                key: Key('owner-share-$index'),
                controller: row.share,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  LengthLimitingTextInputFormatter(6),
                ],
                onChanged: (_) => setState(() => _errors.remove('owners')),
                decoration: InputDecoration(labelText: copy.ownerShare),
              ),
            ),
            if (_owners.length > 1)
              IconButton(
                tooltip: copy.removeRow,
                onPressed: () => setState(() {
                  _owners.removeAt(index).dispose();
                  _errors.remove('owners');
                }),
                icon: const Icon(Icons.close),
              ),
          ],
        ),
      ),
    );
  }

  Widget _licensesEditor(BuildContext context, AppCopy copy) {
    final theme = Theme.of(context);
    final error = _errors['licenses'];
    return KeyedSubtree(
      key: _anchor('licenses'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < _licenses.length; i++) ...[
            _licenseRow(context, copy, i),
            const SizedBox(height: AppSpacing.md),
          ],
          OutlinedButton.icon(
            key: const Key('add-license'),
            onPressed: _licenses.length >= 10
                ? null
                : () => setState(() => _licenses.add(_LicenseRow())),
            icon: const Icon(Icons.add, size: 18),
            label: Text(copy.addLicense),
          ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Text(error, style: theme.textTheme.bodySmall?.copyWith(color: context.colors.danger)),
            ),
        ],
      ),
    );
  }

  Widget _licenseRow(BuildContext context, AppCopy copy, int index) {
    final row = _licenses[index];
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: context.colors.outline),
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 260,
              child: TextField(
                key: Key('license-activity-$index'),
                controller: row.activity,
                onChanged: (_) => setState(() => _errors.remove('licenses')),
                decoration: InputDecoration(labelText: copy.licenseActivity),
              ),
            ),
            SizedBox(
              width: 150,
              child: TextField(
                key: Key('license-number-$index'),
                controller: row.number,
                onChanged: (_) => setState(() => _errors.remove('licenses')),
                decoration: InputDecoration(labelText: copy.licenseNumber),
              ),
            ),
            SizedBox(
              width: 160,
              child: TextField(
                controller: row.issuedText,
                readOnly: true,
                onTap: () => _pickDate(
                  display: row.issuedText,
                  past: true,
                  set: (iso) {
                    row.issued = iso;
                    _errors.remove('licenses');
                  },
                ),
                decoration: InputDecoration(labelText: copy.licenseIssued),
              ),
            ),
            SizedBox(
              width: 160,
              child: TextField(
                controller: row.untilText,
                readOnly: true,
                onTap: () => _pickDate(
                  display: row.untilText,
                  past: false,
                  set: (iso) => row.until = iso,
                ),
                decoration: InputDecoration(labelText: copy.licenseUntil),
              ),
            ),
            IconButton(
              tooltip: copy.removeRow,
              onPressed: () => setState(() => _licenses.removeAt(index).dispose()),
              icon: const Icon(Icons.close),
            ),
          ],
        ),
      ),
    );
  }

  Widget _interestsEditor(BuildContext context, AppCopy copy) {
    final theme = Theme.of(context);
    final error = _errors['interests'];
    return KeyedSubtree(
      key: _anchor('interests'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final choice in bankInterestChoices)
                FilterChip(
                  key: Key('interest-${choice.code}'),
                  label: Text(copy.say(choice.label)),
                  selected: _interests.contains(choice.code),
                  onSelected: (on) => setState(() {
                    on ? _interests.add(choice.code) : _interests.remove(choice.code);
                    _errors.remove('interests');
                  }),
                ),
            ],
          ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Text(error, style: theme.textTheme.bodySmall?.copyWith(color: context.colors.danger)),
            ),
        ],
      ),
    );
  }

  Widget _documentsCard(BuildContext context, AppCopy copy) {
    final theme = Theme.of(context);
    final colors = context.colors;
    final docs = docsFor(widget.kind);
    return IBuildCard(
      key: const Key('register-section-documents'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(copy.documentsTitle, style: theme.textTheme.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          Text(
            copy.documentsRule,
            style: theme.textTheme.bodyMedium?.copyWith(color: colors.inkMuted),
          ),
          const SizedBox(height: AppSpacing.lg),
          for (final doc in docs) ...[
            _docRow(context, copy, doc),
            Divider(height: AppSpacing.xl, color: colors.outline),
          ],
        ],
      ),
    );
  }

  Widget _docRow(BuildContext context, AppCopy copy, RegDoc doc) {
    final theme = Theme.of(context);
    final colors = context.colors;
    final files = _files[doc.type] ?? const <PickedFile>[];
    return Column(
      key: Key('doc-${doc.type}'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(copy.say(doc.title), style: theme.textTheme.titleSmall),
            Text(
              doc.required ? copy.docRequired : copy.docOptional,
              style: theme.textTheme.labelSmall?.copyWith(
                color: doc.required ? colors.warning : colors.inkMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          copy.say(doc.hint),
          style: theme.textTheme.bodySmall?.copyWith(color: colors.inkMuted),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (var i = 0; i < files.length; i++)
              InputChip(
                label: Text(files[i].name, overflow: TextOverflow.ellipsis),
                onDeleted: () => setState(() => files.removeAt(i)),
              ),
            OutlinedButton.icon(
              key: Key('doc-add-${doc.type}'),
              onPressed: files.length >= 5 ? null : () => _addFile(doc.type),
              icon: const Icon(Icons.attach_file, size: 18),
              label: Text(copy.addFile),
            ),
          ],
        ),
      ],
    );
  }

  Widget _submitCard(BuildContext context, AppCopy copy, int done, int required) {
    final theme = Theme.of(context);
    final colors = context.colors;
    return IBuildCard(
      key: _anchor('consents'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CheckboxListTile(
            key: const Key('consent-data'),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: _consentData,
            onChanged: (value) => setState(() {
              _consentData = value ?? false;
              _errors.remove('consents');
            }),
            title: Text(copy.consentPersonalData, style: theme.textTheme.bodyMedium),
          ),
          CheckboxListTile(
            key: const Key('consent-truth'),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: _consentTruth,
            onChanged: (value) => setState(() {
              _consentTruth = value ?? false;
              _errors.remove('consents');
            }),
            title: Text(copy.consentTruth, style: theme.textTheme.bodyMedium),
          ),
          if (_errors['consents'] != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text(
                _errors['consents']!,
                style: theme.textTheme.bodySmall?.copyWith(color: colors.danger),
              ),
            ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            copy.filledProgress(done, required),
            key: const Key('register-progress'),
            style: theme.textTheme.bodyMedium?.copyWith(color: colors.inkMuted),
          ),
          if (_banner != null) ...[
            const SizedBox(height: AppSpacing.md),
            ErrorNote(message: _banner!),
          ],
          if (_progress != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(_progress!),
          ],
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(
            key: const Key('register-submit'),
            label: copy.submitApplication,
            busy: _busy,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}

String statusLink(String token) {
  final base = Uri.base;
  final origin = base.scheme == 'http' || base.scheme == 'https' ? base.origin : '';
  return '$origin/#/register/status?t=$token';
}

class _SentView extends StatelessWidget {
  const _SentView({required this.receipt, required this.bank});

  final ({String id, String code, String token, bool docsFailed}) receipt;
  final bool bank;

  @override
  Widget build(BuildContext context) {
    final copy = LocaleScope.copy(context);
    final theme = Theme.of(context);
    final colors = context.colors;
    final link = statusLink(receipt.token);
    return Column(
      key: const Key('register-sent'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(Icons.check_circle_outline, size: 48, color: colors.success),
        const SizedBox(height: AppSpacing.md),
        Text(copy.sentTitle, style: theme.textTheme.headlineMedium),
        const SizedBox(height: AppSpacing.sm),
        Text(copy.sentBody, style: theme.textTheme.bodyLarge?.copyWith(color: colors.inkMuted)),
        const SizedBox(height: AppSpacing.xl),
        IBuildCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(copy.applicationNumber, style: theme.textTheme.labelLarge),
              const SizedBox(height: AppSpacing.xs),
              SelectableText(
                receipt.code,
                key: const Key('sent-code'),
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(copy.statusLink, style: theme.textTheme.labelLarge),
              const SizedBox(height: AppSpacing.xs),
              SelectableText(link, key: const Key('sent-link')),
              const SizedBox(height: AppSpacing.md),
              CopyTextButton(text: link),
              if (receipt.docsFailed) ...[
                const SizedBox(height: AppSpacing.lg),
                ErrorNote(message: copy.docsFailed),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        IBuildCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(copy.nextTitle, style: theme.textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              Text(copy.nextCall),
              const SizedBox(height: AppSpacing.xs),
              Text(copy.nextCheck),
              const SizedBox(height: AppSpacing.xs),
              Text(copy.nextDecision),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            PrimaryButton(
              key: const Key('sent-open-status'),
              label: copy.openStatus,
              onPressed: () => context.go('/register/status?t=${receipt.token}'),
            ),
            TextButton(
              key: const Key('sent-to-login'),
              onPressed: () => context.go('/login'),
              child: Text(copy.backToSignIn),
            ),
          ],
        ),
      ],
    );
  }
}

class CopyTextButton extends StatefulWidget {
  const CopyTextButton({super.key, required this.text});

  final String text;

  @override
  State<CopyTextButton> createState() => CopyTextButtonState();
}

class CopyTextButtonState extends State<CopyTextButton> {
  var _copied = false;

  @override
  Widget build(BuildContext context) {
    final copy = LocaleScope.copy(context);
    return OutlinedButton.icon(
      onPressed: () async {
        await Clipboard.setData(ClipboardData(text: widget.text));
        if (mounted) setState(() => _copied = true);
      },
      icon: Icon(_copied ? Icons.check : Icons.copy, size: 18),
      label: Text(_copied ? copy.copiedText : copy.copyText),
    );
  }
}
