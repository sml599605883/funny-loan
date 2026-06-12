import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:funny_loan/app/modules/certification_step/models/address_node.dart';
import 'package:funny_loan/app/modules/certification_step/models/address_option.dart';
import 'package:funny_loan/app/modules/certification_step/models/address_selection.dart';
import 'package:funny_loan/app/modules/certification_step/models/personal_info_field_option.dart';
import 'package:funny_loan/app/modules/certification_step/views/widgets/address_selection_sheet.dart';
import 'package:funny_loan/app/modules/certification_step/views/widgets/enum_selection_sheet.dart';
import 'package:funny_loan/app/theme/screen_adapter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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
