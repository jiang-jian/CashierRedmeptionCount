import 'package:ailand_pos/data/services/nfc_service.dart';
import 'package:ailand_pos/modules/device_setup/controllers/device_setup_controller.dart';
import 'package:ailand_pos/modules/device_setup/views/device_setup_page.dart';
import 'package:get/get.dart';
import '../../modules/login/views/login_page.dart';
import '../../modules/login/controllers/login_controller.dart';
import '../../modules/home/views/home_page.dart';
import '../../modules/home/controllers/home_controller.dart';
import '../../modules/cashier/views/cashier_page.dart';
import '../../modules/cashier/controllers/cashier_controller.dart';

part 'app_routes.dart';

class AppPages {
  static const initial = Routes.login;

  static final routes = [
    GetPage(
      name: Routes.login,
      page: () => const LoginPage(),
      binding: BindingsBuilder(() {
        Get.lazyPut<LoginController>(() => LoginController());
      }),
    ),
    GetPage(
      name: Routes.home,
      page: () => const HomePage(),
      binding: BindingsBuilder(() {
        Get.lazyPut<HomeController>(() => HomeController());
      }),
    ),
    GetPage(
      name: Routes.cashier,
      page: () => const CashierPage(),
      binding: BindingsBuilder(() {
        Get.lazyPut<CashierController>(() => CashierController());
      }),
    ),
    GetPage(
      name: Routes.deviceSetup,
      page: () => const DeviceSetupPage(),
      binding: BindingsBuilder(() {
        Get.putAsync(() => NfcService().init());
        Get.lazyPut<DeviceSetupController>(() => DeviceSetupController());
      }),
    ),
  ];
}
