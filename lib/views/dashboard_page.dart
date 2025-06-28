import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vendaai/controllers/venda_controller.dart';
import 'package:vendaai/views/estoque_view.dart';
import 'package:vendaai/views/cadastrar_produto_view.dart';
import 'package:vendaai/views/clientes_view.dart';
import 'package:vendaai/views/nova_venda_view.dart';
import 'package:vendaai/views/historico_view.dart';
import 'package:vendaai/views/resumo_periodo_page.dart';
import '../views/historico_pagamentos_view.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final _controller = VendaController();
  DateTime _dataSelecionada = DateTime.now();
  double _total = 0;
  double _fiado = 0;
  double _pago = 0;

  @override
  void initState() {
    super.initState();
    _carregarResumo(_dataSelecionada);
  }

  Future<void> _carregarResumo(DateTime dia) async {
    final resumo = await _controller.calcularResumoParaDia(dia);
    setState(() {
      _total = resumo['total'] ?? 0;
      _fiado = resumo['fiado'] ?? 0;
      _pago  = resumo['pago']  ?? 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yyyy');
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Image.asset('assets/images/vendaai_logo.png', height: 48),
                ],
              ),
            ),

            // Destaques do dia com seletor de data
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFF26A6DF),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Destaques de ${fmt.format(_dataSelecionada)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.calendar_today, color: Colors.white),
                        onPressed: () async {
                          final DateTime? novaData = await showDatePicker(
                            context: context,
                            initialDate: _dataSelecionada,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                            locale: const Locale('pt', 'BR'),
                          );
                          if (novaData != null && novaData != _dataSelecionada) {
                            setState(() {
                              _dataSelecionada = novaData;
                            });
                            await _carregarResumo(_dataSelecionada);
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _InfoBox(
                          value: 'R\$ ${_total.toStringAsFixed(2)}',
                          label: 'Total vendido',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _InfoBox(
                          value: 'R\$ ${_fiado.toStringAsFixed(2)}',
                          label: 'Total fiado',
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _InfoBox(
                          value: 'R\$ ${_pago.toStringAsFixed(2)}',
                          label: 'Total recebido',
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Botões principais
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  // Primeira linha de botões
                  Row(
                    children: [
                      Expanded(
                        child: _MenuButton(
                          icon: Icons.shopping_cart,
                          label: 'Nova venda',
                          color: Colors.orange,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const NovaVendaView()),
                            ).then((_) {
                              _carregarResumo(_dataSelecionada);
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _MenuButton(
                          icon: Icons.person,
                          label: 'Clientes',
                          color: const Color(0xFF26A6DF),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const ClientesView()),
                            );
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: _MenuButton(
                          icon: Icons.inventory,
                          label: 'Cadastrar produto',
                          color: const Color(0xFF26A6DF),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const CadastrarProdutoView()),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _MenuButton(
                          icon: Icons.calculate,
                          label: 'Estoque',
                          color: const Color(0xFF26A6DF),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const EstoqueView()),
                            );
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const HistoricoView()),
                        );
                      },
                      child: const Text(
                        'Histórico de Vendas',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const HistoricoPagamentosView()),
                        );
                      },
                      child: const Text(
                        'Histórico de Pagamentos',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF26A6DF),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.timeline, color: Colors.white),
                      label: const Text(
                        'Resumo Período',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white,),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ResumoPeriodoPage()),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: FloatingActionButton(
                  backgroundColor: Colors.orange,
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Ajuda ainda não implementada'),
                      ),
                    );
                  },
                  child: const Icon(Icons.help_outline, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _InfoBox({
    required this.value,
    required this.label,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      constraints: const BoxConstraints(minHeight: 80),
      decoration: BoxDecoration(
        color: const Color(0xFF1A91C3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _MenuButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: onTap,
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
