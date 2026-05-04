import 'package:flutter_sample/l10n/app_localizations.dart';
import 'package:flutter_sample/src/features/chart/domain/chart_type.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAppLocalizations extends Mock implements AppLocalizations {}

void main() {
  group('ChartType', () {
    late MockAppLocalizations mockL10n;

    setUp(() {
      mockL10n = MockAppLocalizations();
    });

    test('getLocalizedLabelがlineのとき正しいラベルを返すこと', () {
      when(() => mockL10n.chartLine).thenReturn('折れ線グラフ');
      expect(ChartType.line.getLocalizedLabel(mockL10n), '折れ線グラフ');
      verify(() => mockL10n.chartLine).called(1);
    });

    test('getLocalizedLabelがbarのとき正しいラベルを返すこと', () {
      when(() => mockL10n.chartBar).thenReturn('棒グラフ');
      expect(ChartType.bar.getLocalizedLabel(mockL10n), '棒グラフ');
      verify(() => mockL10n.chartBar).called(1);
    });

    test('getLocalizedLabelがpieのとき正しいラベルを返すこと', () {
      when(() => mockL10n.chartPie).thenReturn('円グラフ');
      expect(ChartType.pie.getLocalizedLabel(mockL10n), '円グラフ');
      verify(() => mockL10n.chartPie).called(1);
    });
  });
}
