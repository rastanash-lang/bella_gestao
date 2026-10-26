class Cliente {
  final int? id;
  final String nome;
  final String? telefone;
  final String? observacoesTecnicas; // Fórmulas de tinta, químicas, alergias e preferências
  final DateTime dataCadastro;

  Cliente({
    this.id,
    required this.nome,
    this.telefone,
    this.observacoesTecnicas,
    required this.dataCadastro,
  });

  Cliente copyWith({
    int? id,
    String? nome,
    String? telefone,
    String? observacoesTecnicas,
    DateTime? dataCadastro,
  }) {
    return Cliente(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      telefone: telefone ?? this.telefone,
      observacoesTecnicas: observacoesTecnicas ?? this.observacoesTecnicas,
      dataCadastro: dataCadastro ?? this.dataCadastro,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'telefone': telefone,
      'observacoesTecnicas': observacoesTecnicas,
      'dataCadastro': dataCadastro.toIso8601String(),
    };
  }

  factory Cliente.fromMap(Map<String, dynamic> map) {
    return Cliente(
      id: map['id'] as int?,
      nome: map['nome'] as String,
      telefone: map['telefone'] as String?,
      observacoesTecnicas: map['observacoesTecnicas'] as String?,
      dataCadastro: DateTime.parse(map['dataCadastro'] as String),
    );
  }
}
