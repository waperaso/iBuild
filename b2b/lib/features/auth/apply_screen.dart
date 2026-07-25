import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/localization/status_labels.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_theme_ext.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_dropdown_field.dart';
import '../../core/widgets/auth_hero_panel.dart';
import '../../core/widgets/b2b_brand.dart';
import '../../core/widgets/confirm_dialogs.dart';
import '../../core/widgets/documents_upload_card.dart';
import '../../core/widgets/language_switcher.dart';
import '../../core/widgets/pill_button.dart';
import '../../l10n/gen/app_localizations.dart';
import '../admin/admin_api.dart';
import 'auth.dart';

/// Verification documents for the application currently being drafted or
/// awaiting review — separate from `org_profile_screen.dart`'s own provider
/// since a fresh applicant isn't `residence_admin` yet and shouldn't depend
/// on that screen ever having been visited.
final _applyDocumentsProvider = FutureProvider((ref) {
  return ref.watch(adminApiProvider).myDocuments();
});

enum _ApplyStep { onboarding, role, details }

/// Where the applicant currently sits: filling out the multi-step form, or
/// looking at the outcome of a submission already on file with the server.
enum _AppPhase { loading, wizard, draft, pending, rejected, approved }

/// Every applicant registers as a property developer — that's the only role
/// this app's residence-admin features are built around. "Also acts as a
/// contractor" isn't a mutually-exclusive alternative (a developer can very
/// well build its own projects), so it's a non-exclusive checkbox rather than
/// a second card; it just decides whether the construction-license field is
/// relevant and which `accountKind` value goes to the server (kept for
/// backward compatibility with existing KYC records and server validation).
const String _kDeveloperAccountKind = 'property_developer';
const String _kContractorAccountKind = 'construction_company';

/// Fixed region choices for the registration form. Stored as stable,
/// human-readable values so the KYC review dialog reads sensibly regardless of
/// the applicant's UI language.
///
/// Deliberately narrowed to the two areas iBuild currently onboards
/// developers in — the rest of the country is filtered out for now rather
/// than offered as a choice that can't actually be acted on yet.
const List<String> kRegionOptions = <String>['Tashkent', 'New Tashkent'];

String _regionLabel(AppLocalizations l10n, String value) => switch (value) {
  'Tashkent' => l10n.applyRegionTashkent,
  'New Tashkent' => l10n.applyRegionNewTashkent,
  _ => value,
};

/// Maps free-text region data from an older submission onto one of the fixed
/// [kRegionOptions], falling back to null when it doesn't match.
String? _regionFromStored(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  return kRegionOptions.contains(value.trim()) ? value.trim() : null;
}

class DeveloperApplyScreen extends ConsumerStatefulWidget {
  const DeveloperApplyScreen({super.key});

  @override
  ConsumerState<DeveloperApplyScreen> createState() =>
      _DeveloperApplyScreenState();
}

class _DeveloperApplyScreenState extends ConsumerState<DeveloperApplyScreen> {
  final _name = TextEditingController();
  final _legalName = TextEditingController();
  final _inn = TextEditingController();
  final _legalForm = TextEditingController(text: 'LLC / ООО');
  final _legalAddress = TextEditingController();
  final _officeAddress = TextEditingController();
  final _registrationNumber = TextEditingController();
  final _email = TextEditingController();
  final _directorName = TextEditingController();
  final _directorPinfl = TextEditingController();
  final _directorPassport = TextEditingController();
  final _directorPhone = TextEditingController();
  final _uboName = TextEditingController();
  final _license = TextEditingController();
  _ApplyStep _step = _ApplyStep.onboarding;
  bool _alsoContractor = false;
  String? _region;
  bool _uboDeclared = false;
  bool _loading = false;
  String? _message;
  String? _uploadingDocType;
  double _docUploadProgress = 0;

