use strict;
use warnings;
use Test::More tests => 6;

use PomCur::TestUtil;
use PomCur::Curs::Utils;

my $test_util = PomCur::TestUtil->new();
$test_util->init_test('curs_annotations_1');

my $config = $test_util->config();
my $schema = $test_util->track_schema();

my $curs_schema = PomCur::Curs::get_schema_for_key($config, 'aaaa0005');

my ($completed_count, $annotations_ref) =
  PomCur::Curs::Utils::get_annotation_table($config, $curs_schema);

my @annotations = @$annotations_ref;

is (@annotations, 2);

is ($annotations[0]->{gene_identifier}, 'SPCC1739.10');
is ($annotations[0]->{term_ontid}, 'GO:0055085');
is ($annotations[0]->{taxonid}, '4896');
like ($annotations[0]->{creation_date}, qr/\d+-\d+-\d+/);
is ($annotations[0]->{gene_synonyms_string}, '');
