class Produto {
  final int? id;
  final String nome;
  final String categoria; // 'Coloração', 'Tratamento', 'Unhas', 'Revenda', 'Descartáveis', 'Outros'
  final int quantidadeAtual;
  final int quantidadeMinima;
  final double precoCusto;
  final double precoVenda;
  final String unidade; // 'un', 'ml', 'g', 'kit'

  Produto({
    this.id,
    required this.nome,
    required this.categoria,
    required this.quantidadeAtual,
    this.quantidadeMinima = 2,
    required this.precoCusto,
    this.precoVenda = 0.0,
    this.unidade = 'un',
  });

  bool get estoqueBaixo => quantidadeAtual <= quantidadeMinima;
  bool get emFalta => quantidadeAtual <= 0;

  Produto copyWith({
    int? id,
    String? nome,
    String? categoria,
    int? quantidadeAtual,
    int? quantidadeMinima,
    double? precoCusto,
    double? precoVenda,
    String? unidade,
  }) {
    return Produto(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      categoria: categoria ?? this.categoria,
      quantidadeAtual: quantidadeAtual ?? this.quantidadeAtual,
      quantidadeMinima: quantidadeMinima ?? this.quantidadeMinima,
      precoCusto: precoCusto ?? this.precoCusto,
      precoVenda: precoVenda ?? this.precoVenda,
      unidade: unidade ?? this.unidade,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'categoria': categoria,
      'quantidadeAtual': quantidadeAtual,
      'quantidadeMinima': quantidadeMinima,
      'precoCusto': precoCusto,
      'precoVenda': precoVenda,
      'unidade': unidade,
    };
  }

  factory Produto.fromMap(Map<String, dynamic> map) {
    return Produto(
      id: map['id'] as int?,
      nome: map['nome'] as String,
      categoria: map['categoria'] as String,
      quantidadeAtual: map['quantidadeAtual'] as int,
      quantidadeMinima: map['quantidadeMinima'] as int? ?? 2,
      precoCusto: (map['precoCusto'] as num).toDouble(),
      precoVenda: (map['precoVenda'] as num?)?.toDouble() ?? 0.0,
      unidade: map['unidade'] as String? ?? 'un',
    );
  }
}
