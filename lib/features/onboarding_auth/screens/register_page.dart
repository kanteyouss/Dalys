import 'package:flutter/material.dart';
import '../../../data/models/user_model.dart';
import '../../../data/services/auth_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emergencyContactNameController = TextEditingController();
  final _emergencyContactPhoneController = TextEditingController();
  final _doctorEmailController = TextEditingController();
  final _hospitalEmailController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  final _authService = AuthService();

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _emergencyContactNameController.dispose();
    _emergencyContactPhoneController.dispose();
    _doctorEmailController.dispose();
    _hospitalEmailController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final user = UserModel(
      nom: _nomController.text.trim(),
      prenom: _prenomController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      telephone: _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
      emergencyContactName: _emergencyContactNameController.text.trim().isEmpty
          ? null
          : _emergencyContactNameController.text.trim(),
      emergencyContactPhone:
          _emergencyContactPhoneController.text.trim().isEmpty
              ? null
              : _emergencyContactPhoneController.text.trim(),
      doctorEmail: _doctorEmailController.text.trim().isEmpty
          ? null
          : _doctorEmailController.text.trim(),
      hospitalEmail: _hospitalEmailController.text.trim().isEmpty
          ? null
          : _hospitalEmailController.text.trim(),
    );

    final success = await _authService.register(user);

    setState(() => _isLoading = false);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Inscription réussie ! Vous pouvez vous connecter.')),
        );
        Navigator.pop(context); // Retour à la page de connexion
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur : Cet email est déjà utilisé.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Créer un compte'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Rejoignez DALYS',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Suivez votre santé respiratoire intelligemment',
                style: TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Nom & Prénom
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _prenomController,
                      decoration: const InputDecoration(
                        labelText: 'Prénom',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Requis' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _nomController,
                      decoration: const InputDecoration(
                        labelText: 'Nom',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Requis' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Email
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return 'L\'email est requis';
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                      .hasMatch(value)) {
                    return 'Email invalide';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Téléphone (Optionnel)
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Téléphone (Optionnel)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),

              // Mot de passe
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Mot de passe',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword
                        ? Icons.visibility_off
                        : Icons.visibility),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                obscureText: _obscurePassword,
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return 'Le mot de passe est requis';
                  if (value.length < 6) return 'Minimum 6 caractères';
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Section Contact d'urgence
              const Divider(),
              const Text(
                'Contact d\'urgence (Optionnel)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emergencyContactNameController,
                decoration: const InputDecoration(
                  labelText: 'Nom du contact d\'urgence',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.contact_emergency),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emergencyContactPhoneController,
                decoration: const InputDecoration(
                  labelText: 'Téléphone du contact d\'urgence',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 24),

              // Section Contacts médicaux
              const Divider(),
              const Text(
                'Contacts médicaux (Optionnel)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _doctorEmailController,
                decoration: const InputDecoration(
                  labelText: 'Email du médecin',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.medical_services),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _hospitalEmailController,
                decoration: const InputDecoration(
                  labelText: 'Email de l\'hôpital',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.local_hospital),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: _isLoading ? null : _register,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('S\'inscrire', style: TextStyle(fontSize: 18)),
              ),
              const SizedBox(height: 16),

              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Déjà un compte ? Se connecter'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
