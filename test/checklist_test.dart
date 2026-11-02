import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sitestamp/models/checklist.dart';
import 'package:sitestamp/models/stamp_data.dart';
import 'package:sitestamp/services/app_settings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('parseSteps trims, drops blanks and caps at 40', () {
    expect(Checklist.parseSteps('  A \n\n B\n   \nC'), ['A', 'B', 'C']);
    final many = List.generate(60, (i) => 'step $i').join('\n');
    expect(Checklist.parseSteps(many).length, 40);
  });

  test('stepLabel and json round trip', () {
    const c = Checklist(id: 'x', name: 'Test', steps: ['One', 'Two', 'Three']);
    expect(c.stepLabel(1), 'Step 2/3: Two');
    final back = Checklist.fromJson(c.toJson());
    expect(back.name, 'Test');
    expect(back.steps, ['One', 'Two', 'Three']);
  });

  test('built-in checklists exist and have steps', () {
    expect(Checklist.builtIns.length, greaterThanOrEqualTo(3));
    for (final c in Checklist.builtIns) {
      expect(c.steps, isNotEmpty);
      expect(c.builtIn, isTrue);
    }
  });

  test('stamp prints the checklist step and stores it', () {
    final d = StampData(
      time: DateTime(2026, 1, 2, 3, 4, 5),
      memo: '',
      project: 'Roof 12',
      step: 'Step 4/8: Inverter and its label',
    );
    final lines = d.toLines();
    expect(lines, contains('Project: Roof 12'));
    expect(lines, contains('Step 4/8: Inverter and its label'));
    expect(StampData.fromJson(d.toJson()).step, 'Step 4/8: Inverter and its label');
  });

  test('progress: next step, mark done, reset, per project', () async {
    SharedPreferences.setMockInitialValues({});
    final s = await AppSettings.load();
    expect(s.activeChecklist, isNull);
    expect(s.nextStepIndex('A'), isNull);

    await s.addChecklist('Mine', ['one', 'two', 'three']);
    expect(s.activeChecklist?.name, 'Mine');
    expect(s.nextStepIndex('A'), 0);

    await s.markStepDone('A', 0);
    await s.markStepDone('A', 2);
    expect(s.completedSteps('A'), {0, 2});
    expect(s.nextStepIndex('A'), 1);
    expect(s.nextStepIndex('B'), 0); // other project is separate

    await s.markStepDone('A', 1);
    expect(s.nextStepIndex('A'), isNull); // all done

    await s.resetProgress('A');
    expect(s.nextStepIndex('A'), 0);
  });

  test('checklists persist and can be removed', () async {
    SharedPreferences.setMockInitialValues({});
    final s = await AppSettings.load();
    await s.addChecklist('Persisted', ['a', 'b']);
    final id = s.activeChecklist!.id;

    final again = await AppSettings.load();
    expect(again.checklists.any((c) => c.id == id), isTrue);
    expect(again.activeChecklist?.name, 'Persisted');

    await again.removeChecklist(id);
    expect(again.activeChecklist, isNull);
    expect(again.checklists.any((c) => c.id == id), isFalse);
  });
}
