import 'package:cloud_firestore/cloud_firestore.dart';

class PagamentoController {
  final _firestore = FirebaseFirestore.instance;
  final String _collection = 'pagamentos';

  /// Registra um pagamento de um cliente
  Future<void> registrarPagamento({
    required String clienteId,
    required double valor,
  }) async {
    try {
      final pagamento = {
        'clienteId': clienteId,
        'valor': valor,
        'data': Timestamp.now(),
      };

      final docRef = await _firestore.collection(_collection).add(pagamento);
      print('✅ Pagamento registrado: ${docRef.id}');
    } catch (e) {
      print('❌ Erro ao registrar pagamento: $e');
    }
  }

  /// Lista os pagamentos feitos por um cliente específico
  Stream<List<Map<String, dynamic>>> listarPagamentosPorCliente(
    String clienteId,
  ) {
    return _firestore
        .collection(_collection)
        .where('clienteId', isEqualTo: clienteId)
        .orderBy('data', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  /// Soma o total pago por um cliente
  Future<double> calcularTotalPago(String clienteId) async {
    final snapshot =
        await _firestore
            .collection(_collection)
            .where('clienteId', isEqualTo: clienteId)
            .get();

    double total = 0;
    for (var doc in snapshot.docs) {
      final valor = (doc.data()['valor'] ?? 0).toDouble();
      total += valor;
    }

    return total;
  }

  /// Exclui um pagamento (opcional)
  Future<void> excluirPagamento(String pagamentoId) async {
    await _firestore.collection(_collection).doc(pagamentoId).delete();
  }
}
