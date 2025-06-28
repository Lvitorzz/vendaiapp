import 'package:flutter/material.dart';
import 'package:vendaai/controllers/produto_controller.dart';
import 'package:vendaai/models/produto_model.dart';
import 'package:vendaai/views/cadastrar_produto_view.dart';

class EstoqueView extends StatefulWidget {
  const EstoqueView({super.key});

  @override
  State<EstoqueView> createState() => _EstoqueViewState();
}

class _EstoqueViewState extends State<EstoqueView> {
  final ProdutoController _controller = ProdutoController();
  final TextEditingController _searchController = TextEditingController();
  String _busca = '';

  void _mostrarDetalhesProduto(ProdutoModel produto) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(produto.nome),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Preço: R\$ ${produto.preco.toStringAsFixed(2)}'),
            Text('Estoque: ${produto.estoque} unidade(s)'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
          TextButton(
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Excluir Produto'),
                  content: const Text('Tem certeza que deseja excluir este produto?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancelar'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Excluir', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await _controller.deletarProduto(produto.id!);
                Navigator.pop(context); // Fecha o modal de detalhes
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Produto excluído com sucesso.')),
                );
              }
            },
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF26A6DF),
      body: SafeArea(
        child: Column(
          children: [
            // Cabeçalho
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Estoque',
                    style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

            // Campo de busca
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Buscar produto',
                  border: InputBorder.none,
                  icon: Icon(Icons.search),
                ),
                onChanged: (value) => setState(() => _busca = value),
              ),
            ),

            // Stream e conteúdo
            Expanded(
              child: StreamBuilder<List<ProdutoModel>>(
                stream: _controller.lerProdutos(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Colors.white));
                  }

                  if (snapshot.hasError) {
                    return const Center(child: Text('Erro ao carregar produtos', style: TextStyle(color: Colors.white)));
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('Nenhum produto cadastrado.', style: TextStyle(color: Colors.white)));
                  }

                  final produtos = snapshot.data!;
                  final produtosFiltrados = produtos.where((p) {
                    return p.nome.toLowerCase().contains(_busca.toLowerCase());
                  }).toList();

                  return Column(
                    children: [
                      // Total de produtos
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F7DB2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: '${produtosFiltrados.length} ',
                                  style: const TextStyle(
                                    color: Colors.orange,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const TextSpan(
                                  text: 'Produtos cadastrados',
                                  style: TextStyle(color: Colors.white, fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Lista de produtos
                      Expanded(
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                          ),
                          child: ListView.builder(
                            itemCount: produtosFiltrados.length,
                            itemBuilder: (context, index) {
                              final produto = produtosFiltrados[index];
                              return Container(
                                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF2F2F2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        produto.nome,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      produto.estoque.toString(),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Colors.orange,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.orange,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => CadastrarProdutoView(produto: produto),
                                          ),
                                        );
                                      },
                                      child: const Text('Editar', style: TextStyle(color: Colors.white),),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF26A6DF),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      onPressed: () {
                                        _mostrarDetalhesProduto(produto);
                                      },
                                      child: const Text('Detalhes', style: TextStyle(color: Colors.white),),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
