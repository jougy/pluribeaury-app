import { spawn } from 'node:child_process';

const previewPort = Number(process.env.SMOKE_TEST_PORT || 4325);
const previewHost = process.env.SMOKE_TEST_HOST || '127.0.0.1';
const baseUrl = `http://${previewHost}:${previewPort}`;

const routes = [
	['/', null],
	['/Descobrir', 'Beleza &amp; Estilo'],
	['/Especialidades/cabelo', 'Cabelo'],
	['/ListaProfissionais', 'Profissionais em destaque'],
	['/Agenda', 'Minha Agenda'],
	['/Mapa', 'Visualização espacial'],
	['/Favoritos', 'Coleção pessoal'],
	['/Perfil', 'Conta, preferências'],
	['/Agendamento', 'Fluxo em 3 etapas'],
	['/CadastroProfissional', 'Wizard de verificação'],
	['/ProfissionalDetalhe/studio-aura', 'Studio Aura'],
	['/Chat/studio-aura', 'Chat'],
];

function runCommand(command, args) {
	return new Promise((resolve, reject) => {
		const child = spawn(command, args, {
			stdio: 'inherit',
			env: process.env,
		});

		child.on('exit', (code) => {
			if (code === 0) {
				resolve();
				return;
			}

			reject(new Error(`${command} ${args.join(' ')} failed with code ${code}`));
		});
	});
}

async function waitForServer(url, timeoutMs = 15000) {
	const start = Date.now();

	while (Date.now() - start < timeoutMs) {
		try {
			const response = await fetch(url);
			if (response.ok) {
				return;
			}
		} catch {}

		await new Promise((resolve) => setTimeout(resolve, 500));
	}

	throw new Error(`Preview server did not become ready at ${url} within ${timeoutMs}ms`);
}

async function assertRoute(pathname, expectedText) {
	const response = await fetch(`${baseUrl}${pathname}`, {
		redirect: pathname === '/' ? 'manual' : 'follow',
	});

	if (pathname === '/') {
		if (![200, 301, 302, 307, 308].includes(response.status)) {
			throw new Error(`Route ${pathname} returned unexpected status ${response.status}`);
		}

		return;
	}

	if (!response.ok) {
		throw new Error(`Route ${pathname} returned status ${response.status}`);
	}

	if (!expectedText) {
		return;
	}

	const html = await response.text();
	if (!html.includes(expectedText)) {
		throw new Error(`Route ${pathname} did not contain expected text: ${expectedText}`);
	}
}

let previewProcess;

try {
	console.log('\n[smoke] Building project...');
	await runCommand('npm', ['run', 'build']);

	console.log(`\n[smoke] Starting preview on ${baseUrl} ...`);
	previewProcess = spawn('npm', ['run', 'preview', '--', '--host', previewHost, '--port', String(previewPort)], {
		stdio: 'inherit',
		env: process.env,
	});

	await waitForServer(`${baseUrl}/Descobrir`);

	console.log('\n[smoke] Checking main routes...');
	for (const [pathname, expectedText] of routes) {
		await assertRoute(pathname, expectedText);
		console.log(`[smoke] OK ${pathname}`);
	}

	console.log('\n[smoke] Smoke test passed.');
} finally {
	if (previewProcess && !previewProcess.killed) {
		previewProcess.kill('SIGTERM');
	}
}
