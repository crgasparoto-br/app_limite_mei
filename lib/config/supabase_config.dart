// Configurações do Supabase
// IMPORTANTE: Em produção, use variáveis de ambiente ou arquivo .env
class SupabaseConfig {
  // TODO: Substituir por suas credenciais do Supabase
  // Para obter: https://supabase.com/dashboard/project/_/settings/api
  static const String supabaseUrl = 'https://naydhekxmotqsydhcvmo.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5heWRoZWt4bW90cXN5ZGhjdm1vIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njk0MzA1OTAsImV4cCI6MjA4NTAwNjU5MH0.qTt7eJRQk6KQ5zzSQNKWZ9cQ5ndGVPSFD7O1V-Z1wd8';
  
  // Validação
  static bool get isConfigured => 
      supabaseUrl.isNotEmpty && 
      supabaseAnonKey.isNotEmpty;
}
