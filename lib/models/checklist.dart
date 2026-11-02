/// A repeatable list of photos a job needs (one step = one photo).
class Checklist {
  const Checklist({
    required this.id,
    required this.name,
    required this.steps,
    this.builtIn = false,
  });

  final String id;
  final String name;
  final List<String> steps;
  final bool builtIn;

  Map<String, Object?> toJson() => {'id': id, 'name': name, 'steps': steps};

  factory Checklist.fromJson(Map<String, dynamic> j) => Checklist(
        id: j['id'] as String,
        name: j['name'] as String,
        steps: [for (final s in (j['steps'] as List)) s.toString()],
      );

  /// One step per line; blank lines are ignored; at most 40 steps.
  static List<String> parseSteps(String text) => text
      .split('\n')
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty)
      .take(40)
      .toList();

  /// "Step 2/8: Inverter and label"
  String stepLabel(int index) => 'Step ${index + 1}/${steps.length}: ${steps[index]}';

  /// Examples to start from. Adapt them to the exact photos your client or
  /// scheme asks for; they are not official requirements.
  static const List<Checklist> builtIns = [
    Checklist(
      id: 'builtin_solar',
      name: 'Rooftop solar installation',
      builtIn: true,
      steps: [
        'Site and roof before work',
        'Mounting structure',
        'All panels installed',
        'Inverter and its label',
        'DC and AC wiring and protection',
        'Earthing',
        'Meter / connection point',
        'Completed installation, all panels visible',
      ],
    ),
    Checklist(
      id: 'builtin_civil',
      name: 'Civil works progress',
      builtIn: true,
      steps: [
        'Site before work starts',
        'Excavation / foundation',
        'Reinforcement',
        'Concrete / casting',
        'Work in progress',
        'Completed work',
        'Name board at site',
      ],
    ),
    Checklist(
      id: 'builtin_service',
      name: 'Maintenance visit',
      builtIn: true,
      steps: [
        'Equipment before service',
        'Fault or issue found',
        'Service in progress',
        'Parts replaced',
        'Equipment after service',
      ],
    ),
    Checklist(
      id: 'builtin_delivery',
      name: 'Delivery proof',
      builtIn: true,
      steps: [
        'Parcel at the location',
        'Receiver or door',
        'Signed copy',
      ],
    ),
  ];
}
