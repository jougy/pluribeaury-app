import { categories, professionals } from '../data/pluribeauty';

export interface RouteContract {
	pathname: string;
	expectedText?: string;
	acceptRedirect?: boolean;
	source: 'static' | 'category' | 'professional' | 'chat';
}

const staticRoutes: RouteContract[] = [
	{ pathname: '/', acceptRedirect: true, source: 'static' },
	{ pathname: '/Descobrir', expectedText: 'Beleza &amp; Estilo', source: 'static' },
	{ pathname: '/ListaProfissionais', expectedText: 'Profissionais em destaque', source: 'static' },
	{ pathname: '/Agenda', expectedText: 'Minha Agenda', source: 'static' },
	{ pathname: '/Mapa', expectedText: 'Visualização espacial', source: 'static' },
	{ pathname: '/Favoritos', expectedText: 'Coleção pessoal', source: 'static' },
	{ pathname: '/Perfil', expectedText: 'Conta, preferências', source: 'static' },
	{ pathname: '/Agendamento', expectedText: 'Fluxo em 3 etapas', source: 'static' },
	{ pathname: '/CadastroProfissional', expectedText: 'Wizard de verificação', source: 'static' },
];

export function getRouteContracts() {
	return [
		...staticRoutes,
		...categories.map((category) => ({
			pathname: `/Especialidades/${category.id}`,
			expectedText: category.name,
			source: 'category' as const,
		})),
		...professionals.map((professional) => ({
			pathname: `/ProfissionalDetalhe/${professional.id}`,
			expectedText: professional.name,
			source: 'professional' as const,
		})),
		...professionals.map((professional) => ({
			pathname: `/Chat/${professional.id}`,
			expectedText: professional.name,
			source: 'chat' as const,
		})),
	];
}
