use warnings;
use strict;
use Data::Dumper;
# four parameters input required
# file1: gene name list
# file2: genes in gff3 format, in this case Lentil v2.0
# file3: medicago on lc2.0 file
# file4: soybean on lc2.0 file
# file5: output file name

my $file_in_name_list = $ARGV[0];

my $file_in_lc20 = $ARGV[1];

my $file_in_medicago = $ARGV[2];

my $file_in_soybean = $ARGV[3];

my $out_name = $ARGV[4];

##  part 1:
# read through file of gene name list, store in one HASH, but name(key) in hash will be unique, which may not what we want
# store all names in order in one array, for order reference, so we can print info of these genes in original order

open (my $IN_name_list,"<", $file_in_name_list) or die ("Could not open file: $file_in_name_list .\n");

my %genes_need_extracted;
my @genes_order_reference;

while (defined (my $line_name_list = <$IN_name_list>)){
  chomp($line_name_list);
	#print 'Gene name:'. $line_name_list;
  push (@genes_order_reference, $line_name_list);
  next if $line_name_list =~ /^#/;
  if (!(exists $genes_need_extracted{$line_name_list})){
    #print $line_name_list. "\n";
    $genes_need_extracted{ $line_name_list }{'key'} = $line_name_list;
		$genes_need_extracted{ $line_name_list }{'appears'}=1;
		$genes_need_extracted{ $line_name_list }{'found'}=0;
	}
  else{
    $genes_need_extracted{$line_name_list}{"appears"}++;
  }
}
close $IN_name_list;

#print Dumper \%genes_need_extracted;
foreach my $key (keys %genes_need_extracted){
	#print $key.";";
}

##  part 2:
# read through our gff3 files of whole genome genes
# check if keys of hash from step1 exist, if exist, store in a new hash using name as key too
open (my $IN_wanted,"<", $file_in_lc20) or die ("Could not open file: $file_in_lc20 \n");
open (my $OUT, ">", $out_name.'_summary.txt') or die("Could not open output file:".$out_name.'_summary.txt'."\n");
open (my $OUT_gff3, ">", $out_name.'_lc2.0.gff3') or die("Could not open output file:".$out_name.'_lc2.0.gff3'."\n");

my $flag_gene_need_record = 0;
my $gff3_gene_name;
my $gene_subpart_order=0;
while (defined (my $line_wanted = <$IN_wanted>)){
  chomp $line_wanted;
  next if $line_wanted =~ /^#/;
  my @line_wanted_exp = split(/\t/, $line_wanted);

  # update hash key once read to a gene line
  if ($line_wanted_exp[2] =~ /gene/){
    $flag_gene_need_record = 0;
    $line_wanted_exp[8] =~ qr/Name=(.+?);/;
		$gff3_gene_name = $1;
		chomp $gff3_gene_name;
    #print $gff3_gene_name . "\n";
    # check if gene name exist in list
    # we will deal with gene and gene parts (mRNA, CDS, exon ...) separately
    if (exists $genes_need_extracted{$gff3_gene_name}){
			#print $gff3_gene_name . "\n";
      $genes_need_extracted{$gff3_gene_name}{"found"}++;
      $genes_need_extracted{$gff3_gene_name}{"gene"}=$line_wanted;
      $flag_gene_need_record = 1;
      $gene_subpart_order=0;
    }
  }
  else{
    if ($flag_gene_need_record == 1){
      $gene_subpart_order++;
      $genes_need_extracted{$gff3_gene_name}{"gene_part"}{$gene_subpart_order}=$line_wanted;
    }
    else{
      next;
    }
  }
}
#print Dumper %genes_need_extracted;

# check generated array to see if all genes from step1 are stored properly
# its ok if one gene appears multiple times because name list we get may contain repeatative genes
# "found" time should always be one since no duplicated genes shoud be found in our gene file
foreach my $key (keys %genes_need_extracted){
  if ($genes_need_extracted{$key} >= 1){
    print "$key appears:\t",$genes_need_extracted{$key}{"appears"},"time(s), and found\t",$genes_need_extracted{$key}{"found"}," time(s).\n";
  }
}
# print total number of elements from array and hash for comparison
print 'Total number of lines(genes+header lines start with #) read from GeneList file is ',scalar(@genes_order_reference),"\n";
print "Total number of unique genes extracted from $file_in_lc20 is:\n",scalar(keys %genes_need_extracted),"\n";
close $IN_wanted;
# step 3
# print genes in order in two formats
# one in foramt of: ID  Chrom Start End Description
# anotehr in format of GFF3

