#!/usr/bin/env python3
"""Impressão digital de uma pasta: hash de caminho + tamanho + data de modificação de cada arquivo.
Uso: python3 _fingerprint.py <pasta> [nome-de-arquivo-a-ignorar ...]
Usado por atualizar-indice-geral.sh para saber se conhecimento/ mudou desde a última regeneração do
INDICE-GERAL.md. Portável (Windows/macOS/Linux) — não depende de find -printf nem de md5sum."""
import hashlib
import os
import sys

pasta = sys.argv[1] if len(sys.argv) > 1 else "."
ignorar = set(sys.argv[2:])

h = hashlib.md5()
for raiz, dirs, arquivos in os.walk(pasta):
    dirs.sort()
    for nome in sorted(arquivos):
        if nome in ignorar:
            continue
        caminho = os.path.join(raiz, nome)
        try:
            st = os.stat(caminho)
        except OSError:
            continue
        h.update(("%s|%d|%d\n" % (caminho.replace(os.sep, "/"), st.st_size, st.st_mtime_ns)).encode("utf-8"))
print(h.hexdigest())
