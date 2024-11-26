import 'package:flutter/material.dart';
import 'package:app_finance/database/db_helper.dart';

class CategoriasScreen extends StatefulWidget {
  const CategoriasScreen({super.key});

  @override
  State<CategoriasScreen> createState() => _CategoriasScreenState();
}

class _CategoriasScreenState extends State<CategoriasScreen> {
  late Future<Map<String, Map<String, dynamic>>> _dataFuture;
  String selectedTipo = 'egreso'; // Valor predeterminado

  @override
  void initState() {
    super.initState();
    _dataFuture = fetchCategorias();
  }

  Future<Map<String, Map<String, dynamic>>> fetchCategorias() async {
    final dbHelper = BasedatoHelper();
    final db = await dbHelper.database;

    // Obtenemos los grupos y las categorías desde la base de datos
    final grupos = await db.query('grupos');
    final categorias = await db.query('categorias');

    // Estructura del resultado con los grupos y sus categorías
    final Map<String, Map<String, dynamic>> data = {};

    for (final grupo in grupos) {
      final nombreGrupo = grupo['nombre'] as String? ?? 'Sin nombre';
      final descripcionGrupo =
          grupo['descripcion'] as String? ?? 'Sin descripción';
      final tipoGrupo =
          grupo['tipo'] as String? ?? 'egreso'; // Asumimos egreso si falta

      // Creamos la clave del grupo incluyendo el nombre y descripción
      final grupoKey = '$nombreGrupo ($descripcionGrupo)';

      // Filtramos las categorías asociadas a este grupo
      final categoriasDelGrupo = categorias
          .where((cat) => cat['grupo_id'] == grupo['id'])
          .map((cat) => {
                'nombre': cat['nombre'] ?? 'Sin nombre',
                'descripcion': cat['descripcion'] ?? 'Sin descripción',
              })
          .toList();

      // Añadimos al mapa la información del grupo y sus categorías
      data[grupoKey] = {
        'tipo': tipoGrupo, // Tipo del grupo (ingreso o egreso)
        'descripcion': descripcionGrupo,
        'nombre': nombreGrupo,
        'categorias': categoriasDelGrupo, // Lista de categorías
      };
    }

    return data;
  }

  Future<void> _addGrupo(String nombre, String descripcion, String tipo) async {
    final dbHelper = BasedatoHelper();
    final db = await dbHelper.database;

    await db.insert('grupos', {
      'nombre': nombre,
      'descripcion': descripcion,
      'tipo': tipo,
    });
    setState(() {
      _dataFuture = fetchCategorias();
    });
  }

  Future<void> _addCategoria(
      String nombre, String descripcion, int grupoId, String tipo) async {
    final dbHelper = BasedatoHelper();
    final db = await dbHelper.database;

    await db.insert('categorias', {
      'grupo_id': grupoId,
      'nombre': nombre,
      'descripcion': descripcion,
      'tipo': tipo,
    });
    setState(() {
      _dataFuture = fetchCategorias();
    });
  }

