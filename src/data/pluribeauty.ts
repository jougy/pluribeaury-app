export type CategoryKey =
	| 'cabelo'
	| 'barba'
	| 'unhas'
	| 'estetica'
	| 'maquiagem'
	| 'depilacao'
	| 'massagem'
	| 'podologia'
	| 'spa'
	| 'sobrancelha'
	| 'cilios'
	| 'bronzeamento'
	| 'corte-masculino'
	| 'barbearia'
	| 'skincare-masculino'
	| 'design-de-barba'
	| 'tratamento-capilar'
	| 'outros';

export type ServiceType = 'salao' | 'domicilio';
export type ProfileType = 'individual' | 'salao';
export type BookingStatus = 'pendente' | 'confirmado' | 'concluido' | 'cancelado';

export interface Service {
	id: string;
	professionalId: string;
	name: string;
	category: CategoryKey;
	description: string;
	price: number;
	durationMinutes: number;
	availableAt: ServiceType[];
}

export interface Professional {
	id: string;
	name: string;
	tagline: string;
	coverPhoto: string;
	profilePhoto: string;
	specialties: CategoryKey[];
	bio: string;
	location: {
		address: string;
		city: string;
		lat: number;
		lng: number;
	};
	profileType: ProfileType;
	serviceTypes: ServiceType[];
	rating: number;
	totalReviews: number;
	distanceKm: number;
	priceFrom: number;
	isFeatured: boolean;
	portfolio: string[];
}

export interface Booking {
	id: string;
	clientName: string;
	professionalId: string;
	serviceIds: string[];
	date: string;
	time: string;
	locationType: ServiceType;
	address?: string;
	status: BookingStatus;
}

export interface ChatMessage {
	id: string;
	from: 'client' | 'professional';
	text: string;
	time: string;
}

