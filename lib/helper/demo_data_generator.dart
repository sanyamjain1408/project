import '../data/models/exchange_order.dart';

class DemoDataGenerator {

  static Trade getTradeDemo() {
    return Trade(id: 956)
      ..transactionId = "166425830600000000000000000941"
      ..type = "buy"
      ..price = 12.00
      ..createdAt = DateTime.now()
      ..actualAmount = 5631591.44958847
      ..processed = 0.00119256
      ..status = 0
      ..actualAmount = 67579097.39506164
      ..amount = 5631591.44839591
      ..total = 67579097.38075092
      ..fees = 3378954.86903754;
  }
}