import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vendaai/controllers/pagamento_controller.dart';
import 'package:vendaai/controllers/venda_controller.dart';
import 'package:vendaai/models/cliente_model.dart';
import 'package:vendaai/models/venda_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/pagamento_model.dart';

class DetalhesClienteView extends StatefulWidget {
  final ClienteModel cliente;
  const DetalhesClienteView({super.key, required this.cliente});

  @override
  State<DetalhesClienteView> createState() => _DetalhesClienteViewState();
}

class _DetalhesClienteViewState extends State<DetalhesClienteView> {
  double _totalFiado = 0.0;
  double _totalPago = 0.0;
  late final VendaController _vendaController;
  final ScrollController _scrollController = ScrollController();
  bool _showScrollButton = false;

  @override
  void initState() {
    super.initState();
    _vendaController = VendaController();
    _vendaController
        .listarVendasPorCliente(widget.cliente.id!)
        .listen(calcularTotais);
    _scrollController.addListener(_scrollListener);
  }

  void _abrirHistoricoPagamentos() {
  showDialog(
    context: context,
    builder: (_) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.maxFinite,
        height: 500,
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(16),
        child: StreamBuilder<List<PagamentoModel>>(
          stream: PagamentoController().listarPagamentosDoCliente(widget.cliente.id!),
          builder: (context, snapshot) {
            final pagamentos = snapshot.data ?? [];

            if (pagamentos.isEmpty) {
              return const Center(
                child: Text('Nenhum pagamento registrado.'),
              );
            }

            return Column(
              children: [
                const Text(
                  'Todos os Pagamentos',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    itemCount: pagamentos.length,
                    itemBuilder: (_, index) {
                      final pagamento = pagamentos[index];
                      final dataFmt = DateFormat('dd/MM/yyyy – HH:mm').format(pagamento.data);

                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Data:', style: TextStyle(fontWeight: FontWeight.bold)),
                                Text(dataFmt, style: const TextStyle(color: Colors.black54)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Valor:', style: TextStyle(fontWeight: FontWeight.bold)),
                                Text('R\$ ${NumberFormat.currency(locale: "pt_BR", symbol: "").format(pagamento.valor)}'),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Fechar'),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _scrollListener() {
    final offset = _scrollController.offset;
    final max = _scrollController.position.maxScrollExtent;
    if (offset <= 0) {
      if (_showScrollButton) setState(() => _showScrollButton = false);
    } else if (offset >= max) {
      if (_showScrollButton) setState(() => _showScrollButton = false);
    } else {
      if (!_showScrollButton) setState(() => _showScrollButton = true);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void calcularTotais(List<VendaModel> vendas) async {
    final fiadas = vendas.where((v) => v.foiFiada).toList();
    final totalFiado = fiadas.fold<double>(0.0, (sum, v) {
      final valor = v.produtos.isNotEmpty
          ? v.produtos.fold(0.0, (s, p) => s + p.preco * p.quantidade)
          : v.valor;
      return sum + valor;
    });
    final totalPago = await PagamentoController()
        .calcularTotalPago(widget.cliente.id!);
    setState(() {
      _totalFiado = totalFiado;
      _totalPago = totalPago;
    });
  }

  void _abrirDetalhesVenda(VendaModel venda) {
    final dataStr = DateFormat('dd/MM/yyyy – HH:mm').format(venda.data);
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text('Venda – $dataStr', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 12),
                Text('Tipo: ${venda.foiFiada ? 'Fiada' : 'Paga'}'),
                const SizedBox(height: 8),
                const Text('Produtos:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...venda.produtos.map((p) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${p.quantidade}x ${p.nome}'),
                      Text('R\$ ${(p.preco * p.quantidade).toStringAsFixed(2)}'),
                    ],
                  ),
                )),
                const Divider(height: 24),
                Text('Total: R\$ ${venda.valor.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                if (venda.observacao?.isNotEmpty ?? false) ...[
                  const SizedBox(height: 8),
                  const Text('Observação:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(venda.observacao!),
                ],
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fechar')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> abrirModalPagamento() async {
    final controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Efetuar pagamento'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Valor pago'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              final valor = double.tryParse(controller.text.replaceAll(',', '.'));
              if (valor != null && valor > 0) {
                await PagamentoController().registrarPagamento(
                  clienteId: widget.cliente.id!,
                  valor: valor,
                );
                Navigator.pop(ctx);
                final vendas = await _vendaController.listarVendasPorCliente(widget.cliente.id!).first;
                calcularTotais(vendas);
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  Future<void> cobrarClienteNoWhatsapp() async {
    final numero = widget.cliente.whatsapp?.replaceAll(RegExp(r'\D'), '');
    if (numero == null || numero.isEmpty) return;
    final restante = (_totalFiado - _totalPago).toStringAsFixed(2);
    final msg = Uri.encodeComponent("Olá ${widget.cliente.nome}, seu saldo pendente é R\$ $restante.");
    final uri = Uri.parse("https://wa.me/$numero?text=$msg");
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
    else ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Não foi possível abrir o WhatsApp.")));
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF26A6DF),
      floatingActionButton: _showScrollButton
          ? FloatingActionButton(
        backgroundColor: Colors.white,
        onPressed: _scrollToBottom,
        child: const Icon(Icons.arrow_downward, color: Color(0xFF26A6DF)),
      )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(onTap: () => Navigator.pop(context), child: const Icon(Icons.arrow_back, color: Colors.white)),
                  const SizedBox(width: 12),
                  const Text('Detalhes do Cliente', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 6, offset: const Offset(0, 3)),
                          ],
                        ),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Nome: ${widget.cliente.nome}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text('Cadastro: ${DateFormat('dd/MM/yyyy').format(widget.cliente.dataCadastro ?? DateTime.now())}'),
                          const SizedBox(height: 4),
                          Text('Telefone: ${widget.cliente.telefone ?? 'Não informado'}'),
                          const SizedBox(height: 4),
                          Text('WhatsApp: ${widget.cliente.whatsapp ?? 'Não informado'}'),
                          const Divider(height: 20),
                          const Text('DÍVIDAS EM ABERTO', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text('Total devedor: R\$ ${(_totalFiado - _totalPago).toStringAsFixed(2)}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text('Observação: ${widget.cliente.observacao ?? 'Nenhuma'}'),
                        ]),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: Text('Lista de Compras Fiadas', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    StreamBuilder<List<VendaModel>>(
                      stream: _vendaController.listarVendasPorCliente(widget.cliente.id!),
                      builder: (context, snapshot) {
                        final fiadas = snapshot.data?.where((v) => v.foiFiada).toList() ?? [];
                        if (fiadas.isEmpty) {
                          return const Padding(padding: EdgeInsets.all(16), child: Text('Nenhuma compra fiada.', style: TextStyle(color: Colors.white)));
                        }
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Column(
                            children: fiadas.map((venda) {
                              final dataFmt = DateFormat('dd/MM/yyyy – HH:mm').format(venda.data);
                              return Container(
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [
                                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2)),
                                ]),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                      Text('Data:', style: const TextStyle(fontWeight: FontWeight.bold)),
                                      Text(dataFmt, style: const TextStyle(color: Colors.black54)),
                                    ]),
                                    const SizedBox(height: 6),
                                    ...venda.produtos.map((p) => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('${p.quantidade}x ${p.nome}'), Text('R\$ ${(p.preco * p.quantidade).toStringAsFixed(2)}')])),
                                    if (venda.produtos.isEmpty)
                                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Valor:'), Text('R\$ ${venda.valor.toStringAsFixed(2)}')]),
                                    if (venda.observacao?.isNotEmpty ?? false) ...[
                                      const SizedBox(height: 6),
                                      Text('Obs: ${venda.observacao!}', style: const TextStyle(fontStyle: FontStyle.italic)),
                                    ],
                                    const SizedBox(height: 12),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF26A6DF), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                                        onPressed: () => _abrirDetalhesVenda(venda),
                                        child: const Text('Detalhes', style: TextStyle(color: Colors.white)),
                                      ),
                                    ),
                                  ]),
                                ),
                              );
                            }).toList(),
                          ),
                        );
                      },
                    ),
                    
                    
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Text(
                        'Histórico de Pagamentos',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    StreamBuilder<List<PagamentoModel>>(
                      stream: PagamentoController().listarPagamentosDoCliente(widget.cliente.id!),
                      builder: (context, snapshot) {
                        final pagamentos = snapshot.data ?? [];

                        if (pagamentos.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text(
                              'Nenhum pagamento registrado.',
                              style: TextStyle(color: Colors.white),
                            ),
                          );
                        }

                        // Mostra só os 3 mais recentes na view
                        final ultimos = pagamentos.take(3).toList();

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Column(
                            children: [
                              ...ultimos.map((pagamento) {
                                final dataFmt = DateFormat('dd/MM/yyyy – HH:mm').format(pagamento.data);

                                return Container(
                                  margin: const EdgeInsets.symmetric(vertical: 6),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                        const Text('Data:', style: TextStyle(fontWeight: FontWeight.bold)),
                                        Text(dataFmt, style: const TextStyle(color: Colors.black54)),
                                      ]),
                                      const SizedBox(height: 6),
                                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                        const Text('Valor:', style: TextStyle(fontWeight: FontWeight.bold)),
                                        Text('R\$ ${NumberFormat.currency(locale: "pt_BR", symbol: "").format(pagamento.valor)}'),
                                      ]),
                                    ],
                                  ),
                                );
                              }),
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: _abrirHistoricoPagamentos,
                                  child: const Text(
                                    'Ver todos os pagamentos',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF7ED321),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              icon: const FaIcon(FontAwesomeIcons.whatsapp, color: Colors.white),
                              label: const Text('Cobrar cliente', style: TextStyle(fontSize: 18, color: Colors.white)),
                              onPressed: cobrarClienteNoWhatsapp,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF7ED321),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              icon: const Icon(Icons.payment, color: Colors.white),
                              label: const Text('Efetuar pagamento', style: TextStyle(fontSize: 18, color: Colors.white)),
                              onPressed: abrirModalPagamento,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
