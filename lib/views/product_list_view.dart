import 'package:flutter/material.dart';
import 'package:vendaai/models/produto_model.dart';
import '../controllers/produto_controller.dart';

class ProdutoView extends StatefulWidget {
  const ProdutoView({super.key});

  @override
  State<ProdutoView> createState() => _ProdutoViewState();
}

class _ProdutoViewState extends State<ProdutoView> {
  final ProdutoController _controller = ProdutoController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cadastrar produtos)'),
        backgroundColor: Colors.deepOrange,
      ),
      body: StreamBuilder<List<ProdutoModel>>(
        stream: _controller.lerProdutos(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Nenhum produto cadastrado.'));
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Ocorreu um erro ao carregar os produtos.'));
          }

          final produtos = snapshot.data!;

          return ListView.builder(
            itemCount: produtos.length,
            itemBuilder: (context, index) {
              final produto = produtos[index];
              return ListTile(
                title: Text(produto.nome),
                subtitle: Text('Preço: R\$ ${produto.preco.toStringAsFixed(2)} - Estoque: ${produto.estoque}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _mostrarFormularioProduto(produto: produto),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _controller.deletarProduto(produto.id!),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarFormularioProduto(),
        backgroundColor: Colors.deepOrange,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _mostrarFormularioProduto({ProdutoModel? produto}) {
    final nomeController = TextEditingController(text: produto?.nome ?? '');
    final precoController = TextEditingController(text: produto?.preco.toString() ?? '');
    final estoqueController = TextEditingController(text: produto?.estoque.toString() ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(produto == null ? 'Adicionar Produto' : 'Editar Produto'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nomeController, decoration: const InputDecoration(labelText: 'Nome')),
              TextField(controller: precoController, decoration: const InputDecoration(labelText: 'Preço'), keyboardType: TextInputType.number),
              TextField(controller: estoqueController, decoration: const InputDecoration(labelText: 'Estoque'), keyboardType: TextInputType.number),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () {
                final nome = nomeController.text;
                final preco = double.tryParse(precoController.text) ?? 0.0;
                final estoque = int.tryParse(estoqueController.text) ?? 0;

                if (nome.isNotEmpty) {
                  final novoProduto = ProdutoModel(id: produto?.id, nome: nome, preco: preco, estoque: estoque);
                  
                  if (produto == null) {
                    _controller.adicionarProduto(novoProduto);
                  } else {
                    _controller.atualizarProduto(novoProduto);
                  }
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );
  }
}