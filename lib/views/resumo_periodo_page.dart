import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vendaai/controllers/venda_controller.dart';

class ResumoPeriodoPage extends StatefulWidget {
  const ResumoPeriodoPage({super.key});

  @override
  State<ResumoPeriodoPage> createState() => _ResumoPeriodoPageState();
}

class _ResumoPeriodoPageState extends State<ResumoPeriodoPage> {
  final _controller = VendaController();
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  double _total = 0, _fiado = 0, _pago = 0;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _buscarResumo();
  }

  Future<void> _buscarResumo() async {
    setState(() => _loading = true);
    final resumo = await _controller.calcularResumoEntrePeriodo(
      _startDate,
      _endDate,
    );
    setState(() {
      _total = resumo['total'] ?? 0;
      _fiado = resumo['fiado'] ?? 0;
      _pago  = resumo['pago']  ?? 0;
      _loading = false;
    });
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: _endDate,
      locale: const Locale('pt','BR'),
    );
    if (picked != null) {
      setState(() => _startDate = picked);
      if (_endDate.isBefore(picked)) _endDate = picked;
      await _buscarResumo();
    }
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: DateTime.now(),
      locale: const Locale('pt','BR'),
    );
    if (picked != null) {
      setState(() => _endDate = picked);
      await _buscarResumo();
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yyyy');
    return Scaffold(
      backgroundColor: const Color(0xFF26A6DF),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
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
                    'Resumo por Período',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Seletor de período
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today, color: Color(0xFF26A6DF)),
                      label: Text(fmt.format(_startDate)),
                      onPressed: _pickStartDate,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF26A6DF)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today, color: Color(0xFF26A6DF)),
                      label: Text(fmt.format(_endDate)),
                      onPressed: _pickEndDate,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF26A6DF)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Conteúdo branco com resultados
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: _loading
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFF26A6DF)))
                    : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              const Icon(Icons.bar_chart, size: 40, color: Color(0xFF26A6DF)),
                              const SizedBox(height: 8),
                              Text(
                                'Período: ${fmt.format(_startDate)} - ${fmt.format(_endDate)}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _ResumoCard(
                            icon: Icons.sell,
                            label: 'Total vendido',
                            value: _total,
                            color: Colors.blueAccent,
                          ),
                          _ResumoCard(
                            icon: Icons.monetization_on,
                            label: 'Total recebido',
                            value: _pago,
                            color: Colors.green,
                          ),
                          _ResumoCard(
                            icon: Icons.account_balance_wallet,
                            label: 'Total fiado',
                            value: _fiado,
                            color: Colors.orange,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _buscarResumo,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Atualizar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResumoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final double value;
  final Color color;

  const _ResumoCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 8),
              Text(
                'R\$ ${value.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Colors.black54),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
