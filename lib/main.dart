import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'models/cita_model.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Citas Médicas',
      home: PantallaCitas(),
    );
  }
}

class PantallaCitas extends StatefulWidget {
  const PantallaCitas({super.key});

  @override
  State<PantallaCitas> createState() => _PantallaCitasState();
}

class _PantallaCitasState extends State<PantallaCitas> {
  final ApiService apiService = ApiService();
  late Future<List<Cita>> futuroCitas;
  final int pacienteIdSimulado = 1; // ID de prueba basado en tu base de datos

  @override
  void initState() {
    super.initState();
    futuroCitas = apiService.obtenerCitas(pacienteIdSimulado);
  }

  void _refrescarCitas() {
    setState(() {
      futuroCitas = apiService.obtenerCitas(pacienteIdSimulado);
    });
  }
  void _mostrarDialogoEditar(Cita cita) async {
  // 1. Cargamos los médicos desde la API
  List<Map<String, dynamic>> medicos = await apiService.obtenerMedicos();
  
  // 2. Controladores
  final TextEditingController motivoController = TextEditingController(text: "Consulta de revisión");
  DateTime fechaSeleccionada = cita.fechaHora;
  
  // CUIDADO AQUÍ: Asegúrate de que el ID por defecto sea un número válido de la lista
  int? medicoSeleccionadoId;
  if (medicos.isNotEmpty) {
    medicoSeleccionadoId = medicos.first['id'] as int;
  }

  if (!mounted) return;
  
  // 3. Mostrar el cuadro de diálogo
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder( // Permite actualizar el estado interno del Pop-up
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Editar Cita Médica'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // CAMPO 1: Selección de Médico (Dropdown)
                  const ListTile(title: Text("Seleccione Médico:", style: TextStyle(fontWeight: FontWeight.bold))),
                  DropdownButton<int>(
                    value: medicoSeleccionadoId,
                    isExpanded: true,
                    items: medicos.map((medico) {
                      return DropdownMenuItem<int>(
                        value: medico['id'],
                        child: Text(medico['nombre']),
                      );
                    }).toList(),
                    onChanged: (nuevoId) {
                      setDialogState(() { medicoSeleccionadoId = nuevoId; });
                    },
                  ),
                  const Divider(),

                  // CAMPO 2: Selección de Fecha y Hora (Botón Nativo)
                  ListTile(
                    title: const Text("Fecha y Hora:", style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(fechaSeleccionada.toString().substring(0, 16)),
                    trailing: const Icon(Icons.calendar_month),
                    onTap: () async {
                      // Selector de Fecha
                      DateTime? fecha = await showDatePicker(
                        context: context,
                        initialDate: fechaSeleccionada,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (fecha != null) {
                        // Selector de Hora
                        if (!context.mounted) return;
                        TimeOfDay? hora = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(fechaSeleccionada),
                        );
                        if (hora != null) {
                          setDialogState(() {
                            fechaSeleccionada = DateTime(
                              fecha.year, fecha.month, fecha.day, hora.hour, hora.minute
                            );
                          });
                        }
                      }
                    },
                  ),
                  const Divider(),

                  // CAMPO 3: Cuadro de texto para escribir el Motivo
                  const ListTile(title: Text("Motivo de la Cita:", style: TextStyle(fontWeight: FontWeight.bold))),
                  TextField(
                    controller: motivoController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Ej. Dolor de cabeza, control...',
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                child: const Text('Cancelar'),
                onPressed: () => Navigator.of(context).pop(),
              ),
              ElevatedButton(
                child: const Text('Guardar Cambios'),
                onPressed: () async {
                  // Enviamos los datos reales ingresados por el usuario al servidor
                  bool editado = await apiService.actualizarCita(
                    cita.id, 
                    fechaSeleccionada.toIso8601String(), 
                    'pendiente', // Regresa a pendiente para revisión médica
                    motivoController.text
                  );

                  if (editado) {
                    _refrescarCitas();
                    if (!context.mounted) return;
                    Navigator.of(context).pop(); // Cierra el Pop-up
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('¡Cita modificada con éxito!'))
                    );
                  }
                },
              ),
            ],
          );
        },
      );
    },
  );
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis Citas Médicas')),
      body: FutureBuilder<List<Cita>>(
        future: futuroCitas,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No tienes citas agendadas.'));
          }

          return ListView.builder(
  itemCount: snapshot.data!.length,
  itemBuilder: (context, index) {
    final cita = snapshot.data![index];
    return ListTile(
      leading: const Icon(Icons.calendar_today, color: Colors.blue),
      title: Text('Médico ID: ${cita.medico}'),
      subtitle: Text('Fecha: ${cita.fechaHora.toString()}\nEstado: ${cita.estado}'),
      isThreeLine: true,
      trailing: Row(
        mainAxisSize: MainAxisSize.min, // Ajusta el espacio horizontal de los botones
        children: [
          // BOTÓN PARA CAMBIAR/EDITAR INFORMACIÓN
          IconButton(
  icon: const Icon(Icons.edit, color: Colors.orange),
  onPressed: () {
    // Al presionar el lápiz, abrimos el formulario interactivo enviando la cita elegida
    _mostrarDialogoEditar(cita);
  },
),
          // BOTÓN PARA BORRAR INFORMACIÓN
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () async {
              bool borrado = await apiService.borrarCita(cita.id);
              
              if (borrado) {
                _refrescarCitas();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Cita eliminada de la agenda'))
                );
              }
            },
          ),
        ],
      ),
    );
  },


          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Acción simplificada: Agenda una cita rápida para pruebas
          bool exito = await apiService.agendarCita(
            pacienteIdSimulado, 
            2, // Médico ID simulado
            DateTime.now().add(const Duration(days: 2)).toIso8601String(), 
            'Consulta General'
          );
          if (exito) {
            _refrescarCitas();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('¡Cita agendada con éxito!'))
            );
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
