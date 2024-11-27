import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:app_finance/database/db_helper.dart';

class GraficosScreen extends StatefulWidget {
  const GraficosScreen({super.key});

  @override
  _GraficosScreenState createState() => _GraficosScreenState();
}

class _GraficosScreenState extends State<GraficosScreen> {
  final BasedatoHelper dbHelper = BasedatoHelper();
  List<BarChartGroupData> barGroups = [];

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    // Obtén las transacciones de la última semana
    List<Map<String, dynamic>> transacciones =
        await dbHelper.obtenerTransaccionesUltimaSemana();

    print(
        "Transacciones obtenidas: $transacciones"); // Verifica los datos obtenidos

    // Creamos un mapa para almacenar la sumatoria de ingresos y egresos por día
    Map<String, double> ingresosPorDia = {};
    Map<String, double> egresosPorDia = {};

    for (var transaccion in transacciones) {
      // Convierte la fecha en formato ISO 8601 a DateTime y luego extrae solo la fecha (sin la hora)
      String fecha = DateTime.parse(transaccion['fecha'])
          .toLocal()
          .toString()
          .split(' ')[0];

      double monto =
          transaccion['total']; // Asegúrate de que 'total' es el campo correcto

      if (transaccion['tipo'] == 'ingreso') {
        ingresosPorDia[fecha] = (ingresosPorDia[fecha] ?? 0) + monto;
      } else {
        egresosPorDia[fecha] = (egresosPorDia[fecha] ?? 0) + monto;
      }
    }

    // Obtener la fecha de hoy y la fecha de hace 6 días para crear los 7 días
    DateTime today = DateTime.now();
    List<String> dias = [];
    for (int i = 6; i >= 0; i--) {
      dias.add(
          DateFormat('yyyy-MM-dd').format(today.subtract(Duration(days: i))));
    }

    // Crear los BarChartGroupData
    List<BarChartGroupData> groups = [];
    for (String dia in dias) {
      double ingresos = ingresosPorDia[dia] ?? 0;
      double egresos = egresosPorDia[dia] ?? 0;

      groups.add(
        BarChartGroupData(
          x: dias.indexOf(dia), // El índice para cada día
          barRods: [
            // Barra de egresos
            BarChartRodData(
              toY: egresos,
              color: const Color.fromRGBO(255, 0, 0, 1), // Rojo para egresos
              width: 15, // Ajusté el ancho para hacer las barras más compactas
              borderRadius: BorderRadius.zero, // Sin bordes redondeados
            ),
            // Barra de ingresos apilada sobre los egresos
            BarChartRodData(
              toY: ingresos,
              color: const Color.fromRGBO(0, 255, 0, 1), // Verde para ingresos
              width: 15, // Ancho consistente
              borderRadius: BorderRadius.zero, // Sin bordes redondeados
            ),
          ],
        ),
      );
    }

    // Actualiza el estado con los datos
    setState(() {
      barGroups = groups;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: barGroups.isEmpty
            ? const Center(child: CircularProgressIndicator()) // Cargando
            : BarChart(
                BarChartData(
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 410,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          DateTime date = DateTime.now()
                              .subtract(Duration(days: 6 - value.toInt()));
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            child: Text(
                              DateFormat('dd/MM').format(date),
                              style: const TextStyle(
                                  fontSize: 10, fontWeight: FontWeight.w500),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                      show: true,
                      border: Border.all(color: Colors.grey, width: 2)),
                  gridData: const FlGridData(
                      show: true,
                      drawHorizontalLine: true,
                      drawVerticalLine: false),
                  barGroups: barGroups,
                  alignment: BarChartAlignment.spaceBetween,
                ),
              ),
      ),
    );
  }
}
