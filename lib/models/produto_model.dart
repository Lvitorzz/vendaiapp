import 'package:cloud_firestore/cloud_firestore.dart';

class ProdutoModel {
  String? id;
  String nome;
  double preco;
  int estoque;
  String? observacao;

  ProdutoModel({
    this.id,
    required this.nome,
    required this.preco,
    required this.estoque,
    this.observacao,
  });

  Map<String, dynamic> toJson() {
    return {
      'nome': nome,
      'preco': preco,
      'estoque': estoque,
      'observacao': observacao ?? '',
    };
  }

  factory ProdutoModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return ProdutoModel(
      id: doc.id,
      nome: data['nome'] ?? '',
      preco: (data['preco'] ?? 0).toDouble(),
      estoque: ((data['estoque'] ?? 0) as num).toInt(),
      observacao: data['observacao'] ?? '',
    );
  }
}
