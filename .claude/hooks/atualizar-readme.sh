#!/bin/bash
# Regenera a tabela de skills no README.md quando um SKILL.md é criado ou editado.
# Triggered as PostToolUse hook on Write and Edit operations.

INPUT=$(cat)

FILE_PATH=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('tool_input', {}).get('file_path', ''))
except:
    print('')
" 2>/dev/null || echo "")

# Só executa para modificações em arquivos SKILL.md
if [[ "$FILE_PATH" != *".claude/skills/"*"/SKILL.md" ]]; then
  exit 0
fi

python3 << 'PYEOF'
import os, re

skills_dir = ".claude/skills"
readme_path = "README.md"

if not os.path.isfile(readme_path):
    exit(0)

rows = []
for skill_name in sorted(os.listdir(skills_dir)):
    skill_file = os.path.join(skills_dir, skill_name, "SKILL.md")
    if not os.path.isfile(skill_file):
        continue

    content = open(skill_file, encoding="utf-8").read()

    # Tenta extrair description do frontmatter YAML
    match = re.search(r'^description:\s*(.+?)$', content, re.MULTILINE)
    if match:
        desc = match.group(1).strip()
        first_sentence = re.split(r'(?<=[.!?])\s', desc)[0]
    else:
        # Tenta extrair do bloco ## Descrição
        match = re.search(r'^## Descrição\s*\n(.*?)(?=\n##|\Z)', content, re.MULTILINE | re.DOTALL)
        if match:
            desc = re.sub(r'<!--.*?-->', '', match.group(1), flags=re.DOTALL).strip()
            first_sentence = re.split(r'(?<=[.!?])\s', desc)[0] if desc else "*(descrição não preenchida)*"
        else:
            first_sentence = "*(descrição não preenchida)*"

    rows.append(f"| `/{skill_name}` | {first_sentence} |")

table = "| Comando | Descrição |\n|---|---|\n" + "\n".join(rows)

readme = open(readme_path, encoding="utf-8").read()
new_readme = re.sub(
    r'<!-- SKILLS_TABLE_START -->.*?<!-- SKILLS_TABLE_END -->',
    f'<!-- SKILLS_TABLE_START -->\n{table}\n<!-- SKILLS_TABLE_END -->',
    readme,
    flags=re.DOTALL
)

if new_readme != readme:
    open(readme_path, 'w', encoding="utf-8").write(new_readme)
    print(f"README.md atualizado ({len(rows)} skills).")
PYEOF