  /// Which screen is on display: the wizard itself, or a read-only view of
  /// an application already on file (pending / on review / declined /
  /// approved). Backed by [_developer], which mirrors `GET /developers/me`.
  _AppPhase _phase = _AppPhase.loading;
  Map<String, dynamic>? _developer;
  bool _refreshing = false;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _name.dispose();
    _legalName.dispose();
    _inn.dispose();
    _legalForm.dispose();
    _legalAddress.dispose();
    _officeAddress.dispose();
    _registrationNumber.dispose();
    _email.dispose();
    _directorName.dispose();
    _directorPinfl.dispose();
    _directorPassport.dispose();
    _directorPhone.dispose();
    _uboName.dispose();
    _license.dispose();
    super.dispose();
  }

  /// Paints instantly from whatever was cached in secure storage on the
  /// last successful fetch (so returning to a pending application doesn't
  /// flash the wizard while the network round-trip is in flight), then
  /// reconciles with the server.
  Future<void> _bootstrap() async {
    try {
      final storage = ref.read(secureStorageProvider);
      final cached = await storage.read(
        key: AuthStorageKeys.developerApplicationJson,
      );
      if (cached != null && mounted) {
        try {
          final dev = jsonDecode(cached) as Map<String, dynamic>;
          setState(() {
            _developer = dev;
            _phase = _phaseFor(dev);
          });
        } catch (_) {
          // Corrupt cache — fall through to the network fetch below.
        }
      }
    } catch (_) {
      // Secure-storage read itself failed (e.g. platform channel error on a
      // fresh web reload) — no cached snapshot to paint from, but the
      // network fetch below still runs and can recover on its own.
    }
    await _refreshDeveloper(showSpinner: _developer == null);
  }

  _AppPhase _phaseFor(Map<String, dynamic> dev) =>
      switch (dev['verificationStatus']) {
        'rejected' => _AppPhase.rejected,
        'approved' => _AppPhase.approved,
        'draft' => _AppPhase.draft,
        _ => _AppPhase.pending, // pending or in_review share one view.
      };

  Future<void> _refreshDeveloper({bool showSpinner = false}) async {
    if (!mounted) return;
    setState(() {
      if (showSpinner) _phase = _AppPhase.loading;
      _refreshing = true;
    });
    final storage = ref.read(secureStorageProvider);
    try {
      final dev = await ref.read(adminApiProvider).myDeveloper();
      if (dev == null) {
        await storage.delete(key: AuthStorageKeys.developerApplicationJson);
        if (mounted) {
          setState(() {
            _developer = null;
            _phase = _AppPhase.wizard;
          });
        }
        return;
      }
      await storage.write(
        key: AuthStorageKeys.developerApplicationJson,
        value: jsonEncode(dev),
      );
      if (mounted) {
        setState(() {
          _developer = dev;
          _phase = _phaseFor(dev);
        });
      }
      final status = dev['verificationStatus'] as String?;
      if (status == 'approved') {
        // Flips the cached role to residence_admin so the router redirects
        // out of this screen without requiring a fresh sign-in.
        await ref.read(authControllerProvider.notifier).refreshMe();
      }
      _schedulePoll(status);
    } catch (_) {
      if (_developer == null && mounted) {
        setState(() => _phase = _AppPhase.wizard);
      }
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  /// While a decision is still pending, quietly re-check every 20s so an
  /// admin's decision shows up without the applicant having to tap refresh.
  void _schedulePoll(String? status) {
    _pollTimer?.cancel();
    if (status == 'pending' || status == 'in_review') {
      _pollTimer = Timer(const Duration(seconds: 20), () {
        if (mounted) _refreshDeveloper();
      });
    }
  }

  /// "Resend with new data": hydrates the wizard from the declined
  /// application so the applicant only has to fix what was wrong, then
  /// drops them on the role step (in case the account kind itself needs to
  /// change) instead of the welcome screen.
  void _startResubmit() {
    final dev = _developer;
    if (dev != null) {
      _name.text = dev['name']?.toString() ?? '';
      _legalName.text = dev['legalName']?.toString() ?? '';
      _inn.text = dev['inn']?.toString() ?? '';
      _legalForm.text = dev['legalForm']?.toString() ?? _legalForm.text;
      _legalAddress.text = dev['legalAddress']?.toString() ?? '';
      _officeAddress.text = dev['officeAddress']?.toString() ?? '';
      _region = _regionFromStored(dev['region']?.toString());
      _registrationNumber.text = dev['registrationNumber']?.toString() ?? '';
      _email.text = dev['email']?.toString() ?? '';
      _directorName.text = dev['directorFullName']?.toString() ?? '';
      _directorPinfl.text = dev['directorPinfl']?.toString() ?? '';
      _directorPassport.text = dev['directorPassport']?.toString() ?? '';
      _directorPhone.text = dev['directorPhone']?.toString() ?? '';
      _uboName.text = dev['uboFullName']?.toString() ?? '';
      _license.text = dev['constructionLicense']?.toString() ?? '';
      _uboDeclared = dev['uboDeclared'] == true;
      _alsoContractor =
          dev['accountKind']?.toString() == _kContractorAccountKind;
    }
    setState(() {
      _message = null;
      _step = _ApplyStep.role;
      _phase = _AppPhase.wizard;
    });
  }

  Future<void> _submitForReview() async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _loading = true;
      _message = null;
    });
    try {
      final developer =
          await ref.read(adminApiProvider).submitDeveloperForReview();
      final storage = ref.read(secureStorageProvider);
      await storage.write(
        key: AuthStorageKeys.developerApplicationJson,
        value: jsonEncode(developer),
      );
      if (!mounted) return;
      setState(() {
        _developer = developer;
        _phase = _phaseFor(developer);
      });
      _schedulePoll(developer['verificationStatus'] as String?);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.applySubmitForReviewSuccess)),
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await ref.read(authControllerProvider.notifier).signOut();
        return;
      }
      setState(() => _message = _apiErrorMessage(l10n, e));
    } catch (e) {
      setState(() => _message = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _loading = true;
      _message = null;
    });
    try {
      final developer = await ref
          .read(adminApiProvider)
          .registerDeveloper(
            name: _name.text.trim(),
            legalName: _legalName.text.trim(),
            inn: _inn.text.replaceAll(RegExp(r'\s'), ''),
            accountKind: _alsoContractor
                ? _kContractorAccountKind
                : _kDeveloperAccountKind,
            legalForm: _legalForm.text.trim(),
            legalAddress: _legalAddress.text.trim(),
            directorFullName: _directorName.text.trim(),
            directorPinfl: _directorPinfl.text.replaceAll(RegExp(r'\s'), ''),
            uboDeclared: _uboDeclared,
            registrationNumber: _optional(_registrationNumber),
            officeAddress: _optional(_officeAddress),
            region: _region,
            email: _optional(_email),
            directorPassport: _optional(_directorPassport),
            directorPhone: _optional(_directorPhone),
            uboFullName: _optional(_uboName),
            constructionLicense: _optional(_license),
          );
      final storage = ref.read(secureStorageProvider);
      await storage.write(
        key: AuthStorageKeys.developerApplicationJson,
        value: jsonEncode(developer),
      );
      if (!mounted) return;
      setState(() {
        _developer = developer;
        _phase = _phaseFor(developer);
        _step = _ApplyStep.onboarding;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.applySaveDraftSuccess)),
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await ref.read(authControllerProvider.notifier).signOut();
        return;
      }
      setState(() => _message = _apiErrorMessage(l10n, e));
    } catch (e) {
      setState(() => _message = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Verification-document upload for the in-progress application — the
  /// same `POST /developers/me/documents` used post-approval, but reachable
  /// here too: a moderator can only approve once all 4 required documents
  /// are on file, so applicants must be able to upload them *before*
  /// approval, while still in `draft`/`pending`/`rejected` status.
  Future<void> _uploadDocument(String type) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
      withData: true,
    );
    if (result == null || result.files.isEmpty || !mounted) return;
    final picked = result.files.single;
    final bytes = picked.bytes;
    if (bytes == null) return;

    final l10n = AppLocalizations.of(context);
    // Documents are never sent the instant a file is picked — the applicant
    // reviews a preview (name, size, thumbnail) and must explicitly confirm.
    final confirmed = await confirmDocumentUpload(
      context,
      documentTypeLabel: documentTypeLabel(l10n, type),
      filename: picked.name,
      bytes: bytes,
    );
    if (!confirmed || !mounted) return;

    setState(() {
      _uploadingDocType = type;
      _docUploadProgress = 0;
      _message = null;
    });
    try {
      await ref
          .read(adminApiProvider)
          .uploadDeveloperDocument(
            type: type,
            bytes: bytes,
            filename: picked.name,
            onSendProgress: (sent, total) {
              if (total <= 0 || !mounted) return;
              setState(() => _docUploadProgress = sent / total);
            },
          );
      ref.invalidate(_applyDocumentsProvider);
      if (mounted) setState(() => _message = l10n.orgDocumentUploaded);
    } catch (e) {
      if (mounted) {
        setState(() => _message = l10n.orgDocumentUploadError('$e'));
      }
    } finally {
      if (mounted) setState(() => _uploadingDocType = null);
    }
  }

  static String? _optional(TextEditingController c) {
    final v = c.text.trim();
    return v.isEmpty ? null : v;
  }

  static String _apiErrorMessage(AppLocalizations l10n, DioException e) {
    final data = e.response?.data;
    if (data is Map) {
      final error = data['error'];
      if (error is Map && error['message'] is String) {
        return error['message'] as String;
      }
    }
    if (e.response?.statusCode != null) {
      return l10n.applyRequestFailed('${e.response!.statusCode}');
    }
    return l10n.applyNetworkError;
  }

  String _appBarTitle(AppLocalizations l10n) => switch (_step) {
    _ApplyStep.onboarding => l10n.applyStepWelcome,
    _ApplyStep.role => l10n.applyStepRole,
    _ApplyStep.details => l10n.applyStepDetails,
  };

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    switch (_phase) {
      case _AppPhase.loading:
        return Scaffold(
          backgroundColor: colors.background,
          body: const Center(child: CircularProgressIndicator()),
        );
      case _AppPhase.draft:
        final draftDocs = ref.watch(_applyDocumentsProvider);
        final missingDocs = draftDocs.maybeWhen(
          data: missingRequiredDocumentTypes,
          orElse: () => kRequiredDocumentTypes,
        );
        final docsReady = missingDocs.isEmpty;
        return _statusScaffold(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DocumentsUploadCard(
                documentsAsync: draftDocs,
                uploadingType: _uploadingDocType,
                uploadProgress: _docUploadProgress,
                onUpload: _uploadDocument,
              ),
              const SizedBox(height: AppSpacing.xl),
              _DraftApplicationCard(
                developer: _developer!,
                loading: _loading,
                message: _message,
                canSubmit: docsReady,
                missingDocumentTypes: missingDocs,
                onEdit: _startResubmit,
                onSubmitForReview: (_loading || !docsReady)
                    ? null
                    : _submitForReview,
              ),
            ],
          ),
        );
      case _AppPhase.pending:
        return _statusScaffold(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DocumentsUploadCard(
                documentsAsync: ref.watch(_applyDocumentsProvider),
                uploadingType: _uploadingDocType,
                uploadProgress: _docUploadProgress,
                onUpload: _uploadDocument,
              ),
              const SizedBox(height: AppSpacing.xl),
              _PendingReviewCard(
                developer: _developer!,
                refreshing: _refreshing,
                onRefresh: () => _refreshDeveloper(),
              ),
            ],
          ),
        );
      case _AppPhase.rejected:
        return _statusScaffold(
          child: _RejectedCard(
            developer: _developer!,
            onResubmit: _startResubmit,
            onExit: () async {
              final confirmed = await confirmSignOut(context);
              if (!confirmed || !mounted) return;
              ref.read(authControllerProvider.notifier).signOut();
            },
          ),
        );
      case _AppPhase.approved:
        return _statusScaffold(child: const _ApprovedCard());
      case _AppPhase.wizard:
        return _wizardScaffold(context);
    }
  }

  Widget _statusScaffold({required Widget child}) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        actions: [
          const Padding(
            padding: EdgeInsets.only(right: AppSpacing.sm),
            child: LanguageSwitcher(),
          ),
          TextButton(
            onPressed: () async {
              final confirmed = await confirmSignOut(context);
              if (!confirmed || !mounted) return;
              ref.read(authControllerProvider.notifier).signOut();
            },
            child: Text(l10n.commonSignOut),
          ),
        ],
      ),
      body: _responsiveBody(child),
    );
  }

  /// Centers [child] in a phone-width column on narrow windows; once there's
  /// room for both a real form column and [AuthHeroPanel], switches to a
  /// two-pane desktop layout instead of stranding a mobile-width card in an
  /// otherwise empty desktop canvas.
  Widget _responsiveBody(Widget child, {double wideMaxWidth = 560}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scrollable = SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: child,
        );
        if (constraints.maxWidth < AppBreakpoints.tablet) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: scrollable,
            ),
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AuthHeroPanel(),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: wideMaxWidth),
                  child: scrollable,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _wizardScaffold(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(_appBarTitle(l10n)),
        leading: _step == _ApplyStep.onboarding
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() {
                  _message = null;
                  _step = switch (_step) {
                    _ApplyStep.details => _ApplyStep.role,
                    _ApplyStep.role => _ApplyStep.onboarding,
                    _ApplyStep.onboarding => _ApplyStep.onboarding,
                  };
                }),
              ),
        actions: [
          const Padding(
            padding: EdgeInsets.only(right: AppSpacing.sm),
            child: LanguageSwitcher(),
          ),
          TextButton(
            onPressed: () async {
              final confirmed = await confirmSignOut(context);
              if (!confirmed || !mounted) return;
              ref.read(authControllerProvider.notifier).signOut();
            },
            child: Text(l10n.commonSignOut),
          ),
        ],
      ),
      body: _responsiveBody(
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _StepDots(step: _step),
            const SizedBox(height: AppSpacing.xl),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: switch (_step) {
                _ApplyStep.onboarding => _OnboardingStep(
                  key: const ValueKey('onboarding'),
                  onContinue: () => setState(() => _step = _ApplyStep.role),
                  onHaveAccount: () async {
                    final confirmed = await confirmSignOut(context);
                    if (!confirmed || !mounted) return;
                    ref.read(authControllerProvider.notifier).signOut();
                  },
                ),
                _ApplyStep.role => _RoleStep(
                  key: const ValueKey('role'),
                  alsoContractor: _alsoContractor,
                  onAlsoContractorChanged: (v) =>
                      setState(() => _alsoContractor = v),
                  onContinue: () => setState(() => _step = _ApplyStep.details),
                ),
                _ApplyStep.details => _DetailsStep(
                  key: const ValueKey('details'),
                  alsoContractor: _alsoContractor,
                  name: _name,
                  legalName: _legalName,
                  inn: _inn,
                  legalForm: _legalForm,
                  legalAddress: _legalAddress,
                  officeAddress: _officeAddress,
                  region: _region,
                  onRegionChanged: (v) => setState(() => _region = v),
                  registrationNumber: _registrationNumber,
                  email: _email,
                  directorName: _directorName,
                  directorPinfl: _directorPinfl,
                  directorPassport: _directorPassport,
                  directorPhone: _directorPhone,
                  uboName: _uboName,
                  license: _license,
                  uboDeclared: _uboDeclared,
                  onUboChanged: (v) => setState(() => _uboDeclared = v ?? false),
                  loading: _loading,
                  message: _message,
                  onSubmit: _loading ? null : _submit,
                ),
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Horizontal stepper for the review pipeline: waiting for review -> on
/// review -> decision. Mirrors [_StepDots] visually but labels each stop so
/// the applicant can see exactly where their application sits.
class _ReviewStepper extends StatelessWidget {
  const _ReviewStepper({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    final decided = status == 'approved' || status == 'rejected';
    final activeIndex = switch (status) {
      'pending' => 0,
      'in_review' => 1,
      _ => 2, // approved / rejected
    };
    final labels = [
      l10n.devStatusPending,
      l10n.devStatusInReview,
      decided
          ? developerStatusLabelStandalone(l10n, status)
          : l10n.applyReviewDecisionLabel,
    ];
    final decisionColor = status == 'rejected'
        ? colors.danger
        : (status == 'approved' ? colors.success : colors.ink);

    return Row(
      children: [
        for (var i = 0; i < labels.length; i++) ...[
          Expanded(
            child: Column(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i <= activeIndex
                        ? (i == 2 && decided ? decisionColor : colors.ink)
                        : colors.outline,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  labels[i],
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: i <= activeIndex
                        ? (i == 2 && decided ? decisionColor : colors.ink)
                        : colors.inkMuted,
                    fontWeight: i == activeIndex ? FontWeight.w700 : null,
                  ),
                ),
              ],
            ),
          ),
          if (i != labels.length - 1)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Container(
                width: 24,
                height: 2,
                color: i < activeIndex ? colors.ink : colors.outline,
              ),
            ),
        ],
      ],
    );
  }
}

