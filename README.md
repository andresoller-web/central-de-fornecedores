# SLR Engenharia — Central de Parceiros

Plataforma interna de gestão de **fornecedores e prestadores de serviço** da SLR Engenharia:
funil de homologação (Cadastro → Qualificação → Homologação → Homologados → Re-Qualificação → Black List),
avaliações ponderadas de obra, controle de documentos, academia de processos e painel de produtividade.

## Estado atual

- **Frontend:** aplicação React (single-page) empacotada em um único `index.html`. Não precisa de build.
- **Dados (hoje):** ficam no navegador (`localStorage`), por dispositivo. **Ainda não são compartilhados entre computadores.**
- **Deploy:** Vercel, conectado a este repositório GitHub. Cada `git push` gera um novo deploy automático.

## Roadmap

1. ✅ Subir o app exatamente como está (Vercel + GitHub).
2. ⏳ Migrar o armazenamento de `localStorage` para **Supabase** (Postgres + Auth), para que os dados sejam
   compartilhados por toda a equipe, com login real e permissões.
3. ⏳ Endurecer a segurança: autenticação Supabase (senhas com hash forte no servidor), Row Level Security
   por perfil (admin / analista / operações), e política de CSP.

## Como rodar localmente

Basta abrir o `index.html` no navegador. (Opcionalmente, servir com um servidor estático.)

## Estrutura

- `index.html` — a aplicação inteira.
- `vercel.json` — configuração de deploy e headers de segurança HTTP.
