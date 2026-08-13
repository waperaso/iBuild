import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ibuild_core/ibuild_core.dart';

import '../../../core/utils/formatters.dart';
import '../../discovery/providers/filters_providers.dart';
import '../data/ai_models.dart';
import '../data/ai_repository.dart';

/// Lifecycle of the AI smart search panel shared by discovery + map.
/// [needsClarification] is the `blocked: true` answer — the server understood
/// nothing, so there is no result set to show, only "did you mean" hints.
enum AiSearchPhase { idle, thinking, success, needsClarification, error }

class AiSearchState {
  const AiSearchState({
    this.phase = AiSearchPhase.idle,
    this.query = '',
    this.allSteps = const [],
    this.revealedStepCount = 0,
    this.results = const [],
    this.constraints = AiSearchConstraints.empty,
    this.totals,
    this.understood = true,
    this.blocked = false,
    this.suggestions = const [],
    this.unknownTerms = const [],
    this.error,
  });

  final AiSearchPhase phase;
  final String query;
  final List<AiSearchStep> allSteps;
  final int revealedStepCount;
  final List<AiSearchResult> results;
  final AiSearchConstraints constraints;
  final AiSearchTotals? totals;

  /// Whether the server could map the query onto the catalogue vocabulary at
  /// all, and whether it skipped the traversal because of that.
  final bool understood;
  final bool blocked;

  /// "Did you mean" replacements — blocking (the whole `needsClarification`
  /// card) when [blocked], a slim hint row above the results otherwise.
  final List<AiSearchSuggestion> suggestions;
  final List<String> unknownTerms;
  final AiException? error;

  List<AiSearchStep> get revealedSteps =>
      revealedStepCount >= allSteps.length
      ? allSteps
      : allSteps.sublist(0, revealedStepCount);

  bool get isRevealingSteps =>
      phase == AiSearchPhase.thinking && revealedStepCount < allSteps.length;

  /// The one step the status line renders — the latest revealed one.
  AiSearchStep? get currentStep {
    final revealed = revealedSteps;
    return revealed.isEmpty ? null : revealed.last;
  }

  /// `0..1` reveal progress for the status-line progress hint.
  double get revealProgress {
    if (allSteps.isEmpty) return 0;
    return (revealedStepCount / allSteps.length).clamp(0.0, 1.0);
  }

  AiSearchState copyWith({
    AiSearchPhase? phase,
    String? query,
    List<AiSearchStep>? allSteps,
    int? revealedStepCount,
    List<AiSearchResult>? results,
    AiSearchConstraints? constraints,
    AiSearchTotals? totals,
    bool? understood,
    bool? blocked,
    List<AiSearchSuggestion>? suggestions,
    List<String>? unknownTerms,
    AiException? error,
  }) {
    return AiSearchState(
      phase: phase ?? this.phase,
      query: query ?? this.query,
      allSteps: allSteps ?? this.allSteps,
      revealedStepCount: revealedStepCount ?? this.revealedStepCount,
      results: results ?? this.results,
      constraints: constraints ?? this.constraints,
      totals: totals ?? this.totals,
      understood: understood ?? this.understood,
      blocked: blocked ?? this.blocked,
      suggestions: suggestions ?? this.suggestions,
      unknownTerms: unknownTerms ?? this.unknownTerms,
      error: error ?? this.error,
    );
  }
}

/// Deterministic per-search jitter so the same query paces identically on
/// repeat (plan: "stable per search, not random-looking flicker").
int stepDelayMs(String query, int index) =>
    350 + ((query.hashCode + index * 97).abs() % 250);

/// Deterministic phrasing-variant index for a `steps[].code`, `variantCount`
/// wide — see `ai_search_step_labels.dart`.
int stepVariantIndex(String query, String code, int variantCount) {
  if (variantCount <= 0) return 0;
  return (query.hashCode + code.hashCode).abs() % variantCount;
}

ProjectStatus? _projectStatusFromWire(String? wire) => switch (wire) {
  'planned' => ProjectStatus.planned,
  'under_construction' => ProjectStatus.underConstruction,
  'ready' => ProjectStatus.ready,
  'handed_over' => ProjectStatus.handedOver,
  _ => null,
};

