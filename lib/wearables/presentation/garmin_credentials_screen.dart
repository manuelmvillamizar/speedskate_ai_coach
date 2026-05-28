import 'package:flutter/material.dart';

import '../../athlete_program_service.dart';
import '../application/garmin_credentials_service.dart';

class GarminCredentialsScreen extends StatefulWidget {
  final AthleteProgramProfile athlete;

  const GarminCredentialsScreen({super.key, required this.athlete});

  @override
  State<GarminCredentialsScreen> createState() =>
      _GarminCredentialsScreenState();
}

class _GarminCredentialsScreenState extends State<GarminCredentialsScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool loading = true;
  bool saving = false;
  bool obscurePassword = true;
  String statusMessage = '';

  @override
  void initState() {
    super.initState();
    _loadExistingEmail();
  }

  Future<void> _loadExistingEmail() async {
    final email = await GarminCredentialsService.readEmail(widget.athlete.id);

    if (!mounted) return;

    setState(() {
      emailController.text = email ?? '';
      loading = false;
      statusMessage = email == null
          ? 'Ingresa las credenciales Garmin de este atleta.'
          : 'Ya existe un correo Garmin guardado para este atleta.';
    });
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _saveCredentials() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        statusMessage = 'Debes escribir email y contraseña.';
      });
      return;
    }

    setState(() {
      saving = true;
      statusMessage = 'Guardando credenciales del atleta...';
    });

    try {
      await GarminCredentialsService.saveCredentials(
        athleteId: widget.athlete.id,
        email: email,
        password: password,
      );

      if (!mounted) return;

      setState(() {
        saving = false;
        statusMessage = 'Credenciales guardadas correctamente.';
      });

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        saving = false;
        statusMessage = 'No se pudieron guardar las credenciales: $e';
      });
    }
  }

  Future<void> _clearCredentials() async {
    setState(() {
      saving = true;
      statusMessage = 'Eliminando credenciales...';
    });

    try {
      await GarminCredentialsService.clearCredentials(widget.athlete.id);

      if (!mounted) return;

      setState(() {
        emailController.clear();
        passwordController.clear();
        saving = false;
        statusMessage = 'Credenciales eliminadas.';
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        saving = false;
        statusMessage = 'No se pudieron eliminar las credenciales: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final athlete = widget.athlete;

    return Scaffold(
      appBar: AppBar(title: const Text('Configurar Garmin')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  color: const Color(0xFF111827),
                  surfaceTintColor: Colors.transparent,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Icon(Icons.watch, size: 46, color: Colors.green),
                        const SizedBox(height: 12),
                        Text(
                          athlete.name,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Estas credenciales se guardan solo para este atleta.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Card(
                  color: const Color(0xFF111827),
                  surfaceTintColor: Colors.transparent,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        TextField(
                          controller: emailController,
                          enabled: !saving,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email Garmin',
                            prefixIcon: Icon(Icons.email),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: passwordController,
                          enabled: !saving,
                          obscureText: obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Contraseña Garmin',
                            prefixIcon: const Icon(Icons.lock),
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              onPressed: saving
                                  ? null
                                  : () {
                                      setState(() {
                                        obscurePassword = !obscurePassword;
                                      });
                                    },
                              icon: Icon(
                                obscurePassword
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        if (statusMessage.isNotEmpty)
                          Text(
                            statusMessage,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white70),
                          ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: saving ? null : _saveCredentials,
                            icon: saving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.save),
                            label: Text(
                              saving ? 'Guardando...' : 'Guardar credenciales',
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: saving ? null : _clearCredentials,
                            icon: const Icon(Icons.delete_outline),
                            label: const Text('Eliminar credenciales'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Card(
                  color: Color(0xFF172554),
                  surfaceTintColor: Colors.transparent,
                  child: Padding(
                    padding: EdgeInsets.all(14),
                    child: Text(
                      'Nota: este método es para desarrollo local. Más adelante, en producción, lo ideal será usar autorización segura/OAuth o backend propio.',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
