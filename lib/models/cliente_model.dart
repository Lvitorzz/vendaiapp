import 'package:cloud_firestore/cloud_firestore.dart';

class ClienteModel {
  String? id;
  String nome;
  String? telefone;
  String? whatsapp;
  String? observacao;
  DateTime dataCadastro;

  ClienteModel({
    this.id,
    required this.nome,
    this.telefone,
    this.whatsapp,
    this.observacao,
    required this.dataCadastro,
  });

  Map<String, dynamic> toJson() {
    return {
      'nome': nome,
      'telefone': telefone ?? '',
      'whatsapp': whatsapp ?? '',
      'observacao': observacao ?? '',
      'dataCadastro': Timestamp.fromDate(dataCadastro),
    };
  }

  factory ClienteModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ClienteModel(
      id: doc.id,
      nome: data['nome'] ?? '',
      telefone: data['telefone'] ?? '',
      whatsapp: data['whatsapp'] ?? '',
      observacao: data['observacao'] ?? '',
      dataCadastro: (data['dataCadastro'] as Timestamp).toDate(),
    );
  }
}