export const categories = [
	{
		id: 'cabelo',
		name: 'Cabelo',
		description: 'Cortes e penteados',
		keywords: ['corte', 'cortar', 'penteado', 'escova', 'chapinha', 'babyliss', 'mechas', 'luzes', 'morena iluminada', 'coloracao', 'tintura', 'hidratacao', 'progressiva', 'botox capilar', 'alisamento', 'casamento', 'noiva', 'visual'],
		color: '#A0522D',
		image:
			'https://images.unsplash.com/photo-1521590832167-7bcbfaa6381f?auto=format&fit=crop&w=1200&q=80',
	},
	{
		id: 'barba',
		name: 'Barba',
		description: 'Design e cuidados',
		keywords: ['barba', 'aparar barba', 'barba alinhada', 'barba cheia', 'hidratar barba', 'cuidados masculinos'],
		color: '#8B7355',
		image:
			'https://images.unsplash.com/photo-1517832606299-7ae9b720a186?auto=format&fit=crop&w=1200&q=80',
	},
	{
		id: 'unhas',
		name: 'Unhas',
		description: 'Manicure e pedicure',
		keywords: ['manicure', 'pedicure', 'alongamento', 'gel', 'fibra', 'blindagem', 'nail art', 'esmalte', 'pe', 'mao', 'spa dos pes', 'casamento', 'noiva'],
		color: '#6B7B3F',
		image:
			'https://images.unsplash.com/photo-1604654894610-df63bc536371?auto=format&fit=crop&w=1200&q=80',
	},
	{
		id: 'maquiagem',
		name: 'Maquiagem',
		description: 'Make profissional',
		keywords: ['make', 'makeup', 'maquiar', 'social', 'editorial', 'festa', 'formatura', 'casamento', 'noiva', 'pele glow', 'olho esfumado', 'beauty'],
		color: '#D4C4B0',
		image:
			'https://images.unsplash.com/photo-1487412947147-5cebf100ffc2?auto=format&fit=crop&w=1200&q=80',
	},
	{
		id: 'estetica',
		name: 'Estética',
		description: 'Cuidados faciais',
		keywords: ['limpeza de pele', 'peeling', 'microagulhamento', 'facial', 'pele', 'tratamento facial', 'rejuvenescimento', 'acne', 'skincare', 'bem-estar'],
		color: '#A0522D',
		image:
			'https://images.unsplash.com/photo-1515377905703-c4788e51af15?auto=format&fit=crop&w=1200&q=80',
	},
	{
		id: 'depilacao',
		name: 'Depilação',
		description: 'Cera e laser',
		keywords: ['depilar', 'depilacao a laser', 'cera', 'virilha', 'buco', 'perna', 'axila', 'remocao de pelos'],
		color: '#8B7355',
		image:
			'https://images.unsplash.com/photo-1552693673-1bf958298935?auto=format&fit=crop&w=1200&q=80',
	},
	{
		id: 'massagem',
		name: 'Massagem',
		description: 'Relaxamento corporal',
		keywords: ['relaxar', 'dor nas costas', 'tensao', 'drenagem', 'modeladora', 'terapeutica', 'relaxante', 'corpo', 'bem-estar'],
		color: '#6B7B3F',
		image:
			'https://images.unsplash.com/photo-1515377905703-c4788e51af15?auto=format&fit=crop&w=1200&q=80',
	},
	{
		id: 'podologia',
		name: 'Podologia',
		description: 'Cuidados com pés',
		keywords: ['pes', 'unha encravada', 'calosidade', 'calo', 'podologo', 'cuidados com os pes', 'micose', 'pedicure terapeutica'],
		color: '#A0522D',
		image:
			'https://images.unsplash.com/photo-1519014816548-bf5fe059798b?auto=format&fit=crop&w=1200&q=80',
	},
	{
		id: 'spa',
		name: 'Spa',
		description: 'Tratamentos completos',
		keywords: ['spa day', 'relaxamento', 'autocuidado', 'wellness', 'ritual', 'experiencia', 'dia de beleza', 'bem-estar'],
		color: '#D4C4B0',
		image:
			'https://images.unsplash.com/photo-1544161515-4ab6ce6db874?auto=format&fit=crop&w=1200&q=80',
	},
	{
		id: 'sobrancelha',
		name: 'Sobrancelha',
		description: 'Design e micropigmentação',
		keywords: ['design de sobrancelha', 'henna', 'micropigmentacao', 'brow lamination', 'sobrancelhas', 'fio a fio', 'brow'],
		color: '#8B7355',
		image:
			'https://images.unsplash.com/photo-1512496015851-a90fb38ba796?auto=format&fit=crop&w=1200&q=80',
	},
	{
		id: 'cilios',
		name: 'Cílios',
		description: 'Extensão e volume',
		keywords: ['extensao de cilios', 'volume brasileiro', 'lash lifting', 'lash', 'fio a fio', 'mega volume', 'cilio'],
		color: '#A0522D',
		image:
			'https://images.unsplash.com/photo-1522337360788-8b13dee7a37e?auto=format&fit=crop&w=1200&q=80',
	},
	{
		id: 'bronzeamento',
		name: 'Bronzeamento',
		description: 'Natural e artificial',
		keywords: ['bronze', 'marquinha', 'verao', 'corpo dourado', 'jato', 'natural', 'praia', 'sol'],
		color: '#D4C4B0',
		image:
			'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?auto=format&fit=crop&w=1200&q=80',
	},
	{
		id: 'corte-masculino',
		name: 'Corte Masculino',
		description: 'Estilo e precisão',
		keywords: ['degrade', 'fade', 'pezinho', 'corte social', 'corte masculino', 'cabelo masculino', 'maquina', 'tesoura'],
		color: '#8B7355',
		image:
			'https://images.unsplash.com/photo-1622286342621-4bd786c2447c?auto=format&fit=crop&w=1200&q=80',
	},
	{
		id: 'barbearia',
		name: 'Barbearia',
		description: 'Experiência completa',
		keywords: ['barbearia', 'toalha quente', 'corte e barba', 'masculino', 'navalha', 'acabamento', 'ritual masculino'],
		color: '#A0522D',
		image:
			'https://images.unsplash.com/photo-1503951914875-452162b0f3f1?auto=format&fit=crop&w=1200&q=80',
	},
	{
		id: 'skincare-masculino',
		name: 'Skincare Masculino',
		description: 'Cuidados com pele',
		keywords: ['pele masculina', 'limpeza de pele masculina', 'oleosidade', 'poros', 'rosto masculino', 'autocuidado masculino'],
		color: '#6B7B3F',
		image:
			'https://images.unsplash.com/photo-1620331311520-246422fd82f9?auto=format&fit=crop&w=1200&q=80',
	},
	{
		id: 'design-de-barba',
		name: 'Design de Barba',
		description: 'Modelagem profissional',
		keywords: ['modelagem de barba', 'desenho de barba', 'barba alinhada', 'contorno', 'acabamento de barba', 'navalhado'],
		color: '#8B7355',
		image:
			'https://images.unsplash.com/photo-1512690459411-b0fd1c86b8c8?auto=format&fit=crop&w=1200&q=80',
	},
	{
		id: 'tratamento-capilar',
		name: 'Tratamento Capilar',
		description: 'Saúde dos fios',
		keywords: ['cronograma capilar', 'queda de cabelo', 'nutricao', 'reconstrucao', 'hidratacao', 'saude dos fios', 'couro cabeludo', 'fortalecimento'],
		color: '#A0522D',
		image:
			'https://images.unsplash.com/photo-1595476108010-b4d1f102b1b1?auto=format&fit=crop&w=1200&q=80',
	},
] as const;

