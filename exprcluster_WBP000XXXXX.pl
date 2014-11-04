#!/usr/bin/perl -w

use strict;
use Ace;

my $line;
my @tmp;

#-----------------for microarray, find all probes from citace-----------
print "Connecting to database...";
my $db = Ace->connect(-path => '/home/citace/citace',  -program => '/usr/local/bin/tace') || die print "Connection failure: ", Ace->error;
print "done\n";

my $query='QUERY FIND Microarray_results Microarray = Affymetrix_C.elegans_Genome_Array';
@tmp=$db->find($query);

print scalar @tmp, " Affymetrix (GPL200) Microarray_results objects found\n";

my %os=();
foreach (@tmp) {
    $os{$_}=1;
}


#------------ for CDS or Gene ID based clusters -----------------------------


#--------------find all Gene IDs from WormBase --------------------------------
my ($aliasid, $alias, $geneid);
my %GeneIDalias; 
my $totalGene = 0;
print "Create Alias-Gene ID corresponding table ...\n";

open (ALIAS, "/home/wen/dict/AliasGeneNames.txt") || die "cannot open $!\n";
while ($line=<ALIAS>) {
    chomp ($line);
    if ($line ne "") {
	($alias, $geneid) = split /\s/, $line;
	$GeneIDalias{$alias} = $geneid;
	$totalGene++;
    }
}
close (ALIAS);

open (ALIAS, "/home/wen/SPELL/TablesForSPELL/alias_to_systematic.txt") || die "cannot open $!\n";
while ($line=<ALIAS>) {
    chomp ($line);
    ($aliasid, $alias, $geneid) = split /\t/, $line;
    $GeneIDalias{$alias} = $geneid;
    $totalGene++;
}
close (ALIAS);

print "$totalGene gene alias found with WormBase ID.\n";


#------- parse expression cluster results --------------------

my $ref = "WBPaper000XXXXX";
open (OUT1, ">WBPaper000XXXXXExprCluster.ace") || die "cannot open $!\n"; #data for CitaceMinus
print OUT1 "\n";

#Print Expression_cluster based on Affy ID, data are not entered to Microarray_experiment objects. 
#If data need to be entered to Microarray_experiment objects, see the parsing script for WBPaper00034757.  

my $c = 0; #total number of input files.
my @inputFile = ("TableS.csv"); 
my ($Cluster, $ClusDes, $fc, $p);
my @stuff;

while ($c < 1) {
    open (IN2, "$inputFile[$c]") || die "cannot open $!\n";
    while ($line = <IN2>) {
	chomp($line);
	if ($line =~ /Cluster/) {
	    ($stuff[0], $Cluster, $ClusDes) = split /:/, $line;	
	    print OUT1 "\nExpression_cluster : \"$ref:$Cluster\"\n";
	    print OUT1 "Reference\t\"$ref\"\n";
	    print OUT1 "Description\t\"$ClusDes\"\n";
	    print OUT1 "Algorithm\t\"\"\n";  
	    print OUT1 "Species\t\"Caenorhabditis elegans\"\n";
	    print OUT1 "Life_stage\t\"\" \/\/\n";
	    #print OUT1 "GO_term\t\"\" \/\/\n";
	    #print OUT1 "Anatomy_term\t\"\" \/\/\n";
	    #print OUT1 "WBProcess\t\"\" \/\/\n";	    
	    print OUT1 "Regulated_by_gene\t\"\" \/\/\n";
	    #print OUT1 "Regulated_by_treatment\t\"Bacteria: \"\n";
	    print OUT1 "Regulated_by_molecule\t\"\" \/\/\n";
	    print OUT1 "Based_on_WB_Release\n";
	    print OUT1 "Microarray_experiment\n";
	    print OUT1 "Tiling_array\n";
	    print OUT1 "RNASeq\n";
	    print OUT1 "Mass_spectrometry\n";


	} elsif ($line ne "") {


#for clusters based on probes

	    if ($os{$line}) {
		print OUT1 "Microarray_results\t\"$line\"\n";
	    } else {
		print "Cannot find oligo set for $line.\n";
	    }   

#for clusters based on CDS or Gene ID (including tiling array or RNAseq analysis)
	    ($alias, $fc, $p) = split /\s/, $line;
	    if ($GeneIDalias{$alias}) {
		print OUT1 "Gene \"$GeneIDalias{$alias}\" \"Fold change: $fc, p_value: $p\"\n";
	    } else {
		print "Cannot find WormBase Gene ID for $alias.\n";
	    }   

	}
    }
    $c++;
    close (IN2);
}
#Done printing. 

close (OUT1); 
