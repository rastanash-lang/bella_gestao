class Transacao {
  final int? id;
  final String descricao;
  final String? cliente; // Nome da cliente (opcional)
  final double valor;
  final String tipo; // 'entrada' ou 'saida'
  final String ambito; // 'PJ' ou 'PF'
  final String categoria;
  final String formaPagamento; // 'Pix', 'Dinheiro', 'Débito', 'Crédito'
  final String status; // 'Pago' ou 'Pendente'
  final String? tipoCusto;
  final String? tipoReceita;
  final int parcelaAtual;
  final int totalParcelas;
  final DateTime data;

  Transacao({
    this.id,
    required this.descricao,
    this.cliente,
    required this.valor,
    required this.tipo,
    required this.ambito,
    required this.categoria,
    required this.formaPagamento,
    required this.status,
    this.tipoCusto,
    this.tipoReceita,
    this.parcelaAtual = 1,
    this.totalParcelas = 1,
    required this.data,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'descricao': descricao,
      'cliente': cliente,
      'valor': valor,
      'tipo': tipo,
      'ambito': ambito,
      'categoria': categoria,
      'formaPagamento': formaPagamento,
      'status': status,
      'tipoCusto': tipoCusto,
      'tipoReceita': tipoReceita,
      'parcelaAtual': parcelaAtual,
      'totalParcelas': totalParcelas,
      'data': data.toIso8601String(),
    };
  }

  factory Transacao.fromMap(Map<String, dynamic> map) {
    return Transacao(
      id: map['id'] as int?,
      descricao: map['descricao'] as String,
      cliente: map['cliente'] as String?,
      valor: (map['valor'] as num).toDouble(),
      tipo: map['tipo'] as String,
      ambito: map['ambito'] as String,
      categoria: map['categoria'] as String,
      formaPagamento: map['formaPagamento'] as String,
      status: map['status'] as String,
      tipoCusto: map['tipoCusto'] as String?,
      tipoReceita: map['tipoReceita'] as String?,
      parcelaAtual: map['parcelaAtual'] as int? ?? 1,
      totalParcelas: map['totalParcelas'] as int? ?? 1,
      data: DateTime.parse(map['data'] as String),
    );
  }
}