export const professionals: Professional[] = [
	{
		id: 'studio-aura',
		name: 'Studio Aura',
		tagline: 'Colorimetria, corte e finalização com linguagem editorial.',
		coverPhoto:
			'https://images.unsplash.com/photo-1522337660859-02fbefca4702?auto=format&fit=crop&w=1400&q=80',
		profilePhoto:
			'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=600&q=80',
		specialties: ['cabelo', 'maquiagem'],
		bio: 'Especialista em atendimento de alto padrão para quem busca praticidade e sofisticação, no salão ou em domicílio.',
		location: {
			address: 'Rua Oscar Freire, 540',
			city: 'São Paulo',
			lat: -23.5629,
			lng: -46.6692,
		},
		profileType: 'individual',
		serviceTypes: ['salao', 'domicilio'],
		rating: 4.9,
		totalReviews: 187,
		distanceKm: 2.4,
		priceFrom: 120,
		isFeatured: true,
		portfolio: [
			'https://images.unsplash.com/photo-1562322140-8baeececf3df?auto=format&fit=crop&w=1000&q=80',
			'https://images.unsplash.com/photo-1595476108010-b4d1f102b1b1?auto=format&fit=crop&w=1000&q=80',
			'https://images.unsplash.com/photo-1512496015851-a90fb38ba796?auto=format&fit=crop&w=1000&q=80',
		],
	},
	{
		id: 'barbearia-norte',
		name: 'Barbearia Norte',
		tagline: 'Corte clássico, barba terapêutica e atendimento pontual.',
		coverPhoto:
			'https://images.unsplash.com/photo-1621605815971-fbc98d665033?auto=format&fit=crop&w=1400&q=80',
		profilePhoto:
			'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=600&q=80',
		specialties: ['barba', 'cabelo'],
		bio: 'Experiência masculina com agenda organizada, serviço rápido e acabamento impecável.',
		location: {
			address: 'Av. Paulista, 1280',
			city: 'São Paulo',
			lat: -23.5615,
			lng: -46.6564,
		},
		profileType: 'salao',
		serviceTypes: ['salao'],
		rating: 4.8,
		totalReviews: 124,
		distanceKm: 4.1,
		priceFrom: 70,
		isFeatured: true,
		portfolio: [
			'https://images.unsplash.com/photo-1512690459411-b0fd1c86b8c8?auto=format&fit=crop&w=1000&q=80',
			'https://images.unsplash.com/photo-1622288432450-277d0fef5ed6?auto=format&fit=crop&w=1000&q=80',
			'https://images.unsplash.com/photo-1621605815971-fbc98d665033?auto=format&fit=crop&w=1000&q=80',
		],
	},
	{
		id: 'atelier-oliva',
		name: 'Atelier Oliva',
		tagline: 'Nail design, brow shaping e autocuidado com assinatura.',
		coverPhoto:
			'https://images.unsplash.com/photo-1487412912498-0447578fcca8?auto=format&fit=crop&w=1400&q=80',
		profilePhoto:
			'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?auto=format&fit=crop&w=600&q=80',
		specialties: ['unhas', 'estetica'],
		bio: 'Atendimento delicado, com processos higienizados e ambiente pensado para relaxar.',
		location: {
			address: 'Rua dos Pinheiros, 233',
			city: 'São Paulo',
			lat: -23.5674,
			lng: -46.6885,
		},
		profileType: 'individual',
		serviceTypes: ['salao', 'domicilio'],
		rating: 4.9,
		totalReviews: 96,
		distanceKm: 1.6,
		priceFrom: 65,
		isFeatured: false,
		portfolio: [
			'https://images.unsplash.com/photo-1607779097040-26e80aa78e66?auto=format&fit=crop&w=1000&q=80',
			'https://images.unsplash.com/photo-1610992015732-2449b76344bc?auto=format&fit=crop&w=1000&q=80',
			'https://images.unsplash.com/photo-1519014816548-bf5fe059798b?auto=format&fit=crop&w=1000&q=80',
		],
	},
	{
		id: 'maison-lumi',
		name: 'Maison Lumi',
		tagline: 'Make, penteado e produção completa para ocasiões especiais.',
		coverPhoto:
			'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?auto=format&fit=crop&w=1400&q=80',
		profilePhoto:
			'https://images.unsplash.com/photo-1544005313-94ddf0286df2?auto=format&fit=crop&w=600&q=80',
		specialties: ['maquiagem', 'cabelo'],
		bio: 'Equipe boutique para eventos, casamentos e produções com deslocamento inteligente.',
		location: {
			address: 'Alameda Lorena, 880',
			city: 'São Paulo',
			lat: -23.5682,
			lng: -46.6639,
		},
		profileType: 'individual',
		serviceTypes: ['domicilio'],
		rating: 4.7,
		totalReviews: 71,
		distanceKm: 6.2,
		priceFrom: 180,
		isFeatured: true,
		portfolio: [
			'https://images.unsplash.com/photo-1522337360788-8b13dee7a37e?auto=format&fit=crop&w=1000&q=80',
			'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?auto=format&fit=crop&w=1000&q=80',
			'https://images.unsplash.com/photo-1483985988355-763728e1935b?auto=format&fit=crop&w=1000&q=80',
		],
	},
];