  void _showAddDialog(BuildContext context, {required bool isGrupo}) async {
    final TextEditingController nombreController = TextEditingController();
    final TextEditingController descripcionController = TextEditingController();
    int? selectedGrupoId;

    // Inicializar el valor de tipo localmente dentro del diálogo
    String localSelectedTipo = selectedTipo; // Usar el valor global como base

    // Si no es un grupo, obtenemos los grupos de la base de datos
    if (!isGrupo) {
      final dbHelper = BasedatoHelper();
      final grupos = await dbHelper.database.then((db) => db.query('grupos'));
      if (grupos.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Primero debes agregar un grupo')),
        );
        return;
      }
      selectedGrupoId = grupos.first['id'] as int;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isGrupo ? 'Agregar Grupo' : 'Agregar Categoría'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Campos de texto para nombre y descripción
                  TextField(
                    controller: nombreController,
                    decoration: const InputDecoration(labelText: 'Nombre'),
                  ),
                  TextField(
                    controller: descripcionController,
                    decoration: const InputDecoration(labelText: 'Descripción'),
                  ),
                  // Botones de Ingreso y Egreso
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: localSelectedTipo == 'ingreso'
                              ? Colors.green
                              : Colors.grey, // Verde si seleccionado
                        ),
                        onPressed: () {
                          setState(() {
                            localSelectedTipo = 'ingreso';
                          });
                        },
                        child: const Text(
                          'Ingreso',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: localSelectedTipo == 'egreso'
                              ? Colors.red
                              : Colors.grey, // Rojo si seleccionado
                        ),
                        onPressed: () {
                          setState(() {
                            localSelectedTipo = 'egreso';
                          });
                        },
                        child: const Text('Egreso',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                  if (!isGrupo)
                    FutureBuilder<List<Map<String, dynamic>>>(
                      future: BasedatoHelper()
                          .database
                          .then((db) => db.query('grupos')),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        } else if (snapshot.hasError ||
                            snapshot.data!.isEmpty) {
                          return const Text('No hay grupos disponibles.');
                        }

                        final gruposFiltrados = snapshot.data!.where((grupo) {
                          return grupo['tipo'] == localSelectedTipo;
                        }).toList();

                        if (gruposFiltrados.isEmpty) {
                          return const Text(
                              'No hay grupos para el tipo seleccionado.');
                        }

                        if (!gruposFiltrados
                            .any((grupo) => grupo['id'] == selectedGrupoId)) {
                          selectedGrupoId = gruposFiltrados[0]['id'] as int;
                        }

                        return DropdownButton<int>(
                          value: selectedGrupoId,
                          isExpanded: true,
                          items: gruposFiltrados.map((grupo) {
                            return DropdownMenuItem<int>(
                              value: grupo['id'] as int,
                              child: Text(grupo['nombre'] as String),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedGrupoId = value;
                            });
                          },
                        );
                      },
                    )
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final nombre = nombreController.text.trim();
                final descripcion = descripcionController.text.trim();

                if (nombre.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('El nombre no puede estar vacío')),
                  );
                  return;
                }

                if (isGrupo) {
                  _addGrupo(nombre, descripcion, localSelectedTipo);
                } else if (selectedGrupoId != null) {
                  _addCategoria(
                      nombre, descripcion, selectedGrupoId!, localSelectedTipo);
                }

                Navigator.of(context).pop();
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Map<String, Map<String, dynamic>>>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            final data = snapshot.data!;
            return ListView.builder(
              itemCount: data.keys.length,
              itemBuilder: (context, index) {
                // Ordenamos los grupos, primero 'egreso', luego 'ingreso'
                final sortedKeys = data.keys.toList()
                  ..sort((a, b) {
                    final tipoA = data[a]?['tipo'];
                    final tipoB = data[b]?['tipo'];
                    // Primero 'egreso', luego 'ingreso'
                    if (tipoA == 'egreso' && tipoB == 'ingreso') return -1;
                    if (tipoA == 'ingreso' && tipoB == 'egreso') return 1;
                    return 0; // No cambiamos el orden si son del mismo tipo
                  });

                final grupoKey = sortedKeys[index];
                final grupoData = data[grupoKey] as Map<String, dynamic>;
                final tipo = grupoData['tipo'] as String;
                final String nombreGrupo = grupoData['nombre'] as String;
                final String descripcionGrupo =
                    grupoData['descripcion'] as String;
                final categorias =
                    grupoData['categorias'] as List<Map<String, dynamic>>;

                return Card(
                  margin: const EdgeInsets.all(8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  color:
                      tipo == 'ingreso' ? Colors.green[100] : Colors.red[100],
                  elevation: 4,
                  child: ExpansionTile(
                    initiallyExpanded: false,
                    title: Text(
                      nombreGrupo,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.black,
                      ),
                    ),
                    subtitle: Text(
                      descripcionGrupo,
                      style: TextStyle(
                        color: Colors.black.withOpacity(0.5),
                      ),
                    ),
                    children: categorias
                        .map((categoria) => ListTile(
                              contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 35),
                              title: Text(categoria['nombre'] as String,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              subtitle: Text(
                                categoria['descripcion'] as String,
                                style: TextStyle(
                                    color: Colors.black.withOpacity(0.5)),
                              ),
                            ))
                        .toList(),
                  ),
                );
              },
            );
          } else {
            return const Center(child: Text('No hay grupos ni categorías.'));
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            builder: (context) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.group),
                    title: const Text('Agregar Grupo'),
                    onTap: () {
                      Navigator.of(context).pop();
                      _showAddDialog(context, isGrupo: true);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.category),
                    title: const Text('Agregar Categoría'),
                    onTap: () {
                      Navigator.of(context).pop();
                      _showAddDialog(context, isGrupo: false);
                    },
                  ),
                ],
              );
            },
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
