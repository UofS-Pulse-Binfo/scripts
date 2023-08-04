#!/usr/bin/env drush

/**
 * Lookup germplasm from a tab-delimited file to provide uniquename/accession.
 *
 * Parameters:
 *  --name-col = the column number containing the germplasm name (1st column = 1)
 *  --genus = the genus the germplasm belong to (i.e. Lens)
 *  --input-file = the name of the file containing the germplasm list
 *
 * Author: Lacey-Anne Sanderson
 * Date: 2022Jan5
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
drush_print("Input File: $input_file");
$output_file = $input_file . ".results.tsv";
drush_print("Output File: $output_file");

// --name-col
$param = drush_get_option('name-col');
if (empty($param)) {
	return drush_set_error('MISSING_PARAM', 'The --name-col paramter is required.');
}
if (!is_numeric($param) || $param < 1 || $param != round($param)) {
	return drush_set_error('BAD_INPUT', 'The --name-col should be a positive integer.');
}
else {
	// Columns are 0-indexed so do that here.
	$germ_name_col_no = $param - 1;
}
drush_print("Germplasm Name Column (0-indexed): $germ_name_col_no");

// --genus
$genus = drush_get_option('genus');
if (empty($genus)) {
	return drush_set_error('MISSING_PARAM', 'The --genus paramter is required.');
}
$organism_ids = chado_query('SELECT organism_id FROM {organism} WHERE genus = :genus',
	[':genus' => $genus])->fetchCol();
if (empty($organism_ids)) {
	return drush_set_error('INVALID_GENUS', "The genus you provided is not in the database.");
}

$IN = fopen($input_file, "r");
$OUT = fopen($output_file, "w");
if ($IN AND $OUT) {
	while (($line = fgetcsv($IN, 0, "\t")) !== false) {
		$germ_name = trim($line[$germ_name_col_no]);
		$germ_found = chado_query('SELECT uniquename FROM {stock} WHERE name=:name and organism_id IN (:org)',
	 		[':name' => $germ_name, ':org' => $organism_ids])->fetchCol();

		$code = 'NOT-FOUND';
		if (sizeof($germ_found) == 1) {
			$code = 'UNIQUE';
		}
		elseif (!empty($germ_found)) {
			$code = "DUPLICATED";
		}
		// If not found then try harder?
		else {
			$germ_found = chado_query('SELECT uniquename, name FROM {stock} WHERE name ~ :name and organism_id IN (:org)',
	 		  [':name' => '^' . $germ_name . '.{0,2}', ':org' => $organism_ids])->fetchCol();
			if (!empty($germ_found)) {
				$code = 'NOT FOUND BUT MIGHT BE: ' . print_r($germ_found, TRUE);
			}
		}

		// Compile Results.
		$result = $germ_found;
		array_unshift($result, $code);
		array_unshift($result, $germ_name);
		fputcsv($OUT, $result, "\t");
	}
	fclose($IN);
	fclose($OUT);
}
else {
	drush_set_error('CANNOT_OPEN_FILE', 'Unable to open the input or output files.');
}
