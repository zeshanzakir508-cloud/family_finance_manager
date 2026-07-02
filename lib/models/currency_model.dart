class CurrencyModel {
  final String code;
  final String name;
  final String symbol;
  final String flag;
  final double? rate;
  final bool isFavorite;

  CurrencyModel({
    required this.code,
    required this.name,
    required this.symbol,
    required this.flag,
    this.rate,
    this.isFavorite = false,
  });

  factory CurrencyModel.fromMap(Map<String, dynamic> map) {
    return CurrencyModel(
      code: map['code'] ?? '',
      name: map['name'] ?? '',
      symbol: map['symbol'] ?? '',
      flag: map['flag'] ?? '🌍',
      rate: map['rate']?.toDouble(),
      isFavorite: map['isFavorite'] ?? false,
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
    };
  }

  CurrencyModel copyWith({
    String? code,
    String? name,
    String? symbol,
    String? flag,
    double? rate,
    bool? isFavorite,
  }) {
    return CurrencyModel(
      code: code ?? this.code,
      name: name ?? this.name,
      symbol: symbol ?? this.symbol,
      flag: flag ?? this.flag,
      rate: rate ?? this.rate,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}
