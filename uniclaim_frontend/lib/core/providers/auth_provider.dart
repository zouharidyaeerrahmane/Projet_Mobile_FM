import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../../shared/models/models.dart';

class AuthState {
  final UserModel? user;
  final bool       loading;
  final String?    error;

  const AuthState({this.user, this.loading = false, this.error});

  bool get isAuthenticated => user != null;

  AuthState copyWith({UserModel? user, bool? loading, String? error, bool clearUser = false}) =>
      AuthState(
        user    : clearUser ? null : (user ?? this.user),
        loading : loading   ?? this.loading,
        error   : error,
      );
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) {
    _checkSession();
  }

  Future<void> _checkSession() async {
    try {
      final res = await ApiService().get('/auth/me');
      if (res.data['authenticated'] == true) {
        final profil = await ApiService().get('/auth/profil');
        state = AuthState(user: UserModel.fromJson(profil.data));
      }
    } catch (_) {
      // Pas de session active — normal
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final res = await ApiService().post('/auth/login', {
        'email'    : email.trim(),
        'password' : password,
      });
      final user = UserModel.fromJson(res.data['user']);
      state = AuthState(user: user);
      return true;
    } on Exception catch (e) {
      state = state.copyWith(
        loading : false,
        error   : e.toString().contains('401')
            ? 'Email ou mot de passe incorrect'
            : 'Erreur de connexion — vérifiez le serveur',
      );
      return false;
    }
  }

  Future<bool> updateRoomNumber(String roomNumber) async {
    try {
      final res = await ApiService().patch('/users/me/room', {'roomNumber': roomNumber});
      final updated = UserModel.fromJson(res.data);
      state = state.copyWith(user: updated);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await ApiService().post('/auth/logout', {});
    } catch (_) {}
    await ApiService().clearSession();
    state = const AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (_) => AuthNotifier(),
);
