import '../../../core/json/json.dart';

class AppHomeModel {
  const AppHomeModel({
    required this.raw,
    this.loanProcessText = '',
    this.account = '',
    this.accountText = '',
    this.tips = '',
    this.broadcastNews = '',
    this.signIn = '',
    this.recommendations = const [],
    this.loanProcessList = const [],
    this.periodList = const [],
    this.extendLists = const [],
    required this.order,
  });

  final Map<String, dynamic> raw;
  final String loanProcessText;
  final String account;
  final String accountText;
  final String tips;
  final String broadcastNews;
  final String signIn;
  final List<HomeRecommendationModel> recommendations;
  final List<HomeProcessItemModel> loanProcessList;
  final List<HomePeriodModel> periodList;
  final List<HomeBannerModel> extendLists;
  final HomeOrderModel order;

  factory AppHomeModel.fromJson(Json json) {
    final recommendationList = json['keelboat'].listValue
        .whereType<Map>()
        .map(
          (item) => HomeRecommendationModel.fromJson(Json(item)),
        )
        .toList(growable: false);
    final loanProcessList = json['topworks'].listValue
        .whereType<Map>()
        .map(
          (item) => HomeProcessItemModel.fromJson(Json(item)),
        )
        .toList(growable: false);
    final periodList = json['uncake'].listValue
        .whereType<Map>()
        .map((item) => HomePeriodModel.fromJson(Json(item)))
        .toList(growable: false);
    final extendLists = json['coeducational'].listValue
        .whereType<Map>()
        .map((item) => HomeBannerModel.fromJson(Json(item)))
        .toList(growable: false);

    return AppHomeModel(
      raw: Map<String, dynamic>.from(json.mapValue),
      loanProcessText: json['inflective'].stringValue,
      account: json['surly'].stringValue,
      accountText: json['carbonylations'].stringValue,
      tips: json['ariettes'].stringValue,
      broadcastNews: json['burdie'].stringValue,
      signIn: json['delimes'].stringValue,
      recommendations: recommendationList,
      loanProcessList: loanProcessList,
      periodList: periodList,
      extendLists: extendLists,
      order: HomeOrderModel.fromJson(json),
    );
  }
}

class HomeRecommendationModel {
  const HomeRecommendationModel({
    required this.raw,
    this.id = '',
    this.productName = '',
    this.productLogo = '',
    this.buttonText = '',
    this.amountRange = '',
    this.amountRangeDes = '',
    this.termInfo = '',
    this.termInfoDes = '',
    this.loanRate = '',
    this.loanRateDes = '',
    this.productId = '',
    this.productDesc = '',
    this.productTags = '',
    this.productCode = '',
    this.buttonColor = '',
    this.buttonStatus = '',
    this.buttonExplain = '',
    this.inside = '',
    this.term = '',
    this.productType = '',
    this.isCopyPhone = '',
    this.loanRateValue = '',
    this.todayClicked = '',
    this.labelText = '',
    this.titleText = '',
    this.sordDesc = '',
    this.todayApplyNum = '',
    this.amountMax = '',
    this.loanTermText = '',
    this.signInUrl = '',
    this.waitBindCard = '',
    this.waitCashWithdrawal = '',
    this.waitRepayment = '',
    this.ifRedPoint = '',
    this.redPointId = '',
    this.isNewbie = '',
    this.isH5 = '',
    this.nativeKey = '',
    this.sort = '',
    this.style = '',
    this.iconUrl = '',
    this.linkUrl = '',
    this.imgUrl = '',
    this.buttonUrl = '',
  });

  final Map<String, dynamic> raw;
  final String id;
  final String productName;
  final String productLogo;
  final String buttonText;
  final String amountRange;
  final String amountRangeDes;
  final String termInfo;
  final String termInfoDes;
  final String loanRate;
  final String loanRateDes;
  final String productId;
  final String productDesc;
  final String productTags;
  final String productCode;
  final String buttonColor;
  final String buttonStatus;
  final String buttonExplain;
  final String inside;
  final String term;
  final String productType;
  final String isCopyPhone;
  final String loanRateValue;
  final String todayClicked;
  final String labelText;
  final String titleText;
  final String sordDesc;
  final String todayApplyNum;
  final String amountMax;
  final String loanTermText;
  final String signInUrl;
  final String waitBindCard;
  final String waitCashWithdrawal;
  final String waitRepayment;
  final String ifRedPoint;
  final String redPointId;
  final String isNewbie;
  final String isH5;
  final String nativeKey;
  final String sort;
  final String style;
  final String iconUrl;
  final String linkUrl;
  final String imgUrl;
  final String buttonUrl;

