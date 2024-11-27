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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
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
          Center(child: Text('Calendario')),
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
              leading: const Icon(Icons.home),
              title: const Text('Inicio'),
              onTap: () async {
                final dbHelper = BasedatoHelper();
                await dbHelper.clearDatabase();
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Configuración'),
              onTap: () async {
                final dbHelper = BasedatoHelper();
                await dbHelper.printAllRecords();
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
          title: const Text('Ayuda'),
          content: const Text('Aquí va la información de ayuda.'),
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