/// AI smart search state, shared by the discovery and map tabs (one global
/// provider instance — switching tabs never loses an in-flight or completed
/// search). Also the sole write path into [discoveryFiltersProvider] now
/// that the manual filter sheet is gone (plan Part 2).
///
/// [search] is only ever called from an explicit user action — Enter, the
/// pill's arrow button, a "did you mean" chip, or a constraint chip's "×".
/// Editing the query text never runs a search and never touches this state,
/// so a finished result set stays on screen verbatim while the user retypes.
class AiSearchController extends Notifier<AiSearchState> {
  int _generation = 0;

  @override
  AiSearchState build() => const AiSearchState();

  Future<void> search(
    String query, {
    required String userLanguage,
    Map<String, dynamic>? constraints,
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    final generation = ++_generation;

    state = AiSearchState(phase: AiSearchPhase.thinking, query: trimmed);

    try {
      final response = await ref
          .read(aiRepositoryProvider)
          .search(
            query: trimmed,
            userLanguage: userLanguage,
            constraints: constraints,
          );
      if (generation != _generation) return;

      state = state.copyWith(
        allSteps: response.steps,
        revealedStepCount: 0,
        results: response.blocked ? const [] : response.results,
        constraints: response.constraints,
        totals: response.totals,
        understood: response.understood,
        blocked: response.blocked,
        suggestions: response.suggestions,
        unknownTerms: response.unknownTerms,
      );
      await _revealSteps(generation);
      if (generation != _generation) return;

      // A blocked answer leaves the underlying project grid/pins alone: the
      // server never traversed the catalogue, so there is nothing to project
      // onto [DiscoveryFilters].
      if (response.blocked) {
        state = state.copyWith(phase: AiSearchPhase.needsClarification);
        return;
      }

      state = state.copyWith(phase: AiSearchPhase.success);
      _applyConstraintsToDiscoveryFilters(response.constraints, trimmed);
    } on AiException catch (error) {
      if (generation != _generation) return;
      state = AiSearchState(
        phase: AiSearchPhase.error,
        query: trimmed,
        error: error,
      );
    }
  }

  Future<void> _revealSteps(int generation) async {
    final steps = state.allSteps;
    for (var i = 0; i < steps.length; i++) {
      if (generation != _generation) return;
      state = state.copyWith(revealedStepCount: i + 1);
      await Future<void>.delayed(
        Duration(milliseconds: stepDelayMs(state.query, i)),
      );
    }
  }

  /// Removes one or more constraint keys (a chip's "×") and re-runs the
  /// search with the remaining constraints sent as an override — the server
  /// takes `constraints` as authoritative when present and skips re-parsing.
  Future<void> removeConstraintKeys(
    Set<String> keys, {
    required String userLanguage,
  }) {
    final next = state.constraints.withoutKeys(keys);
    return search(
      state.query,
      userLanguage: userLanguage,
      constraints: next.toJson(),
    );
  }

  void clear() {
    _generation++;
    state = const AiSearchState();
  }

  /// Projects the subset of parsed constraints that [DiscoveryFilters]
  /// actually models (plan: "so the existing `GET /projects` query mapping
  /// needs zero changes") — fields with no filter-sheet equivalent (unit
  /// kind, floor rules, amenities, developer/project name...) only drive the
  /// rich AI results panel, not the underlying project grid/pins.
  void _applyConstraintsToDiscoveryFilters(
    AiSearchConstraints constraints,
    String query,
  ) {
    double? toUsd(double? amount) {
      if (amount == null) return null;
      return constraints.currency == 'UZS'
          ? amount / Formatters.usdToUzsRate
          : amount;
    }

    ref
        .read(discoveryFiltersProvider.notifier)
        .applySheetFilters(
          districts: constraints.district == null
              ? const {}
              : {constraints.district!},
          status: _projectStatusFromWire(constraints.projectStatus),
          minPrice: toUsd(constraints.priceMin),
          maxPrice: toUsd(constraints.priceMax),
          rooms: constraints.rooms?.toSet() ?? const {},
          areaMin: constraints.areaMin,
          offplanOnly: constraints.isOffplan ?? false,
        );
    ref.read(discoveryFiltersProvider.notifier).setSearchText(query);
  }
}

final aiSearchProvider = NotifierProvider<AiSearchController, AiSearchState>(
  AiSearchController.new,
);
