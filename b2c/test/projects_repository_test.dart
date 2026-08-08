import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ibuild_client/features/discovery/data/projects_repository.dart';
import 'package:ibuild_client/features/leads/data/leads_repository.dart';
import 'package:ibuild_client/features/units/data/units_repository.dart';
import 'package:ibuild_core/ibuild_core.dart';

/// Mock-data mode with an empty bundled catalogue (`MockData.projects`).
void main() {
  late ProviderContainer container;

  setUp(() => container = ProviderContainer());
  tearDown(() => container.dispose());

  test('ProjectsRepository returns empty list when catalogue is empty', () async {
    final repo = container.read(projectsRepositoryProvider);

    final buy = await repo.fetchProjects(
      const ProjectFilter(mode: DiscoveryMode.buy),
    );
    expect(buy, isEmpty);

    final rent = await repo.fetchProjects(
      const ProjectFilter(mode: DiscoveryMode.rent),
    );
    expect(rent, isEmpty);
  });

  test('ProjectsRepository paginates empty results', () async {
    final repo = container.read(projectsRepositoryProvider);

    final firstPage = await repo.fetchProjects(const ProjectFilter(limit: 2));
    expect(firstPage, isEmpty);

    final secondPage = await repo.fetchProjects(
      const ProjectFilter(page: 2, limit: 2),
    );
    expect(secondPage, isEmpty);
  });

  test('ProjectsRepository throws for unknown project id', () async {
    final repo = container.read(projectsRepositoryProvider);
    expect(() => repo.fetchProject('missing'), throwsStateError);
  });

  test('UnitsRepository returns null for an unknown id', () async {
    final repo = container.read(unitsRepositoryProvider);
    final found = await repo.fetchUnit('does-not-exist');
    expect(found, isNull);
  });

  test('LeadsRepository.submitLead fabricates a lead in mock mode', () async {
    final repo = container.read(leadsRepositoryProvider);
    final lead = await repo.submitLead(
      projectId: 'prj-test',
      projectName: 'Test Residence',
      intent: LeadIntent.callback,
      contactPhone: '+998 90 000 00 00',
      consent: true,
    );
    expect(lead.projectId, 'prj-test');
    expect(lead.status, LeadStatus.newLead);
    expect(lead.number, startsWith('LD-'));
  });
}
