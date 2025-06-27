import 'package:flutter/material.dart';
import 'package:vendaai/controllers/produto_controller.dart';
import 'package:vendaai/models/produto_model.dart';

class CadastrarProdutoView extends StatefulWidget {
  final ProdutoModel? produto;

  const CadastrarProdutoView({super.key, this.produto});

  @override
  State<CadastrarProdutoView> createState() => _CadastrarProdutoViewState();
}

class _CadastrarProdutoViewState extends State<CadastrarProdutoView> {
  final _formKey = GlobalKey<FormState>();
  final ProdutoController _controller = ProdutoController();

  late TextEditingController _nomeController;
  late TextEditingController _precoController;
  late TextEditingController _estoqueController;
  late TextEditingController _obsController;

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.produto?.nome ?? '');
    _precoController = TextEditingController(
      text: widget.produto?.preco.toStringAsFixed(2) ?? '',
    );
    _estoqueController = TextEditingController(
      text: widget.produto?.estoque.toString() ?? '',
    );
    _obsController = TextEditingController(
      text: widget.produto?.observacao ?? '',
    );
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _precoController.dispose();
    _estoqueController.dispose();
    _obsController.dispose();
    super.dispose();
  }

  void _salvarProduto() {
    if (_formKey.currentState!.validate()) {
      final nome = _nomeController.text;
      final preco = double.tryParse(_precoController.text) ?? 0.0;
      final estoque = int.tryParse(_estoqueController.text) ?? 0;
      final observacao = _obsController.text;

      final produto = ProdutoModel(
        id: widget.produto?.id,
        nome: nome,
        preco: preco,
        estoque: estoque,
        observacao: observacao,
      );

      if (widget.produto == null) {
        _controller.adicionarProduto(produto);
      } else {
        _controller.atualizarProduto(produto);
      }

      Navigator.pop(context);
    }
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey),
      filled: true,
      fillColor: const Color(0xFFE0E0E0),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF26A6DF),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Topo
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Cadastro de produto',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Nome', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: _nomeController,
                      decoration: _inputDecoration('Digite o nome do produto'),
                      validator: (value) => value == null || value.isEmpty ? 'Informe o nome' : null,
                    ),
                    const SizedBox(height: 16),

                    const Text('Preço', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: _precoController,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration('Digite o preço do produto'),
                      validator: (value) => value == null || value.isEmpty ? 'Informe o preço' : null,
                    ),
                    const SizedBox(height: 16),

                    const Text('Quantidade estoque', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: _estoqueController,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration('Digite a quantidade do produto'),
                      validator: (value) => value == null || value.isEmpty ? 'Informe a quantidade' : null,
                    ),
                    const SizedBox(height: 16),

                    const Text('Observação', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: _obsController,
                      maxLines: 4,
                      decoration: _inputDecoration('Digite observações...'),
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _salvarProduto,
                        child: const Text(
                          'Cadastrar',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
