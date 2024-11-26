import 'package:flutter/material.dart';
import 'package:app_finance/database/db_helper.dart';
import 'package:intl/intl.dart'; // Importar para formatear fechas

class PresupuestosScreen extends StatefulWidget {
  const PresupuestosScreen({super.key});

  @override
  State<PresupuestosScreen> createState() => _PresupuestosScreenState();
}

class _PresupuestosScreenState extends State<PresupuestosScreen> {
  List<Map<String, dynamic>> _presupuestos = [];
  final _databaseHelper = BasedatoHelper();

  // Variables de fechas
  DateTime? inicio;
  DateTime? fin;

  @override
  void initState() {
    super.initState();
    _fetchPresupuestos();
  }

  Future<void> _fetchPresupuestos() async {
    final db = await _databaseHelper.database;

    final query = '''
      SELECT g.id AS grupo_id, g.nombre AS grupo_nombre, 
             c.id AS categoria_id, c.nombre AS categoria_nombre,
             p.tipo, p.monto, p.inicio, p.fin, p.id AS presupuesto_id
      FROM grupos g
      LEFT JOIN categorias c ON c.grupo_id = g.id
      LEFT JOIN presupuestos p 
           ON (p.grupo_id = g.id AND p.tipo = 'grupo') 
           OR (p.categoria_id = c.id AND p.tipo = 'categoria')
      ORDER BY g.nombre, c.nombre;
    ''';

    final presupuestos = await db.rawQuery(query);

    setState(() {
      _presupuestos = presupuestos;
    });
  }

  String _formatFecha(DateTime fecha) {
    return DateFormat('d MMMM yyyy', 'es').format(fecha); // Formateo en español
  }

  // Función para mostrar el DatePicker
  Future<DateTime> _selectDate(BuildContext context, bool isInicio) async {
    final DateTime picked = await showDatePicker(
          context: context,
          initialDate: isInicio
              ? (inicio ?? DateTime.now())
              : (fin ?? DateTime.now().add(Duration(days: 30))),
          firstDate: DateTime(2000),
          lastDate: DateTime(2101),
        ) ??
        DateTime.now(); // Si el usuario cancela, asigna la fecha actual

    return picked; // Retorna la fecha seleccionada
  }

