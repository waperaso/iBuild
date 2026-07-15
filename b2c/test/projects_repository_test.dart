import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ibuild_client/features/discovery/data/projects_repository.dart';
import 'package:ibuild_client/features/leads/data/leads_repository.dart';
import 'package:ibuild_client/features/units/data/units_repository.dart';
import 'package:ibuild_client/models/mock_data.dart';
import 'package:ibuild_core/ibuild_core.dart';

/// These exercise the mock-data seam (`Env.useMockData` defaults to `true`
/// in tests, see `lib/core/config/env.dart`) so they run hermetically without
/// the dev server in `../server`.
void main() {
  late ProviderContainer container;

  setUp(() => container = ProviderContainer());
  tearDown(() => container.dispose());

  test('ProjectsRepository filters by discovery mode', () async {
    final repo = container.read(projectsRepositoryProvider);

    final buy = await repo.fetchProjects(
      const ProjectFilter(mode: DiscoveryMode.buy),
    );
    expect(buy, isNotEmpty);
    expect(buy.every((p) => p.type == ProjectType.residentialComplex), isTrue);

    final rent = await repo.fetchProjects(
      const ProjectFilter(mode: DiscoveryMode.rent),
    );
    expect(rent.every((p) => p.type == ProjectType.businessCentre), isTrue);
  });

  test(
    'ProjectsRepository applies search, district and status filters',
    () async {
      final repo = container.read(projectsRepositoryProvider);
      final target = MockData.projects.first;

      final bySearch = await repo.fetchProjects(
        ProjectFilter(search: target.name),
      );
      expect(bySearch.any((p) => p.id == target.id), isTrue);

      final byDistrict = await repo.fetchProjects(
        ProjectFilter(district: target.district),
      );
      expect(byDistrict, isNotEmpty);
      expect(byDistrict.every((p) => p.district == target.district), isTrue);

      final byStatus = await repo.fetchProjects(
        const ProjectFilter(status: ProjectStatus.underConstruction),
      );
      expect(
        byStatus.every((p) => p.status == ProjectStatus.underConstruction),
        isTrue,
      );
    },
  );

  test('ProjectsRepository pages results', () async {
    final repo = container.read(projectsRepositoryProvider);

    final firstPage = await repo.fetchProjects(const ProjectFilter(limit: 2));
    expect(firstPage.length, 2);

    final secondPage = await repo.fetchProjects(
      const ProjectFilter(page: 2, limit: 2),
    );
    expect(secondPage, isNotEmpty);
    expect(
      firstPage
          .map((p) => p.id)
          .toSet()
          .intersection(secondPage.map((p) => p.id).toSet()),
      isEmpty,
    );
  });

  test('ProjectsRepository fetches a single project by id', () async {
    final repo = container.read(projectsRepositoryProvider);
    final project = await repo.fetchProject(MockData.projects.first.id);
    expect(project.id, MockData.projects.first.id);
  });

  test('UnitsRepository finds a unit nested inside mock projects', () async {
    final repo = container.read(unitsRepositoryProvider);
    final firstUnit = MockData.projects.first.buildings.first.units.first;

    final found = await repo.fetchUnit(firstUnit.id);
    expect(found, isNotNull);
    expect(found!.id, firstUnit.id);
  });

  test('UnitsRepository returns null for an unknown id', () async {
    final repo = container.read(unitsRepositoryProvider);
    final found = await repo.fetchUnit('does-not-exist');
    expect(found, isNull);
  });

  test('LeadsRepository.submitLead fabricates a lead in mock mode', () async {
    final repo = container.read(leadsRepositoryProvider);
    final lead = await repo.submitLead(
      projectId: 'prj-1',
      projectName: 'Aaradhya Homes',
      intent: LeadIntent.callback,
      contactPhone: '+998 90 000 00 00',
      consent: true,
    );
    expect(lead.projectId, 'prj-1');
    expect(lead.status, LeadStatus.newLead);
    expect(lead.number, startsWith('LD-'));
  });
}
