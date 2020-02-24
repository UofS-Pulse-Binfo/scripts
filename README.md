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
An easy way to convert file formats by Vim. Make sure write permission is obtained before open a file with Vim.


### SQL
Use the same format as one-liners.

#### Breakdown of features per type.
```sql
SELECT cvt.name as type, count(*) as number 
FROM chado.feature base 
LEFT JOIN chado.cvterm cvt ON cvt.cvterm_id=base.type_id 
GROUP BY cvt.name;
```
This query returns a list of all types of features, as well as the number of records for each.

**This query can be altered to work on any chado table with a type_id by simply changing `feature` to the same of the table.**
