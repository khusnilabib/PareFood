/// Edit-profile page (F2, PF-DOC-11 §3.1 presentation/pages).
library;

import 'package:flutter/material.dart';
import 'package:pare_design/pare_design.dart';

import '../../domain/user_profile.dart';
import '../widgets/edit_profile_form.dart';

/// Scoped profile editing entry point.
class EditProfilePage extends StatelessWidget {
  const EditProfilePage({required this.profile, super.key});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit profil')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(PfSpacing.xl),
          child: EditProfileForm(profile: profile),
        ),
      ),
    );
  }
}
