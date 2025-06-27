import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vendaai/models/venda_model.dart';

class VendaController {
  final _firestore = FirebaseFirestore.instance;
  final _collection = 'vendas';

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
        print('✔ Estoque de "${item.nome}" atualizado: $estoqueAtual → $estoqueFinal');
      }
    }
  }

  Stream<List<VendaModel>> listarVendas() {
    return _firestore
        .collection(_collection)
        .orderBy('data', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => VendaModel.fromFirestore(doc)).toList());
  }

  Stream<List<VendaModel>> listarVendasPorCliente(String clienteId) {
    return _firestore
        .collection(_collection)
        .where('clienteId', isEqualTo: clienteId)
        .orderBy('data', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => VendaModel.fromFirestore(doc)).toList());
  }

  Stream<List<VendaModel>> listarVendasFiadasPorCliente(String clienteId) {
    return _firestore
        .collection(_collection)
        .where('clienteId', isEqualTo: clienteId)
        .where('tipo', isEqualTo: 'fiada')
        .orderBy('data', descending: true)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) {
            print('! Nenhuma venda FIADA para cliente $clienteId');
          } else {
            print('✔ ${snapshot.docs.length} venda(s) FIADAS para $clienteId');
            for (var doc in snapshot.docs) {
              final v = VendaModel.fromFirestore(doc);
              print('→ ${v.id} | ${v.tipo} | R\$ ${v.valor}');
            }
          }

          return snapshot.docs
              .map((doc) => VendaModel.fromFirestore(doc))
              .toList();
        });
  }

  Future<Map<String, double>> calcularResumoDoDia() async {
    final hoje = DateTime.now();
    final inicioDoDia = DateTime(hoje.year, hoje.month, hoje.day);
    final fimDoDia = DateTime(hoje.year, hoje.month, hoje.day, 23, 59, 59);

    final snapshot = await _firestore
        .collection(_collection)
        .where('data', isGreaterThanOrEqualTo: Timestamp.fromDate(inicioDoDia))
        .where('data', isLessThanOrEqualTo: Timestamp.fromDate(fimDoDia))
        .get();

    double total = 0;
    double fiado = 0;
    double pago = 0;

    for (var doc in snapshot.docs) {
      final venda = VendaModel.fromFirestore(doc);

      double valorCalculado = venda.produtos.isNotEmpty
          ? venda.produtos.fold(0.0,
              (sum, p) => sum + (p.preco * p.quantidade))
          : venda.valor;

      total += valorCalculado;

      final tipo = venda.tipo.trim().toLowerCase();
      if (tipo == 'fiada') {
        fiado += valorCalculado;
      } else if (tipo == 'paga') {
        pago += valorCalculado;
      }

      print('→ Venda ${venda.id} | Tipo: ${venda.tipo} | Valor: $valorCalculado');
    }

    print('Resumo do dia → Total: $total | Pago: $pago | Fiado: $fiado');

    return {
      'total': total,
      'fiado': fiado,
      'pago': pago,
    };
  }

  Future<void> excluirVenda(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();
    } catch (e) {
      rethrow;
    }
  }
}
