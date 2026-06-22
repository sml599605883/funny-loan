import 'app_routes.dart';

class NavigationTargetMapper {
  NavigationTargetMapper._();

  static const main = 'main';
  static const setting = 'setting';
  static const login = 'login';
  static const order = 'order';
  static const productDetail = 'productDetail';
  static const recredit = 'recredit';
  static const apiRemindUrl = 'apiRemindUrl';

  static const Map<String, String> _appPageAliases = <String, String>{
    main: main,
    'Ruinousnesses': main,
    setting: setting,
    'MeshuggaDemised': setting,
    login: login,
    'ShirrNeurochemical': login,
    order: order,
    'Anthranilate': order,
    productDetail: productDetail,
    'Unbosomed': productDetail,
    recredit: recredit,
    'ContradictSentimentalist': recredit,
    apiRemindUrl: apiRemindUrl,
    'Hurraying': apiRemindUrl,
  };

  static const Map<String, String> _productDetailAuthItemAliases =
      <String, String>{
        'governmental': 'name',
        'rucking': 'mobile',
        'underspin': 'id_number',
        'eidos': 'tax_card',
        'fibromatous': 'id_card_back',
        'PaterInstallers': 'public',
        'accumulators': 'face',
        'Hoarily': 'face',
        'Impersonality': 'personal',
        'work': 'job',
        'RavenousNonrestrictive': 'job',
        'Taglike': 'ext',
        'SeashoresScarcity': 'bank',
        'protyles': 'emergent',
        'orbs': 'education',
        'fragging': 'marriage',
        'interrogators': 'company_name',
        'picklocks': 'company_address',
        'tonsuring': 'family_monthly_salary',
        'varve': 'purpose',
        'fertile': 'live',
        'kneepieces': 'home_city',
        'confirming': 'residentaddress',
        'miscarried': 'home_pin_code',
        'endonucleases': 'email',
        'placets': 'job_type',
        'encoder': 'position',
        'ivylike': 'work_length',
        'undrew': 'spouse_name',
        'tamping': 'children_num',
        'sclerotizations': 'pay_method',
        'possessive': 'work_industry',
        'antisubversion': 'company_full_address',
        'airer': 'company_pincode',
        'hypoallergenic': 'monthly_income',
        'pollened': 'company_phone',
        'dines': 'salary_day',
        'hinnies': 'salary_type',
        'scissions': 'sex',
        'sightlessnesses': 'postalcode',
        'vaporlike': 'alternate_mobile',
        'industrial': 'facebook_account',
        'ichorous': 'viber_account',
        'coleading': 'complete_address',
        'excruciations': 'number_of_credit_cards',
        'polders': 'use_of_funds',
        'semihobos': 'residential_address',
        'vaporousnesses': 'company_address_detail',
        'hydrocele': 'monthly_salary',
      };

  static String normalizeAppPage(String rawPage) {
    final page = rawPage.trim();
    return _appPageAliases[page] ?? page;
  }

  static String? appPageFromTarget(String rawTarget) {
    final target = rawTarget.trim();
    if (target.isEmpty) {
      return null;
    }
    final directPage = _appPageAliases[target];
    if (directPage != null) {
      return directPage;
    }

    final uri = Uri.tryParse(target);
    if (uri == null) {
      return null;
    }

    final queryPage =
        uri.queryParameters['appPage'] ?? uri.queryParameters['page'];
    if (queryPage != null && queryPage.trim().isNotEmpty) {
      return normalizeAppPage(queryPage);
    }

    final candidates = <String>[
      if (uri.host.isNotEmpty) uri.host,
      ...uri.pathSegments.where((segment) => segment.isNotEmpty),
      if (uri.fragment.isNotEmpty) uri.fragment,
    ];
    for (final candidate in candidates.reversed) {
      final appPage = _appPageAliases[candidate];
      if (appPage != null) {
        return appPage;
      }
    }

    return null;
  }

  static String? routeForAppPage(String rawPage) {
    switch (normalizeAppPage(rawPage)) {
      case main:
        return AppRoutes.home;
      case setting:
        return AppRoutes.setting;
      case login:
        return AppRoutes.login;
      case order:
        return AppRoutes.orderList;
      case productDetail:
        return AppRoutes.detail;
      case recredit:
        return AppRoutes.recredit;
      default:
        return null;
    }
  }

  static int orderTabIndexForCode(Object? rawCode) {
    switch ('$rawCode'.trim()) {
      case '7':
        return 1;
      case '6':
        return 2;
      case '5':
        return 3;
      default:
        return 0;
    }
  }

  static String normalizeProductDetailAuthItemCode(String rawCode) {
    final code = rawCode.trim();
    return _productDetailAuthItemAliases[code] ?? code;
  }

  static bool isCertificationStepRouteKey(String rawCode) {
    switch (normalizeProductDetailAuthItemCode(rawCode)) {
      case 'public':
      case 'face':
      case 'personal':
      case 'job':
      case 'ext':
        return true;
      default:
        return false;
    }
  }
}
