import '../../features/auth/data/auth_service.dart';
import '../../features/finance/data/finance_service.dart';
import 'api_client.dart';

abstract final class AppServices {
  static final ApiClient client = ApiClient();
  static final AuthService auth = AuthApiService(client);
  static final FinanceService finance = FinanceApiService(client);
}
