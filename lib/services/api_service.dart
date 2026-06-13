import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/cita_model.dart';

class ApiService {
  // Nota: Usa '10.0.2.2' si estás usando el emulador de Android para referirte a tu localhost
  final String baseUrl = 'http://10.0.2.2:3000'; 

  Future<List<Cita>> obtenerCitas(int pacienteId) async {
    final respuesta = await http.get(Uri.parse('$baseUrl/citas/$pacienteId'));

    if (respuesta.statusCode == 200) {
      List<dynamic> cuerpo = jsonDecode(respuesta.body);
      return cuerpo.map((item) => Cita.fromJson(item)).toList();
    } else {
      throw Exception('Error al cargar las citas');
    }
  }

  Future<bool> agendarCita(int pacienteId, int medicoId, String fechaHora, String motivo) async {
    final respuesta = await http.post(
      Uri.parse('$baseUrl/citas'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'paciente_id': pacienteId,
        'medico_id': medicoId,
        'fecha_hora': fechaHora,
        'motivo': motivo,
      }),
    );
    return respuesta.statusCode == 200;
  }
  // Modificar una cita (PUT)
Future<bool> actualizarCita(int citaId, String nuevaFecha, String nuevoEstado, String nuevoMotivo) async {
  final respuesta = await http.put(
    Uri.parse('$baseUrl/citas/$citaId'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'fecha_hora': nuevaFecha,
      'estado': nuevoEstado,
      'motivo': nuevoMotivo,
    }),
  );
  return respuesta.statusCode == 200;
}

// Eliminar una cita (DELETE)
Future<bool> borrarCita(int citaId) async {
  final respuesta = await http.delete(Uri.parse('$baseUrl/citas/$citaId'));
  return respuesta.statusCode == 200;
}
Future<List<Map<String, dynamic>>> obtenerMedicos() async {
  final respuesta = await http.get(Uri.parse('$baseUrl/medicos'));
  if (respuesta.statusCode == 200) {
    List<dynamic> datos = jsonDecode(respuesta.body);
    return datos.map((m) => {'id': m['id'], 'nombre': m['nombre']}).toList();
  }
  return [];
}
}
