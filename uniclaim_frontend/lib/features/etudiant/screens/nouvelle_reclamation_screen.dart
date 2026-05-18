import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'dart:io';
import '../../../core/services/api_service.dart';
import '../../../core/constants/app_theme.dart';

// Catégories disponibles
const _categories = [
  {'key': 'electricite',   'label': 'Électricité',   'icon': Icons.bolt_rounded},
  {'key': 'plomberie',     'label': 'Plomberie',     'icon': Icons.water_drop_outlined},
  {'key': 'menuiserie',    'label': 'Menuiserie',    'icon': Icons.handyman_outlined},
  {'key': 'climatisation', 'label': 'Climatisation', 'icon': Icons.ac_unit_rounded},
  {'key': 'internet',      'label': 'Internet/WiFi', 'icon': Icons.wifi_rounded},
  {'key': 'autre',         'label': 'Autre',         'icon': Icons.build_outlined},
];

class NouvelleReclamationScreen extends StatefulWidget {
  const NouvelleReclamationScreen({super.key});
  @override
  State<NouvelleReclamationScreen> createState() => _State();
}

class _State extends State<NouvelleReclamationScreen> {
  final _titleCtrl  = TextEditingController();
  final _descCtrl   = TextEditingController();
  final _formKey    = GlobalKey<FormState>();
  File?  _image;
  bool   _loading   = false;
  String _category  = 'electricite'; // sélection par défaut

  Future<void> _pickImage() async {
    final img = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 75);
    if (img != null) setState(() => _image = File(img.path));
  }

  Future<void> _pickCamera() async {
    final img = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 75);
    if (img != null) setState(() => _image = File(img.path));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final formData = FormData.fromMap({
        'title'      : _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'category'   : _category,
        if (_image != null)
          'image': await MultipartFile.fromFile(
            _image!.path, filename: _image!.path.split('/').last),
      });

      await ApiService().postForm('/complaints', formData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
              SizedBox(width: 10),
              Text('Réclamation transmise au technicien !'),
            ]),
            backgroundColor: AppColors.success,
            behavior       : SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content        : Text('Erreur : $e'),
            backgroundColor: AppColors.error,
            behavior       : SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nouvelle réclamation')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [

              // ── Sélecteur catégorie ───────────────────────────────
              _sectionLabel('Type de problème *'),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount  : 3,
                shrinkWrap      : true,
                physics         : const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 10,
                mainAxisSpacing : 10,
                childAspectRatio: 1.1,
                children: _categories.map((cat) {
                  final key     = cat['key'] as String;
                  final label   = cat['label'] as String;
                  final icon    = cat['icon'] as IconData;
                  final sel     = _category == key;
                  final color   = key.categoryColor;

                  return GestureDetector(
                    onTap: () => setState(() => _category = key),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      decoration: BoxDecoration(
                        color       : sel
                          ? color.withValues(alpha: 0.12)
                          : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border      : Border.all(
                          color: sel ? color : const Color(0xFFDDE3EA),
                          width: sel ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(icon,
                            color: sel ? color : AppColors.textHint,
                            size : 26),
                          const SizedBox(height: 6),
                          Text(label,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize  : 11,
                              fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                              color     : sel ? color : AppColors.textSecondary,
                              height    : 1.2,
                            )),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),

              // Info technicien affecté
              const SizedBox(height: 12),
              _TechnicianInfo(category: _category),

              const SizedBox(height: 20),

              // ── Titre ─────────────────────────────────────────────
              _sectionLabel('Titre de la réclamation *'),
              const SizedBox(height: 8),
              TextFormField(
                controller : _titleCtrl,
                decoration : const InputDecoration(
                  hintText  : 'Ex : Prise électrique en panne',
                  prefixIcon: Icon(Icons.title_rounded),
                ),
                validator: (v) =>
                  v == null || v.trim().length < 5
                    ? 'Titre trop court (min. 5 caractères)' : null,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 20),

              // ── Description ───────────────────────────────────────
              _sectionLabel('Description du problème *'),
              const SizedBox(height: 8),
              TextFormField(
                controller : _descCtrl,
                maxLines   : 5,
                decoration : const InputDecoration(
                  hintText          : 'Décrivez le problème : localisation, depuis quand, symptômes...',
                  alignLabelWithHint: true,
                  prefixIcon        : Padding(
                    padding: EdgeInsets.only(bottom: 64),
                    child  : Icon(Icons.description_outlined),
                  ),
                ),
                validator: (v) =>
                  v == null || v.trim().length < 10
                    ? 'Description trop courte (min. 10 caractères)' : null,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 24),

              // ── Photo ─────────────────────────────────────────────
              _sectionLabel('Photo (optionnelle)'),
              const SizedBox(height: 8),
              if (_image != null) ...[
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(_image!,
                        width: double.infinity, height: 200, fit: BoxFit.cover),
                    ),
                    Positioned(
                      top: 8, right: 8,
                      child: GestureDetector(
                        onTap: () => setState(() => _image = null),
                        child: Container(
                          padding   : const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Colors.black54, shape: BoxShape.circle),
                          child: const Icon(Icons.close_rounded,
                            color: Colors.white, size: 18),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: _pickImage,
                  icon : const Icon(Icons.swap_horiz_rounded),
                  label: const Text('Changer la photo'),
                ),
              ] else ...[
                Row(
                  children: [
                    Expanded(child: _photoButton(
                      icon: Icons.photo_library_outlined,
                      label: 'Galerie', onTap: _pickImage)),
                    const SizedBox(width: 12),
                    Expanded(child: _photoButton(
                      icon: Icons.camera_alt_outlined,
                      label: 'Caméra', onTap: _pickCamera)),
                  ],
                ),
              ],

              const SizedBox(height: 32),

              SizedBox(
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : _submit,
                  icon : _loading
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : const Icon(Icons.send_rounded),
                  label: Text(_loading ? 'Envoi en cours...' : 'Soumettre la réclamation'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(text,
    style: const TextStyle(
      fontSize: 13, fontWeight: FontWeight.w700,
      color: AppColors.textSecondary, letterSpacing: 0.3));

  Widget _photoButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap       : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height    : 80,
        decoration: BoxDecoration(
          color       : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border      : Border.all(color: const Color(0xFFDDE3EA)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.primary, size: 26),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(
              fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

// ── Affiche le technicien qui recevra la réclamation ──────────────
class _TechnicianInfo extends StatelessWidget {
  final String category;
  const _TechnicianInfo({required this.category});

  static const _techMap = {
    'electricite'  : 'Karim Benali — Électricité',
    'plomberie'    : 'Sofiane Meziane — Plomberie',
  };

  @override
  Widget build(BuildContext context) {
    final color     = category.categoryColor;
    final techName  = _techMap[category];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color       : color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
        border      : Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(category.categoryIcon, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: techName != null
              ? RichText(text: TextSpan(
                  style: TextStyle(fontSize: 12, color: color),
                  children: [
                    const TextSpan(text: 'Sera transmis à : ',
                      style: TextStyle(fontWeight: FontWeight.w500)),
                    TextSpan(text: techName,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  ],
                ))
              : Text('Sera transmis au technicien disponible',
                  style: TextStyle(fontSize: 12, color: color,
                    fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}
