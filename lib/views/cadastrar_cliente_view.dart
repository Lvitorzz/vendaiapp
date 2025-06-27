import 'package:flutter/material.dart';
import 'package:vendaai/controllers/cliente_controller.dart';
import 'package:vendaai/models/cliente_model.dart';

class CadastrarClienteView extends StatefulWidget {
  final ClienteModel? cliente;

  const CadastrarClienteView({super.key, this.cliente});

  @override
  State<CadastrarClienteView> createState() => _CadastrarClienteViewState();
}

class _CadastrarClienteViewState extends State<CadastrarClienteView> {
  final _formKey = GlobalKey<FormState>();
  final ClienteController _controller = ClienteController();

  late TextEditingController _nomeController;
  late TextEditingController _telefoneController;
  late TextEditingController _whatsappController;
  late TextEditingController _obsController;

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.cliente?.nome ?? '');
    _telefoneController = TextEditingController(
      text: widget.cliente?.telefone ?? '',
    );
    _whatsappController = TextEditingController(
      text: widget.cliente?.whatsapp ?? '',
    );
    _obsController = TextEditingController(
      text: widget.cliente?.observacao ?? '',
    );
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _telefoneController.dispose();
    _whatsappController.dispose();
    _obsController.dispose();
    super.dispose();
  }

  void _salvarCliente() {
    if (_formKey.currentState!.validate()) {
      final agora = DateTime.now();

      final cliente = ClienteModel(
        id: widget.cliente?.id,
        nome: _nomeController.text,
        telefone: _telefoneController.text,
        whatsapp: _whatsappController.text,
        observacao: _obsController.text,
        dataCadastro:
            widget.cliente?.dataCadastro ?? agora, // define apenas se for novo
      );

      if (widget.cliente == null) {
        _controller.adicionarCliente(cliente);
      } else {
        _controller.atualizarCliente(cliente);
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
                    'Cadastro de cliente',
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
                    const Text(
                      'Nome',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: _nomeController,
                      decoration: _inputDecoration('Digite o nome do cliente'),
                      validator:
                          (value) =>
                              value == null || value.isEmpty
                                  ? 'Informe o nome'
                                  : null,
                    ),
                    const SizedBox(height: 16),

                    const Text(
                      'Telefone',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: _telefoneController,
                      keyboardType: TextInputType.phone, // Teclado numérico
                      decoration: _inputDecoration(
                        'Digite o telefone do cliente (opcional)',
                      ),
                    ),
                    const SizedBox(height: 16),

                    const Text(
                      'Whatsapp',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: _whatsappController,
                      keyboardType: TextInputType.phone, // Teclado numérico
                      decoration: _inputDecoration(
                        'Digite o whatsapp do cliente',
                      ),
                    ),
                    const SizedBox(height: 16),

                    const Text(
                      'Observação',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
                        onPressed: _salvarCliente,
                        child: Text(
                          widget.cliente == null ? 'Cadastrar' : 'Salvar',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
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
