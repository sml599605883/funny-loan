import '../../../core/json/json.dart';

class AppHomeModel {
  const AppHomeModel({
    required this.raw,
    required this.serviceEntry,
    this.bannerList = const [],
    this.largeCard,
    this.productList = const [],
    this.processList = const [],
  });

  final Map<String, dynamic> raw;
  final HomeServiceEntryModel serviceEntry;
  final List<HomeBannerModel> bannerList;
  final HomeCardModel? largeCard;
  final List<HomeProductModel> productList;
  final List<HomeProcessModel> processList;

  bool get hasBanner => bannerList.isNotEmpty;

  bool get hasLargeCard => largeCard != null;

  bool get hasProductList => productList.isNotEmpty;

  bool get hasProcessList => processList.isNotEmpty;

  factory AppHomeModel.fromJson(Json json) {
    final moduleList = json['keelboat'].listValue
        .map((item) => HomeModuleModel.fromJson(Json(item)))
        .toList();
    final largeCardList = _moduleItems(
      moduleList,
      HomeModuleType.largeCard,
      HomeCardModel.fromJson,
    );
    final smallCardList = _moduleItems(
      moduleList,
      HomeModuleType.smallCard,
      HomeCardModel.fromJson,
    );

    return AppHomeModel(
      raw: Map<String, dynamic>.from(json.mapValue),
      serviceEntry: HomeServiceEntryModel.fromJson(json['antichurch']),
      bannerList: _moduleItems(
        moduleList,
        HomeModuleType.banner,
        HomeBannerModel.fromJson,
      ),
      largeCard: largeCardList.isNotEmpty
          ? largeCardList.first
          : smallCardList.isNotEmpty
          ? smallCardList.first
          : null,
      productList: _moduleItems(
        moduleList,
        HomeModuleType.productList,
        HomeProductModel.fromJson,
      ),
      processList: _moduleItems(
        moduleList,
        HomeModuleType.processList,
        HomeProcessModel.fromJson,
      ),
    );
  }

  static List<T> _moduleItems<T>(
    List<HomeModuleModel> modules,
    HomeModuleType type,
    T Function(Json json) builder,
  ) {
    final module = modules.cast<HomeModuleModel?>().firstWhere(
      (item) => item?.type == type,
      orElse: () => null,
    );
    if (module == null) {
      return <T>[];
    }
    return module.items.map(builder).toList();
  }
}

enum HomeModuleType {
  banner,
  largeCard,
  smallCard,
  repay,
  productList,
  processList,
  adList,
  unknown,
}

class HomeModuleModel {
  const HomeModuleModel({
    required this.raw,
    required this.rawType,
    required this.type,
    this.items = const [],
  });

  final Map<String, dynamic> raw;
  final String rawType;
  final HomeModuleType type;
  final List<Json> items;

  factory HomeModuleModel.fromJson(Json json) {
    final items = json['federalizes'].listValue.map(Json.new).toList();
    final rawType = json['outcrop'].stringValue;
    return HomeModuleModel(
      raw: Map<String, dynamic>.from(json.mapValue),
      rawType: rawType,
      type: _parseType(rawType),
      items: items,
    );
  }

  static HomeModuleType _parseType(String rawType) {
    switch (rawType) {
      case 'BANNER':
      case 'Subtilizations':
        return HomeModuleType.banner;
      case 'LARGE_CARD':
      case 'Paresthetic':
        return HomeModuleType.largeCard;
      case 'SMALL_CARD':
      case 'RegimentationsSaving':
        return HomeModuleType.smallCard;
      case 'REPAY':
      case 'Calipashes':
        return HomeModuleType.repay;
      case 'PRODUCT_LIST':
      case 'SummariseHumanists':
        return HomeModuleType.productList;
      case 'PROCESS_LIST':
      case 'Frostfishes':
        return HomeModuleType.processList;
      case 'AD_LIST':
      case 'Peartly':
        return HomeModuleType.adList;
      default:
        return HomeModuleType.unknown;
    }
  }
}

class HomeServiceEntryModel {
  const HomeServiceEntryModel({
    required this.raw,
    this.iconUrl = '',
    this.linkUrl = '',
  });

  final Map<String, dynamic> raw;
  final String iconUrl;
  final String linkUrl;

  factory HomeServiceEntryModel.fromJson(Json json) {
    return HomeServiceEntryModel(
      raw: Map<String, dynamic>.from(json.mapValue),
      iconUrl: json['lintier'].stringValue,
      linkUrl: json['intimacies'].stringValue,
    );
  }
}

class HomeBannerModel {
  const HomeBannerModel({
    required this.raw,
    this.id = '',
    this.imageUrl = '',
    this.linkUrl = '',
  });

  final Map<String, dynamic> raw;
  final String id;
  final String imageUrl;
  final String linkUrl;

  factory HomeBannerModel.fromJson(Json json) {
    return HomeBannerModel(
      raw: Map<String, dynamic>.from(json.mapValue),
      id: json['isolines'].stringValue,
      imageUrl: json['lectin'].stringValue,
      linkUrl: json['sidearms'].stringValue,
    );
  }
}