/// Same lookup as [developerStatusLabel] but importable without the raw
/// value falling back to itself for approved/rejected — kept local so the
/// stepper reads naturally ("Approved" / "Declined") as its final stop.
String developerStatusLabelStandalone(AppLocalizations l10n, String status) =>
    switch (status) {
      'approved' => l10n.devStatusApproved,
      'rejected' => l10n.devStatusRejected,
      _ => status,
    };

/// Shown while the application is saved as `draft` — the applicant can edit
/// or explicitly submit for platform review.
class _DraftApplicationCard extends StatelessWidget {
  const _DraftApplicationCard({
    required this.developer,
    required this.loading,
    required this.message,
    required this.canSubmit,
    required this.missingDocumentTypes,
    required this.onEdit,
    required this.onSubmitForReview,
  });

  final Map<String, dynamic> developer;
  final bool loading;
  final String? message;
  final bool canSubmit;

  /// Raw document `type` values (e.g. `license`) still missing an upload —
  /// named individually in the hint below instead of a generic "some
  /// documents are missing" so the applicant knows exactly what to add.
  final List<String> missingDocumentTypes;
  final VoidCallback onEdit;
  final VoidCallback? onSubmitForReview;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const B2bBrand(),
          const SizedBox(height: AppSpacing.xxl),
          Icon(Icons.edit_note_outlined, size: 40, color: colors.accentSecondary),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.applyDraftTitle,
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.applyDraftSubtitle,
            style: textTheme.bodyMedium?.copyWith(color: colors.inkMuted),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: colors.surfaceAlt,
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  developer['name']?.toString() ?? '',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${l10n.kycInn}: ${developer['inn'] ?? '—'}',
                  style: textTheme.bodySmall?.copyWith(color: colors.inkMuted),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          PillButton(
            label: l10n.applySubmitForReview,
            expand: true,
            loading: loading,
            onPressed: onSubmitForReview,
          ),
          if (!canSubmit && !loading) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              missingDocumentTypes.isEmpty
                  ? l10n.applyDocumentsRequiredHint
                  : l10n.applyDocumentsMissingHint(
                      missingDocumentTypes
                          .map((type) => documentTypeLabel(l10n, type))
                          .join(', '),
                    ),
              style: textTheme.bodySmall?.copyWith(color: colors.danger),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          PillButton(
            label: l10n.applyRejectedResendAction,
            expand: true,
            variant: PillButtonVariant.outline,
            onPressed: loading ? null : onEdit,
          ),
          if (message != null) ...[
            const SizedBox(height: AppSpacing.lg),
            Text(
              message!,
              style: textTheme.bodyMedium?.copyWith(color: colors.danger),
            ),
          ],
        ],
      ),
    );
  }
}

