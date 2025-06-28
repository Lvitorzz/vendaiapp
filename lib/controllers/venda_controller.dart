import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vendaai/models/venda_model.dart';

class VendaController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'vendas';

  Future<void> adicionarVenda(VendaModel venda) async {
    // Adiciona a venda
    await _firestore.collection(_collection).add(venda.toJson());

    // Atualiza o estoque dos produtos vendidos
    for (var item in venda.produtos) {
      final docRef = _firestore.collection('produtos').doc(item.id);
      final docSnap = await docRef.get();

      if (docSnap.exists) {
        final dados = docSnap.data()!;
        final estoqueAtual = ((dados['estoque'] ?? 0) as num).toInt();
        final novoEstoque = estoqueAtual - item.quantidade;
        final estoqueFinal = novoEstoque < 0 ? 0 : novoEstoque;

        await docRef.update({'estoque': estoqueFinal});
        // Em desenvolvimento, use um logger em vez de print():
        print('✔ Estoque de "${item.nome}" atualizado: '
            '$estoqueAtual → $estoqueFinal');
      }
    }
  }

  Stream<List<VendaModel>> listarVendas() {
    return _firestore
        .collection(_collection)
        .orderBy('data', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => VendaModel.fromFirestore(doc))
        .toList());
  }

  Stream<List<VendaModel>> listarVendasPorCliente(String clienteId) {
    return _firestore
        .collection(_collection)
        .where('clienteId', isEqualTo: clienteId)
        .orderBy('data', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => VendaModel.fromFirestore(doc))
        .toList());
  }

  Stream<List<VendaModel>> listarVendasFiadasPorCliente(String clienteId) {
    return _firestore
        .collection(_collection)
        .where('clienteId', isEqualTo: clienteId)
        .where('tipo', isEqualTo: 'fiada')
        .orderBy('data', descending: true)
        .snapshots()
        .map((snapshot) {
      // Em desenvolvimento, use um logger em vez de print():
      if (snapshot.docs.isEmpty) {
        print('! Nenhuma venda FIADA para cliente $clienteId');
      } else {
        print(
            '✔ ${snapshot.docs.length} venda(s) FIADAS para $clienteId');
      }
      return snapshot.docs
          .map((doc) => VendaModel.fromFirestore(doc))
          .toList();
    });
  }

  /// Calcula resumo (total, fiado e pago) para hoje.
  Future<Map<String, double>> calcularResumoDoDia() {
    return calcularResumoParaDia(DateTime.now());
  }

  /// Calcula total vendido, total fiado e total recebido para o [dia] especificado.
  Future<Map<String, double>> calcularResumoParaDia(DateTime dia) async {
    // Define início e fim do dia
    final start = DateTime(dia.year, dia.month, dia.day);
    final end = DateTime(dia.year, dia.month, dia.day, 23, 59, 59);

    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('data', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('data', isLessThanOrEqualTo:   Timestamp.fromDate(end))
          .get();

      double total = 0, fiado = 0, pago = 0;

      for (final doc in snapshot.docs) {
        final venda = VendaModel.fromFirestore(doc);
        final valor = venda.produtos.isNotEmpty
            ? venda.produtos.fold<double>(
            0.0, (sum, p) => sum + p.preco * p.quantidade)
            : venda.valor;

        total += valor;
        if (venda.foiFiada) {
          fiado += valor;
        } else {
          pago += valor;
        }
      }

      return {
        'total': total,
        'fiado': fiado,
        'pago':  pago,
      };
    } catch (e, st) {
      // Em produção, troque por um logger apropriado
      print('Erro ao calcular resumo para $dia: $e\n$st');
      return {
        'total': 0,
        'fiado': 0,
        'pago':  0,
      };
    }
  }

  Future<Map<String, double>> calcularResumoEntrePeriodo(
      DateTime dataInicio,
      DateTime dataFim,
      ) async {
    // Normaliza para pegar o dia inteiro
    final start = DateTime(
      dataInicio.year,
      dataInicio.month,
      dataInicio.day,
      0, 0, 0,
    );
    final end = DateTime(
      dataFim.year,
      dataFim.month,
      dataFim.day,
      23, 59, 59,
    );

    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('data', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('data', isLessThanOrEqualTo:   Timestamp.fromDate(end))
          .get();

      double total = 0, fiado = 0, pago = 0;
      for (final doc in snapshot.docs) {
        final venda = VendaModel.fromFirestore(doc);
        final valor = venda.produtos.isNotEmpty
            ? venda.produtos.fold<double>(
            0, (s, p) => s + p.preco * p.quantidade)
            : venda.valor;

        total += valor;
        if (venda.foiFiada) {
          fiado += valor;
        } else {
          pago += valor;
        }
      }

      return {'total': total, 'fiado': fiado, 'pago': pago};
    } catch (e, st) {
      print('Erro ao calcular resumo no período: $e\n$st');
      return {'total': 0, 'fiado': 0, 'pago': 0};
    }
  }


  Future<void> excluirVenda(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();
    } catch (e) {
      rethrow;
    }
  }
}
