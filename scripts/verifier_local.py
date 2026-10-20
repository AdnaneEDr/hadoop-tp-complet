"""Controle independant des donnees, sans simuler HDFS ni YARN. Python 3 standard."""
from pathlib import Path
from collections import Counter
from itertools import combinations
import re,json,time,math,hashlib
ROOT=Path(__file__).resolve().parents[1]; OUT=ROOT/'resultats'/'verification_locale';OUT.mkdir(parents=True,exist_ok=True)
files=sorted(p for p in (ROOT/'donnees/livres').glob('*.txt') if p.name!='bible-kjv.txt')
words=Counter();raw=Counter();per_file=0;lines=0;size=0
for p in files:
 data=p.read_bytes();text=data.decode('utf-8');c=Counter(re.findall(r'[^\W\d_]+',text.lower()))
 words.update(c);raw.update(text.split());per_file+=len(c);lines+=data.count(b'\n');size+=len(data)
def save_counts(name,c):
 (OUT/name).write_text(''.join(f'{k}\t{v}\n' for k,v in sorted(c.items())),encoding='utf-8')
save_counts('wordcount_complet.tsv',words);save_counts('wordcount_hadoop_standard.tsv',raw)
(OUT/'tous.txt').write_bytes(b''.join(p.read_bytes() for p in files))
stop=set((ROOT/'scripts/mots_vides.txt').read_text().split(','))
filtered=Counter({k:v for k,v in words.items() if len(k)>=3 and k not in stop});save_counts('wordcount_filtre.tsv',filtered)
summary=dict(octets=size,lignes=lines,mots=sum(words.values()),mots_distincts=len(words),paires_apres_combinaison_par_fichier=per_file,top10=words.most_common(10),top5_filtre=filtered.most_common(5),ignores=sum(words.values())-sum(filtered.values()),top3_standard=raw.most_common(3))
assert size==2843966 and lines==55654
assert sum(words.values())==511244 and len(words)==23892
assert per_file==39051 and filtered['whale']==1228
def graph(p):
 g={}
 for line in p.read_text(encoding='utf-8').splitlines():
  who,fs=line.split(':');g[who]=set(filter(None,(x.strip() for x in fs.split(','))))
 return g
def render(g,k,minn=1):
 out={}
 for who,fs in g.items():
  for group in combinations(sorted(fs),k):out.setdefault(group,set()).add(who)
 rows=[]
 for group,fs in sorted(out.items()):
  if len(fs)<minn:continue
  status='amis entre eux' if all(b in g.get(a,set()) and a in g.get(b,set()) for a,b in combinations(group,2)) else 'PAS tous amis'
  rows.append(','.join(group)+'\t'+str(len(fs))+'\t['+', '.join(sorted(fs))+']\t'+status+'\n')
 return ''.join(rows),sum(math.comb(len(v),k) for v in g.values()),len(out)
g=graph(ROOT/'donnees/amis.txt')
def method1(g):
 pairs={}
 for who,fs in g.items():
  for f in fs:pairs.setdefault(tuple(sorted((who,f))),[]).append(fs)
 invalid=0;rows=[]
 for pair,lists in sorted(pairs.items()):
  if len(lists)!=2:invalid+=1;continue
  rows.append(','.join(pair)+'\t['+', '.join(sorted(lists[0]&lists[1]))+']\n')
 return ''.join(rows),invalid
text,invalid=method1(g);(OUT/'amis_m1.tsv').write_text(text,encoding='utf-8');assert len(text.splitlines())==9 and invalid==0
for k in (2,3,4):
 text,emitted,distinct=render(g,k);(OUT/f'amis_k{k}.tsv').write_text(text,encoding='utf-8');summary[f'petit_k{k}']={'emis':emitted,'groupes':distinct}
assert [summary[f'petit_k{k}']['emis'] for k in (2,3,4)]==[24,14,3]
asym=graph(ROOT/'donnees/amis_asymetrique.txt');(OUT/'amis_asymetrique_k2.tsv').write_text(render(asym,2)[0],encoding='utf-8')
text,invalid=method1(asym);(OUT/'amis_asymetrique_m1.tsv').write_text(text,encoding='utf-8');assert invalid==2
summary['asymetrie_m1_arretes_ignorees']=invalid
g=graph(ROOT/'donnees/amis_1000.txt');names=sorted(g);index={n:i for i,n in enumerate(names)};N=len(names)
summary['graphe_1000_symetrique']=all(a in g.get(b,set()) for a,fs in g.items() for b in fs)
for k in (2,3,4):
 start=time.perf_counter();counts=Counter()
 for who,fs in g.items():
  ids=sorted(index[x] for x in fs)
  for group in combinations(ids,k):
   key=0
   for x in group:key=key*N+x
   counts[key]+=1
 distinct=len(counts);emitted=sum(counts.values());kept=[]
 for key,n in counts.items():
  if n<3:continue
  ids=[]
  for _ in range(k):ids.append(key%N);key//=N
  group=tuple(names[x] for x in reversed(ids));fs=set.intersection(*(g[x] for x in group))
  assert len(fs)==n
  status='amis entre eux' if all(b in g[a] and a in g[b] for a,b in combinations(group,2)) else 'PAS tous amis'
  kept.append((group,n,fs,status))
 kept.sort(key=lambda x:(-x[1],x[0]))
 (OUT/f'amis_1000_k{k}_min3.tsv').write_text(''.join(','.join(a)+'\t'+str(n)+'\t['+', '.join(sorted(fs))+']\t'+status+'\n' for a,n,fs,status in kept),encoding='utf-8')
 summary[f'grand_k{k}']={'emis':emitted,'distincts':distinct,'retenus':len(kept),'duree_secondes':round(time.perf_counter()-start,3),'maximum':[(','.join(a),n,status) for a,n,fs,status in kept if n==kept[0][1]]}
 print('graphe',k,summary[f'grand_k{k}'],flush=True);del counts
(OUT/'synthese.json').write_text(json.dumps(summary,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps(summary,ensure_ascii=False,indent=2),flush=True)
