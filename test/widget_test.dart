import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:salahsync/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('com.pfaacodin01.salahsync/sound_mode'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'getSoundMode') {
          return 'normal';
        } else if (methodCall.method == 'hasNotificationPolicyAccess') {
          return true;
        }
        return null;
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('com.pfaacodin01.salahsync/sound_mode'),
      null,
    );
  });

  testWidgets('SalahSync app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('SalahSync'), findsWidgets);
  });
}


