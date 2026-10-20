#!/bin/bash
# Vérifie que les fichiers locaux sont intacts (tailles attendues par le livret).
cd "$(dirname "$0")"
ok=1
while read f t; do
  r=$(wc -c < "$f" 2>/dev/null || echo 0)
  if [ "$r" = "$t" ]; then echo "OK      $f ($t octets)"; else echo "ERREUR  $f : $r au lieu de $t"; ok=0; fi
done <<LISTE
livres/carroll-alice.txt 144395
livres/shakespeare-hamlet.txt 162881
livres/melville-moby_dick.txt 1242990
livres/austen-emma.txt 887071
livres/chesterton-brown.txt 406629
livres/bible-kjv.txt 4332554
LISTE
[ $ok = 1 ] && echo "Tous les fichiers sont conformes."
