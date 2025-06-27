import 'package:cloud_firestore/cloud_firestore.dart';

class PagamentoModel {
  final String? id;
  final String clienteId;
  final double valor;
  final DateTime data;

  PagamentoModel({
    this.id,
    required this.clienteId,
    required this.valor,
    required this.data,
  });

  Map<String, dynamic> toJson() => {
    'clienteId': clienteId,
    'valor': valor,
    'data': Timestamp.fromDate(data),
  };

  factory PagamentoModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PagamentoModel(
      id: doc.id,
      clienteId: data['clienteId'],
      valor: (data['valor'] ?? 0.0).toDouble(),
      data: (data['data'] as Timestamp).toDate(),
    );
  }
}
