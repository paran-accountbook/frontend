const paymentMethods = ['현금', '체크카드', '신용카드', '간편결제', '계좌이체', '기타'];

String normalizePaymentMethod(String? method) => switch (method) {
  '카드' => '체크카드',
  final String value when paymentMethods.contains(value) => value,
  _ => '기타',
};
