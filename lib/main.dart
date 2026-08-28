import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'controllers/financeiro_controller.dart';
import 'core/theme/app_theme.dart';
import 'views/home/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR', null); // Inicializa formatação em português
  runApp(const BellaGestaoApp());
}

class BellaGestaoApp extends StatelessWidget {
  const BellaGestaoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => FinanceiroController()..carregarTransacoes(),
        ),
      ],
      child: MaterialApp(
        title: 'Bella Gestão',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const HomeScreen(),
      ),
    );
  }
}
