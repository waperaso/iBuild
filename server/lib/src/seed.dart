import 'db.dart';
import 'passwords.dart';

/// Local pilot accounts. The password is hashed before it is stored.
const seedAccounts = <({String login, String name, String role, bool active})>[
  (login: 'a.director', name: 'Navoi Developer', role: 'director', active: true),
  (login: 'a.developer', name: 'Tester (full access)', role: 'developer', active: true),
  (login: 'a.contractor', name: 'Navoi Contractor', role: 'contractor', active: true),
  (login: 'a.contractor2', name: 'Engineering Contractor', role: 'contractor', active: true),
  (login: 'a.tech', name: 'Navoi Site Inspector', role: 'tech', active: true),
  (login: 'a.observer', name: 'D. Rakhimov', role: 'observer', active: true),
  (login: 'a.disabled', name: 'Disabled Employee', role: 'observer', active: false),
  (login: 'b.director', name: 'Chilanzar Developer', role: 'director', active: true),
  (login: 'b.contractor', name: 'Chilanzar Contractor', role: 'contractor', active: true),
  (login: 'b.tech', name: 'Chilanzar Site Inspector', role: 'tech', active: true),
  (login: 'b.observer', name: 'S. Yusupova', role: 'observer', active: true),
];

const navoiPlan = '17500000000.00';
const navoiMasonryPlan = '13400000000.00';
const navoiEngineeringPlan = '4100000000.00';
const chilonzorPlan = '1500000000.00';

/// Platform account that sees every company. Existing companies and projects
/// stay as they are. The password is set only when the account is created.
Future<void> ensurePlatformAdmin(AppDatabase db, String password) async {
  final existing = await db.userIdByLogin('a.admin');
  if (existing != null) {
    await db.setPlatformAdmin('a.admin', true);
    return;
  }
  if (password.isEmpty) {
    throw StateError('SEED_PASSWORD is required to create the platform admin');
  }
  final hash = hashPassword(password);
  final company = await db.companyIdByInn('300000000') ??
      await db.insertCompany(
        name: 'iBuild',
        inn: '300000000',
        contact: 'platform@ibuild.uz',
      );
  await db.insertUser(
    companyId: company,
    name: 'iBuild Administrator',
    login: 'a.admin',
    passwordHash: hash,
  );
  await db.setPlatformAdmin('a.admin', true);
}

Future<void> seedIfEmpty(AppDatabase db, String password) async {
  if (password.isEmpty) {
    throw StateError('SEED_PASSWORD is required when SEED_ON_START=true');
  }
  if (await db.companyCount() > 0) return;
  await seedDemo(db, password);
}

/// Fills the anonymized pilot estimate when an older database has companies
/// but no budget lines yet.
/// The two pilot companies and the project each one works on. A seeded login
/// without a project sees an empty cabinet, so these are restored when they go
/// missing instead of being created once and never checked again.
const pilotProjects = <({String inn, String name, String address})>[
  (
    inn: '300000001',
    name: 'Navoi Residences',
    address: '12 Babur Street, Yakkasaray District, Tashkent',
  ),
  (
    inn: '300000002',
    name: 'Chilanzar Residences',
    address: 'Building 4, Block 9, Chilanzar District, Tashkent',
  ),
];

/// Gives every seeded account back the project membership it is supposed to
/// have, creating the project when it is gone. Changes nothing when the stand
/// is already whole.
Future<void> ensurePilotProjects(AppDatabase db) async {
  for (final pilot in pilotProjects) {
    final company = await db.companyIdByInn(pilot.inn);
    if (company == null) continue;
    final projectId = await db.projectIdByName(company, pilot.name) ??
        await db.insertProject(
          companyId: company,
          name: pilot.name,
          address: pilot.address,
        );
    final prefix = pilot.inn == '300000001' ? 'a.' : 'b.';
    for (final account in seedAccounts) {
      if (!account.login.startsWith(prefix)) continue;
      if (!account.active) continue;
      if (account.login == 'a.contractor2') continue;
      final userId = await db.userIdByLogin(account.login);
      if (userId == null) continue;
      if (await db.memberExists(projectId, userId)) continue;
      await db.insertMember(
        projectId: projectId,
        userId: userId,
        role: account.role,
      );
    }
  }
}

Future<void> seedPilotBudgetIfMissing(AppDatabase db, String password) async {
  if (await db.companyCount() == 0) return;
  for (final account in seedAccounts) {
    await db.renameUserByLogin(account.login, account.name);
  }
  await ensurePilotProjects(db);
  final hash = hashPassword(password);
  final navoi = await db.companyIdByInn('300000001');
  final chilonzor = await db.companyIdByInn('300000002');
  if (navoi != null) {
    final navoiProject = await db.projectIdByName(navoi, 'Navoi Residences');
    final dev = await db.userIdByLogin('a.developer') ??
        await db.insertUser(
          companyId: navoi,
          name: 'Tester (full access)',
          login: 'a.developer',
          passwordHash: hash,
        );
    if (navoiProject != null && !await db.memberExists(navoiProject, dev)) {
      await db.insertMember(projectId: navoiProject, userId: dev, role: 'developer');
    }
  }
  if (await db.countOf('budget_items') > 0) return;
  if (navoi == null || chilonzor == null) return;
  final navoiProject = await db.projectIdByName(navoi, 'Navoi Residences');
  final chilonzorProject = await db.projectIdByName(chilonzor, 'Chilanzar Residences');
  if (navoiProject == null || chilonzorProject == null) return;
  final engineer = await db.userIdByLogin('a.contractor2');
  final engineerId = engineer ??
      await db.insertUser(
        companyId: navoi,
        name: 'Engineering Contractor',
        login: 'a.contractor2',
        passwordHash: hash,
      );
  await _writePilotBudget(
    db,
    navoiCompanyId: navoi,
    chilonzorCompanyId: chilonzor,
    navoiProjectId: navoiProject,
    chilonzorProjectId: chilonzorProject,
    navoiMasonId: (await db.userIdByLogin('a.contractor'))!,
    navoiEngineerId: engineerId,
    chilonzorContractorId: (await db.userIdByLogin('b.contractor'))!,
    attachExisting: true,
  );
}

