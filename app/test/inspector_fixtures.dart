// Sample data for the site inspector (the technical supervisor): two projects,
// a queue of tranches waiting on their check, and two site visits. Shared by
// the widget test and the screenshot harness under tool/.
import 'package:ibuild/models.dart';

import 'support.dart';

class InspectorApi extends FakeApi {
  InspectorApi() : super(user: _me, projects: _projects, lines: _lines);

  @override
  Future<List<FundingRequest>> requests() async => _requests;

  @override
  Future<FundingRequest> request(String id) async {
    for (final item in _requests) {
      if (item.id == id) return item;
    }
    return _requests.first;
  }

  @override
  Future<List<NoticeItem>> notices() async => _notices;

  @override
  Future<List<InspectionOrder>> inspections() async => _orders;

  @override
  Future<List<ProjectMember>> members(String projectId) async => _members;
}

const _me = UserProfile(
  id: 'user-tech',
  name: 'А. Каримов',
  login: 'a.karimov',
  companyId: 'company-1',
  companyName: 'Навои Девелопмент',
  active: true,
  memberships: [
    Membership(projectId: 'project-1', role: AppRole.tech),
    Membership(projectId: 'project-2', role: AppRole.tech),
  ],
);

const _projects = [
  ProjectSummary(
    id: 'project-1',
    companyId: 'company-1',
    name: 'ЖК Навои',
    address: 'Ташкент, улица Бабура, 12',
    active: true,
    myRole: AppRole.tech,
    plan: '42500000000.00',
    reserved: '6400000000.00',
    paid: '18900000000.00',
    available: '17200000000.00',
  ),
  ProjectSummary(
    id: 'project-2',
    companyId: 'company-1',
    name: 'ЖК Чилонзор',
    address: 'Ташкент, улица Мукими, 4',
    active: true,
    myRole: AppRole.tech,
    plan: '28000000000.00',
    reserved: '2100000000.00',
    paid: '9400000000.00',
    available: '16500000000.00',
  ),
];

const _lines = [
  BudgetLine(
    id: 'line-1',
    title: 'Работы нулевого цикла',
    amount: '3500000000.00',
    available: '2600000000.00',
    contractorFirmId: 'firm-1',
    contractorFirmName: 'Монолит Строй Сервис',
  ),
  BudgetLine(
    id: 'line-2',
    title: 'Кладка, секция А',
    amount: '2400000000.00',
    available: '900000000.00',
    contractorFirmId: 'firm-1',
    contractorFirmName: 'Монолит Строй Сервис',
  ),
];

const _members = [
  ProjectMember(
    id: 'member-1',
    userId: 'user-1',
    name: 'Н. Юсупова',
    login: 'n.yusupova',
    role: 'director',
  ),
  ProjectMember(
    id: 'member-2',
    userId: 'user-tech',
    name: 'А. Каримов',
    login: 'a.karimov',
    role: 'tech',
  ),
];

const _requests = [
  FundingRequest(
    id: 'req-1',
    projectId: 'project-1',
    projectName: 'ЖК Навои',
    budgetItemId: 'line-1',
    lineTitle: 'Работы нулевого цикла',
    amount: '2260000000.00',
    description: 'Фундамент и материалы на площадке, секция А. Готовность по акту 62%.',
    status: 'submitted',
    mine: false,
    version: 3,
    linePlan: '3500000000.00',
    lineReserved: '400000000.00',
    linePaid: '500000000.00',
    lineAvailable: '2600000000.00',
    files: [
      RequestFile(id: 'f1', contentType: 'image/jpeg', sizeBytes: 418000, kind: 'photo'),
      RequestFile(id: 'f2', contentType: 'image/jpeg', sizeBytes: 377000, kind: 'photo'),
      RequestFile(id: 'f3', contentType: 'application/pdf', sizeBytes: 91000, kind: 'document'),
    ],
    events: [
      RequestEvent(
        action: 'created',
        oldStatus: null,
        newStatus: 'draft',
        reason: '',
        amount: '2260000000.00',
        at: '2026-10-19T09:12:00Z',
        authorName: 'Н. Юсупова',
      ),
      RequestEvent(
        action: 'submitted',
        oldStatus: 'draft',
        newStatus: 'submitted',
        reason: '',
        amount: '2260000000.00',
        at: '2026-10-21T14:40:00Z',
        authorName: 'Н. Юсупова',
      ),
    ],
  ),
  FundingRequest(
    id: 'req-2',
    projectId: 'project-2',
    projectName: 'ЖК Чилонзор',
    budgetItemId: 'line-2',
    lineTitle: 'Кладка, секция А',
    amount: '840000000.00',
    description: 'Кладка третьего этажа, кирпич на площадке.',
    status: 'submitted',
    mine: false,
    version: 2,
    files: [],
  ),
  FundingRequest(
    id: 'req-3',
    projectId: 'project-1',
    projectName: 'ЖК Навои',
    budgetItemId: 'line-2',
    lineTitle: 'Монолит, секция Б',
    amount: '1420000000.00',
    description: 'Перекрытие четвёртого этажа.',
    status: 'tech_approved',
    mine: false,
    version: 4,
    files: [],
  ),
  FundingRequest(
    id: 'req-4',
    projectId: 'project-1',
    projectName: 'ЖК Навои',
    budgetItemId: 'line-1',
    lineTitle: 'Кровля',
    amount: '610000000.00',
    description: 'Не подтверждён объём по гидроизоляции.',
    status: 'rejected',
    mine: false,
    version: 5,
    files: [],
  ),
];

const _notices = [
  NoticeItem(
    id: 'req-1',
    project: 'ЖК Навои',
    line: 'Работы нулевого цикла',
    amount: '2260000000.00',
    status: 'submitted',
  ),
  NoticeItem(
    id: 'req-2',
    project: 'ЖК Чилонзор',
    line: 'Кладка, секция А',
    amount: '840000000.00',
    status: 'submitted',
  ),
];

const _orders = [
  InspectionOrder(
    id: 'ins-1',
    projectId: 'project-1',
    projectName: 'ЖК Навои',
    status: 'requested',
    scheduledOn: '2026-10-28',
    note: 'Проверить объём по фундаменту секции А и наличие материалов на площадке.',
    gateCode: 'foundation',
    requestId: 'req-1',
    requestLine: 'Работы нулевого цикла',
  ),
  InspectionOrder(
    id: 'ins-2',
    projectId: 'project-2',
    projectName: 'ЖК Чилонзор',
    status: 'reported',
    scheduledOn: '2026-10-14',
    note: 'Кладка третьего этажа подтверждена частично, 74%.',
    gateCode: 'masonry',
    requestId: 'req-2',
    requestLine: 'Кладка, секция А',
  ),
];