  factory HomeRecommendationModel.fromJson(Json json) {
    return HomeRecommendationModel(
      raw: Map<String, dynamic>.from(json.mapValue),
      id: json['isolines'].stringValue,
      productName: json['disprovable'].stringValue,
      productLogo: json['subsider'].stringValue,
      buttonText: json['overengineered'].stringValue,
      amountRange: json['decrial'].stringValue,
      amountRangeDes: json['yesterday'].stringValue,
      termInfo: json['cryptococci'].stringValue,
      termInfoDes: json['reifier'].stringValue,
      loanRate: json['recitalists'].stringValue,
      loanRateDes: json['scumbag'].stringValue,
      productId: json['cohabiter'].stringValue,
      productDesc: json['preabsorbing'].stringValue,
      productTags: json['tymbals'].stringValue,
      productCode: json['alkylated'].stringValue,
      buttonColor: json['logorrheic'].stringValue,
      buttonStatus: json['housepainter'].stringValue,
      buttonExplain: json['precancels'].stringValue,
      inside: json['dilutes'].stringValue,
      term: json['temerariousness'].stringValue,
      productType: json['remudas'].stringValue,
      isCopyPhone: json['atonalism'].stringValue,
      loanRateValue: json['profitwise'].stringValue,
      todayClicked: json['symposiums'].stringValue,
      labelText: json['oxbow'].stringValue,
      titleText: json['scrappiness'].stringValue,
      sordDesc: json['imprinting'].stringValue,
      todayApplyNum: json['slouches'].stringValue,
      amountMax: json['reconcilements'].stringValue,
      loanTermText: json['vomitives'].stringValue,
      signInUrl: json['revertible'].stringValue,
      waitBindCard: json['outcapering'].stringValue,
      waitCashWithdrawal: json['microflora'].stringValue,
      waitRepayment: json['repoured'].stringValue,
      ifRedPoint: json['mythologically'].stringValue,
      redPointId: json['playactings'].stringValue,
      isNewbie: json['corotations'].stringValue,
      isH5: json['boltonia'].stringValue,
      nativeKey: json['sorrowfully'].stringValue,
      sort: json['ramentum'].stringValue,
      style: json['anticipating'].stringValue,
      iconUrl: json['lintier'].stringValue,
      linkUrl: json['intimacies'].stringValue,
      imgUrl: json['lectin'].stringValue,
      buttonUrl: json['estrangement'].stringValue,
    );
  }
}

class HomeProcessItemModel {
  const HomeProcessItemModel({
    required this.raw,
    this.id = '',
    this.title = '',
    this.subtitle = '',
    this.content = '',
    this.imgUrl = '',
    this.iconUrl = '',
    this.sort = '',
    this.tag = '',
    this.name = '',
    this.logo = '',
  });

  final Map<String, dynamic> raw;
  final String id;
  final String title;
  final String subtitle;
  final String content;
  final String imgUrl;
  final String iconUrl;
  final String sort;
  final String tag;
  final String name;
  final String logo;

  factory HomeProcessItemModel.fromJson(Json json) {
    return HomeProcessItemModel(
      raw: Map<String, dynamic>.from(json.mapValue),
      id: json['isolines'].stringValue,
      title: json['hazinesses'].stringValue,
      subtitle: json['tissual'].stringValue,
      content: json['unchains'].stringValue,
      imgUrl: json['dizzyingly'].stringValue,
      iconUrl: json['lintier'].stringValue,
      sort: json['ramentum'].stringValue,
      tag: json['thugs'].stringValue,
      name: json['governmental'].stringValue,
      logo: json['euchromatic'].stringValue,
    );
  }
}

class HomePeriodModel {
  const HomePeriodModel({
    required this.raw,
    this.period = '',
    this.periodDesc = '',
    this.selected = '',
    this.term = '',
    this.termType = '',
    this.loanMode = '',
    this.maxAmount = '',
    this.minAmount = '',
    this.terms = '',
  });

