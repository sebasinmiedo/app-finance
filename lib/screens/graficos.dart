import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:app_finance/database/db_helper.dart';
import 'package:month_year_picker/month_year_picker.dart';

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

  List<int> years = List.generate(
      101, (index) => 2000 + index); // Lista de años de 2000 a 2100
  List<String> months = [
    'Enero',
    'Febrero',
    'Marzo',
    'Abril',
    'Mayo',
    'Junio',
    'Julio',
    'Agosto',
    'Septiembre',
    'Octubre',
    'Noviembre',
    'Diciembre'
  ];

  String? selectedMonth;
  int? selectedYear;

  List<String> meses = List.generate(12, (index) {
    return DateFormat('MMMM', 'es').format(DateTime(0, index + 1));
  }); // Genera la lista de meses en español.

  @override
  void initState() {
    super.initState();
    _cargarDatos();
    _cargarGastosPorCategoria();
    selectedMonth = months[currentMonth.month - 1]; // Establecer el mes actual
    selectedYear = currentMonth.year; // Establecer el año actual
  }

  void _updateDate() {
    setState(() {
      currentMonth =
          DateTime(selectedYear!, months.indexOf(selectedMonth!) + 1, 1);
    });
    _cargarGastosPorCategoria();
  }

  void _showMonthYearPicker() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: <Widget>[
              Text('Selecciona un Mes y Año',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              DropdownButton<String>(
                value: selectedMonth,
                items: months.map((month) {
                  return DropdownMenuItem<String>(
                    value: month,
                    child: Text(month),
                  );
                }).toList(),
                onChanged: (newMonth) {
                  setState(() {
                    selectedMonth = newMonth;
                  });
                },
              ),
              DropdownButton<int>(
                value: selectedYear,
                items: years.map((year) {
                  return DropdownMenuItem<int>(
                    value: year,
                    child: Text(year.toString()),
                  );
                }).toList(),
                onChanged: (newYear) {
                  setState(() {
                    selectedYear = newYear;
                  });
                },
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Cerrar el BottomSheet
                  _updateDate(); // Actualizar el mes y año
                },
                child: Text("Aceptar"),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _cargarGastosPorCategoria() async {
    // Obtener el inicio y fin del mes actual
    DateTime inicioMes = DateTime(currentMonth.year, currentMonth.month, 1);
    DateTime finMes = DateTime(currentMonth.year, currentMonth.month + 1, 0);

    // Obtener los datos desde la base de datos
    List<Map<String, dynamic>> resultados =
        await dbHelper.obtenerGastosPorCategoria(inicioMes, finMes);

    if (resultados.isEmpty) {
      setState(() {
        pieSections = []; // No hay datos disponibles
      });
      return;
    }

    double totalGeneral =
        resultados.fold(0.0, (sum, item) => sum + item['total']);

    List<Color> colores = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.yellow,
      Colors.teal,
      Colors.pink,
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.yellow,
      Colors.teal,
      Colors.pink,
    ];

    // Crear las secciones del gráfico circular
    List<PieChartSectionData> sections = [];
    int colorIndex = 0;
    for (var resultado in resultados) {
      String categoria = resultado['categoria'];
      double total = resultado['total'];

      double porcentaje = (total / totalGeneral) * 100;

      sections.add(
        PieChartSectionData(
            color: colores[colorIndex % colores.length],
            value: total,
            title: '$categoria\nS/. ${total.toStringAsFixed(2)}',
            titleStyle: const TextStyle(
              color: Colors.black,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
            radius: 40,
            titlePositionPercentageOffset: 1.7,
            badgeWidget: Text(
              '${porcentaje.toStringAsFixed(1)}%',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            )),
      );
      colorIndex++;
    }

    setState(() {
      pieSections = sections;
    });
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

  void _cambiarMes(String mesSeleccionado) {
    int mesIndex = meses.indexOf(mesSeleccionado) + 1;
    setState(() {
      currentMonth = DateTime(currentMonth.year, mesIndex, 1);
    });
    _cargarGastosPorCategoria(); // Actualiza los datos con el nuevo mes.
  }

  Color _colorAleatorio() {
    return Color((0xFF000000 + (0xFFFFFF * (pieSections.length / 10))).toInt())
        .withOpacity(1.0);
  }

  Future<void> _seleccionarMes() async {
    DateTime? mesSeleccionado = await showMonthYearPicker(
      context: context,
      initialDate: currentMonth, // Fecha inicial (mes actual)
      firstDate: DateTime(2000, 1), // Primera fecha seleccionable
      lastDate: DateTime(2100, 12), // Última fecha seleccionable
      locale: const Locale('es'), // Idioma en español
    );

    if (mesSeleccionado != null) {
      // Actualiza el mes seleccionado
      setState(() {
        currentMonth = DateTime(mesSeleccionado.year, mesSeleccionado.month);
      });

      // Recarga los datos del gráfico
      await _cargarTransaccionesPorMes(currentMonth);
      await _cargarGastosPorCategoria();
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
            const SizedBox(height: 15), // Separador
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Gastos del Mes por Categoría',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Selecciona Mes:',
                      style: TextStyle(fontSize: 16),
                    ),
                    ElevatedButton(
                      onPressed: _showMonthYearPicker,
                      child: Text(
                        '${currentMonth.month}/${currentMonth.year}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 250,
                  child: pieSections.isEmpty
                      ? const Center(child: Text('No hay datos disponibles'))
                      : PieChart(
                          PieChartData(
                            sections: pieSections,
                            centerSpaceRadius: 50,
                            sectionsSpace: 2,
                          ),
                        ),
                ),
              ],
            ),
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
