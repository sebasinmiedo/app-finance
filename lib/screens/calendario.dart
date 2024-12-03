import 'package:app_finance/database/db_helper.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarioScreen extends StatefulWidget {
  const CalendarioScreen({super.key});

  @override
  _CalendarioScreenState createState() => _CalendarioScreenState();
}

class _CalendarioScreenState extends State<CalendarioScreen> {
  DateTime _fechaSeleccionada = DateTime.now();
  List<Map<String, dynamic>> _transacciones = [];
  Map<String, double> _totalesDia = {'ingresos': 0.0, 'egresos': 0.0};
  Map<String, double> _totalesMes = {'ingresos': 0.0, 'egresos': 0.0};

  @override
  void initState() {
    super.initState();
    _cargarTransacciones(_fechaSeleccionada);
  }

  Future<void> _cargarTotales(DateTime fecha) async {
    // Carga los totales para el día y el mes
    final totalesDia = await BasedatoHelper().obtenerTotalesPorDia(fecha);
    final totalesMes = await BasedatoHelper().obtenerTotalesPorMes(fecha);

    setState(() {
      _totalesDia = totalesDia;
      _totalesMes = totalesMes;
    });
  }

  // Función para cargar transacciones desde la base de datos
  Future<void> _cargarTransacciones(DateTime fecha) async {
    List<Map<String, dynamic>> transacciones =
        await BasedatoHelper().obtenerTransaccionesPorFecha(fecha);
    setState(() {
      _transacciones = transacciones;
    });

    // Cargar los totales
    _cargarTotales(fecha);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          TableCalendar(
            rowHeight: 45,
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _fechaSeleccionada,
            selectedDayPredicate: (day) => isSameDay(day, _fechaSeleccionada),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _fechaSeleccionada = selectedDay;
              });
              _cargarTransacciones(selectedDay);
            },
            calendarStyle: const CalendarStyle(
              todayDecoration:
                  BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
              selectedDecoration:
                  BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
            ),
          ),
          const SizedBox(height: 8),
          // Totales
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Text(
                      'Totales del mes:',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Column(
                      children: [
                        Text(
                          '   Ingresos: S/.${_totalesMes['ingresos']!.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.green,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          'Gastos: S/.${_totalesMes['egresos']!.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    const SizedBox(height: 8),
                    Text(
                      'Totales del día:',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Column(
                      children: [
                        Text(
                          '     Ingresos: S/.${_totalesDia['ingresos']!.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.green,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          '  Gastos: S/.${_totalesDia['egresos']!.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _transacciones.isNotEmpty
                ? ListView.builder(
                    itemCount: _transacciones.length,
                    itemBuilder: (context, index) {
                      final transaccion = _transacciones[index];
                      final esIngreso = transaccion['tipo'] == 'ingreso';

                      return ListTile(
                        title: Text(
                          transaccion['titulo'],
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 17),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Monto: S/.${transaccion['monto'].toString()}',
                              style: TextStyle(
                                color: esIngreso ? Colors.green : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                                'Categoría: ${transaccion['categoria_nombre']}'),
                            Text('Grupo: ${transaccion['grupo_nombre']}'),
                          ],
                        ),
                        isThreeLine: true,
                      );
                    },
                  )
                : const Center(
                    child: Text('No hay transacciones para este día'),
                  ),
          ),
        ],
      ),
    );
  }
}
