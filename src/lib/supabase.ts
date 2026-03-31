import { createClient } from '@supabase/supabase-js';

const supabaseUrl = import.meta.env.PUBLIC_SUPABASE_URL;
const supabaseAnonKey = import.meta.env.PUBLIC_SUPABASE_ANON_KEY;

export function hasSupabaseEnv() {
	return Boolean(supabaseUrl && supabaseAnonKey);
}

export function getSupabaseBrowserClient() {
	if (!hasSupabaseEnv()) {
		return null;
	}

	return createClient(supabaseUrl, supabaseAnonKey, {
		auth: {
			persistSession: true,
			autoRefreshToken: true,
			detectSessionInUrl: true,
		},
	});
}