class HomeCardModel {
  const HomeCardModel({
    required this.raw,
    this.id = '',
    this.productName = '',
    this.productLogo = '',
    this.buttonText = '',
    this.maxAmount = '',
    this.maxAmountDesc = '',
    this.termInfo = '',
    this.termInfoDesc = '',
    this.rateInfo = '',
    this.rateInfoDesc = '',
    this.description = '',
    this.authStatus = 0,
    this.receiptAccount = '',
    this.receiptAccountDesc = '',
    this.progressList = const [],
    this.creditList = const [],
    this.amountIconUrl = '',
    this.rateIconUrl = '',
  });

  final Map<String, dynamic> raw;
  final String id;
  final String productName;
  final String productLogo;
  final String buttonText;
  final String maxAmount;
  final String maxAmountDesc;
  final String termInfo;
  final String termInfoDesc;
  final String rateInfo;
  final String rateInfoDesc;
  final String description;
  final int authStatus;
  final String receiptAccount;
  final String receiptAccountDesc;
  final List<HomeProgressStepModel> progressList;
  final List<HomeCreditStepModel> creditList;
  final String amountIconUrl;
  final String rateIconUrl;

  factory HomeCardModel.fromJson(Json json) {
    return HomeCardModel(
      raw: Map<String, dynamic>.from(json.mapValue),
      id: json['isolines'].stringValue,
      productName: json['disprovable'].stringValue,
      productLogo: json['subsider'].stringValue,
      buttonText: json['overengineered'].stringValue,
      maxAmount: json['decrial'].stringValue,
      maxAmountDesc: json['yesterday'].stringValue,
      termInfo: json['cryptococci'].stringValue,
      termInfoDesc: json['reifier'].stringValue,
      rateInfo: json['recitalists'].stringValue,
      rateInfoDesc: json['scumbag'].stringValue,
      description: json['inflective'].stringValue,
      authStatus: json['landforms'].intValue,
      receiptAccount: json['surly'].stringValue,
      receiptAccountDesc: json['carbonylations'].stringValue,
      progressList: json['topworks'].listValue
          .map((item) => HomeProgressStepModel.fromJson(Json(item)))
          .toList(),
      creditList: json['uncake'].listValue
          .map((item) => HomeCreditStepModel.fromJson(Json(item)))
          .toList(),
      amountIconUrl: json['allegorizes'].stringValue,
      rateIconUrl: json['pieplant'].stringValue,
    );
  }
}

class HomeProgressStepModel {
  const HomeProgressStepModel({
    required this.raw,
    this.title = '',
    this.amount = '',
    this.isSelected = 0,
  });

  final Map<String, dynamic> raw;
  final String title;
  final String amount;
  final int isSelected;

  factory HomeProgressStepModel.fromJson(Json json) {
    return HomeProgressStepModel(
      raw: Map<String, dynamic>.from(json.mapValue),
      title: json['hazinesses'].stringValue,
      amount: json['herpetologist'].stringValue,
      isSelected: json['religiously'].intValue,
    );
  }
}

class HomeCreditStepModel {
  const HomeCreditStepModel({
    required this.raw,
    this.period = '',
    this.periodDesc = '',
    this.rateInfo = '',
  });

  final Map<String, dynamic> raw;
  final String period;
  final String periodDesc;
  final String rateInfo;

  factory HomeCreditStepModel.fromJson(Json json) {
    return HomeCreditStepModel(
      raw: Map<String, dynamic>.from(json.mapValue),
      period: json['genres'].stringValue,
      periodDesc: json['burners'].stringValue,
      rateInfo: json['recitalists'].stringValue,
    );
  }
}

class HomeProductModel {
  const HomeProductModel({
    required this.raw,
    this.id = '',
    this.productName = '',
    this.maxAmount = '',
    this.tags = const [],
    this.productDesc = '',
    this.productLogo = '',
    this.productCode = '',
    this.buttonText = '',
    this.buttonColor = '',
    this.maxAmountDesc = '',
    this.rateDesc = '',
    this.buttonStatus = 0,
    this.buttonExplain = 0,
    this.inside = 0,
    this.term = '',
    this.productType = 0,
    this.isCopyPhone = '',
    this.loanRateValue = '',
    this.linkUrl = '',
    this.termInfo = '',
    this.todayClicked = 0,
    this.labelText = const [],
    this.titleText = '',
    this.sortDesc = const [],
    this.todayApplyNum = 0,
    this.amountMax = '',
    this.loanRate = '',
    this.loanTermText = '',
  });

  final Map<String, dynamic> raw;
  final String id;
  final String productName;
  final String maxAmount;
  final List<String> tags;
  final String productDesc;
  final String productLogo;
  final String productCode;
  final String buttonText;
  final String buttonColor;
  final String maxAmountDesc;
  final String rateDesc;
  final int buttonStatus;
  final int buttonExplain;
  final int inside;
  final String term;
  final int productType;
  final String isCopyPhone;
  final String loanRateValue;
  final String linkUrl;
  final String termInfo;
  final int todayClicked;
  final List<String> labelText;
  final String titleText;
  final List<String> sortDesc;
  final int todayApplyNum;
  final String amountMax;
  final String loanRate;
  final String loanTermText;

