# Werkwijze: een Wine-prefix laten starten

Document voor sessies die hier zelfstandig mee aan de slag gaan. Geschreven na het
uitzoeken van Colin McRae Rally 04 (zie `BEVINDING-ColinMcRae4.md` in deze map voor
de concrete uitkomst).

## Uitgangssituatie

- Elke spel heeft een eigen map onder `/home/peter/GAMEPREFIXES/<Spel>/`.
- De prefix die een spel écht gebruikt staat in die map, in de home-map van de
  gebruiker (`<map>/pfx`). Dat is de **productie-prefix**.
- `movedprefixes/` op de NFS-share is **tijdelijke steigersbouw**: een werkbare
  prefix wordt daar neergezet om als maatstaf te dienen. Die worden weggehaald
  zodra het klaar is. **Verwacht dus niet dat ze er over een week nog staan, en
  leg daar niets belangrijks in op dat je niet hebt weggeschreven.**
- Referentie-prefixen in `movedprefixes/` zijn een **meetlat, geen sjabloon**.
  Niet kopiëren; gebruiken om een verse prefix tegen te verifiëren.

## Kernprincipe: differentiatie

Je hebt twee prefixes: één die het spel start en één die crasht. Het verschil ertussen
is het bewijs. Niet gokken waar het misgaat, maar het verschil laten praten.

De aanpak is **aftrekkend**: begin vanuit de prefix die werkt en verwijder per groep
bestanden of takken. De groep die de crash terugbrengt is schuldig; binnen die groep
ga je verder in kleinere stappen.

### Stappen

0. **Meet de prefices tegen elkaar** voordat je iets uitprobeert. Hoeveel bestanden,
   hoe groot zijn de registerbestanden, welke mappen verschillen.
1. **Controleer de premisse.** Draai de productie-prefix en bevestig dat hij nog steeds
   crasht, en draai de werkbare kopie en bevestig dat die werkt. Krijg je hier al geen
   reproduceerbare crash, dan heeft de rest van het werk geen zin.
2. **Vind een werkbare referentie.** Zonder de crashende prefix werkeloos te maken
   valt er niets af te leiden.
3. **Groepeer de verschillen** in logische groepen: native DLL's, API-sets, VB6/OCX,
   drivers, per tak van het register.
4. **Test per groep** in de werkende kopie. Werkt de prefix nog? Dan is die groep
   onschuldig.
5. **Verfijn** de schuldige groep tot één bestand, sleutel of instelling.
6. **Schrijf de bevinding weg** (zie *Vastleggen* onderaan) vóór de referentie
   verdwijnt.

## Gereedschap in `ColinMcRae4/`

Alles draait op prefixen in `diag-pfx` (referentie, onaangeroerd) en `diag-work`
(per ronde schoon opgebouwd met `rsync -a --delete`). De productie-prefix wordt pas
aangeraakt als de oplossing bewezen is.

| bestand | doet |
|---|---|
| `bisect.sh <bestandslijst> [label]` | verwijdert een lijst bestanden uit `diag-work` en draait |
| `ref-files.txt` | de bestandslijst van de werkbare referentie |
| `regmix.py <uitmap> [--take/--keep/--drop PREFIX]` | bouwt een hybride registerbestand |
| `g6_registry.sh` | ronde 3: is het overgebleven verschil in het register? |
| `g7_regkeys.sh` | de tak-zoeker; de scenario's staan in de `SCEN`-array |

`regmix.py` neemt het register van de productie-prefix als basis en zet er voor
opgegeven takken de versie uit de werkbare referentie eronderin. `keep` wint van
`take`, `drop` verwijdert een tak helemaal. Met lege argumenten is de uitvoer
byte-identiek aan de productie-prefix — controleer dat altijd eerst, anders meet je
de verkeerde drempel.

De bron in `movedprefixes/` wordt **altijd alleen gelezen**. Elk script telt de
bestanden in de bron voor en na de run en meldt of dat aantal onveranderd is.

