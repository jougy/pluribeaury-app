import { describe, expect, it } from 'vitest';
import { bookings, categories, getBookingSummary, getServicesByProfessional, professionals, services } from '../src/data/pluribeauty';

describe('data contracts', () => {
	it('keeps category ids unique', () => {
		expect(new Set(categories.map((category) => category.id)).size).toBe(categories.length);
	});

	it('keeps professional ids unique', () => {
		expect(new Set(professionals.map((professional) => professional.id)).size).toBe(professionals.length);
	});

	it('assigns every service to a valid professional and valid category', () => {
		const professionalIds = new Set(professionals.map((professional) => professional.id));
		const categoryIds = new Set(categories.map((category) => category.id));

		for (const service of services) {
			expect(professionalIds.has(service.professionalId), service.id).toBe(true);
			expect(categoryIds.has(service.category), service.id).toBe(true);
		}
	});

	it('ensures every professional has at least one service and coherent priceFrom', () => {
		for (const professional of professionals) {
			const professionalServices = getServicesByProfessional(professional.id);
			expect(professionalServices.length, professional.id).toBeGreaterThan(0);

			const minPrice = Math.min(...professionalServices.map((service) => service.price));
			expect(professional.priceFrom, professional.id).toBe(minPrice);
		}
	});

	it('keeps bookings aligned with their professional services', () => {
		for (const booking of bookings) {
			const summary = getBookingSummary(booking);

			expect(summary.professional, booking.id).toBeDefined();
			expect(summary.selectedServices.length, booking.id).toBe(booking.serviceIds.length);
			expect(summary.selectedServices.every((service) => service.professionalId === booking.professionalId), booking.id).toBe(true);
			expect(summary.totalPrice, booking.id).toBeGreaterThan(0);
			expect(summary.totalDuration, booking.id).toBeGreaterThan(0);
		}
	});
});