/// Shown while a submitted application is `pending` or `in_review` — the
/// applicant can't do anything but wait (or nudge a refresh); editing
/// reopens only after a decline.
class _PendingReviewCard extends StatelessWidget {
  const _PendingReviewCard({
    required this.developer,
    required this.refreshing,
    required this.onRefresh,
  });

  final Map<String, dynamic> developer;
  final bool refreshing;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final status = developer['verificationStatus']?.toString() ?? 'pending';

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const B2bBrand(),
          const SizedBox(height: AppSpacing.xxl),
          Icon(
            Icons.hourglass_top_outlined,
            size: 40,
            color: colors.accentSecondary,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.applyPendingTitle,
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.applyPendingSubtitle,
            style: textTheme.bodyMedium?.copyWith(color: colors.inkMuted),
          ),
          const SizedBox(height: AppSpacing.xxl),
          _ReviewStepper(status: status),
          const SizedBox(height: AppSpacing.xxl),
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: colors.surfaceAlt,
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  developer['name']?.toString() ?? '',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${l10n.kycInn}: ${developer['inn'] ?? '—'}',
                  style: textTheme.bodySmall?.copyWith(color: colors.inkMuted),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          PillButton(
            label: l10n.applyPendingRefresh,
            expand: true,
            variant: PillButtonVariant.outline,
            loading: refreshing,
            onPressed: refreshing ? null : onRefresh,
          ),
        ],
      ),
    );
  }
}