  Future<void> _showPresupuestoDialog({
    required String tipo,
    required int referenciaId,
    Map<String, dynamic>? presupuesto,
  }) async {
    final db = await _databaseHelper.database;

    // Asignamos los valores de inicio y fin si existen en el presupuesto
    inicio = presupuesto != null
        ? DateTime.parse(presupuesto['inicio'])
        : DateTime.now();
    fin = presupuesto != null
        ? DateTime.parse(presupuesto['fin'])
        : DateTime.now().add(Duration(days: 30));

    TextEditingController montoController = TextEditingController(
      text: presupuesto != null ? presupuesto['monto'].toString() : '',
    );

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            // Cuando las fechas cambian, se debe reconstruir el diálogo
            return AlertDialog(
              title: Text(presupuesto == null
                  ? 'Agregar Presupuesto'
                  : 'Editar Presupuesto'),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      decoration: const InputDecoration(labelText: 'Monto'),
                      controller: montoController,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    // Selector de fecha de inicio
                    Row(
                      children: [
                        Text(
                          'Inicio: ${_formatFecha(inicio!)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.calendar_today),
                          onPressed: () async {
                            // Seleccionar fecha de inicio y actualizar el estado del diálogo
                            final selectedDate =
                                await _selectDate(context, true);
                            setStateDialog(() {
                              inicio = selectedDate;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Selector de fecha de fin
                    Row(
                      children: [
                        Text(
                          'Fin: ${_formatFecha(fin!)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.calendar_today),
                          onPressed: () async {
                            // Seleccionar fecha de fin y actualizar el estado del diálogo
                            final selectedDate =
                                await _selectDate(context, false);
                            setStateDialog(() {
                              fin = selectedDate;
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () async {
                    // Validar si el campo de monto está vacío
                    if (montoController.text.isEmpty) {
                      // Mostrar un mensaje de error si el campo monto está vacío
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content:
                              Text('El campo de monto no puede estar vacío'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return; // Evitar continuar si el monto está vacío
                    }

                    // Si el monto no está vacío, continuar con la creación o actualización
                    final data = {
                      'tipo': tipo,
                      tipo == 'grupo' ? 'grupo_id' : 'categoria_id':
                          referenciaId,
                      'monto': double.parse(montoController.text),
                      'inicio': inicio!.toIso8601String(),
                      'fin': fin!.toIso8601String(),
                    };

                    try {
                      if (presupuesto == null) {
                        // Insertar un nuevo presupuesto
                        await db.insert('presupuestos', data);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Presupuesto guardado exitosamente'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } else {
                        // Actualizar un presupuesto existente
                        await db.update(
                          'presupuestos',
                          data,
                          where: 'id = ?',
                          whereArgs: [presupuesto['presupuesto_id']],
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content:
                                Text('Presupuesto actualizado exitosamente'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }

                      // Recargar los presupuestos después de guardar o actualizar
                      _fetchPresupuestos();
                      Navigator.pop(context); // Cerrar el diálogo
                    } catch (e) {
                      // Mostrar un mensaje de error si algo falla al guardar
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error al guardar el presupuesto: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  child: const Text('Guardar'),
                )
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deletePresupuesto(int presupuestoId) async {
    final db = await _databaseHelper.database;
    await db.delete(
      'presupuestos',
      where: 'id = ?',
      whereArgs: [presupuestoId],
    );
    _fetchPresupuestos();
  }

  Widget _buildPresupuestosList() {
    Map<int, List<Map<String, dynamic>>> groupedPresupuestos = {};

    for (var item in _presupuestos) {
      int groupId = item['grupo_id'];
      groupedPresupuestos[groupId] ??= [];
      groupedPresupuestos[groupId]!.add(item);
    }

    return ListView(
      padding: const EdgeInsets.all(8),
      children: groupedPresupuestos.entries.map((entry) {
        int groupId = entry.key;
        String groupName = entry.value.first['grupo_nombre'];

        return Card(
          elevation: 4,
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  groupName,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Divider(),
                ...entry.value.map((item) {
                  if (item['categoria_id'] == null) {
                    // Presupuesto del grupo
                    return item['presupuesto_id'] == null
                        ? ElevatedButton(
                            onPressed: () => _showPresupuestoDialog(
                                tipo: 'grupo', referenciaId: groupId),
                            child: const Text('Agregar Presupuesto al Grupo'),
                          )
                        : ListTile(
                            title: const Text('Presupuesto del Grupo'),
                            subtitle: Text('Monto: S/. ${item['monto']}'),
                            trailing: PopupMenuButton(
                              onSelected: (value) {
                                if (value == 'editar') {
                                  _showPresupuestoDialog(
                                      tipo: 'grupo',
                                      referenciaId: groupId,
                                      presupuesto: item);
                                } else if (value == 'eliminar') {
                                  _deletePresupuesto(item['presupuesto_id']);
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                    value: 'editar', child: Text('Editar')),
                                const PopupMenuItem(
                                    value: 'eliminar', child: Text('Eliminar')),
                              ],
                            ),
                          );
                  } else {
                    // Presupuesto de la categoría
                    return ListTile(
                      title: Text(item['categoria_nombre']),
                      subtitle: item['presupuesto_id'] == null
                          ? const Text('Sin presupuesto asignado')
                          : Text('Monto: S/. ${item['monto']}'),
                      trailing: item['presupuesto_id'] == null
                          ? ElevatedButton(
                              onPressed: () => _showPresupuestoDialog(
                                  tipo: 'categoria',
                                  referenciaId: item['categoria_id']),
                              child: const Text('Agregar'),
                            )
                          : PopupMenuButton(
                              onSelected: (value) {
                                if (value == 'editar') {
                                  _showPresupuestoDialog(
                                      tipo: 'categoria',
                                      referenciaId: item['categoria_id'],
                                      presupuesto: item);
                                } else if (value == 'eliminar') {
                                  _deletePresupuesto(item['presupuesto_id']);
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                    value: 'editar', child: Text('Editar')),
                                const PopupMenuItem(
                                    value: 'eliminar', child: Text('Eliminar')),
                              ],
                            ),
                    );
                  }
                }).toList(),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildPresupuestosList(),
    );
  }
}
