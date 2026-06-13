class Cita {
  final int id;
  final String medico;
  final DateTime fechaHora;
  final String estado;

  Cita({required this.id, required this.medico, required this.fechaHora, required this.estado});

  factory Cita.fromJson(Map<String, dynamic> json) {
    return Cita(
      id: json['id'],
      medico: json['medico'],
      fechaHora: DateTime.parse(json['fecha_hora']),
      estado: json['estado'],
    );
  }
}