Future<void> seedDemo(AppDatabase db, String password) async {
  final hash = hashPassword(password);
  final navoi = await db.insertCompany(
    name: 'Navoi Development',
    inn: '300000001',
    contact: '+998 71 200 00 01',
  );
  final chilonzor = await db.insertCompany(
    name: 'Chilanzar Stroy',
    inn: '300000002',
    contact: '+998 71 200 00 02',
  );
  final navoiProject = await db.insertProject(
    companyId: navoi,
    name: 'Navoi Residences',
    address: '12 Babur Street, Yakkasaray District, Tashkent',
  );
  final chilonzorProject = await db.insertProject(
    companyId: chilonzor,
    name: 'Chilanzar Residences',
    address: 'Building 4, Block 9, Chilanzar District, Tashkent',
  );

  for (final account in seedAccounts) {
    final companyId = account.login.startsWith('a.') ? navoi : chilonzor;
    final projectId = account.login.startsWith('a.') ? navoiProject : chilonzorProject;
    final userId = await db.insertUser(
      companyId: companyId,
      name: account.name,
      login: account.login,
      passwordHash: hash,
      active: account.active,
    );
    if (!account.active) continue;
    if (account.login == 'a.contractor2') continue;
    await db.insertMember(projectId: projectId, userId: userId, role: account.role);
  }
  await ensurePlatformAdmin(db, password);

  final users = <String, String>{};
  for (final account in seedAccounts) {
    final id = await db.userIdByLogin(account.login);
    if (id != null) users[account.login] = id;
  }
  await _writePilotBudget(
    db,
    navoiCompanyId: navoi,
    chilonzorCompanyId: chilonzor,
    navoiProjectId: navoiProject,
    chilonzorProjectId: chilonzorProject,
    navoiMasonId: users['a.contractor']!,
    navoiEngineerId: users['a.contractor2']!,
    chilonzorContractorId: users['b.contractor']!,
    attachExisting: true,
  );
}

Future<void> _writePilotBudget(
  AppDatabase db, {
  required String navoiCompanyId,
  required String chilonzorCompanyId,
  required String navoiProjectId,
  required String chilonzorProjectId,
  required String navoiMasonId,
  required String navoiEngineerId,
  required String chilonzorContractorId,
  required bool attachExisting,
}) async {
  final masonry = await db.insertFirm(
    companyId: navoiCompanyId,
    name: 'Navoi Stroy Montazh',
    inn: '301000001',
    contact: '+998 90 100 00 01',
  );
  final engineering = await db.insertFirm(
    companyId: navoiCompanyId,
    name: 'Navoi Engineering Networks',
    inn: '301000002',
    contact: '+998 90 100 00 02',
  );
  final chilonzorFirm = await db.insertFirm(
    companyId: chilonzorCompanyId,
    name: 'Chilanzar Podryad',
    inn: '302000001',
    contact: '+998 90 200 00 01',
  );

  if (attachExisting) {
    await db.setMemberFirm(
      projectId: navoiProjectId,
      userId: navoiMasonId,
      contractorFirmId: masonry,
    );
    await db.setMemberFirm(
      projectId: chilonzorProjectId,
      userId: chilonzorContractorId,
      contractorFirmId: chilonzorFirm,
    );
  }
  if (!await db.memberExists(navoiProjectId, navoiEngineerId)) {
    await db.insertMember(
      projectId: navoiProjectId,
      userId: navoiEngineerId,
      role: 'contractor',
      contractorFirmId: engineering,
    );
  } else {
    await db.setMemberFirm(
      projectId: navoiProjectId,
      userId: navoiEngineerId,
      contractorFirmId: engineering,
    );
  }

  const navoiLines = <({String title, String amount, String firm})>[
    (title: 'Foundation', amount: '4800000000.00', firm: 'masonry'),
    (title: 'Masonry and cast-in-place concrete', amount: '6200000000.00', firm: 'masonry'),
    (title: 'Roofing and facade', amount: '2400000000.00', firm: 'masonry'),
    (title: 'Building services', amount: '3150000000.00', firm: 'engineering'),
    (title: 'Landscaping', amount: '950000000.00', firm: 'engineering'),
  ];
  for (final line in navoiLines) {
    await db.insertBudgetLine(
      projectId: navoiProjectId,
      title: line.title,
      amount: line.amount,
      contractorFirmId: line.firm == 'masonry' ? masonry : engineering,
    );
  }
  await db.insertBudgetLine(
    projectId: chilonzorProjectId,
    title: 'Foundation',
    amount: '1000000000.00',
    contractorFirmId: chilonzorFirm,
  );
  await db.insertBudgetLine(
    projectId: chilonzorProjectId,
    title: 'Building services',
    amount: '500000000.00',
    contractorFirmId: chilonzorFirm,
  );
}
