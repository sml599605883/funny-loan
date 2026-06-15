import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:funny_loan/app/core/json/json.dart';
import 'package:funny_loan/app/modules/certification_step/models/address_node.dart';
import 'package:funny_loan/app/modules/certification_step/models/address_option.dart';
import 'package:funny_loan/app/modules/certification_step/models/address_selection.dart';
import 'package:funny_loan/app/modules/certification_step/models/personal_info_field_option.dart';
import 'package:funny_loan/app/modules/certification_step/views/widgets/address_selection_sheet.dart';
import 'package:funny_loan/app/modules/certification_step/views/widgets/enum_selection_sheet.dart';
import 'package:funny_loan/app/modules/certification_step/views/widgets/salary_day_selection_sheet.dart';
import 'package:funny_loan/app/theme/screen_adapter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('personal info option parses maintenance metadata', () {
    final options = PersonalInfoFieldOption.parseList(
      Json(const <Map<String, dynamic>>[
        <String, dynamic>{
          'outcrop': '6',
          'governmental': 'GCash',
          'euchromatic': 'https://example.com/gcash.png',
          'fleshed': 1,
          'cantilenas': 'Under maintenance. Loans may be delayed',
        },
      ]),
    );

    expect(options.single.label, 'GCash');
    expect(options.single.value, '6');
    expect(options.single.logoUrl, 'https://example.com/gcash.png');
    expect(options.single.isUnderMaintenance, isTrue);
    expect(
      options.single.maintenanceText,
      'Under maintenance. Loans may be delayed',
    );
  });

  testWidgets('enum selection sheet returns tapped option on done', (
    WidgetTester tester,
  ) async {
    final options = <PersonalInfoFieldOption>[
      const PersonalInfoFieldOption(label: 'BDO', value: '1'),
      const PersonalInfoFieldOption(label: 'BPI', value: '2'),
    ];
    PersonalInfoFieldOption? selectedOption;

    await tester.pumpWidget(
      _buildSheetHost(
        child: EnumSelectionSheet(
          options: options,
          currentValue: '1',
          onSelected: (option) => selectedOption = option,
        ),
      ),
    );

    await tester.tap(find.text('BPI'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    expect(selectedOption?.label, 'BPI');
    expect(selectedOption?.value, '2');
  });

  testWidgets(
    'enum selection sheet shows maintenance copy and still allows selection',
    (WidgetTester tester) async {
      final options = <PersonalInfoFieldOption>[
        const PersonalInfoFieldOption(
          label: 'GCash e-wallet',
          value: '6',
          logoUrl: 'https://example.com/gcash.png',
          isUnderMaintenance: true,
          maintenanceText: 'Under maintenance. Loans may be delayed',
        ),
        const PersonalInfoFieldOption(label: 'PayMaya e-wallet', value: '7'),
      ];
      PersonalInfoFieldOption? selectedOption;

      await tester.pumpWidget(
        _buildSheetHost(
          child: EnumSelectionSheet(
            options: options,
            currentValue: '',
            onSelected: (option) => selectedOption = option,
          ),
        ),
      );

      expect(
        find.text('Under maintenance. Loans may be delayed'),
        findsOneWidget,
      );

      await tester.tap(find.text('GCash e-wallet'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      expect(selectedOption?.label, 'GCash e-wallet');
      expect(selectedOption?.value, '6');
    },
  );

  testWidgets('address selection sheet walks through three levels', (
    WidgetTester tester,
  ) async {
    final options = <AddressOption>[
      const AddressOption(
        addressId: 'province-a',
        label: 'Province A',
        children: <AddressNode>[
          AddressNode(
            addressId: 'city-a1',
            label: 'City A1',
            children: <AddressNode>[
              AddressNode(
                addressId: 'district-a1a',
                label: 'District A1A',
                children: <AddressNode>[],
              ),
            ],
          ),
        ],
      ),
    ];
    AddressSelection? selectedAddress;

    await tester.pumpWidget(
      _buildSheetHost(
        child: AddressSelectionSheet(
          title: 'Residential Address',
          options: options,
          currentValue: '',
          onSelected: (selection) => selectedAddress = selection,
        ),
      ),
    );

    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    expect(selectedAddress?.label, 'Province A-City A1-District A1A');
    expect(selectedAddress?.value, 'Province A-City A1-District A1A');
  });

  testWidgets('salary day sheet cancel on second level returns to first level', (
    WidgetTester tester,
  ) async {
    final options = <SalaryDayGroup>[
      const SalaryDayGroup(
        label: '1st Half',
        value: 'half_1',
        children: <SalaryDayOption>[
          SalaryDayOption(label: '5th', value: '5'),
          SalaryDayOption(label: '10th', value: '10'),
        ],
      ),
      const SalaryDayGroup(
        label: '2nd Half',
        value: 'half_2',
        children: <SalaryDayOption>[
          SalaryDayOption(label: '20th', value: '20'),
          SalaryDayOption(label: '25th', value: '25'),
        ],
      ),
    ];

    await tester.pumpWidget(
      _buildSheetHost(
        child: SalaryDaySelectionSheet(
          options: options,
          currentGroupValue: '',
          currentChildValue: '',
        ),
      ),
    );

    await tester.tap(find.text('2nd Half'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    expect(find.text('25th'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('1st Half'), findsOneWidget);
    expect(find.text('2nd Half'), findsOneWidget);
    expect(find.text('25th'), findsNothing);
  });
}

Widget _buildSheetHost({required Widget child}) {
  return MaterialApp(
    home: Builder(
      builder: (context) {
        ScreenAdapter.init(context);
        return Scaffold(
          body: child,
        );
      },
    ),
  );
}
