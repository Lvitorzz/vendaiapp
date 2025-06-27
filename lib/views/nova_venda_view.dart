import 'package:flutter/material.dart';
import 'package:vendaai/controllers/venda_controller.dart';
import 'package:vendaai/models/venda_model.dart';
import 'package:vendaai/models/cliente_model.dart';
import 'package:vendaai/models/produto_model.dart';
import 'package:vendaai/controllers/cliente_controller.dart';
import 'package:vendaai/controllers/produto_controller.dart';

class NovaVendaView extends StatefulWidget {
  const NovaVendaView({super.key});

  @override
  State<NovaVendaView> createState() => _NovaVendaViewState();
}

class _NovaVendaViewState extends State<NovaVendaView> {
  final _formKey = GlobalKey<FormState>();
  final _controller = VendaController();

  ClienteModel? _clienteSelecionado;
  String _tipoVenda = 'paga';
  final _obsController = TextEditingController();
  final _valorManualController = TextEditingController();
  final List<ProdutoDaVenda> _produtosSelecionados = [];

  void _finalizarVenda() async {
    if (_produtosSelecionados.isEmpty && _valorManualController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe o valor ou adicione produtos')),
      );
      return;
    }

    if (_tipoVenda == 'fiada' && _clienteSelecionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Venda fiada exige cliente selecionado')),
      );
      return;
    }

    final produtosComProblema = <String>[];

    for (final p in _produtosSelecionados) {
      final produtoAtualizado = await ProdutoController().buscarProdutoPorId(p.id!);
      if (produtoAtualizado == null) continue;

      if (p.quantidade > produtoAtualizado.estoque) {
        produtosComProblema.add('${p.nome} (estoque: ${produtoAtualizado.estoque}, solicitado: ${p.quantidade})');
      }
    }

    if (produtosComProblema.isNotEmpty) {
      final confirmar = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Estoque insuficiente'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Alguns produtos estão com estoque abaixo da quantidade vendida:'),
              const SizedBox(height: 12),
              ...produtosComProblema.map((e) => Text('• $e')),
              const SizedBox(height: 12),
              const Text('Deseja continuar mesmo assim?', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text('Continuar'),
            ),
          ],
        ),
      );

      if (confirmar != true) return;
    }

    final total = _produtosSelecionados.isEmpty
        ? double.tryParse(_valorManualController.text.replaceAll(',', '.')) ?? 0.0
        : _produtosSelecionados.fold(0.0, (sum, p) => sum + (p.preco * p.quantidade));

    final venda = VendaModel(
      clienteId: _clienteSelecionado?.id,
      clienteNome: _clienteSelecionado?.nome,
      produtos: _produtosSelecionados,
      valor: total,
      tipo: _tipoVenda,
      observacao: _obsController.text,
      data: DateTime.now(),
    );

    await _controller.adicionarVenda(venda);
    Navigator.pop(context);
  }

  Future<void> _selecionarCliente() async {
    final clientes = await ClienteController().lerClientes().first;
    showModalBottomSheet(
      context: context,
      builder: (_) => ListView(
        children: clientes.map((c) {
          return ListTile(
            title: Text(c.nome),
            onTap: () {
              setState(() => _clienteSelecionado = c);
              Navigator.pop(context);
            },
          );
        }).toList(),
      ),
    );
  }

  Future<void> _adicionarProduto() async {
    final produtos = await ProdutoController().lerProdutos().first;
    showModalBottomSheet(
      context: context,
      builder: (_) => ListView(
        children: produtos.map((p) {
          return ListTile(
            title: Text(p.nome),
            subtitle: Text('R\$ ${p.preco.toStringAsFixed(2)}'),
            onTap: () async {
              int quantidade = 1;

              final confirmar = await showDialog<bool>(
                context: context,
                builder: (_) => StatefulBuilder(
                  builder: (context, setState) => AlertDialog(
                    title: const Text('Selecionar quantidade'),
                    content: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: () {
                            if (quantidade > 1) setState(() => quantidade--);
                          },
                        ),
                        Text('$quantidade', style: const TextStyle(fontSize: 18)),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () => setState(() => quantidade++),
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancelar'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Adicionar'),
                      ),
                    ],
                  ),
                ),
              );

              if (confirmar == true) {
                setState(() {
                  final existente = _produtosSelecionados.firstWhere(
                    (item) => item.id == p.id,
                    orElse: () => ProdutoDaVenda(id: '', nome: '', preco: 0, quantidade: 0),
                  );
                  if (existente.id != '') {
                    existente.quantidade += quantidade;
                  } else {
                    _produtosSelecionados.add(ProdutoDaVenda(
                      id: p.id,
                      nome: p.nome,
                      preco: p.preco,
                      quantidade: quantidade,
                    ));
                  }
                });
              }

              Navigator.pop(context);
            },
          );
        }).toList(),
      ),
    );
  }

  InputDecoration _input(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFE0E0E0),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  double get _valorTotal {
    if (_produtosSelecionados.isEmpty) {
      return double.tryParse(_valorManualController.text.replaceAll(',', '.')) ?? 0.0;
    } else {
      return _produtosSelecionados.fold(0.0, (s, p) => s + (p.preco * p.quantidade));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF26A6DF),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    const Text('Nova venda', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 24),
                const Text('Cliente', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: _selecionarCliente,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0E0E0),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_clienteSelecionado?.nome ?? 'Escolha o cliente', style: const TextStyle(color: Colors.grey)),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Produtos', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Column(
                  children: [
                    if (_produtosSelecionados.isNotEmpty)
                      ..._produtosSelecionados.map((p) => Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              leading: const Icon(Icons.shopping_cart),
                              title: Text(p.nome, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('${p.quantidade}x - R\$ ${(p.preco * p.quantidade).toStringAsFixed(2)}'),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => setState(() => _produtosSelecionados.remove(p)),
                              ),
                            ),
                          )),
                    TextButton.icon(
                      onPressed: _adicionarProduto,
                      icon: const Icon(Icons.add, color: Colors.white),
                      label: const Text('Adicionar produto', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_produtosSelecionados.isEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Valor da venda', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      TextFormField(
                        controller: _valorManualController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: _input('R\$'),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                const Text('Tipo da venda', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0E0E0),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Column(
                    children: [
                      RadioListTile(
                        value: 'paga',
                        groupValue: _tipoVenda,
                        onChanged: (val) => setState(() => _tipoVenda = val!),
                        title: const Text('Venda paga'),
                      ),
                      RadioListTile(
                        value: 'fiada',
                        groupValue: _tipoVenda,
                        onChanged: (val) => setState(() => _tipoVenda = val!),
                        title: const Text('Venda fiada'),
                        subtitle: const Text('- Exige cliente', style: TextStyle(color: Colors.orange)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Observação', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _obsController,
                  maxLines: 3,
                  decoration: _input(''),
                ),
                const SizedBox(height: 24),
                Text('Total: R\$ ${_valorTotal.toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.orange, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _finalizarVenda,
                    child: const Text('Finalizar venda', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
