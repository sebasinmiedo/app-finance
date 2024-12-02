import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarioScreen extends StatefulWidget {
  const CalendarioScreen({super.key});

  @override
  _CalendarioScreenState createState() => _CalendarioScreenState();
}

class _CalendarioScreenState extends State<CalendarioScreen> {
  // Fecha seleccionada
  DateTime _fechaSeleccionada = DateTime.now();

  // Simulación de transacciones
  final Map<String, List<Map<String, dynamic>>> _transaccionesPorFecha = {
    '2024-12-01': [
      {'titulo': 'Cepillo de dientes', 'monto': 12.0},
      {'titulo': 'Jabón', 'monto': 8.0},
    ],
    '2024-12-02': [
      {'titulo': 'Propina', 'monto': 15.0},
      {'titulo': 'Sueldo', 'monto': 100.0},
    ],
  };

  // Obtener transacciones para la fecha seleccionada
  List<Map<String, dynamic>> _obtenerTransacciones(DateTime fecha) {
    String claveFecha = fecha.toIso8601String().split('T').first;
    return _transaccionesPorFecha[claveFecha] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    // Transacciones del día seleccionado
    List<Map<String, dynamic>> transacciones =
        _obtenerTransacciones(_fechaSeleccionada);

    return Scaffold(
      appBar: AppBar(title: Text('Calendario')),
      body: Column(
        children: [
          // Calendario
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _fechaSeleccionada,
            selectedDayPredicate: (day) => isSameDay(day, _fechaSeleccionada),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _fechaSeleccionada = selectedDay;
              });
            },
            calendarStyle: CalendarStyle(
              todayDecoration:
                  BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
              selectedDecoration:
                  BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
            ),
          ),
          const SizedBox(height: 16),
          // Mostrar las transacciones del día seleccionado
          Expanded(
            child: transacciones.isNotEmpty
                ? ListView.builder(
                    itemCount: transacciones.length,
                    itemBuilder: (context, index) {
                      final transaccion = transacciones[index];
                      return ListTile(
                        title: Text(transaccion['titulo']),
                        subtitle:
                            Text('Monto: \$${transaccion['monto'].toString()}'),
                      );
                    },
                  )
                : const Center(
                    child: Text('No hay transacciones para este día')),
          ),
        ],
      ),
    );
  }
}
