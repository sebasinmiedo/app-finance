import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart'; // Importar la librería necesaria
import 'package:app_finance/screens/home.dart';
import 'package:month_year_picker/month_year_picker.dart'; // Tu pantalla principal

void main() async {
  await initializeDateFormatting(
      'es_ES', null); // Usa 'es_ES' o el código de idioma que necesites
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      supportedLocales: const [
        Locale('en', 'US'),
        Locale('es', 'ES'),
        // Puedes agregar otros idiomas si lo necesitas
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        MonthYearPickerLocalizations
            .delegate, // Agregar el delegado de MonthYearPicker
      ],
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.orange,
      ),
      home: const HomeScreen(),
    );
  }
}
