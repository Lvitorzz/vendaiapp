import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vendaai/controllers/pagamento_controller.dart';
import 'package:vendaai/controllers/venda_controller.dart';
import 'package:vendaai/models/cliente_model.dart';
import 'package:vendaai/models/venda_model.dart';

class DetalhesClienteView extends StatefulWidget {
  final ClienteModel cliente;

  const DetalhesClienteView({super.key, required this.cliente});

  @override
  State<DetalhesClienteView> createState() => _DetalhesClienteViewState();
}

class _DetalhesClienteViewState extends State<DetalhesClienteView> {
  double _totalFiado = 0.0;
  double _totalPago = 0.0;

  void calcularTotais(List<VendaModel> vendas) async {
    final fiadas = vendas.where((v) => (v.tipo ?? '').toLowerCase().trim() == 'fiada').toList();
    final totalFiado = fiadas.fold<double>(0.0, (soma, venda) {
      return soma +
          (venda.produtos.isNotEmpty
              ? venda.produtos.fold(0.0, (s, p) => s + (p.preco * p.quantidade))
              : venda.valor);
    });

    final totalPago = await PagamentoController().calcularTotalPago(widget.cliente.id!);

    setState(() {
      _totalFiado = totalFiado;
      _totalPago = totalPago;
    });
  }

  void abrirModalPagamento() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Efetuar pagamento'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Valor pago'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final valor = double.tryParse(controller.text.replaceAll(',', '.'));
              if (valor != null && valor > 0) {
                await PagamentoController().registrarPagamento(
                  clienteId: widget.cliente.id!,
                  valor: valor,
                );
                if (mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  void cobrarClienteNoWhatsapp() async {
    final numero = widget.cliente.whatsapp?.replaceAll(RegExp(r'\D'), '');
    if (numero == null || numero.isEmpty) return;

    final valorRestante = (_totalFiado - _totalPago).toStringAsFixed(2);
    final mensagem = Uri.encodeComponent(
        "Olá ${widget.cliente.nome}, estamos entrando em contato para lembrar que o valor pendente é de R\$ $valorRestante. Qualquer dúvida estamos à disposição.");
    final url = Uri.parse("https://wa.me/$numero?text=$mensagem");

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Não foi possível abrir o WhatsApp.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF26A6DF),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  const Text('Detalhes', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
            ),

            // Card cliente
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Nome: ${widget.cliente.nome}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('Data de cadastro: ${DateFormat('dd/MM/yyyy').format(widget.cliente.dataCadastro ?? DateTime.now())}'),
                  Text('Telefone: ${widget.cliente.telefone ?? 'Não informado'}'),
                  Text('WhatsApp: ${widget.cliente.whatsapp ?? 'Não informado'}'),
                  const SizedBox(height: 4),
                  Text(
                    'Total dívida: R\$ ${(_totalFiado - _totalPago).toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                  Text('Observação: ${widget.cliente.observacao ?? 'Nenhuma'}'),
                ],
              ),
            ),

            const Padding(
              padding: EdgeInsets.only(bottom: 8.0),
              child: Text('Compras fiadas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            ),

            // Lista de fiadas
            Expanded(
              child: StreamBuilder<List<VendaModel>>(
                stream: VendaController().listarVendasPorCliente(widget.cliente.id!),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text('Nenhuma compra fiada.', style: TextStyle(color: Colors.white)),
                    );
                  }

                  final todas = snapshot.data!;
                  calcularTotais(todas);

                  final fiadas = todas
                      .where((v) => (v.tipo ?? '').toLowerCase().trim() == 'fiada')
                      .toList();

                  if (fiadas.isEmpty) {
                    return const Center(
                      child: Text('Nenhuma compra fiada.', style: TextStyle(color: Colors.white)),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: fiadas.length,
                    itemBuilder: (context, index) {
                      final venda = fiadas[index];
                      final dataFormatada = DateFormat('dd/MM/yyyy – HH:mm').format(venda.data);

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        color: const Color(0xFFE0E0E0),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Data: $dataFormatada', style: const TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              if (venda.produtos.isNotEmpty)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: venda.produtos.map((p) {
                                    return Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('${p.quantidade}x ${p.nome}', style: const TextStyle(fontSize: 14)),
                                        Text('R\$ ${(p.preco * p.quantidade).toStringAsFixed(2)}', style: const TextStyle(fontSize: 14)),
                                      ],
                                    );
                                  }).toList(),
                                )
                              else
                                Text('Valor: R\$ ${venda.valor.toStringAsFixed(2)}', style: const TextStyle(fontSize: 14)),
                              if (venda.observacao != null && venda.observacao!.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text('Obs: ${venda.observacao!}', style: const TextStyle(fontStyle: FontStyle.italic)),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7ED321),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: cobrarClienteNoWhatsapp,
                      child: const Text('Cobrar cliente', style: TextStyle(fontSize: 18, color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7ED321),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: abrirModalPagamento,
                      child: const Text('Efetuar pagamento', style: TextStyle(fontSize: 18, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
