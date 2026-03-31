# Plano de Testes - Pluribeauty

Este arquivo registra os testes mais valiosos para o projeto `Astro + Supabase + PWA` e serve como checklist antes de qualquer entrega.

## 1. Testes Minimos Obrigatorios Antes de Entregar

Sempre que houver mudanca relevante de codigo, executar pelo menos:

1. `npm run build`
2. `npm run test:smoke`

Esses dois passos ja pegam uma boa parte dos crashes comuns:

- erro de PostCSS ou Tailwind
- import quebrado
- rota Astro invalida
- pagina dinamica sem `getStaticPaths`
- erro em build estatico
- preview que nao sobe
- paginas que retornam status diferente de `200`
- HTML final sem o texto-base esperado do produto

## 2. Testes de Build

Objetivo: garantir que o app compila sem quebrar.

Comandos:

```bash
npm run build
```

O que isso pega:

- erros de CSS
- classes inexistentes em pipeline de Tailwind/PostCSS
- imports quebrados
- problemas de rotas dinamicas
- problemas de tipagem/transpilacao

## 3. Smoke Test HTTP

Objetivo: garantir que o app gerado sobe e responde nas rotas principais.

Comando:

```bash
npm run test:smoke
```

Esse teste:

- roda o build
- sobe o `astro preview` em porta isolada
- consulta rotas principais
- valida `status 200`
- valida que o HTML contem texto esperado

Rotas verificadas hoje:

- `/`
- `/Descobrir`
- `/ListaProfissionais`
- `/Agenda`
- `/Mapa`
- `/Favoritos`
- `/Perfil`
- `/Agendamento`
- `/CadastroProfissional`
- `/ProfissionalDetalhe/studio-aura`
- `/Chat/studio-aura`

## 4. Testes Visuais e de Responsividade

Objetivo: evitar regressao de layout.

Checklist manual recomendado:

1. Mobile pequeno, ex.: `360x800`
2. Mobile grande, ex.: `430x932`
3. Tablet, ex.: `768x1024`
4. Desktop, ex.: `1440x900`
5. Ultrawide, ex.: `2560x1080`

Validar:

- bottom nav visivel nas telas certas
- bottom nav escondida em `ProfissionalDetalhe`, `Agendamento` e `Chat`
- cards de categoria sem corte feio
- CTA flutuante sem sobrepor conteudo importante
- texto sem overflow
- formularios confortaveis para toque

## 5. Testes de Fluxo

Objetivo: validar as jornadas principais do produto.

Fluxos importantes:

1. Descobrir -> ListaProfissionais -> ProfissionalDetalhe -> Agendamento -> Agenda
2. Agenda -> Chat
3. Descobrir -> CadastroProfissional
4. Mapa -> escolher profissional -> abrir perfil
5. Favoritos -> abrir perfil -> agendar

## 6. Testes de Dados e Regra de Negocio

Validacoes recomendadas:

- soma correta de preco em multi-selecao de servicos
- soma correta de duracao total
- bloqueio de horario passado
- slots disponiveis para hoje vs datas futuras
- fallback quando `PUBLIC_SUPABASE_URL` ou `PUBLIC_SUPABASE_ANON_KEY` nao existem
- comportamento com lista vazia de profissionais/servicos

## 7. Testes de Supabase Local

Objetivo: garantir ambiente local funcional.

Comandos uteis:

```bash
npx supabase start
npx supabase status
npx supabase db push
npx supabase db reset
```

Validar:

- containers sobem
- API local responde em `http://127.0.0.1:54321`
- Studio abre em `http://127.0.0.1:54323`
- migration principal aplica sem erro
- `.env` local esta sincronizado

## 8. Testes de PWA

Checklist:

- `manifest.webmanifest` acessivel
- `sw.js` acessivel
- service worker registra sem erro no browser
- tema e nome do app corretos ao instalar
- navegacao principal funciona offline ao menos para shell cacheado

## 9. Testes de Regressao Mais Provaveis

Toda mudanca deve considerar risco em:

- layout global
- rotas dinamicas
- script de resumo de servicos em `ProfissionalDetalhe`
- fluxo de agendamento por query string
- `control.sh`
- integracao de env com Supabase local

## 10. Regra de Entrega

Antes de eu encerrar uma tarefa de implementacao neste projeto, devo tentar executar pelo menos:

```bash
npm run build
npm run test:smoke
```

Se algum desses testes nao puder ser executado, isso precisa ser dito explicitamente na entrega.
