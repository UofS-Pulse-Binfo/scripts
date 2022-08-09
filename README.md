# UofS Pulse Bioninformatics Scripts
Scripts and one-liners used by our group. Saved here so they are not forgotten...

## Table of Contents

 - [Scripts](#Scripts)
 - [One-Liners](#One-Liners)
 - [SQL](#SQL)
 
### Scripts
Every time you add a script to this repository please add it's name and a short description here. Each script should be in it's own directory with the following naming format `[Author initials]-[descriptive name]` and a `README.md` must be included in that directory. The `link to script below` should link to the `README.md`.

**Template:**
```
 - [Name](link to script): short description
```

### One-Liners
Every time you add a one-liner this template:

#### Short name of one-liner
```
command -opt file.boo
```
Longer description of what the one-liner does.

#### Use Vim to convert file format
```
:set fileformat=unix/dos/mac then :w
```
An easy way to convert file formats by Vim. Make sure writing permission is obtained before open a file with Vim.


### SQL
Use the same format as one-liners.

#### Search for Germplasm by name.
```sql
SELECT cvt.name as type, o.genus||' '||o.species as species, s.uniquename, s.name 
FROM chado.stock s 
LEFT JOIN chado.organism o ON o.organism_id=s.organism_id 
LEFT JOIN chado.cvterm cvt ON cvt.cvterm_id=s.type_id 
WHERE s.name~'Robin';
```
Lists all germplasm with the letters `Robin` included in the `stock.name` column. Additionally, this resolves the type and orgaqnism for easy reading.

#### Breakdown of features per type.
```sql
SELECT cvt.name as type, count(*) as number 
FROM chado.feature base 
LEFT JOIN chado.cvterm cvt ON cvt.cvterm_id=base.type_id 
GROUP BY cvt.name;
```
This query returns a list of all types of features, as well as the number of records for each.

**This query can be altered to work on any chado table with a type_id by simply changing `feature` to the same of the table.**

#### Lookup Terms
```sql
SELECT cv.cv_id, cv.name as cv_name,
  cvterm.cvterm_id, cvterm.name as cvterm_name,
  db.db_id, db.name as db_name,
  dbxref.dbxref_id, dbxref.accession,
  db.name||':'||dbxref.accession as term
FROM chado.cvterm
JOIN chado.cv ON cv.cv_id=cvterm.cv_id
JOIN chado.dbxref ON cvterm.dbxref_id=dbxref.dbxref_id
JOIN chado.db ON db.db_id=dbxref.db_id
WHERE cvterm.name = 'F1';
```
