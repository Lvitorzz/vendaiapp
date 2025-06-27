import 'package:cloud_firestore/cloud_firestore.dart';

class ProdutoDaVenda {
  String? id;
  String nome;
  double preco;
  int quantidade;

  ProdutoDaVenda({
    this.id,
    required this.nome,
    required this.preco,
    required this.quantidade,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'nome': nome,
        'preco': preco,
        'quantidade': quantidade,
      };

  factory ProdutoDaVenda.fromJson(Map<String, dynamic> json) {
    return ProdutoDaVenda(
      id: json['id'],
      nome: json['nome'] ?? '',
      preco: (json['preco'] ?? 0).toDouble(),
      quantidade: (json['quantidade'] ?? 1).toInt(),
    );
  }
}

class VendaModel {
  String? id;
  String? clienteId;
  String? clienteNome;
  List<ProdutoDaVenda> produtos;
  double valor;
  String tipo; // "paga" ou "fiada"
  String? observacao;
  DateTime data;

  VendaModel({
    this.id,
    this.clienteId,
    this.clienteNome,
    required this.produtos,
    required this.valor,
    required this.tipo,
    this.observacao,
    required this.data,
  });

  Map<String, dynamic> toJson() {
    return {
      'clienteId': clienteId ?? '',
      'clienteNome': clienteNome ?? '',
      'produtos': produtos.map((p) => p.toJson()).toList(),
      'valor': valor,
      'tipo': tipo,
      'observacao': observacao ?? '',
      'data': Timestamp.fromDate(data),
    };
  }

  factory VendaModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return VendaModel(
      id: doc.id,
      clienteId: data['clienteId'] ?? '',
      clienteNome: data['clienteNome'] ?? '',
      produtos: (data['produtos'] as List<dynamic>? ?? [])
          .map((item) => ProdutoDaVenda.fromJson(item))
          .toList(),
      valor: (data['valor'] ?? 0.0).toDouble(),
      tipo: (data['tipo'] ?? 'paga').toString().trim().toLowerCase(),
      observacao: data['observacao'] ?? '',
      data: (data['data'] as Timestamp).toDate(),
    );
  }

  bool get foiPaga => tipo == 'paga';
  bool get foiFiada => tipo == 'fiada';
}
