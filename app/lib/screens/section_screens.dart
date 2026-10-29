import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../api.dart';
import '../l10n.dart';
import '../models.dart';
import '../object_passport.dart';
import '../session_scope.dart';
import '../theme.dart';
import '../widgets.dart';
import 'loan_panels.dart';
import 'project_screen.dart';

class BudgetPage extends StatelessWidget {
  const BudgetPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _ProjectPage(
      title: LocaleScope.copy(context).budget,
      builder: (context, data, reload) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SourcesUsesTable(desk: data.desk),
          const SizedBox(height: AppSpacing.xl),
          BudgetTools(project: data.project, firms: data.firms, onChanged: reload),
          const SizedBox(height: AppSpacing.xl),
          BudgetSection(
            project: data.project,
            budget: data.budget,
            firms: data.firms,
            onChanged: reload,
          ),
        ],
      ),
    );
  }
}

class DocumentsPage extends StatelessWidget {
  const DocumentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _ProjectPage(
      title: LocaleScope.copy(context).documents,
      builder: (context, data, reload) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IBuildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(LocaleScope.copy(context).place(data.project.name), style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: AppSpacing.sm),
                Text(data.project.address),
                const SizedBox(height: AppSpacing.lg),
                ObjectPassport(project: data.project, documents: data.documents),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          DocumentsPanel(project: data.project, desk: data.desk, onChanged: reload),
        ],
      ),
    );
  }
}

class PeoplePage extends StatelessWidget {
  const PeoplePage({super.key});

  @override
  Widget build(BuildContext context) {
    return _ProjectPage(
      title: LocaleScope.copy(context).people,
      builder: (context, data, reload) => MembersSection(
        project: data.project,
        members: data.members,
        firms: data.firms,
        onChanged: reload,
      ),
    );
  }
}

class _Desk {
  const _Desk({
    required this.project,
    required this.budget,
    required this.members,
    required this.firms,
    required this.documents,
    required this.desk,
  });

  final ProjectSummary project;
  final BudgetSnapshot budget;
  final List<ProjectMember> members;
  final List<ContractorFirm> firms;
  final List<ProjectDocument> documents;
  final LoanDesk desk;
}

class _ProjectPage extends StatefulWidget {
  const _ProjectPage({required this.title, required this.builder});

  final String title;
  final Widget Function(BuildContext context, _Desk data, Future<void> Function() reload) builder;

  @override
  State<_ProjectPage> createState() => _ProjectPageState();
}

class _ProjectPageState extends State<_ProjectPage> {
  _Desk? _data;
  var _loading = true;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _load();
  }

  var _started = false;

  Future<void> _load() async {
    final session = SessionScope.of(context);
    final project = session.focusedProject;
    if (project == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final fresh = await session.api.project(project.id);
      final budget = await session.api.budget(project.id);
      final members = await session.api.members(project.id);
      final documents = await session.api.projectDocuments(project.id);
      final firms = fresh.myRole == AppRole.director ||
              fresh.myRole == AppRole.developer ||
              fresh.myRole == AppRole.observer
          ? await session.api.firms()
          : const <ContractorFirm>[];
      LoanDesk desk = LoanDesk.empty;
      try {
        desk = await session.api.loan(project.id);
      } on ApiException {
        desk = LoanDesk.empty;
      }
      if (!mounted) return;
      session.rememberProject(fresh);
      setState(() {
        _data = _Desk(
          project: fresh,
          budget: budget,
          members: members,
          firms: firms,
          documents: documents,
          desk: desk,
        );
        _loading = false;
        _error = null;
      });
    } on ApiException catch (error) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = error.message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final open = SessionScope.of(context).focusedProject;
    final copy = LocaleScope.copy(context);
    return ScreenScroll(
      children: [
        Text(widget.title, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: AppSpacing.xl),
        if (open == null) ...[
          EmptyState(
            title: copy.openProject,
            body: copy.openProjectBody,
          ),
          const SizedBox(height: AppSpacing.md),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => context.go('/projects'),
              child: Text(copy.backToProjects),
            ),
          ),
        ]
        else if (_loading)
          const SizedBox.shrink()
        else if (_error != null)
          Text(copy.known(_error!))
        else
          widget.builder(context, _data!, _load),
      ],
    );
  }
}
