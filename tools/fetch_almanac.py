"""Download Commons photographs and retain per-image attribution; rerunnable."""
import json, urllib.request, urllib.parse, pathlib, re, time
ROOT = pathlib.Path(__file__).resolve().parents[1]
OUT = ROOT / 'assets/almanac'
DATA = [
('pez azul','pez azul','Paracanthurus hepatus','Tiene cara de saber el camino. No le preguntes dos veces.'),
('pez naranja','pez naranja','Carassius auratus','No cuenta chistes: cobra por aparecer con ese traje.'),
('anginla','anginla','Electrophorus electricus','Su factura de luz siempre llega con saldo a favor.'),
('pez linterna','pez linterna','Melanocetus johnsonii','Trajo luz propia. El cargador se vende por separado.'),
('pez dorado millonario','pez dorado millonario','Carassius auratus','Diversifica su cartera entre burbujas y monedas.'),
('pulpo','pulpo nadando 1','Octopus vulgaris','Ocho brazos y aun así nunca encuentra sus llaves.'),
('pez oracles','pez oracles','Synchiropus splendidus','Siempre llega tarde: dice que el tiempo es relativo.'),
('foca','foca','Phoca vitulina','Aplaude tus inversiones. No es asesora financiera.'),
('caracol','caracol 1','Littorina littorea','Reservó primera fila en el cristal y no piensa cederla.'),
('medusa','medusa','Aurelia aurita','Sin cerebro, pero con ideas eléctricas para tus robots.'),
('pez globo','pez goblo tranquilo','Arothron hispidus','Se toma las críticas demasiado a pecho. Y se infla.'),
('delfín','','Tursiops truncatus','Llegó silbando y ya conoce a toda la tripulación.'),
('tiburón','','Carcharodon carcharias','Sonríe para la foto. Tú decide si eso te tranquiliza.'),
('pulpo gigante','pulpo nadando 1','Enteroctopus dofleini','Pide ocho asientos junto a la ventana.'),
('ballena','','Megaptera novaeangliae','Su karaoke se escucha desde el otro lado del océano.'),
('mantarraya gigante','','Mobula birostris','Vuela sin despegar del agua. El equipaje va debajo.'),
('pulpo abisal','pulpo nadando 2','Grimpoteuthis','Tiene orejas de dibujo animado y horario nocturno.'),
('pez payaso','pez payaso','Amphiprion ocellaris','No cuenta chistes: cobra por aparecer con ese traje.')]
def api(host, **args):
    args.update(action='query', format='json')
    req=urllib.request.Request('https://'+host+'/w/api.php?'+urllib.parse.urlencode(args),headers={'User-Agent':'OceanVR-Educational/1.0 (photo attribution research)'})
    with urllib.request.urlopen(req, timeout=30) as r: return json.load(r)
def clean(s): return re.sub('<[^>]+>', '', s)
previous=json.loads((OUT/'catalog.json').read_text(encoding='utf-8')) if (OUT/'catalog.json').exists() else []
entries=[]
for i,(name,sprite,taxon,joke) in enumerate(DATA):
    if i < len(previous) and previous[i].get('photo') and not (i == 3 and previous[i]['photo'].endswith('.png')):
        entries.append(previous[i])
        continue
    entry=dict(name=name,sprite=('res://assets/art/'+sprite+'.png') if sprite else '',taxon=taxon,joke=joke,photo='',source='',credit='',license='',reference='https://en.wikipedia.org/wiki/'+urllib.parse.quote(taxon.replace(' ','_')))
    try:
        pages=api('en.wikipedia.org',titles=taxon,redirects=1,prop='pageimages',piprop='name|thumbnail',pithumbsize=640)['query']['pages']
        page=next(iter(pages.values()))
        filename=page.get('pageimage','')
        if i == 3:
            filename='Melanocetus johnsonii1.jpg'
            entry['taxon']='Melanocetus sp. (referente)'
        if not filename: raise ValueError('No photograph for '+taxon)
        meta=api('commons.wikimedia.org',titles='File:'+filename,prop='imageinfo',iiprop='url|extmetadata',iiurlwidth=640)
        info=next(iter(meta['query']['pages'].values()))['imageinfo'][0]
        ext=info['extmetadata']
        license=ext.get('LicenseShortName',{}).get('value','')
        if not any(x in license for x in ['CC BY','CC0','Public domain']): raise ValueError('Unapproved license '+license)
        url=info.get('thumburl',info['url'])
        suffix='.png' if '.png' in url.lower() else '.jpg'
        path=OUT/(str(i)+suffix)
        if not path.exists():
            req=urllib.request.Request(url,headers={'User-Agent':'OceanVR-Educational/1.0'})
            with urllib.request.urlopen(req,timeout=30) as r: path.write_bytes(r.read())
        entry.update(photo='res://assets/almanac/'+path.name,source=info['descriptionurl'],credit=clean(ext.get('Artist',{}).get('value','Wikimedia Commons')),license=license,license_url=ext.get('LicenseUrl',{}).get('value',''))
        print('OK',taxon,license,flush=True)
    except Exception as e: print('FAILED',taxon,str(e),flush=True)
    entries.append(entry)
    time.sleep(12)
(OUT/'catalog.json').write_text(json.dumps(entries,ensure_ascii=False,indent=2),encoding='utf-8')
(OUT/'CREDITS.md').write_text('# Fotografías del almanaque\n\nFotografías descargadas de Wikimedia Commons; no se modificaron salvo el tamaño de miniatura servido por Commons. Los animales fantásticos usan un referente real, no una identificación científica del personaje. Textos humorísticos originales de Ocean VR.\n\n'+'\n\n'.join(f"- **{e['name']}** — {e['taxon']}: {e['credit']}. {e['license']}. [Fuente]({e['source']}) [Licencia]({e.get('license_url','')})" for e in entries),encoding='utf-8')
(OUT/'CREDITS.txt').write_text((OUT/'CREDITS.md').read_text(encoding='utf-8'),encoding='utf-8')
