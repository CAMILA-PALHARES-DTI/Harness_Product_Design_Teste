# Repositório/

Código-fonte dos produtos do projeto, clonado aqui **para consulta**. Cada time sobe nesta pasta o código das suas aplicações (ex: `[nome-do-app].FrontEnd`, o Design System, a API de autenticação), uma pasta por repositório.

- **Somente leitura.** As skills leem o código para validar ou enriquecer a base de conhecimento (nomes de controllers/rotinas, contratos, componentes e tokens do Design System). Nenhuma skill edita nada aqui.
- **Não faz parte da base de conhecimento.** Tudo nesta pasta é ignorado pelo Git (ver `.gitignore`), exceto este README. Clone os repositórios manualmente.
- **Design System:** se o projeto tem um, clone-o aqui e descreva-o na seção "Aplicações do ecossistema" do `CLAUDE.md`. `create-prototype` e `screen-planner` leem componentes e tokens daqui; se não localizarem o DS sozinhas, perguntam em qual pasta ele está.
- **Autorização:** `create-prototype` e `screen-planner` consultam esta pasta livremente. `intent` e `create-spec` só consultam com autorização explícita do usuário para cada dúvida.

## Como usar

```bash
cd Repositório
git clone <url-do-repositorio-do-produto>
git clone <url-do-repositorio-do-design-system>
```
