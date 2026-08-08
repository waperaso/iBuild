import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ibuild_client/features/discovery/data/projects_repository.dart';
import 'package:ibuild_client/features/leads/data/leads_repository.dart';
import 'package:ibuild_client/features/units/data/units_repository.dart';
import 'package:ibuild_client/models/mock_data.dart';
import 'package:ibuild_core/ibuild_core.dart';

void main() {
  late ProviderContainer container;

  setUp(() => container = ProviderContainer());
  tearDown(() => container.dispose());

  test('ProjectsRepository returns NestOne for buy mode', () async {
    final repo = container.read(projectsRepositoryProvider);
    final buy = await repo.fetchProjects(
      const ProjectFilter(mode: DiscoveryMode.buy),
    );
    expect(buy, isNotEmpty);
    expect(buy.first.name, 'NestOne');
  });

  test('ProjectsRepository returns NestOne for rent mode', () async {
    final repo = container.read(projectsRepositoryProvider);
    final rent = await repo.fetchProjects(
      const ProjectFilter(mode: DiscoveryMode.rent),
    );
    expect(rent.any((p) => p.name == 'NestOne'), isTrue);
  });

  test('ProjectsRepository fetches NestOne by id', () async {
    final repo = container.read(projectsRepositoryProvider);
    final project = await repo.fetchProject('prj-nestone');
    expect(project.name, 'NestOne');
    expect(project.lat, closeTo(41.31215655652716, 0.0001));
  });

  test('UnitsRepository finds a NestOne apartment', () async {
    final repo = container.read(unitsRepositoryProvider);
    final found = await repo.fetchUnit('bld-nestone-living-u11');
    expect(found, isNotNull);
    expect(found!.kind, UnitKind.apartment);
  });

  test('LeadsRepository.submitLead fabricates a lead in mock mode', () async {
    final repo = container.read(leadsRepositoryProvider);
    final lead = await repo.submitLead(
      projectId: 'prj-nestone',
      projectName: 'NestOne',
      intent: LeadIntent.callback,
      contactPhone: '+998 90 000 00 00',
      consent: true,
    );
    expect(lead.projectId, 'prj-nestone');
    expect(lead.status, LeadStatus.newLead);
  });
}
