import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ibuild_core/ibuild_core.dart';

import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_theme_ext.dart';
import '../../../core/widgets/app_chip.dart';
import '../../../core/widgets/constrained_body.dart';
import '../../../core/widgets/pill_button.dart';
import '../../../l10n/enum_labels.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../auth/providers/auth_providers.dart';
import '../../discovery/providers/discovery_providers.dart';
import '../../units/providers/units_providers.dart';
import '../providers/leads_providers.dart';

/// Lead submission form (viewing / callback / off-plan reservation / rent
/// enquiry). Lead-gen only — no payment (plan section 3.6).
class LeadFormScreen extends ConsumerStatefulWidget {
  const LeadFormScreen({
    super.key,
    this.projectId,
    this.unitId,
    this.initialIntent,
  });

  final String? projectId;
  final String? unitId;

  /// Matches [LeadIntent.name] (e.g. `viewing`, `callback`, `buyOffplan`).
  final String? initialIntent;

  @override
  ConsumerState<LeadFormScreen> createState() => _LeadFormScreenState();
}

class _LeadFormScreenState extends ConsumerState<LeadFormScreen> {
  late LeadIntent _intent = LeadIntent.values.firstWhere(
    (i) => i.name == widget.initialIntent,
    orElse: () => LeadIntent.viewing,
  );
  final _phone = TextEditingController(text: '+998 ');
  final _message = TextEditingController();
  bool _submitting = false;
  bool _phonePrefillDone = false;
  bool _consent = false;

  @override
  void dispose() {
    _phone.dispose();
    _message.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_phonePrefillDone) return;
    final user = ref.read(authControllerProvider).value;
    if (user?.phone != null && user!.phone.isNotEmpty) {
      _phone.text = user.phone;
    }
    _phonePrefillDone = true;
  }

  Future<void> _submit() async {
    if (_submitting || !_consent) return;
    setState(() => _submitting = true);
    final l10n = AppLocalizations.of(context);

    try {
      final projectId = widget.projectId ?? 'prj-1';
      final project = widget.projectId != null
          ? await ref.read(projectByIdProvider(projectId).future)
          : null;
      final unit = widget.unitId != null
          ? await ref.read(unitByIdProvider(widget.unitId!).future)
          : null;

      final lead = await ref
          .read(leadsProvider.notifier)
          .submit(
            projectId: project?.id ?? projectId,
            projectName: project?.name ?? l10n.iBuildPartner,
            unitId: unit?.id,
            unitLabel: unit == null ? null : l10n.unitNumberTitle(unit.number),
            intent: _intent,
            contactPhone: _phone.text,
            message: _message.text.isEmpty ? null : _message.text,
            consent: _consent,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.leadSubmittedSnackbar(lead.number))),
      );
      context.go('/inquiries');
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.somethingWentWrong)));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/home'),
        ),
        title: Text(l10n.newInquiryTitle),
      ),
      body: ConstrainedBody(
        maxWidth: 560,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Text(l10n.whatDoYouNeed, style: textTheme.titleMedium),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final intent in LeadIntent.values)
                  AppChip(
                    label: intent.label(context),
                    selected: _intent == intent,
                    onTap: () => setState(() => _intent = intent),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(l10n.contactPhoneLabel, style: textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d+\s()-]')),
                LengthLimitingTextInputFormatter(20),
              ],
              decoration: InputDecoration(hintText: l10n.phoneHint),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(l10n.commentOptionalLabel, style: textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _message,
              maxLines: 4,
              maxLength: 500,
              inputFormatters: [LengthLimitingTextInputFormatter(500)],
              decoration: InputDecoration(
                hintText: l10n.commentHint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  borderSide: BorderSide(color: colors.outline),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  borderSide: BorderSide(color: colors.outline),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            _ConsentCheckbox(
              value: _consent,
              onChanged: (v) => setState(() => _consent = v),
            ),
            const SizedBox(height: AppSpacing.lg),
            Tooltip(
              message: _consent ? '' : l10n.piiConsentRequiredError,
              child: PillButton(
                label: l10n.submitInquiry,
                expand: true,
                onPressed: (_submitting || !_consent) ? null : _submit,
                loading: _submitting,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Required PII-processing consent checkbox (plan section 11 / Track A.2)
/// — the server rejects `POST /v1/leads` with `422` unless `consent: true`
/// is sent, so this must be checked before [PillButton.onPressed] is enabled.
class _ConsentCheckbox extends StatelessWidget {
  const _ConsentCheckbox({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);

    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: value,
              onChanged: (v) => onChanged(v ?? false),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm + 2),
                child: Text(
                  l10n.piiConsentLabel,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.inkMuted,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
