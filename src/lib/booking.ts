import type { Service } from '../data/pluribeauty';
import { availableSlots } from '../data/pluribeauty';

export function sumServices(services: Service[]) {
	return services.reduce(
		(accumulator, service) => ({
			price: accumulator.price + service.price,
			durationMinutes: accumulator.durationMinutes + service.durationMinutes,
		}),
		{ price: 0, durationMinutes: 0 },
	);
}

export function isPastBooking(date: string, time: string) {
	const appointmentDate = new Date(`${date}T${time}:00`);
	return appointmentDate.getTime() < Date.now();
}

export function getAvailableSlots(date: string) {
	const today = new Date();
	const selectedDate = new Date(`${date}T00:00:00`);
	const sameDay =
		today.getFullYear() === selectedDate.getFullYear() &&
		today.getMonth() === selectedDate.getMonth() &&
		today.getDate() === selectedDate.getDate();

	if (!sameDay) {
		return [...availableSlots];
	}

	return availableSlots.filter((slot) => !isPastBooking(date, slot));
}