/// Shown after a decline — surfaces the admin's reason and offers "Edit &
/// resubmit", which hydrates the wizard from this application so the
/// applicant only has to fix what was flagged.
class _RejectedCard extends StatelessWidget {
  const _RejectedCard({
    required this.developer,
    required this.onResubmit,
    required this.onExit,
  });

  final Map<String, dynamic> developer;
  final VoidCallback onResubmit;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final reason = developer['rejectionReason']?.toString();

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const B2bBrand(),
          const SizedBox(height: AppSpacing.xxl),
          Icon(Icons.cancel_outlined, size: 40, color: colors.danger),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.applyRejectedTitle,
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: colors.danger.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppRadii.md),
              border: Border.all(color: colors.danger.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.applyRejectedReasonLabel,
                  style: textTheme.labelMedium?.copyWith(
                    color: colors.danger,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  (reason == null || reason.isEmpty)
                      ? l10n.platformRejectReasonDefault
                      : reason,
                  style: textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          PillButton(
            label: l10n.applyRejectedResendAction,
            expand: true,
            onPressed: onResubmit,
          ),
          const SizedBox(height: AppSpacing.md),
          PillButton(
            label: l10n.commonExit,
            expand: true,
            variant: PillButtonVariant.outline,
            onPressed: onExit,
          ),
        ],
      ),
    );
  }
}