open (my $OUT_medicago, ">", $out_name.'_medicago.gff3') or die("Could not open output file:".$out_name.'_medicago.gff3'."\n");
open (my $OUT_soybean, ">", $out_name.'_soybean.gff3') or die("Could not open output file:".$out_name.'_soybean.gff3'."\n");

my @medicago_orthologs;
my @soybean_orthologs;

for (my $i=0;$i<scalar(@genes_order_reference);$i++){
  if ($genes_order_reference[$i] =~ /^#/){
    print $OUT "\n\n\n",$genes_order_reference[$i],"\n";
    print $OUT "ID\tChrom\tStart\tEnd\tDescription\n";
    next;
  }
  if ($genes_need_extracted{$genes_order_reference[$i]}){
    my @l_exp = split(/\t/, $genes_need_extracted{$genes_order_reference[$i]}{"gene"});
    print $OUT $genes_order_reference[$i],"\t",$l_exp[0],"\t",$l_exp[3],"\t",$l_exp[4],"\t";
    $l_exp[8] =~ qr/Description="(.+?)"/;
    print $OUT $1,"\t";

    print $genes_order_reference[$i],"\t",$l_exp[0],"\t",$l_exp[3],"\t",$l_exp[4],"\n";

    # now get the medicago orthologous genes
    @medicago_orthologs = ();
    open (my $IN_medicago,"<", $file_in_medicago) or die ("Could not open file: $file_in_medicago \n");
    while (defined (my $line_med = <$IN_medicago>)){
      next if $line_med =~ /^#/;
    	chomp $line_med;
    	my @one_gene = split(/\t/,$line_med);
      if ( ($one_gene[0] =~ $l_exp[0])  && ($one_gene[2] =~ 'gene') ){
        if (($one_gene[3] > $l_exp[4]) or ($one_gene[4] < $l_exp[3])){
        }
        else{
          #print $OUT "\n",$one_gene[8];
          push (@medicago_orthologs, $one_gene[8]);
          print $OUT_medicago $line_med,"\n";
        }
      }
    }
    close $IN_medicago;
    if(!(@medicago_orthologs == 0)){
      my $med_ort_names = extract_name_convert_array_2string(\@medicago_orthologs);
      print $OUT $med_ort_names;
      print $med_ort_names,"\n";
    }
    print $OUT "\t";

    # now get the soybean orthologous genes
    @soybean_orthologs = ();
    open (my $IN_soybean,"<", $file_in_soybean) or die ("Could not open file: $file_in_soybean \n");
    while (defined (my $line_gm = <$IN_soybean>)){
      next if $line_gm =~ /^#/;
    	chomp $line_gm;
    	my @one_gene_gm = split(/\t/,$line_gm);
      if ( ($one_gene_gm[0] =~ $l_exp[0])  && ($one_gene_gm[2] =~ 'gene') ){
        if (($one_gene_gm[3] > $l_exp[4]) or ($one_gene_gm[4] < $l_exp[3])){
        }
        else{
          #print $OUT "\n",$one_gene_gm[8];
          push (@soybean_orthologs, $one_gene_gm[8]);
          print $OUT_soybean $line_gm,"\n";
        }
      }
    }
    close $IN_soybean;

    if(!(@soybean_orthologs == 0)){
      my $soy_ort_names = extract_name_convert_array_2string(\@soybean_orthologs);
      print $OUT $soy_ort_names;
      print $soy_ort_names,"\n";
    }

    print $OUT "\n";

    print $OUT_gff3 $genes_need_extracted{$genes_order_reference[$i]}{"gene"},"\n";
  }else{
    print "Warnning: $genes_order_reference[$i] does not exist in HASH!!!\n";
  }
}

close $OUT;
close $OUT_gff3;
close $OUT_medicago;
close $OUT_soybean;

sub extract_name_convert_array_2string{
  my @arr_attribute = @{ $_[0] };
  for (my $m=0;$m<scalar(@arr_attribute);$m++){
    $arr_attribute[$m] =~ /Name=(.+)$/;
    $arr_attribute[$m] = $1;
  }
  return join("; ", @arr_attribute);
}
