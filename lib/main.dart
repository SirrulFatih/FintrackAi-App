import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import 'core/services/hive_service.dart';
import 'core/theme/app_theme.dart';
import 'data/models/transaction_model.dart';
import 'routes/app_bindings.dart';
import 'routes/app_pages.dart';
import 'routes/app_routes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('id_ID');
  Intl.defaultLocale = 'id_ID';

  await Hive.initFlutter();
  if (!Hive.isAdapterRegistered(TransactionModelAdapter.typeIdValue)) {
    Hive.registerAdapter(TransactionModelAdapter());
  }
  if (!Hive.isBoxOpen(HiveService.transactionBoxName)) {
    await Hive.openBox<TransactionModel>(HiveService.transactionBoxName);
  }

  final HiveService hiveService = HiveService();
  Get.put<HiveService>(hiveService, permanent: true);

  runApp(const FinTrackApp());
}

class FinTrackApp extends StatelessWidget {
  const FinTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FinTrack AI',
      initialBinding: AppBindings(),
      initialRoute: AppRoutes.dashboard,
      getPages: AppPages.pages,
      theme: AppTheme.light(),
    );
  }
}
