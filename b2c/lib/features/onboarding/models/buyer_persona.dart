// Buyer-preference quiz domain (Phase 2, frontend-only mock). Captures a short
// persona questionnaire whose result is stored locally and used to shape a
// mock AI prompt/preview — no server involvement.

/// What the buyer optimises for in their next home.
enum QuizGoal { budget, family, investment, luxury }

/// The kind of area they picture themselves in.
enum QuizLocationPref { cityCenter, quietSuburb, businessDistrict, upAndComing }

/// How soon they want to move in.
enum QuizTimeline { readyNow, offplanOk, flexible }

/// The single factor that matters most.
enum QuizPriority { price, space, amenities, location }

/// The derived buyer persona.
enum BuyerPersona { firstTimeBuyer, familyNester, investor, luxurySeeker }

/// One completed set of answers.
class QuizAnswers {
  const QuizAnswers({
    required this.goal,
    required this.location,
    required this.timeline,
    required this.priority,
  });

  final QuizGoal goal;
  final QuizLocationPref location;
  final QuizTimeline timeline;
  final QuizPriority priority;

  Map<String, dynamic> toJson() => {
    'goal': goal.name,
    'location': location.name,
    'timeline': timeline.name,
    'priority': priority.name,
  };

  factory QuizAnswers.fromJson(Map<String, dynamic> json) => QuizAnswers(
    goal: QuizGoal.values.byName(json['goal'] as String),
    location: QuizLocationPref.values.byName(json['location'] as String),
    timeline: QuizTimeline.values.byName(json['timeline'] as String),
    priority: QuizPriority.values.byName(json['priority'] as String),
  );
}

/// Deterministic mapping from answers to a persona (mock — no ML).
BuyerPersona personaFor(QuizAnswers a) {
  switch (a.goal) {
    case QuizGoal.investment:
      return BuyerPersona.investor;
    case QuizGoal.luxury:
      return BuyerPersona.luxurySeeker;
    case QuizGoal.family:
      return BuyerPersona.familyNester;
    case QuizGoal.budget:
      return BuyerPersona.firstTimeBuyer;
  }
}

/// A completed quiz: the answers, the derived persona, and when it was taken.
class QuizResult {
  const QuizResult({
    required this.answers,
    required this.persona,
    required this.completedAt,
  });

  final QuizAnswers answers;
  final BuyerPersona persona;
  final DateTime completedAt;

  Map<String, dynamic> toJson() => {
    'answers': answers.toJson(),
    'persona': persona.name,
    'completedAt': completedAt.toIso8601String(),
  };

  factory QuizResult.fromJson(Map<String, dynamic> json) => QuizResult(
    answers: QuizAnswers.fromJson(json['answers'] as Map<String, dynamic>),
    persona: BuyerPersona.values.byName(json['persona'] as String),
    completedAt:
        DateTime.tryParse(json['completedAt'] as String? ?? '') ??
        DateTime.now(),
  );
}