export const services: Service[] = [
	{
		id: 'svc-aura-cut',
		professionalId: 'studio-aura',
		name: 'Corte + finalização',
		category: 'cabelo',
		description: 'Consulta de visagismo, corte e styling de acabamento.',
		price: 160,
		durationMinutes: 90,
		availableAt: ['salao', 'domicilio'],
	},
	{
		id: 'svc-aura-color',
		professionalId: 'studio-aura',
		name: 'Color refresh',
		category: 'cabelo',
		description: 'Banho de brilho e revitalização da cor.',
		price: 220,
		durationMinutes: 120,
		availableAt: ['salao'],
	},
	{
		id: 'svc-aura-make',
		professionalId: 'studio-aura',
		name: 'Make glow editorial',
		category: 'maquiagem',
		description: 'Pele iluminada, olhos suaves e acabamento fotográfico.',
		price: 190,
		durationMinutes: 75,
		availableAt: ['domicilio'],
	},
	{
		id: 'svc-norte-cut',
		professionalId: 'barbearia-norte',
		name: 'Corte social',
		category: 'cabelo',
		description: 'Corte clássico com acabamento em navalha.',
		price: 70,
		durationMinutes: 45,
		availableAt: ['salao'],
	},
	{
		id: 'svc-norte-beard',
		professionalId: 'barbearia-norte',
		name: 'Barba premium',
		category: 'barba',
		description: 'Modelagem, toalha quente e balm calmante.',
		price: 55,
		durationMinutes: 35,
		availableAt: ['salao'],
	},
	{
		id: 'svc-oliva-gel',
		professionalId: 'atelier-oliva',
		name: 'Blindagem em gel',
		category: 'unhas',
		description: 'Blindagem com acabamento natural e longa duração.',
		price: 85,
		durationMinutes: 70,
		availableAt: ['salao', 'domicilio'],
	},
	{
		id: 'svc-oliva-brow',
		professionalId: 'atelier-oliva',
		name: 'Brow design',
		category: 'estetica',
		description: 'Mapeamento facial, design e finalização suave.',
		price: 65,
		durationMinutes: 40,
		availableAt: ['salao', 'domicilio'],
	},
	{
		id: 'svc-lumi-make',
		professionalId: 'maison-lumi',
		name: 'Produção social',
		category: 'maquiagem',
		description: 'Maquiagem + penteado com deslocamento incluso.',
		price: 280,
		durationMinutes: 120,
		availableAt: ['domicilio'],
	},
];

