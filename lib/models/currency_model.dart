class CurrencyModel {
  final String code;
  final String name;
  final String symbol;
  final String flag;
  final double? rate;
  final bool isFavorite;
  final bool isPopular; // ✅ ADDED: Missing property

  CurrencyModel({
    required this.code,
    required this.name,
    required this.symbol,
    required this.flag,
    this.rate,
    this.isFavorite = false,
    this.isPopular = false, // ✅ ADDED: Default value
  });

  factory CurrencyModel.fromMap(Map<String, dynamic> map) {
    return CurrencyModel(
      code: map['code'] ?? '',
      name: map['name'] ?? '',
      symbol: map['symbol'] ?? '',
      flag: map['flag'] ?? '🌍',
      rate: map['rate']?.toDouble(),
      isFavorite: map['isFavorite'] ?? false,
      isPopular: map['isPopular'] ?? false, // ✅ ADDED
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'name': name,
      'symbol': symbol,
      'flag': flag,
      'rate': rate,
      'isFavorite': isFavorite,
      'isPopular': isPopular, // ✅ ADDED
    };
  }

  CurrencyModel copyWith({
    String? code,
    String? name,
    String? symbol,
    String? flag,
    double? rate,
    bool? isFavorite,
    bool? isPopular, // ✅ ADDED
  }) {
    return CurrencyModel(
      code: code ?? this.code,
      name: name ?? this.name,
      symbol: symbol ?? this.symbol,
      flag: flag ?? this.flag,
      rate: rate ?? this.rate,
      isFavorite: isFavorite ?? this.isFavorite,
      isPopular: isPopular ?? this.isPopular, // ✅ ADDED
    );
  }
}
