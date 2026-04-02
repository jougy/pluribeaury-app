import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { describe, expect, it } from 'vitest';
import { professionals, services } from '../src/data/pluribeauty';

function extractEnumValues(sql: string, enumName: string) {
	const expression = new RegExp(`create type public\\.${enumName} as enum \\(([^;]+)\\)`, 'i');
	const match = sql.match(expression);

	if (!match) {
		throw new Error(`Enum ${enumName} not found in migration`);
	}

	return match[1]
		.split(',')
		.map((value) => value.trim().replace(/^'|'$/g, ''));
}

describe('database alignment', () => {
	const migration = readFileSync(
		resolve(process.cwd(), 'supabase/migrations/202603310001_initial_pluribeauty.sql'),
		'utf8',
	);

	it('keeps active app categories compatible with the database enum', () => {
		const databaseCategories = new Set(extractEnumValues(migration, 'service_category'));
		const usedCategories = new Set([...professionals.flatMap((professional) => professional.specialties), ...services.map((service) => service.category)]);

		for (const category of usedCategories) {
			expect(databaseCategories.has(category), category).toBe(true);
		}
	});

	it('keeps active service types compatible with the database enum', () => {
		const databaseServiceTypes = new Set(extractEnumValues(migration, 'service_type'));
		const usedServiceTypes = new Set([
			...professionals.flatMap((professional) => professional.serviceTypes),
			...services.flatMap((service) => service.availableAt),
		]);

		for (const serviceType of usedServiceTypes) {
			expect(databaseServiceTypes.has(serviceType), serviceType).toBe(true);
		}
	});
});
