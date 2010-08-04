use strict;
use warnings;
use Test::More tests => 7;

use PomCur::TestUtil;
use PomCur::Track;
use PomCur::TrackDB;

my $test_util = PomCur::TestUtil->new();

$test_util->init_test();

my $config = $test_util->config();
my $schema = PomCur::TrackDB->new($config);

my @results = $schema->resultset('Curs')->search();

is(@results, 0);

my $key = 'abcd0123';

my $pub = $schema->find_with_type('Pub', { pubmedid => '19056896' });
my $person = $schema->find_with_type('Person',
                                     {
                                       networkaddress => 'val@sanger.ac.uk'
                                     });

my $curs = $schema->create_with_type('Curs',
                                     {
                                       pub => $pub,
                                       community_curator => $person,
                                       curs_key => $key,
                                     });


my $data_directory = $config->{data_directory};

my @existing_files = glob("$data_directory/*.sqlite3");

is(@existing_files, 1);
is($existing_files[0], "$data_directory/track.sqlite3");

PomCur::Track::create_curs_db($config, $curs);

@results = $schema->resultset('Curs')->search();

is(@results, 1);


my @files_after = sort glob("$data_directory/*.sqlite3");

is(@files_after, 2);
is($files_after[0], "$data_directory/curs_$key.sqlite3");
is($files_after[1], "$data_directory/track.sqlite3");
