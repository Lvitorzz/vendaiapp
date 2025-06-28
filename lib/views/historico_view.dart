import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vendaai/models/venda_model.dart';
import 'package:vendaai/controllers/venda_controller.dart';

class HistoricoView extends StatefulWidget {
  const HistoricoView({super.key});

  @override
  State<HistoricoView> createState() => _HistoricoViewState();
}

class _HistoricoViewState extends State<HistoricoView> {
  final VendaController _controller = VendaController();
  String _filtro = 'todas';

  List<VendaModel> _filtrarVendas(List<VendaModel> vendas) {
    if (_filtro == 'fiadas') {
      return vendas.where((v) => v.tipo == 'fiada').toList();
    } else if (_filtro == 'pagas') {
      return vendas.where((v) => v.tipo == 'paga').toList();
    }
    return vendas;
  }

  void _abrirDetalhes(VendaModel venda) {
    final dataFormatada = DateFormat('dd/MM/yyyy – HH:mm').format(venda.data);

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Detalhes da Venda',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (venda.clienteNome != null && venda.clienteNome!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text('👤 Cliente: ${venda.clienteNome}'),
                    ),
                  Text('📅 Data: $dataFormatada'),
                  const SizedBox(height: 8),
                  Text('💰 Tipo: ${venda.foiPaga ? "Paga" : "Fiada"}'),
                  const SizedBox(height: 12),
                  const Text('🛒 Produtos:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  ...venda.produtos.map((p) => Text(
                    '- ${p.quantidade}x ${p.nome} (R\$ ${(p.preco * p.quantidade).toStringAsFixed(2)})',
                  )),
                  const SizedBox(height: 12),
                  Text(
                    '💵 Total: R\$ ${venda.valor.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (venda.observacao != null && venda.observacao!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text('📝 Observações:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(venda.observacao!),
                  ]
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fechar'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _controller.excluirVenda(venda.id!);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Venda excluída com sucesso')),
                );
              },
              child: const Text(
                'Excluir',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF26A6DF),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Histórico',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: _filtro == 'fiadas' ? Colors.white24 : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.white),
                      ),
                      child: TextButton(
                        onPressed: () => setState(() {
                          _filtro = _filtro == 'fiadas' ? 'todas' : 'fiadas';
                        }),
                        child: const Text('Fiadas', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: _filtro == 'pagas' ? Colors.white24 : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.white),
                      ),
                      child: TextButton(
                        onPressed: () => setState(() {
                          _filtro = _filtro == 'pagas' ? 'todas' : 'pagas';
                        }),
                        child: const Text('Pagas', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: StreamBuilder<List<VendaModel>>(
                  stream: _controller.listarVendas(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(
                        child: Text('Nenhuma venda encontrada.', style: TextStyle(color: Colors.white)),
                      );
                    }

                    final vendasFiltradas = _filtrarVendas(snapshot.data!);

                    return Column(
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0077B6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${vendasFiltradas.length} Vendas listadas',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.orange,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: ListView.builder(
                            itemCount: vendasFiltradas.length,
                            itemBuilder: (_, index) {
                              final venda = vendasFiltradas[index];
                              final total = venda.produtos.isNotEmpty
                                  ? venda.produtos.fold(0.0, (sum, p) => sum + (p.preco * p.quantidade))
                                  : venda.valor;
                              final data = DateFormat('dd/MM/yyyy – HH:mm').format(venda.data);

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 6,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          'Data da Venda:',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        Text(
                                          data,
                                          style: const TextStyle(fontSize: 14, color: Colors.black54),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          'Valor total:',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        Text(
                                          'R\$ ${total.toStringAsFixed(2)}',
                                          style: const TextStyle(fontSize: 14, color: Colors.black87),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF26A6DF),
                                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                        onPressed: () => _abrirDetalhes(venda),
                                        child: const Text(
                                          'Detalhes',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
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
      ),
    );
  }
}
