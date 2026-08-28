class MetaCofrinho {
  final int? id;
  final String titulo;
  final double valorAlvo;
  final double valorAtual;
  final DateTime dataCriacao;

  MetaCofrinho({
    this.id,
    required this.titulo,
    required this.valorAlvo,
    this.valorAtual = 0.0,
    required this.dataCriacao,
  });

  double get percentual => (valorAlvo > 0 ? (valorAtual / valorAlvo) : 0.0).clamp(0.0, 1.0);
  double get restante => (valorAlvo - valorAtual).clamp(0.0, double.infinity);
  bool get concluida => valorAtual >= valorAlvo;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'titulo': titulo,
      'valorAlvo': valorAlvo,
      'valorAtual': valorAtual,
      'dataCriacao': dataCriacao.toIso8601String(),
    };
  }

  factory MetaCofrinho.fromMap(Map<String, dynamic> map) {
    return MetaCofrinho(
      id: map['id'] as int?,
      titulo: map['titulo'] as String,
      valorAlvo: (map['valorAlvo'] as num).toDouble(),
      valorAtual: (map['valorAtual'] as num).toDouble(),
      dataCriacao: DateTime.parse(map['dataCriacao'] as String),
    );
  }
}
