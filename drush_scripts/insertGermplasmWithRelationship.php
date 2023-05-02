<?php
/**
 * @file
 * A script to load a simple TSV file of germplasm.
 * It will create a new stock record based on the first 3 columns and
 * then create a relationship between the new stock record and an existing
 * stock record using the last two columns.
 *
 * USAGE:
 *  drush php-script insertGermplasmWithRelationship.php --script-path=/var/www/html/kpscripts/drush_scripts --input-file=/var/www/html/2.F2.Summer2020.LHM.tsv
 *
 * PARAMETERS:
 *  --input-file
 *   The full path and filename including extension.
 *
 * Expected Format:
 *  1. name: the stock.name of the new record to insert
 *  2. type_id: the cvterm.cvterm_id indicating the type of stock
 *  3. organism_id: the organism.organism_id indicating the species of stock
 *  4. relationship.type_id: the cvterm.cvterm_id indicating the type of relationship to insert
 *  5. parent name: the name of the parent.
 *
 * Assumptions:
 *   - the parent must exist.
 *   - the IDs must all exist.
 *   - if the new record already exists, it will be skipped not updated.
 *   - if the new record exists, no relationship will be added.
 *   - the parent and new record are of the same species / organism_id.
 *
 * Author: Lacey-Anne Sanderson
 * Date: 2023May2
 */

 // Parameters
//--------------------------
// --input-file
drush_print("\nValdiating paramters...");
$input_file = drush_get_option('input-file');
if (empty($input_file)) {
	return drush_set_error('MISSING_PARAM', 'The --input-file paramter is required.');
}
if (!file_exists($input_file)) {
	return drush_set_error('FILE_NOT_FOUND', 'The file specified by --input-file could not be found.');
}
drush_print("Input File: $input_file\n");

$transaction = db_transaction();

$IN = fopen($input_file, "r");
$header = fgetcsv($IN, 0, "\t");
while (($line = fgetcsv($IN, 0, "\t")) !== false) {

  $stock_id = NULL;
	$germ_name = trim($line[0]);
  $type_id = trim($line[1]);
  $organism_id = trim($line[2]);

	$germ_found = chado_query('
    SELECT stock_id
    FROM {stock}
    WHERE name=:name AND type_id=:type_id AND organism_id=:organism_id',
	 	[
      ':name' => $germ_name,
      ':type_id' => $type_id,
      ':organism_id' => $organism_id,
    ])->fetchField();
  if ($germ_found) {
    $stock_id = $germ_found;
    drush_log("$germ_name already exists, skipping...", 'warning');
  }
  else {
    $inserted_values = chado_insert_record(
      'stock',
  	 	[
        'uniquename' => 'GERM TEMP',
        'name' => $germ_name,
        'type_id' => $type_id,
        'organism_id' => $organism_id,
      ]
    );
    $stock_id = $inserted_values['stock_id'];

    $update = chado_update_record(
      'stock',
      $inserted_values,
      ['uniquename' => 'KP:GERM' . $stock_id]
    );

    $germ_found = chado_query('
    SELECT uniquename
    FROM {stock}
    WHERE name=:name AND type_id=:type_id AND organism_id=:organism_id',
	 	[
      ':name' => $germ_name,
      ':type_id' => $type_id,
      ':organism_id' => $organism_id,
    ])->fetchField();
    if ($germ_found) {
      drush_log("Inserted $germ_name (" . $germ_found . ")", 'ok');
    }
    else {
      drush_log("Failed to insert $germ_name", 'error');
    }
  }

  // NOW ADD RELATIONSHIP.
  $values = [
    'subject_id' => $stock_id,
    'type_id' => trim($line[3]),
    'object_id' => [
      'name' => trim($line[4]),
      'organism_id' => $organism_id,
    ],
  ];
  $rel_found = chado_select_record('stock_relationship', ['subject_id'], $values);
  if (is_array($rel_found) AND !empty($rel_found)) {
    drush_log("$germ_name => " . $line[4] . " already exists, skipping...", 'warning');
  }
  else {
    $inserted_rel = chado_insert_record('stock_relationship', $values);
    if (is_array($inserted_rel) AND isset($inserted_rel['stock_relationship_id'])) {
      drush_log("\tSuccessfully inserted relationship from $germ_name => " . $line[4], 'ok');
    }
    else {
      drush_log("\tUnable to insert relationship from $germ_name => " . $line[4], 'error');
    }
  }
}
