import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';
import 'package:app_finance/database/db_helper.dart';

class TransaccionesScreen extends StatefulWidget {
  const TransaccionesScreen({super.key});

  @override
  State<TransaccionesScreen> createState() => _TransaccionesScreenState();
}

class _TransaccionesScreenState extends State<TransaccionesScreen> {
  late Database db; // Base de datos local
  List<Map<String, dynamic>> transacciones = [];

  // Variables para los dropdowns
  List<Map<String, dynamic>> grupos = [];
  List<Map<String, dynamic>> categorias = [];
  String? tipoSeleccionado;
  int? grupoSeleccionado;
  int? categoriaSeleccionada;
  DateTime? fechaSeleccionada;
  TimeOfDay? horaSeleccionada; // Variable para almacenar la hora seleccionada

  @override
  void initState() {
    super.initState();
    _inicializarBaseDeDatos();
  }

  Future<void> _inicializarBaseDeDatos() async {
    db = await BasedatoHelper()
        .database; // Se obtiene la instancia de la base de datos
    _cargarTransacciones();
  }

  Future<void> _cargarTransacciones() async {
    final data = await db.rawQuery('''
      SELECT t.id, t.titulo, t.descripcion, t.tipo, t.monto, t.fecha, 
             c.nombre AS categoria, g.nombre AS grupo
      FROM transacciones t
      JOIN categorias c ON t.categoria_id = c.id
      JOIN grupos g ON c.grupo_id = g.id
      ORDER BY t.fecha DESC;
    ''');

    setState(() {
      transacciones = data;
    });
  }

  Future<void> _agregarTransaccion(
    String titulo,
    String descripcion,
    String tipo,
    double monto,
    int categoriaId,
    DateTime fecha,
  ) async {
    // Almacenamos la fecha y la hora
    final DateTime fechaCompleta = DateTime(
      fecha.year,
      fecha.month,
      fecha.day,
      horaSeleccionada?.hour ?? 0,
      horaSeleccionada?.minute ?? 0,
    );
    await db.insert('transacciones', {
      'titulo': titulo,
      'descripcion': descripcion.isEmpty
          ? null
          : descripcion, // Guardar descripción vacía como null
      'tipo': tipo,
      'monto': monto,
      'categoria_id': categoriaId,
      'fecha': fechaCompleta
          .toIso8601String(), // Almacenamos la fecha y hora combinadas
    });
    _cargarTransacciones();
  }

  Future<void> cargarGrupos(String tipo) async {
    final data = await db.rawQuery('''
      SELECT g.id, g.nombre
      FROM grupos g
      WHERE g.tipo = ?;
    ''', [tipo]);

    setState(() {
      grupos = data;
      grupoSeleccionado = null; // Resetear el grupo seleccionado
      categorias = []; // Resetear las categorías
      categoriaSeleccionada = null; // Resetear la categoría seleccionada
    });
  }

  Future<void> cargarCategorias(int grupoId) async {
    final data = await db.query(
      'categorias',
      where: 'grupo_id = ?',
      whereArgs: [grupoId],
    );

    setState(() {
      categorias = data;
      categoriaSeleccionada = null; // Resetear la categoría seleccionada
    });
  }

