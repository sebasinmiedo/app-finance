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
  List<PieChartSectionData> pieSections = [];
  DateTime currentMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    _cargarDatos();
    _cargarTransaccionesPorMes(currentMonth);
  }

  Future<void> _cargarTransaccionesPorMes(DateTime mes) async {
    DateTime inicioMes = DateTime(mes.year, mes.month, 1);
    DateTime finMes = DateTime(mes.year, mes.month + 1, 0);

    List<Map<String, dynamic>> transacciones =
        await dbHelper.obtenerTransaccionesPorRango(inicioMes, finMes);

    Map<String, double> totalesPorCategoria = {};
    for (var transaccion in transacciones) {
      String categoria = transaccion['categoria'];
      double monto = transaccion['monto'];

      totalesPorCategoria[categoria] =
          (totalesPorCategoria[categoria] ?? 0) + monto;
    }

    List<PieChartSectionData> sections = [];
    totalesPorCategoria.forEach((categoria, total) {
      sections.add(PieChartSectionData(
        color: _colorAleatorio(),
        value: total,
        title: total.toStringAsFixed(2),
        titleStyle: const TextStyle(color: Colors.white, fontSize: 16),
      ));
    });

    setState(() {
      pieSections = sections;
    });
  }

  Color _colorAleatorio() {
    return Color((0xFF000000 + (0xFFFFFF * (pieSections.length / 10))).toInt())
        .withOpacity(1.0);
  }

  Future<void> _seleccionarMes() async {
    DateTime? mesSeleccionado = await showDatePicker(
      context: context,
      initialDate: currentMonth,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      locale: const Locale('es'),
    );

    if (mesSeleccionado != null) {
      setState(() {
        currentMonth = DateTime(mesSeleccionado.year, mesSeleccionado.month);
      });
      _cargarTransaccionesPorMes(currentMonth);
    }
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
              toY: egresos, // Rojo para egresos
              width: 15,
              borderRadius: BorderRadius.zero,
              gradient: const LinearGradient(
                colors: [
                  Color.fromARGB(255, 255, 131, 123),
                  Color.fromARGB(255, 255, 0, 0),
                ], // Gradiente
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
            ),
            //
            BarChartRodData(
              toY: ingresos,
              gradient: const LinearGradient(
                colors: [
                  Color.fromARGB(255, 162, 208, 110),
                  Colors.green,
                ],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
              width: 15, // Ancho consistente
              borderRadius: BorderRadius.zero,
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gráfico de barras
            const Text(
              'Ingresos y Egresos de los ultimos 7 dias',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 200, // Altura específica para el gráfico
              child: barGroups.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : BarChart(
                      BarChartData(
                        titlesData: FlTitlesData(
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          leftTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 30,
                              getTitlesWidget: (double value, TitleMeta meta) {
                                DateTime date = DateTime.now().subtract(
                                    Duration(days: 6 - value.toInt()));
                                return SideTitleWidget(
                                  axisSide: meta.axisSide,
                                  child: Transform.rotate(
                                    angle: -40 * (3.141592653589793 / 180),
                                    child: Text(
                                      DateFormat('EEEE', 'es')
                                          .format(date)
                                          .toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
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
                          show: false,
                        ),
                        barGroups: barGroups,
                        alignment: BarChartAlignment.spaceBetween,
                      ),
                    ),
            ),
            const SizedBox(height: 20), // Separador

            // Gráfico circular
            const Text(
              'Gráfico Circular',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              'Mes: ${DateFormat('MMMM yyyy', 'es').format(currentMonth)}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 10),
            const SizedBox(height: 10),

            GestureDetector(
                onTap: _seleccionarMes,
                child: SizedBox(
                  height: 150,
                  child: PieChart(
                    PieChartData(
                      sections: pieSections.isEmpty
                          ? [
                              PieChartSectionData(
                                color: Colors.grey,
                                value: 1,
                                title: 'No hay datos',
                                titleStyle: const TextStyle(
                                    color: Colors.white, fontSize: 16),
                              ),
                            ]
                          : pieSections,
                      centerSpaceRadius: 50,
                    ),
                  ),
                )),
            SizedBox(
              height: 150,
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(
                      color: Colors.blue,
                      value: 40,
                      title: '40%',
                      titleStyle:
                          const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    PieChartSectionData(
                      color: Colors.green,
                      value: 30,
                      title: '30%',
                      titleStyle:
                          const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    PieChartSectionData(
                      color: Colors.red,
                      value: 20,
                      title: '20%',
                      titleStyle:
                          const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    PieChartSectionData(
                      color: Colors.yellow,
                      value: 10,
                      title: '10%',
                      titleStyle:
                          const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20), // Separador

            // Otro gráfico (puedes duplicar el widget de BarChart o PieChart aquí)
            const Text(
              'Otro Gráfico',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Container(
              height: 300,
              color: Colors.grey.shade300,
              alignment: Alignment.center,
              child: const Text('Otro tipo de gráfico aquí'),
            ),
          ],
        ),
      ),
    );
  }
}