/// Brief transitional view while the cached role refresh (which triggers
/// the router redirect out of this screen) is in flight.
class _ApprovedCard extends StatelessWidget {
  const _ApprovedCard();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const B2bBrand(),
          const SizedBox(height: AppSpacing.xxl),
          Icon(Icons.check_circle_outline, size: 40, color: colors.success),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.applyApprovedTitle,
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.applyApprovedSubtitle,
            style: textTheme.bodyMedium?.copyWith(color: colors.inkMuted),
          ),
          const SizedBox(height: AppSpacing.xl),
          const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}

class _StepDots extends StatelessWidget {
  const _StepDots({required this.step});

  final _ApplyStep step;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final index = _ApplyStep.values.indexOf(step);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_ApplyStep.values.length, (i) {
        final active = i == index;
        final done = i < index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 28 : 8,
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.pill),
            color: active || done ? colors.ink : colors.outline,
          ),
        );
      }),
    );
  }
}

class _OnboardingStep extends StatelessWidget {
  const _OnboardingStep({
    super.key,
    required this.onContinue,
    required this.onHaveAccount,
  });

  final VoidCallback onContinue;
  final VoidCallback onHaveAccount;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const B2bBrand(),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            l10n.applyOnboardingTitle,
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.applyOnboardingSubtitle,
            style: textTheme.bodyMedium?.copyWith(color: colors.inkMuted),
          ),
          const SizedBox(height: AppSpacing.xl),
          _OnboardingPoint(
            icon: Icons.home_work_outlined,
            text: l10n.applyOnboardingPointWorkspace,
          ),
          const SizedBox(height: AppSpacing.md),
          _OnboardingPoint(
            icon: Icons.verified_outlined,
            text: l10n.applyOnboardingPointAccess,
          ),
          const SizedBox(height: AppSpacing.xxl),
          PillButton(
            label: l10n.applyGetStarted,
            expand: true,
            onPressed: onContinue,
          ),
          const SizedBox(height: AppSpacing.md),
          PillButton(
            label: l10n.applyHaveAccount,
            expand: true,
            variant: PillButtonVariant.outline,
            onPressed: onHaveAccount,
          ),
        ],
      ),
    );
  }
}