  final Map<String, dynamic> raw;
  final String period;
  final String periodDesc;
  final String selected;
  final String term;
  final String termType;
  final String loanMode;
  final String maxAmount;
  final String minAmount;
  final String terms;

  factory HomePeriodModel.fromJson(Json json) {
    return HomePeriodModel(
      raw: Map<String, dynamic>.from(json.mapValue),
      period: json['genres'].stringValue,
      periodDesc: json['burners'].stringValue,
      selected: json['religiously'].stringValue,
      term: json['temerariousness'].stringValue,
      termType: json['lixiviates'].stringValue,
      loanMode: json['shrimped'].stringValue,
      maxAmount: json['boroughs'].stringValue,
      minAmount: json['fireboard'].stringValue,
      terms: json['swaggered'].stringValue,
    );
  }
}

class HomeBannerModel {
  const HomeBannerModel({
    required this.raw,
    this.id = '',
    this.title = '',
    this.name = '',
    this.imgUrl = '',
    this.linkUrl = '',
    this.url = '',
    this.position = '',
    this.positionId = '',
    this.source = '',
    this.moduleId = '',
    this.isDisplaySign = '',
    this.signType = '',
  });

  final Map<String, dynamic> raw;
  final String id;
  final String title;
  final String name;
  final String imgUrl;
  final String linkUrl;
  final String url;
  final String position;
  final String positionId;
  final String source;
  final String moduleId;
  final String isDisplaySign;
  final String signType;

  factory HomeBannerModel.fromJson(Json json) {
    return HomeBannerModel(
      raw: Map<String, dynamic>.from(json.mapValue),
      id: json['mislodges'].stringValue,
      title: json['hazinesses'].stringValue,
      name: json['governmental'].stringValue,
      imgUrl: json['dizzyingly'].stringValue,
      linkUrl: json['intimacies'].stringValue,
      url: json['sidearms'].stringValue,
      position: json['encoder'].stringValue,
      positionId: json['magnetites'].stringValue,
      source: json['allantoins'].stringValue,
      moduleId: json['preens'].stringValue,
      isDisplaySign: json['elaboratenesses'].stringValue,
      signType: json['chafes'].stringValue,
    );
  }
}

class HomeOrderModel {
  const HomeOrderModel({
    required this.raw,
    this.orderNo = '',
    this.orderId = '',
    this.productId = '',
    this.productName = '',
    this.productLogo = '',
    this.loanAmount = '',
    this.amount = '',
    this.amountText = '',
    this.date = '',
    this.dateText = '',
    this.orderStatus = '',
    this.status2 = '',
    this.displayAmount = '',
    this.orderStatusText = '',
    this.firstFailedAt = '',
    this.cancelEndAt = '',
    this.buttons = '',
    this.buttonText = '',
    this.buttonUrl = '',
  });

  final Map<String, dynamic> raw;
  final String orderNo;
  final String orderId;
  final String productId;
  final String productName;
  final String productLogo;
  final String loanAmount;
  final String amount;
  final String amountText;
  final String date;
  final String dateText;
  final String orderStatus;
  final String status2;
  final String displayAmount;
  final String orderStatusText;
  final String firstFailedAt;
  final String cancelEndAt;
  final String buttons;
  final String buttonText;
  final String buttonUrl;

  factory HomeOrderModel.fromJson(Json json) {
    return HomeOrderModel(
      raw: Map<String, dynamic>.from(json.mapValue),
      orderNo: json['nosh'].stringValue,
      orderId: json['marlstone'].stringValue,
      productId: json['cohabiter'].stringValue,
      productName: json['territoriality'].stringValue,
      productLogo: json['kwacha'].stringValue,
      loanAmount: json['herpetologist'].stringValue,
      amount: json['unfindable'].stringValue,
      amountText: json['parfocalizes'].stringValue,
      date: json['scauper'].stringValue,
      dateText: json['motioner'].stringValue,
      orderStatus: json['improvements'].stringValue,
      status2: json['administer'].stringValue,
      displayAmount: json['isolationisms'].stringValue,
      orderStatusText: json['snoutiest'].stringValue,
      firstFailedAt: json['contorting'].stringValue,
      cancelEndAt: json['gossamer'].stringValue,
      buttons: json['depressingly'].stringValue,
      buttonText: json['pilular'].stringValue,
      buttonUrl: json['estrangement'].stringValue,
    );
  }
}
