import { describe, expect, it } from 'vitest';
import { categories, professionals } from '../src/data/pluribeauty';
import { getRouteContracts } from '../src/testing/route-contracts';

describe('route contracts', () => {
	it('builds a unique route manifest for smoke tests', () => {
		const contracts = getRouteContracts();
		const pathnames = contracts.map((contract) => contract.pathname);

		expect(new Set(pathnames).size).toBe(pathnames.length);
		expect(contracts.length).toBeGreaterThan(10);
	});

	it('includes one detail and one chat route per professional', () => {
		const contracts = getRouteContracts();

		for (const professional of professionals) {
			expect(contracts.some((contract) => contract.pathname === `/ProfissionalDetalhe/${professional.id}`)).toBe(true);
			expect(contracts.some((contract) => contract.pathname === `/Chat/${professional.id}`)).toBe(true);
		}
	});

	it('includes one specialty route per category', () => {
		const contracts = getRouteContracts();

		for (const category of categories) {
			expect(contracts.some((contract) => contract.pathname === `/Especialidades/${category.id}`)).toBe(true);
		}
	});
});