class _OnboardingPoint extends StatelessWidget {
  const _OnboardingPoint({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: colors.accentSecondary),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    );
  }
}

class _RoleStep extends StatelessWidget {
  const _RoleStep({
    super.key,
    required this.alsoContractor,
    required this.onAlsoContractorChanged,
    required this.onContinue,
  });

  final bool alsoContractor;
  final ValueChanged<bool> onAlsoContractorChanged;
  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.applyRoleTitle,
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.applyRoleSubtitle,
            style: textTheme.bodyMedium?.copyWith(color: colors.inkMuted),
          ),
          const SizedBox(height: AppSpacing.xl),
          const _DeveloperRoleCard(),
          const SizedBox(height: AppSpacing.md),
          _AlsoContractorOption(
            value: alsoContractor,
            onChanged: onAlsoContractorChanged,
          ),
          const SizedBox(height: AppSpacing.xxl),
          PillButton(
            label: l10n.applyContinue,
            expand: true,
            onPressed: onContinue,
          ),
        ],
      ),
    );
  }
}

/// Every applicant is a property developer, full stop — shown as a fixed
/// (non-interactive) card rather than a picker so there's nothing to choose
/// wrong. Whether they also build themselves is the only actual variable,
/// captured separately by [_AlsoContractorOption] below.
class _DeveloperRoleCard extends StatelessWidget {
  const _DeveloperRoleCard();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.accent.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: colors.ink, width: 1.5),
      ),
      child: Row(
        children: [
          Icon(Icons.apartment_outlined, color: colors.ink),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.applyKindDeveloperLabel,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.applyKindDeveloperSubtitle,
                  style: textTheme.bodySmall?.copyWith(
                    color: colors.inkMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Non-exclusive add-on: a developer building its own projects still needs a
/// construction license number, so this just toggles that field on in
/// [_DetailsStep] rather than swapping the whole account type.
class _AlsoContractorOption extends StatelessWidget {
  const _AlsoContractorOption({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);

    return Material(
      color: colors.surfaceAlt,
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: InkWell(
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.engineering_outlined, color: colors.ink),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.applyAlsoContractorLabel,
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.applyAlsoContractorSubtitle,
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Checkbox(value: value, onChanged: (v) => onChanged(v ?? false)),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailsStep extends StatelessWidget {
  const _DetailsStep({
    super.key,
    required this.alsoContractor,
    required this.name,
    required this.legalName,
    required this.inn,
    required this.legalForm,
    required this.legalAddress,
    required this.officeAddress,
    required this.region,
    required this.onRegionChanged,
    required this.registrationNumber,
    required this.email,
    required this.directorName,
    required this.directorPinfl,
    required this.directorPassport,
    required this.directorPhone,
    required this.uboName,
    required this.license,
    required this.uboDeclared,
    required this.onUboChanged,
    required this.loading,
    required this.message,
    required this.onSubmit,
  });

  final bool alsoContractor;
  final TextEditingController name;
  final TextEditingController legalName;
  final TextEditingController inn;
  final TextEditingController legalForm;
  final TextEditingController legalAddress;
  final TextEditingController officeAddress;
  final String? region;
  final ValueChanged<String?> onRegionChanged;
  final TextEditingController registrationNumber;
  final TextEditingController email;
  final TextEditingController directorName;
  final TextEditingController directorPinfl;
  final TextEditingController directorPassport;
  final TextEditingController directorPhone;
  final TextEditingController uboName;
  final TextEditingController license;
  final bool uboDeclared;
  final ValueChanged<bool?> onUboChanged;
  final bool loading;
  final String? message;
  final VoidCallback? onSubmit;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.applyDetailsTitle,
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.applyDetailsSubtitle(
              l10n.applyKindDeveloperLabel.toLowerCase(),
            ),
            style: textTheme.bodyMedium?.copyWith(color: colors.inkMuted),
          ),
          const SizedBox(height: AppSpacing.xl),
          TextField(
            controller: name,
            inputFormatters: [LengthLimitingTextInputFormatter(120)],
            decoration: InputDecoration(
              hintText: l10n.applyBrandName,
              prefixIcon: const Icon(Icons.storefront_outlined),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: legalName,
            inputFormatters: [LengthLimitingTextInputFormatter(200)],
            decoration: InputDecoration(
              hintText: l10n.applyLegalName,
              prefixIcon: const Icon(Icons.gavel_outlined),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: inn,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(9),
            ],
            decoration: InputDecoration(
              hintText: l10n.applyInn,
              prefixIcon: const Icon(Icons.numbers_outlined),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: legalForm,
            inputFormatters: [LengthLimitingTextInputFormatter(60)],
            decoration: InputDecoration(
              hintText: l10n.applyLegalForm,
              prefixIcon: const Icon(Icons.account_balance_outlined),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: registrationNumber,
            inputFormatters: [LengthLimitingTextInputFormatter(40)],
            decoration: InputDecoration(
              hintText: l10n.applyRegistrationNumber,
              prefixIcon: const Icon(Icons.badge_outlined),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: legalAddress,
            maxLines: 2,
            inputFormatters: [LengthLimitingTextInputFormatter(240)],
            decoration: InputDecoration(
              hintText: l10n.applyLegalAddress,
              prefixIcon: const Icon(Icons.location_on_outlined),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: officeAddress,
            maxLines: 2,
            inputFormatters: [LengthLimitingTextInputFormatter(240)],
            decoration: InputDecoration(
              hintText: l10n.applyOfficeAddress,
              prefixIcon: const Icon(Icons.home_work_outlined),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppDropdownField<String>(
            value: region,
            options: kRegionOptions,
            labelBuilder: (option) => _regionLabel(l10n, option),
            label: l10n.applyRegion,
            icon: Icons.map_outlined,
            onChanged: onRegionChanged,
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: email,
            keyboardType: TextInputType.emailAddress,
            inputFormatters: [LengthLimitingTextInputFormatter(120)],
            decoration: InputDecoration(
              hintText: l10n.applyEmail,
              prefixIcon: const Icon(Icons.email_outlined),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(l10n.applyDirectorSectionTitle, style: textTheme.titleMedium),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: directorName,
            inputFormatters: [LengthLimitingTextInputFormatter(120)],
            decoration: InputDecoration(
              hintText: l10n.applyDirectorFullName,
              prefixIcon: const Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: directorPinfl,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(14),
            ],
            decoration: InputDecoration(
              hintText: l10n.applyDirectorPinfl,
              prefixIcon: const Icon(Icons.fingerprint),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: directorPassport,
            inputFormatters: [LengthLimitingTextInputFormatter(30)],
            decoration: InputDecoration(
              hintText: l10n.applyDirectorPassport,
              prefixIcon: const Icon(Icons.credit_card_outlined),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: directorPhone,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-() ]')),
              LengthLimitingTextInputFormatter(20),
            ],
            decoration: InputDecoration(
              hintText: l10n.applyDirectorPhone,
              prefixIcon: const Icon(Icons.phone_outlined),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: uboName,
            inputFormatters: [LengthLimitingTextInputFormatter(120)],
            decoration: InputDecoration(
              hintText: l10n.applyUboName,
              prefixIcon: const Icon(Icons.groups_outlined),
            ),
          ),
          if (alsoContractor) ...[
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: license,
              inputFormatters: [LengthLimitingTextInputFormatter(60)],
              decoration: InputDecoration(
                hintText: l10n.applyLicense,
                prefixIcon: const Icon(Icons.verified_outlined),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: uboDeclared,
                  onChanged: onUboChanged,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text(l10n.applyUboConfirm, style: textTheme.bodySmall),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Tooltip(
                  message: l10n.applyUboHelper,
                  triggerMode: TooltipTriggerMode.tap,
                  showDuration: const Duration(seconds: 8),
                  child: Icon(
                    Icons.help_outline,
                    size: 20,
                    color: colors.inkMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          PillButton(
            label: l10n.applySaveDraft,
            expand: true,
            loading: loading,
            onPressed: onSubmit,
          ),
          if (message != null) ...[
            const SizedBox(height: AppSpacing.lg),
            Text(
              message!,
              style: textTheme.bodyMedium?.copyWith(color: colors.inkMuted),
            ),
          ],
        ],
      ),
    );
  }
}
