import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/locale_controller.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_theme_ext.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../discovery/providers/filters_providers.dart';
import '../../data/ai_models.dart';
import '../../data/ai_repository.dart';
import '../../providers/ai_search_providers.dart';
import 'ai_info_sheet.dart';
import 'ai_mark_badge.dart';

/// How long typing has to stop before `/ai/search/suggest` is asked for a
/// completion. Short enough to feel instant, long enough that a fast typist
/// never generates a request per keystroke.
const Duration _suggestDebounce = Duration(milliseconds: 180);

/// After this many Tab/arrow accepts without manual edits, inline suggest pauses
/// until the user types again — stops endless completion chains.
const _maxConsecutiveAccepts = 2;

/// The single AI-driven search pill that replaces the old free-text search +
/// manual-filter icon row (plan Part 2). Shared verbatim by
/// `discovery_screen.dart` and `map_screen.dart` — both read/write the same
/// [aiSearchProvider], so switching tabs never loses a search.
///
/// Typing only ever asks `/ai/search/suggest` for an inline ghost completion
/// (accepted with Tab, right-arrow at the end of the line, or the "⇥"
/// affordance in the pill). A real search runs on explicit submit only —
/// Enter or the arrow button — so editing the query never re-runs the
/// previous search or disturbs the results already on screen.
class AiSearchBar extends ConsumerStatefulWidget {
  const AiSearchBar({super.key});

  @override
  ConsumerState<AiSearchBar> createState() => _AiSearchBarState();
}

class _AiSearchBarState extends ConsumerState<AiSearchBar> {
  late final _GhostCompletionController _controller;
  final FocusNode _focusNode = FocusNode();
  Timer? _suggestTimer;
  int _suggestGeneration = 0;

  /// Tab/arrow accepts since the last manual edit — caps chained ghost suggests.
  int _acceptChainDepth = 0;

  /// The whole query the current ghost completes to (`typed + ghost`). Kept so
  /// typing the predicted characters just shortens the ghost — and deleting
  /// them grows it back — instead of dropping it and asking the server again.
  String? _completionFull;

