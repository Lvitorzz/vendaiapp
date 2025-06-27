import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vendaai/models/cliente_model.dart';

class ClienteController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final CollectionReference _clientesCollection;

  ClienteController() {
    _clientesCollection = _firestore.collection('clientes');
  }

  Future<void> adicionarCliente(ClienteModel cliente) {
    return _clientesCollection.add(cliente.toJson());
  }

  Stream<List<ClienteModel>> lerClientes() {
    return _clientesCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => ClienteModel.fromFirestore(doc)).toList();
    });
  }

  Future<void> atualizarCliente(ClienteModel cliente) {
    return _clientesCollection.doc(cliente.id).update(cliente.toJson());
  }

  Future<void> deletarCliente(String idCliente) {
    return _clientesCollection.doc(idCliente).delete();
  }
}