  factory HomeProductModel.fromJson(Json json) {
    return HomeProductModel(
      raw: Map<String, dynamic>.from(json.mapValue),
      id: json['isolines'].stringValue,
      productName: json['disprovable'].stringValue,
      maxAmount: json['decrial'].stringValue,
      tags: json['tymbals'].listValue
          .map((item) => Json(item).stringValue)
          .toList(),
      productDesc: json['preabsorbing'].stringValue,
      productLogo: json['subsider'].stringValue,
      productCode: json['alkylated'].stringValue,
      buttonText: json['overengineered'].stringValue,
      buttonColor: json['logorrheic'].stringValue,
      maxAmountDesc: json['yesterday'].stringValue,
      rateDesc: json['scumbag'].stringValue,
      buttonStatus: json['housepainter'].intValue,
      buttonExplain: json['precancels'].intValue,
      inside: json['dilutes'].intValue,
      term: json['temerariousness'].stringValue,
      productType: json['remudas'].intValue,
      isCopyPhone: json['atonalism'].stringValue,
      loanRateValue: json['profitwise'].stringValue,
      linkUrl: json['sidearms'].stringValue,
      termInfo: json['cryptococci'].stringValue,
      todayClicked: json['symposiums'].intValue,
      labelText: json['oxbow'].listValue
          .map((item) => Json(item).stringValue)
          .toList(),
      titleText: json['scrappiness'].stringValue,
      sortDesc: json['imprinting'].listValue
          .map((item) => Json(item).stringValue)
          .toList(),
      todayApplyNum: json['slouches'].intValue,
      amountMax: json['reconcilements'].stringValue,
      loanRate: json['recitalists'].stringValue,
      loanTermText: json['vomitives'].stringValue,
    );
  }
}

class HomeProcessModel {
  const HomeProcessModel({
    required this.raw,
    this.orderNo = '',
    this.productId = '',
    this.productName = '',
    this.productLogo = '',
    this.title = '',
    this.amount = '',
    this.amountDesc = '',
    this.date = '',
    this.dateDesc = '',
    this.receiptAccount = '',
    this.receiptAccountDesc = '',
    this.orderStatus = 0,
    this.cardStatus = 0,
    this.displayAmount = '',
    this.orderStatusText = '',
    this.description = '',
    this.progressList = const [],
    this.firstFailedAt = 0,
    this.cancelEndAt = 0,
    this.linkUrl = '',
    this.buttons = const [],
  });

  final Map<String, dynamic> raw;
  final String orderNo;
  final String productId;
  final String productName;
  final String productLogo;
  final String title;
  final String amount;
  final String amountDesc;
  final String date;
  final String dateDesc;
  final String receiptAccount;
  final String receiptAccountDesc;
  final int orderStatus;
  final int cardStatus;
  final String displayAmount;
  final String orderStatusText;
  final String description;
  final List<HomeProgressStepModel> progressList;
  final int firstFailedAt;
  final int cancelEndAt;
  final String linkUrl;
  final List<HomeProcessButtonModel> buttons;

  factory HomeProcessModel.fromJson(Json json) {
    return HomeProcessModel(
      raw: Map<String, dynamic>.from(json.mapValue),
      orderNo: json['nosh'].stringValue,
      productId: json['cohabiter'].stringValue,
      productName: json['territoriality'].stringValue,
      productLogo: json['kwacha'].stringValue,
      title: json['hazinesses'].stringValue,
      amount: json['unfindable'].stringValue,
      amountDesc: json['parfocalizes'].stringValue,
      date: json['scauper'].stringValue,
      dateDesc: json['motioner'].stringValue,
      receiptAccount: json['surly'].stringValue,
      receiptAccountDesc: json['carbonylations'].stringValue,
      orderStatus: json['improvements'].intValue,
      cardStatus: json['administer'].intValue,
      displayAmount: json['isolationisms'].stringValue,
      orderStatusText: json['snoutiest'].stringValue,
      description: json['inflective'].stringValue,
      progressList: json['topworks'].listValue
          .map((item) => HomeProgressStepModel.fromJson(Json(item)))
          .toList(),
      firstFailedAt: json['contorting'].intValue,
      cancelEndAt: json['gossamer'].intValue,
      linkUrl: json['sidearms'].stringValue,
      buttons: json['depressingly'].listValue
          .map((item) => HomeProcessButtonModel.fromJson(Json(item)))
          .toList(),
    );
  }
}

class HomeProcessButtonModel {
  const HomeProcessButtonModel({
    required this.raw,
    this.action = '',
    this.enabled = 0,
    this.text = '',
  });

  final Map<String, dynamic> raw;
  final String action;
  final int enabled;
  final String text;

  factory HomeProcessButtonModel.fromJson(Json json) {
    return HomeProcessButtonModel(
      raw: Map<String, dynamic>.from(json.mapValue),
      action: json['outcrop'].stringValue,
      enabled: json['ballsy'].intValue,
      text: json['pilular'].stringValue,
    );
  }
}
