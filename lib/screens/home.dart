import 'package:app_finance/screens/calendario.dart';
import 'package:app_finance/screens/categorias.dart';
import 'package:app_finance/screens/graficos.dart';
import 'package:app_finance/screens/presupuestos.dart';
import 'package:app_finance/screens/transacciones.dart';
import 'package:app_finance/database/db_helper.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final BasedatoHelper _dbHelper = BasedatoHelper();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 5,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Bienvenido',
        ),
        backgroundColor: Colors.orange,
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openDrawer(); // Abrir el menú lateral
              },
            );
          },
        ),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              _showHelpDialog(context); // Muestra el diálogo de ayuda
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(
              text: 'GRÁFICOS',
              icon: Icon(Icons.graphic_eq),
            ),
            Tab(
              text: 'TRANSACCIONES',
              icon: Icon(Icons.monetization_on),
            ),
            Tab(
              text: 'CATEGORÍAS',
              icon: Icon(Icons.category_sharp),
            ),
            Tab(
              text: 'CALENDARIO',
              icon: Icon(Icons.calendar_month),
            ),
            Tab(
              text: 'PRESUPUESTO',
              icon: Icon(Icons.savings),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          GraficosScreen(),
          TransaccionesScreen(),
          CategoriasScreen(),
          CalendarioScreen(),
          PresupuestosScreen(),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            Container(
              height: 100,
              decoration: const BoxDecoration(
                color: Colors.orange,
              ),
              child: const Center(
                child: Text(
                  'App Finance',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Eliminar Base de Datos'),
              onTap: () async {
                // Mostrar el cuadro de confirmación
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('Confirmación'),
                      content: const Text(
                          '¿Seguro que deseas eliminar la información?'),
                      actions: <Widget>[
                        TextButton(
                          child: const Text('Cancelar'),
                          onPressed: () {
                            Navigator.of(context)
                                .pop(); // Cierra el cuadro de diálogo
                          },
                        ),
                        TextButton(
                          child: const Text('Eliminar'),
                          onPressed: () async {
                            // Eliminar la base de datos si el usuario confirma
                            await _dbHelper.clearDatabase();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Base de datos eliminada')),
                            );
                            Navigator.of(context)
                                .pop(); // Cierra el cuadro de diálogo
                          },
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Créditos'),
          content: const Text(
              'Puede trabajar de forma colaborativa en este proyecto en el siguiente enlace https://github.com/sebasinmiedo/app-finance.git'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cerrar'),
              onPressed: () {
                Navigator.of(context).pop(); // Cierra el diálogo
              },
            ),
          ],
        );
      },
    );
  }
}