export const bookings: Booking[] = [
	{
		id: 'booking-1',
		clientName: 'Marina Costa',
		professionalId: 'studio-aura',
		serviceIds: ['svc-aura-cut', 'svc-aura-make'],
		date: '2026-04-02',
		time: '14:30',
		locationType: 'domicilio',
		address: 'Rua Haddock Lobo, 410 - Apto 91',
		status: 'confirmado',
	},
	{
		id: 'booking-2',
		clientName: 'Luiz Mota',
		professionalId: 'barbearia-norte',
		serviceIds: ['svc-norte-cut', 'svc-norte-beard'],
		date: '2026-04-05',
		time: '10:00',
		locationType: 'salao',
		status: 'pendente',
	},
	{
		id: 'booking-3',
		clientName: 'Fernanda Reis',
		professionalId: 'atelier-oliva',
		serviceIds: ['svc-oliva-gel'],
		date: '2026-03-20',
		time: '18:15',
		locationType: 'salao',
		status: 'concluido',
	},
];

export const chatMessages: Record<string, ChatMessage[]> = {
	'studio-aura': [
		{ id: 'msg-1', from: 'professional', text: 'Oi, Marina! Recebi seu pedido e já reservei a tarde para você.', time: '09:12' },
		{ id: 'msg-2', from: 'client', text: 'Perfeito. Posso incluir make glow no mesmo atendimento?', time: '09:15' },
		{ id: 'msg-3', from: 'professional', text: 'Pode sim. Ajustei o pacote e enviei a confirmação no agendamento.', time: '09:16' },
	],
};

export const onboardingSteps = [
	{
		title: 'Identificação',
		description: 'Dados pessoais, CPF/CNPJ, documento com foto e validação de contato.',
	},
	{
		title: 'Atuação profissional',
		description: 'Especialidades, formatos de atendimento, faixa de preço e raio de deslocamento.',
	},
	{
		title: 'Portfólio e prova social',
		description: 'Galeria, redes sociais, certificados e links de trabalhos anteriores.',
	},
	{
		title: 'Compliance',
		description: 'Aceite contratual, análise manual e ativação controlada na plataforma.',
	},
] as const;

export const experienceStats = [
	{ label: 'Profissionais verificados', value: '240+' },
	{ label: 'Taxa média de avaliação', value: '4.9/5' },
	{ label: 'Atendimento em domicílio', value: '68%' },
	{ label: 'Retorno em 30 dias', value: '81%' },
] as const;

export const availableSlots = ['09:00', '10:30', '12:00', '14:30', '16:00', '18:30'] as const;

export function formatCurrency(value: number) {
	return new Intl.NumberFormat('pt-BR', {
		style: 'currency',
		currency: 'BRL',
		maximumFractionDigits: 0,
	}).format(value);
}

export function getProfessionalById(id: string) {
	return professionals.find((professional) => professional.id === id);
}

export function getServicesByProfessional(id: string) {
	return services.filter((service) => service.professionalId === id);
}

export function getBookingSummary(booking: Booking) {
	const professional = getProfessionalById(booking.professionalId);
	const selectedServices = booking.serviceIds
		.map((serviceId) => services.find((service) => service.id === serviceId))
		.filter(Boolean) as Service[];

	const totalPrice = selectedServices.reduce((sum, service) => sum + service.price, 0);
	const totalDuration = selectedServices.reduce((sum, service) => sum + service.durationMinutes, 0);

	return {
		professional,
		selectedServices,
		totalPrice,
		totalDuration,
	};
}
