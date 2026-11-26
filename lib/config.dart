/// Configuration de l'app.
///
/// `useSupabase = false` → mode 100 % local (données de démo + shared_preferences).
/// `useSupabase = true`  → backend Supabase (projet `fanzone`, région Paris).
///
/// La clé ci-dessous est une clé *publishable* : elle est faite pour être
/// embarquée dans l'app. La sécurité repose sur les règles RLS côté base.
class AppConfig {
  static const bool useSupabase = true;
  static const String supabaseUrl = 'https://lizbzscnskvsszoiszlt.supabase.co';
  static const String supabaseKey = 'sb_publishable_KGqY-LB3tStz_GIsInz3lA_rJmU9kEl';

  /// Adresse publique de l'app web : base des liens de partage (`#/match/<id>`).
  static const String shareBaseUrl = 'https://delattr-t.github.io/Fanzone/';
}