  @override
  void initState() {
    super.initState();
    _controller = _GhostCompletionController(
      text: ref.read(aiSearchProvider).query,
    );
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _suggestTimer?.cancel();
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus) _clearGhost();
  }

  /// Drops the ghost completion and invalidates any in-flight suggest call so
  /// a late response can never paint a stale continuation.
  void _clearGhost() {
    _suggestTimer?.cancel();
    _suggestGeneration++;
    _completionFull = null;
    if (_controller.ghost.isEmpty) return;
    setState(() => _controller.ghost = '');
  }

  void _onTextChanged(String text) {
    if (text.isEmpty) {
      _acceptChainDepth = 0;
      _clearGhost();
      return;
    }
    final full = _completionFull;
    if (full != null &&
        full.length > text.length &&
        text.isNotEmpty &&
        full.startsWith(text)) {
      setState(() => _controller.ghost = full.substring(text.length));
      return;
    }
    _acceptChainDepth = 0;
    _clearGhost();
    _scheduleSuggest();
  }

  void _scheduleSuggest() {
    _suggestTimer?.cancel();
    if (_acceptChainDepth >= _maxConsecutiveAccepts) return;
    if (!_shouldSuggest(_controller.text)) return;
    _suggestTimer = Timer(_suggestDebounce, _requestSuggest);
  }

  /// The user's "после двух слов": worth a completion once there are two words
  /// to go on, or one token long enough to be more than a stray letter.
  static bool _shouldSuggest(String text) {
    final words = text
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
    if (words.isEmpty) return false;
    return words.length >= 2 || words.last.length >= 3;
  }

  Future<void> _requestSuggest() async {
    final base = _controller.text;
    if (!_shouldSuggest(base)) return;
    final generation = ++_suggestGeneration;
    final language = ref.read(localeControllerProvider).languageCode;
    try {
      final response = await ref
          .read(aiRepositoryProvider)
          .suggest(query: base, userLanguage: language);
      if (!mounted || generation != _suggestGeneration) return;
      if (_controller.text != base || !_focusNode.hasFocus) return;
      _applyCompletion(response, base);
    } on AiException {
      // Suggest is a convenience, not a feature the search depends on: a
      // failure (offline, 404 on an older server, quota-free route disabled)
      // leaves the field exactly as the user typed it, with no error UI.
    }
  }

  void _applyCompletion(AiSearchSuggestResponse response, String base) {
    final full = response.completionFull;
    final tail = response.completion;
    final ghost = full != null && full.length > base.length && full.startsWith(base)
        ? full.substring(base.length)
        : (tail == null || tail.isEmpty ? null : tail);
    if (ghost == null || ghost.trim().isEmpty) return;
    _completionFull = base + ghost;
    setState(() => _controller.ghost = ghost);
  }

  /// Appends the ghost completion and parks the caret at the end — never
  /// submits, so the user can keep refining before searching.
  void _acceptCompletion() {
    final ghost = _controller.ghost;
    if (ghost.isEmpty) return;
    final next = _controller.text + ghost;
    _clearGhost();
    _acceptChainDepth++;
    _controller.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: next.length),
    );
    if (_acceptChainDepth < _maxConsecutiveAccepts) {
      _scheduleSuggest();
    }
  }

  bool get _caretAtEnd {
    final selection = _controller.selection;
    return selection.isCollapsed &&
        selection.baseOffset == _controller.text.length;
  }

  /// Tab has to be intercepted above the field: left to the default handler it
  /// would move focus out of the pill instead of accepting the completion.
  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent || _controller.ghost.isEmpty) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.tab ||
        (key == LogicalKeyboardKey.arrowRight && _caretAtEnd)) {
      _acceptCompletion();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.escape) {
      _clearGhost();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _submit() {
    final text = _controller.text;
    if (text.trim().isEmpty) return;
    _clearGhost();
    final language = ref.read(localeControllerProvider).languageCode;
    ref.read(aiSearchProvider.notifier).search(text, userLanguage: language);
    _focusNode.unfocus();
  }

  void _clear() {
    _acceptChainDepth = 0;
    _clearGhost();
    _controller.clear();
    ref.read(aiSearchProvider.notifier).clear();
    final filters = ref.read(discoveryFiltersProvider.notifier);
    filters.clearSheetFilters();
    filters.setSearchText('');
    _focusNode.unfocus();
  }

  void _openInfo() {
    final l10n = AppLocalizations.of(context);
    showAiInfoSheet(
      context,
      title: l10n.aiSearchInfoTitle,
      description: l10n.aiSearchInfoBody,
      examples: [
        l10n.aiSearchExample1,
        l10n.aiSearchExample2,
        l10n.aiSearchExample3,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    final hasActiveSearch = ref.watch(
      aiSearchProvider.select((s) => s.phase != AiSearchPhase.idle),
    );

    // A "did you mean" chip, an example chip or a clear from elsewhere rewrites
    // the query outside this widget — mirror it into the field. Only fires when
    // the searched query actually changes, so it never fights the user's typing.
    ref.listen(aiSearchProvider.select((s) => s.query), (_, query) {
      if (query == _controller.text) return;
      _acceptChainDepth = 0;
      _clearGhost();
      _controller.value = TextEditingValue(
        text: query,
        selection: TextSelection.collapsed(offset: query.length),
      );
    });

    final pill = BorderRadius.circular(AppRadii.pill);

    return Row(
      children: [
        Expanded(
          child: Material(
            color: colors.surface,
            borderRadius: pill,
            clipBehavior: Clip.antiAlias,
            child: Focus(
              canRequestFocus: false,
              skipTraversal: true,
              onKeyEvent: _onKeyEvent,
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                textInputAction: TextInputAction.search,
                onChanged: _onTextChanged,
                onSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  hintText: l10n.aiSearchHint,
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(left: AppSpacing.md),
                    child: Center(
                      widthFactor: 1,
                      child: AiMarkBadge(compact: true),
                    ),
                  ),
                  prefixIconConstraints: const BoxConstraints(
                    minWidth: 0,
                    minHeight: 0,
                  ),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_controller.ghost.isNotEmpty)
                        _AcceptCompletionButton(onTap: _acceptCompletion),
                      hasActiveSearch
                          ? IconButton(
                              tooltip: l10n.aiSearchClearTooltip,
                              onPressed: _clear,
                              icon: Icon(Icons.close, color: colors.inkMuted),
                            )
                          : IconButton(
                              tooltip: l10n.aiSearchSubmitTooltip,
                              onPressed: _submit,
                              icon: Icon(
                                Icons.arrow_forward_rounded,
                                color: colors.inkMuted,
                              ),
                            ),
                    ],
                  ),
                  suffixIconConstraints: const BoxConstraints(
                    minWidth: 0,
                    minHeight: 0,
                  ),
                  filled: true,
                  fillColor: colors.surface,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.md,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: pill,
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: pill,
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: pill,
                    borderSide: BorderSide(
                      color: colors.accent.withValues(alpha: 0.45),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Material(
          color: colors.surface,
          shape: const CircleBorder(),
          child: IconButton(
            tooltip: l10n.aiSearchInfoTooltip,
            onPressed: _openInfo,
            icon: Icon(Icons.info_outline, color: colors.ink),
          ),
        ),
      ],
    );
  }
}

/// The "⇥" affordance inside the pill: the only way to accept a completion on
/// touch devices, and a discoverability hint for the Tab key on desktop.
class _AcceptCompletionButton extends StatelessWidget {
  const _AcceptCompletionButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);

    return Semantics(
      button: true,
      label: l10n.aiSearchTabAcceptLabel,
      child: Tooltip(
        message: l10n.aiSearchTabHintTooltip,
        child: InkWell(
          // Must not take focus: the field has to keep it so the accepted
          // completion lands in a still-editable query.
          canRequestFocus: false,
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.pill),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: colors.accent.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AppRadii.pill),
              border: Border.all(color: colors.outline),
            ),
            child: Icon(
              Icons.keyboard_tab_rounded,
              size: 16,
              color: colors.accent,
            ),
          ),
        ),
      ),
    );
  }
}

/// Paints [ghost] as dimmed text continuing the user's own query inside the
/// same [TextField]. Extending the rendered span (rather than stacking a
/// second `Text` behind the field) is what keeps the completion aligned to the
/// pixel at every width, and correctly aligned once a long query starts
/// scrolling the field horizontally.
class _GhostCompletionController extends TextEditingController {
  _GhostCompletionController({super.text});

  String ghost = '';

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final base = super.buildTextSpan(
      context: context,
      style: style,
      withComposing: withComposing,
    );
    if (ghost.isEmpty || text.isEmpty) return base;
    return TextSpan(
      children: [
        base,
        TextSpan(
          text: ghost,
          style: (style ?? const TextStyle()).copyWith(
            color: context.colors.inkMuted.withValues(alpha: 0.55),
          ),
        ),
      ],
    );
  }
}
