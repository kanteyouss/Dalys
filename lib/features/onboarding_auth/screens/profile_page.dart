import 'package:flutter/material.dart';
import '../../../data/services/auth_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();

  late TextEditingController _nomController;
  late TextEditingController _prenomController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _emergencyNameController;
  late TextEditingController _emergencyPhoneController;
  late TextEditingController _emergencyEmailController;
  late TextEditingController _doctorEmailController;
  late TextEditingController _hospitalEmailController;
  final _passwordController = TextEditingController();

  bool _isEditing = false;
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    final user = _authService.currentUser;
    _nomController = TextEditingController(text: user?.nom ?? '');
    _prenomController = TextEditingController(text: user?.prenom ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _phoneController = TextEditingController(text: user?.telephone ?? '');
    _emergencyNameController =
        TextEditingController(text: user?.emergencyContactName ?? '');
    _emergencyPhoneController =
        TextEditingController(text: user?.emergencyContactPhone ?? '');
    _emergencyEmailController =
        TextEditingController(text: user?.emergencyContactEmail ?? '');
    _doctorEmailController =
        TextEditingController(text: user?.doctorEmail ?? '');
    _hospitalEmailController =
        TextEditingController(text: user?.hospitalEmail ?? '');
  }

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    _emergencyEmailController.dispose();
    _doctorEmailController.dispose();
    _hospitalEmailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final currentUser = _authService.currentUser!;
    final updatedUser = currentUser.copyWith(
      nom: _nomController.text.trim(),
      prenom: _prenomController.text.trim(),
      email: _emailController.text.trim(),
      telephone: _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
      emergencyContactName: _emergencyNameController.text.trim().isEmpty
          ? null
          : _emergencyNameController.text.trim(),
      emergencyContactPhone: _emergencyPhoneController.text.trim().isEmpty
          ? null
          : _emergencyPhoneController.text.trim(),
      emergencyContactEmail: _emergencyEmailController.text.trim().isEmpty
          ? null
          : _emergencyEmailController.text.trim(),
      doctorEmail: _doctorEmailController.text.trim().isEmpty
          ? null
          : _doctorEmailController.text.trim(),
      hospitalEmail: _hospitalEmailController.text.trim().isEmpty
          ? null
          : _hospitalEmailController.text.trim(),
      // Si le mot de passe est vide, on garde l'ancien (haché)
      password: _passwordController.text.isEmpty
          ? currentUser.password
          : _passwordController.text,
    );

    final success = await _authService.updateProfile(updatedUser);

    setState(() => _isLoading = false);

    if (mounted) {
      if (success) {
        setState(() => _isEditing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil mis à jour avec succès !')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de la mise à jour.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('Non connecté')));
    }

    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Header avec Gradient et Avatar
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      primaryColor,
                      primaryColor.withOpacity(0.8),
                      const Color(0xFF00BCD4), // Accent medical
                    ],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      Stack(
                        children: [
                          Hero(
                            tag: 'profile_avatar',
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 10,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const CircleAvatar(
                                radius: 45,
                                backgroundColor: Colors.white,
                                child: Icon(Icons.person,
                                    size: 50, color: Color(0xFF2E7D8A)),
                              ),
                            ),
                          ),
                          if (_isEditing)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.camera_alt,
                                    size: 20, color: primaryColor),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${user.prenom} ${user.nom}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(_isEditing ? Icons.close : Icons.edit),
                onPressed: () => setState(() {
                  _isEditing = !_isEditing;
                  if (!_isEditing) {
                    // Reset controllers if canceling edit
                    final u = _authService.currentUser;
                    _nomController.text = u?.nom ?? '';
                    _prenomController.text = u?.prenom ?? '';
                    _emailController.text = u?.email ?? '';
                    _phoneController.text = u?.telephone ?? '';
                    _emergencyNameController.text =
                        u?.emergencyContactName ?? '';
                    _emergencyPhoneController.text =
                        u?.emergencyContactPhone ?? '';
                    _emergencyEmailController.text =
                        u?.emergencyContactEmail ?? '';
                    _doctorEmailController.text = u?.doctorEmail ?? '';
                    _hospitalEmailController.text = u?.hospitalEmail ?? '';
                    _passwordController.clear();
                  }
                }),
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Informations Personnelles'),
                    _buildCard([
                      _buildTextField(
                        controller: _prenomController,
                        label: 'Prénom',
                        icon: Icons.person_outline,
                        enabled: _isEditing,
                      ),
                      const Divider(height: 32),
                      _buildTextField(
                        controller: _nomController,
                        label: 'Nom',
                        icon: Icons.person_outline,
                        enabled: _isEditing,
                      ),
                    ]),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Contact'),
                    _buildCard([
                      _buildTextField(
                        controller: _emailController,
                        label: 'Email',
                        icon: Icons.email_outlined,
                        enabled: _isEditing,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const Divider(height: 32),
                      _buildTextField(
                        controller: _phoneController,
                        label: 'Téléphone',
                        icon: Icons.phone_outlined,
                        enabled: _isEditing,
                        keyboardType: TextInputType.phone,
                      ),
                    ]),
                    const SizedBox(height: 32),
                    _buildSectionTitle('Urgence'),
                    _buildCard([
                      _buildTextField(
                        controller: _emergencyNameController,
                        label: 'Contact d\'urgence (Nom)',
                        icon: Icons.contact_emergency_outlined,
                        enabled: _isEditing,
                      ),
                      const Divider(height: 32),
                      _buildTextField(
                        controller: _emergencyPhoneController,
                        label: 'Téléphone d\'urgence',
                        icon: Icons.phone_callback_outlined,
                        enabled: _isEditing,
                        keyboardType: TextInputType.phone,
                      ),
                      const Divider(height: 32),
                      _buildTextField(
                        controller: _emergencyEmailController,
                        label: 'Email d\'urgence',
                        icon: Icons.email_outlined,
                        enabled: _isEditing,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const Divider(height: 32),
                      _buildTextField(
                        controller: _doctorEmailController,
                        label: 'Email du médecin traitant',
                        icon: Icons.medical_services_outlined,
                        enabled: _isEditing,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) => null, // Optionnel
                      ),
                      const Divider(height: 32),
                      _buildTextField(
                        controller: _hospitalEmailController,
                        label: 'Email de l\'hôpital',
                        icon: Icons.local_hospital_outlined,
                        enabled: _isEditing,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) => null, // Optionnel
                      ),
                    ]),
                    const SizedBox(height: 24),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _isEditing
                          ? Column(
                              key: const ValueKey('security_section'),
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionTitle('Sécurité'),
                                _buildCard([
                                  TextFormField(
                                    controller: _passwordController,
                                    decoration: InputDecoration(
                                      labelText: 'Nouveau mot de passe',
                                      helperText:
                                          'Laisser vide pour ne pas changer',
                                      prefixIcon:
                                          const Icon(Icons.lock_outline),
                                      suffixIcon: IconButton(
                                        icon: Icon(_obscurePassword
                                            ? Icons.visibility_off
                                            : Icons.visibility),
                                        onPressed: () => setState(() =>
                                            _obscurePassword =
                                                !_obscurePassword),
                                      ),
                                    ),
                                    obscureText: _obscurePassword,
                                    validator: (value) {
                                      if (value != null &&
                                          value.isNotEmpty &&
                                          value.length < 6) {
                                        return 'Minimum 6 caractères';
                                      }
                                      return null;
                                    },
                                  ),
                                ]),
                                const SizedBox(height: 32),
                                ElevatedButton(
                                  onPressed: _isLoading ? null : _updateProfile,
                                  style: ElevatedButton.styleFrom(
                                    minimumSize: const Size.fromHeight(56),
                                    elevation: 2,
                                  ),
                                  child: _isLoading
                                      ? const CircularProgressIndicator(
                                          color: Colors.white)
                                      : const Text(
                                          'Enregistrer les modifications',
                                          style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold),
                                        ),
                                ),
                              ],
                            )
                          : Column(
                              key: const ValueKey('logout_section'),
                              children: [
                                const SizedBox(height: 20),
                                OutlinedButton.icon(
                                  onPressed: () {
                                    _authService.logout();
                                    Navigator.pushReplacementNamed(
                                        context, '/login');
                                  },
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size.fromHeight(56),
                                    side: const BorderSide(color: Colors.red),
                                    foregroundColor: Colors.red,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  icon: const Icon(Icons.logout),
                                  label: const Text(
                                    'Se déconnecter',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                    ),
                    const SizedBox(height: 24),
                    _buildMedicalDisclaimer(context),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicalDisclaimer(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Attention : Cette application est un outil de suivi et de prévention. Elle ne remplace en aucun cas un diagnostic médical professionnel. En cas d\'urgence, contactez les services de secours.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.orange.shade900,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade600,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool enabled = true,
    TextInputType? keyboardType,
    String? helperText,
    String? Function(String?)? validator,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        helperText: helperText,
        prefixIcon: Icon(icon, size: 22),
        suffixIcon: suffixIcon,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        disabledBorder: InputBorder.none,
        contentPadding: EdgeInsets.zero,
      ),
      enabled: enabled,
      keyboardType: keyboardType,
      style: TextStyle(
        fontSize: 16,
        color: enabled ? null : Colors.grey.shade600,
      ),
      validator: validator ??
          (value) => value == null || value.isEmpty ? 'Requis' : null,
    );
  }
}