  Future<void> _editarTransaccion(
    int id,
    String titulo,
    String descripcion,
    String tipo,
    double monto,
    int categoriaId,
    DateTime fecha,
  ) async {
    final DateTime fechaCompleta = DateTime(
      fecha.year,
      fecha.month,
      fecha.day,
      horaSeleccionada?.hour ?? 0,
      horaSeleccionada?.minute ?? 0,
    );

    await db.update(
      'transacciones',
      {
        'titulo': titulo,
        'descripcion': descripcion.isEmpty ? null : descripcion,
        'tipo': tipo,
        'monto': monto,
        'categoria_id': categoriaId,
        'fecha': fechaCompleta.toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    _cargarTransacciones();
  }

  Future<void> _eliminarTransaccion(int id) async {
    await db.delete(
      'transacciones',
      where: 'id = ?',
      whereArgs: [id],
    );
    _cargarTransacciones();
  }

  @override
  Widget build(BuildContext context) {
    Map<String, List<Map<String, dynamic>>> transaccionesPorDia = {};
    for (var transaccion in transacciones) {
      String dia = transaccion['fecha'].split('T')[0];
      if (!transaccionesPorDia.containsKey(dia)) {
        transaccionesPorDia[dia] = [];
      }
      transaccionesPorDia[dia]!.add(transaccion);
    }

    return Scaffold(
      body: transacciones.isEmpty
          ? const Center(child: Text("No hay transacciones registradas."))
          : ListView(
              children: transaccionesPorDia.entries.map((entry) {
                String dia = entry.key;
                List<Map<String, dynamic>> transaccionesDelDia = entry.value;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Row(
                        children: [
                          Text(
                            '${DateFormat('EEEE', 'es').format(DateTime.parse(dia)).toUpperCase()} ',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors
                                  .blue, // Estilo para el día de la semana
                            ),
                          ),
                          Text(
                            DateFormat('dd/MM/yyyy')
                                .format(DateTime.parse(dia)),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black, // Estilo para la fecha
                            ),
                          ),
                        ],
                      ),
                    ),
                    ...transaccionesDelDia.map((transaccion) {
                      DateTime fechaTransaccion =
                          DateTime.parse(transaccion['fecha']);
                      String hora =
                          DateFormat('HH:mm').format(fechaTransaccion);
                      return ListTile(
                        title: Text(transaccion['titulo'],
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                '${transaccion['grupo']} - ${transaccion['categoria']}'),
                            Text('Hora: $hora'),
                            Text(
                                'Descripción: ${transaccion['descripcion'] ?? "No disponible"}'),
                          ],
                        ),
                        trailing: Wrap(
                          spacing: 1, // Espaciado entre botones
                          children: [
                            Text(
                              'S/. ${transaccion['monto']}',
                              style: TextStyle(
                                color: transaccion['tipo'] == 'ingreso'
                                    ? Colors.green
                                    : Colors.red,
                                fontSize: 15,
                              ),
                            ),
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert,
                                  color: Colors.blue),
                              onSelected: (value) {
                                if (value == 'edit') {
                                  mostrarDialogoEditarTransaccion(
                                      context, transaccion);
                                } else if (value == 'delete') {
                                  _eliminarTransaccion(transaccion['id']);
                                }
                              },
                              itemBuilder: (BuildContext context) {
                                return [
                                  const PopupMenuItem<String>(
                                    value: 'edit',
                                    child: Text('Editar'),
                                  ),
                                  const PopupMenuItem<String>(
                                    value: 'delete',
                                    child: Text('Eliminar'),
                                  ),
                                ];
                              },
                            ),
                          ],
                        ),
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: Text(transaccion['titulo']),
                              content: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                      'Descripción: ${transaccion['descripcion'] ?? "No disponible"}'),
                                  Text('Tipo: ${transaccion['tipo']}'),
                                  Text('Monto: \$${transaccion['monto']}'),
                                  Text(
                                      'Fecha: ${DateFormat('yyyy-MM-dd').format(fechaTransaccion)}'),
                                  Text('Hora: $hora'),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    }).toList(),
                  ],
                );
              }).toList(),
            ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          mostrarDialogoAgregarTransaccion(context);
        },
      ),
    );
  }

  Future<void> mostrarDialogoEditarTransaccion(
      BuildContext context, Map<String, dynamic> transaccion) async {
    final _tituloController =
        TextEditingController(text: transaccion['titulo']);
    final _descripcionController =
        TextEditingController(text: transaccion['descripcion'] ?? "");
    final _montoController =
        TextEditingController(text: transaccion['monto'].toString());

    int? categoriaId = transaccion['categoria_id'];
    String? tipoSeleccionado = transaccion['tipo'];
    DateTime fecha = DateTime.parse(transaccion['fecha']);
    TimeOfDay? horaSeleccionada = TimeOfDay.fromDateTime(fecha);

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Editar Transacción"),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(
                      controller: _tituloController,
                      decoration: const InputDecoration(labelText: "Título"),
                    ),
                    TextField(
                      controller: _descripcionController,
                      decoration:
                          const InputDecoration(labelText: "Descripción"),
                    ),
                    TextField(
                      controller: _montoController,
                      decoration: const InputDecoration(labelText: "Monto"),
                      keyboardType: TextInputType.number,
                    ),
                    DropdownButtonFormField<String>(
                      value: tipoSeleccionado,
                      items: const [
                        DropdownMenuItem(
                            value: "ingreso", child: Text("Ingreso")),
                        DropdownMenuItem(
                            value: "egreso", child: Text("Egreso")),
                      ],
                      onChanged: (value) async {
                        setDialogState(() {
                          tipoSeleccionado = value;
                        });
                        if (value != null) {
                          await cargarGrupos(value);
                          setDialogState(() {});
                        }
                      },
                      decoration: const InputDecoration(labelText: "Tipo"),
                    ),
                    if (tipoSeleccionado != null)
                      DropdownButtonFormField<int>(
                        value: grupoSeleccionado,
                        items: grupos.map((grupo) {
                          return DropdownMenuItem<int>(
                            value: grupo["id"],
                            child: Text(grupo["nombre"]),
                          );
                        }).toList(),
                        onChanged: (value) async {
                          setDialogState(() {
                            grupoSeleccionado = value;
                            categorias = [];
                          });
                          if (value != null) {
                            await cargarCategorias(value);
                          }
                        },
                        decoration: const InputDecoration(labelText: "Grupo"),
                      ),
                    DropdownButtonFormField<int>(
                      value: categoriaId,
                      items: categorias.map((categoria) {
                        return DropdownMenuItem<int>(
                          value: categoria["id"],
                          child: Text(categoria["nombre"]),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          categoriaId = value;
                        });
                      },
                      decoration: const InputDecoration(labelText: "Categoría"),
                    ),
                    ListTile(
                      title: Text(
                          'Fecha: ${DateFormat('yyyy-MM-dd').format(fecha)}',
                          style: const TextStyle(fontSize: 13)),
                      trailing: IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: () async {
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: fecha,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setDialogState(() {
                              fecha = DateTime(
                                picked.year,
                                picked.month,
                                picked.day,
                                fecha.hour,
                                fecha.minute,
                              );
                            });
                          }
                        },
                      ),
                    ),
                    ListTile(
                      title: Text(
                          'Hora: ${horaSeleccionada?.format(context) ?? ''}',
                          style: const TextStyle(fontSize: 13)),
                      trailing: IconButton(
                        icon: const Icon(Icons.access_time),
                        onPressed: () async {
                          final TimeOfDay? picked = await showTimePicker(
                            context: context,
                            initialTime: horaSeleccionada ?? TimeOfDay.now(),
                          );
                          if (picked != null) {
                            setDialogState(() {
                              horaSeleccionada = picked;
                              fecha = DateTime(
                                fecha.year,
                                fecha.month,
                                fecha.day,
                                picked.hour,
                                picked.minute,
                              );
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text("Cancelar"),
                ),
                TextButton(
                  onPressed: () async {
                    final titulo = _tituloController.text;
                    final descripcion = _descripcionController.text;
                    final monto = double.tryParse(_montoController.text) ?? 0;

                    if (titulo.isNotEmpty && categoriaId != null) {
                      await db.update(
                        'transacciones',
                        {
                          'titulo': titulo,
                          'descripcion':
                              descripcion.isEmpty ? null : descripcion,
                          'tipo': tipoSeleccionado,
                          'monto': monto,
                          'categoria_id': categoriaId,
                          'fecha': fecha.toIso8601String(),
                        },
                        where: 'id = ?',
                        whereArgs: [transaccion['id']],
                      );
                      _cargarTransacciones();
                      Navigator.pop(context);
                    }
                  },
                  child: const Text("Guardar"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> mostrarDialogoAgregarTransaccion(BuildContext context) async {
    final _tituloController = TextEditingController();
    final _descripcionController = TextEditingController();
    final _montoController = TextEditingController();

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Agregar Transacción"),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(
                      controller: _tituloController,
                      decoration: const InputDecoration(labelText: "Título"),
                    ),
                    TextField(
                      controller: _descripcionController,
                      decoration:
                          const InputDecoration(labelText: "Descripción"),
                    ),
                    TextField(
                      controller: _montoController,
                      decoration: const InputDecoration(labelText: "Monto"),
                      keyboardType: TextInputType.number,
                    ),
                    DropdownButtonFormField<String>(
                      value: tipoSeleccionado,
                      items: const [
                        DropdownMenuItem(
                            value: "ingreso", child: Text("Ingreso")),
                        DropdownMenuItem(
                            value: "egreso", child: Text("Egreso")),
                      ],
                      onChanged: (value) async {
                        setDialogState(() {
                          tipoSeleccionado = value;
                          grupos = [];
                          categorias = [];
                          grupoSeleccionado = null;
                          categoriaSeleccionada = null;
                        });
                        if (value != null) {
                          await cargarGrupos(value);
                          setDialogState(() {});
                        }
                      },
                      decoration: const InputDecoration(labelText: "Tipo"),
                    ),
                    if (tipoSeleccionado != null)
                      DropdownButtonFormField<int>(
                        value: grupoSeleccionado,
                        items: grupos.map((grupo) {
                          return DropdownMenuItem<int>(
                            value: grupo["id"],
                            child: Text(grupo["nombre"]),
                          );
                        }).toList(),
                        onChanged: (value) async {
                          setDialogState(() {
                            grupoSeleccionado = value;
                            categorias = [];
                            categoriaSeleccionada = null;
                          });
                          if (value != null) {
                            await cargarCategorias(value);
                          }
                        },
                        decoration: const InputDecoration(labelText: "Grupo"),
                      ),
                    if (grupoSeleccionado != null)
                      DropdownButtonFormField<int>(
                        value: categoriaSeleccionada,
                        items: categorias.map((categoria) {
                          return DropdownMenuItem<int>(
                            value: categoria["id"],
                            child: Text(categoria["nombre"]),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setDialogState(() {
                            categoriaSeleccionada = value;
                          });
                        },
                        decoration:
                            const InputDecoration(labelText: "Categoría"),
                      ),
                    ListTile(
                      title: Text(
                          'Fecha: ${fechaSeleccionada != null ? DateFormat('yyyy-MM-dd').format(fechaSeleccionada!) : 'Selecciona una fecha'}',
                          style: const TextStyle(fontSize: 13)),
                      trailing: IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: () async {
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: fechaSeleccionada ?? DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setDialogState(() {
                              fechaSeleccionada = DateTime(
                                picked.year,
                                picked.month,
                                picked.day,
                                fechaSeleccionada?.hour ?? 0,
                                fechaSeleccionada?.minute ?? 0,
                              );
                            });
                          }
                        },
                      ),
                    ),
                    ListTile(
                      title: Text(
                        'Hora: ${horaSeleccionada != null ? horaSeleccionada!.format(context) : 'Selecciona una hora'}',
                        style: const TextStyle(fontSize: 13),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.access_time),
                        onPressed: () async {
                          final TimeOfDay? picked = await showTimePicker(
                            context: context,
                            initialTime: horaSeleccionada ?? TimeOfDay.now(),
                          );
                          if (picked != null) {
                            setDialogState(() {
                              horaSeleccionada = picked;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text("Cancelar"),
                ),
                TextButton(
                  onPressed: () {
                    final titulo = _tituloController.text.trim();
                    final descripcion = _descripcionController.text.trim();
                    final monto = double.tryParse(_montoController.text) ?? 0;

                    // Validar campos obligatorios
                    if (titulo.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('El campo Título es obligatorio'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    if (tipoSeleccionado == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Debe seleccionar un tipo'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    if (categoriaSeleccionada == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Debe seleccionar una categoría'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    // Agregar la transacción si todo está correcto
                    try {
                      _agregarTransaccion(
                        titulo,
                        descripcion,
                        tipoSeleccionado!,
                        monto,
                        categoriaSeleccionada!,
                        fechaSeleccionada ?? DateTime.now(),
                      );

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Transacción guardada exitosamente'),
                          backgroundColor: Colors.green,
                        ),
                      );

                      Navigator.pop(context);
                    } catch (e) {
                      // Mostrar mensaje de error
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'Ocurrió un error al guardar la transacción: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  child: const Text("Guardar"),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
