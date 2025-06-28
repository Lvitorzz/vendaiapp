import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../controllers/pagamento_controller.dart';
import '../models/pagamento_model.dart';

class HistoricoPagamentosView extends StatefulWidget {
  const HistoricoPagamentosView({super.key});

  @override
  State<HistoricoPagamentosView> createState() => _HistoricoPagamentosViewState();
}

class _HistoricoPagamentosViewState extends State<HistoricoPagamentosView> {
  final PagamentoController _controller = PagamentoController();

    void _abrirDetalhes(PagamentoModel pagamento) {
    final dataFormatada = DateFormat('dd/MM/yyyy – HH:mm').format(pagamento.data);

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: const Color(0xFFF5F5F5), 
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: const [
              Expanded(
                child: Text(
                  'Detalhes do Pagamento',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('👤 Cliente: ${pagamento.clienteId}'),
                const SizedBox(height: 8),
                Text('📅 Data: $dataFormatada'),
                const SizedBox(height: 8),
                Text(
                  '💵 Valor: ${NumberFormat.simpleCurrency(locale: "pt_BR").format(pagamento.valor)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fechar'),
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
              // Cabeçalho
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Histórico de Pagamentos',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Lista de pagamentos
              Expanded(
                child: StreamBuilder<List<PagamentoModel>>(
                  stream: _controller.listarTodosPagamentos(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      );
                    }

                    final pagamentos = snapshot.data ?? [];

                    if (pagamentos.isEmpty) {
                      return const Center(
                        child: Text(
                          'Nenhum pagamento encontrado.',
                          style: TextStyle(color: Colors.white),
                        ),
                      );
                    }

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
                            '${pagamentos.length} pagamentos listados',
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
                            itemCount: pagamentos.length,
                            itemBuilder: (_, index) {
                              final p = pagamentos[index];
                              final data = DateFormat('dd/MM/yyyy – HH:mm').format(p.data);

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
                                          'Data do Pagamento:',
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
                                          'Valor:',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        Text(
                                          NumberFormat.simpleCurrency(locale: 'pt_BR').format(p.valor),
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
                                        onPressed: () => _abrirDetalhes(p),
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