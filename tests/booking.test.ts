import { afterEach, describe, expect, it, vi } from 'vitest';
import { availableSlots, services } from '../src/data/pluribeauty';
import { getAvailableSlots, isPastBooking, sumServices } from '../src/lib/booking';

describe('booking rules', () => {
	afterEach(() => {
		vi.useRealTimers();
	});

	it('sums selected services into total price and duration', () => {
		const selectedServices = services.slice(0, 3);

		expect(sumServices(selectedServices)).toEqual({
			price: selectedServices.reduce((total, service) => total + service.price, 0),
			durationMinutes: selectedServices.reduce((total, service) => total + service.durationMinutes, 0),
		});
	});

	it('flags bookings in the past', () => {
		vi.useFakeTimers();
		vi.setSystemTime(new Date('2026-04-01T14:00:00'));

		expect(isPastBooking('2026-04-01', '13:30')).toBe(true);
		expect(isPastBooking('2026-04-01', '15:30')).toBe(false);
	});

	it('keeps all slots for future days', () => {
		vi.useFakeTimers();
		vi.setSystemTime(new Date('2026-04-01T14:00:00'));

		expect(getAvailableSlots('2026-04-03')).toEqual([...availableSlots]);
	});

	it('filters out past slots when booking for today', () => {
		vi.useFakeTimers();
		vi.setSystemTime(new Date('2026-04-01T13:15:00'));

		expect(getAvailableSlots('2026-04-01')).toEqual(['14:30', '16:00', '18:30']);
	});
});
