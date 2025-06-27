import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vendaai/models/produto_model.dart';

class ProdutoController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final CollectionReference _produtosCollection;

  ProdutoController() {
    _produtosCollection = _firestore.collection('produtos');
  }

  /// Adiciona um novo produto
  Future<void> adicionarProduto(ProdutoModel produto) {
    return _produtosCollection.add(produto.toJson());
  }

  /// Retorna um stream com todos os produtos
  Stream<List<ProdutoModel>> lerProdutos() {
    return _produtosCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => ProdutoModel.fromFirestore(doc)).toList();
    });
  }

  /// Atualiza os dados de um produto
  Future<void> atualizarProduto(ProdutoModel produto) {
    return _produtosCollection.doc(produto.id).update(produto.toJson());
  }

  /// Remove um produto pelo ID
  Future<void> deletarProduto(String idProduto) {
    return _produtosCollection.doc(idProduto).delete();
  }

  /// Busca um produto pelo ID
  Future<ProdutoModel?> buscarProdutoPorId(String idProduto) async {
    final doc = await _produtosCollection.doc(idProduto).get();
    if (!doc.exists) return null;
    return ProdutoModel.fromFirestore(doc);
  }
}
