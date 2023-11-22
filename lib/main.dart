// ignore_for_file: library_private_types_in_public_api, prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Registro de Finanzas',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late Database _database;
  double _income = 0.0;
  double _expense = 0.0;

  @override
  void initState() {
    super.initState();
    _initDatabase();
  }

  Future<void> _initDatabase() async {
    _database = await openDatabase(
      join(await getDatabasesPath(), 'finance_database.db'),
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE transactions(id INTEGER PRIMARY KEY, type TEXT, amount REAL)',
        );
      },
      version: 1,
    );
    _updateBalance();
  }

  Future<void> _updateBalance() async {
    final List<Map<String, dynamic>> transactions = await _database.query('transactions');
    double income = 0.0;
    double expense = 0.0;

    for (var transaction in transactions) {
      if (transaction['type'] == 'income') {
        income += transaction['amount'] as double;
      } else {
        expense += transaction['amount'] as double;
      }
    }

    setState(() {
      _income = income;
      _expense = expense;
    });
  }

  Future<void> _addTransaction(String type, BuildContext context) async {
    double? amount = await showDialog<double>(
      context: context,
      builder: (BuildContext context) {
        TextEditingController controller = TextEditingController();
        return AlertDialog(
          title: Text('Agregar $type'),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Monto'),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Agregar'),
              onPressed: () {
                double? enteredAmount = double.tryParse(controller.text);
                if (enteredAmount != null && enteredAmount > 0) {
                  Navigator.of(context).pop(enteredAmount);
                } else {
                  // Show error or handle invalid input
                }
              },
            ),
          ],
        );
      },
    );

    if (amount != null) {
      await _performTransaction(type, amount);
    }
  }

  Future<void> _performTransaction(String type, double amount) async {
    if (type == 'expense' && amount > _income - _expense) {
      // No permitir egresos mayores a ingresos
      return;
    }

    await _database.insert(
      'transactions',
      {'type': type, 'amount': amount},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    _updateBalance();
  }

  Future<void> _resetData() async {
    await _database.delete('transactions');
    _updateBalance();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro de Finanzas'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ListTile(
              title: const Text(
                'Ingresos:',
                style: TextStyle(fontSize: 24),
              ),
              trailing: Text(
                '\$ ${_income.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 24, color: Colors.green),
              ),
            ),
            ListTile(
              title: const Text(
                'Egresos:',
                style: TextStyle(fontSize: 24),
              ),
              trailing: Text(
                '\$ ${_expense.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 24, color: Colors.red),
              ),
            ),
            ListTile(
              title: const Text(
                'Saldo:',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              trailing: Text(
                '\$ ${(_income - _expense).toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _addTransaction('income', context),
              child: const Text('Agregar Ingreso'),
            ),
            ElevatedButton(
              onPressed: () => _addTransaction('expense', context),
              child: const Text('Agregar Egreso'),
            ),
            ElevatedButton(
              onPressed: () => _resetData(),
              child: const Text('Restablecer Datos'),
            ),
          ],
        ),
      ),
    );
  }
}