## Valkuilen

Deze kostten allemaal tijd in de CMR4-sessie. Ze gelden voor elk spel.

**1. Filter timestamps uit registervergelijkingen.** Een `.reg`-sleutelregel is
`[sleutel] timestamp` en elke sleutel heeft een `#time=`. Meet je die mee, dan lijkt
*bijna elke* sleutel te verschillen: 13.332 verschillen in `system.reg` in plaats van
de werkelijke 3.831. Dat leidt naar verkeerde kandidaten.

**2. Vergelijk het fault-adres, niet alleen "er was een crash".** `grep -c 'Unhandled
page fault'` is een ruwe detector. Twee totaal verschillende bugs kunnen allebei een
page fault geven. Leg de crash vast als adres (`at address 0052435A`) en vergelijk dát.
Anders valideer je stilletjes een andere bug dan die je onderzocht — of, erger, een
regressie die je ten onrechte als succes leest.

**3. Aftrekken heeft een blinde vlek.** "Tak X wegzetten werkt niet" bewijst niet dat
X onschuldig is, als de oorzaak een **combinatie** van meerdere takken is. Draai daarom
daarna de **leave-one-in**-variant: zet de hele prefix terug op de werkbare referentie,
behalve één tak. Als dát crasht, is die ene tak schuldig. In CMR4 bleek precies dát de
variant die het antwoord opleverde.

**4. Let op hoofdletterongevoeligheid.** Een Windows-register is
hoofdletterongevoelig, dus `Software\CODEMASTERS\X` en `Software\Codemasters\X` zijn
dezelfde sleutel. In een `.reg`-bestand kunnen beide spellingen naast elkaar staan;
Wine merge-t ze bij het laden. Dat maakt het onduidelijk welke waarden gelden — ruim
de oude variant op in plaats van hem te laten staan. Let hier ook op bij je
`grep`-pats: zonder `(?i)` of een juiste escaping matcht een patroon maar één spelling.

**5. Gok niet op herkenning.** In CMR4 bleken drie aannames aantrekkelijk en alle drie
onjuist: 19 `DllOverrides` (er waren er nul), `VideoMemorySize=256` (onge schuldig, maar
de sleutel waarschijnlijk wel de oorzaak in), en het restant zelf (onge schuldig). De
echte oorzaak stond in een sleutel met 12.633 buren. Test hypothesen, vertrouw ze niet.

**6. Houd de prefix self-consistent.** De werkbare referentie en een vers aangemaakte
prefix hebben niet dezelfde `dosdevices`-letters. Meng je het register van de ene met
de bestanden van de andere, dan meet je een mismatch die in de werkelijkheid nooit
bestaat.

## Vastleggen

Het belangrijkste: **schrijf de oplossing op voordat `movedprefixes/` weg is.** De
bevinding van CMR4 is precies zo'n geval — zonder dit document zou een volgende sessie
opnieuw dezelfde halve dag nodig hebben om te ontdekken dat een verse CMR4-prefix
crasht. Noteer per spel: symptoom, oorzaak, fix, terugrolmogelijkheid, en wat níét de
oorzaak bleek.

Niet vooruitlopen op een prefix die je alleen in `movedprefixes/` hebt staan. Als een
spel een prefix nodig heeft die blijft bestaan, maak die dan aan in de home-map van de
gebruiker.

## Recept: verse prefix in de home-map

Voor een prefix die blijft bestaan kun je niet meer op `movedprefixes/` leunen. Maak
hem aan in de home-map van de gebruiker en **verifieer** hem daarna tegen een
referentie-prefix zolang die er nog is.

Let daarbij op het CMR4-probleem: sommige spellen starten niet op een lege prefix,
omdat ze een eigen registersleutel met installatiepaden nodig hebben en die niet zelf
kunnen aanmaken. Controleer dit per spel: een verse prefix die meteen crasht op een
NULL-dereference is doorgaans een ontbrekende spellingsconfiguratie, geen Wine-probleem.