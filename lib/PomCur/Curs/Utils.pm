package PomCur::Curs::Utils;

=head1 NAME

PomCur::Curs::Utils - Utilities for Curs code

=head1 SYNOPSIS

=head1 AUTHOR

Kim Rutherford C<< <kmr44@cam.ac.uk> >>

=head1 BUGS

Please report any bugs or feature requests to C<kmr44@cam.ac.uk>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc PomCur::Curs::Utils

=over 4

=back

=head1 COPYRIGHT & LICENSE

Copyright 2009 Kim Rutherford, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 FUNCTIONS

=cut

use strict;
use warnings;
use Carp;
use Moose;

=head2 get_annotation_table

 Usage   : my @annotations =
             PomCur::Curs::Utils::get_annotation_table($config, $schema);
 Function: Return a table of the current annotations
 Args    : $config - the PomCur::Config object
           $schema - a PomCur::CursDB object
 Returns : ($completed_count, $table)
           where:
             $completed_count - a count of the annotations that are incomplete
                because they need an evidence code or a with field, etc.
             $table - an array of hashes containing the annotation in the form:
           [ { gene_identifier => 'SPCC1739.11c', gene_name => 'cdc11',
               annotation_type => 'molecular_function',
               annotation_id => 1234, term_ontid => 'GO:0055085',
               term_name => 'transmembrane transport',
               evidence_code => 'IDA',
               evidence_type_name => 'Inferred from direct assay' },
             { gene_identifier => '...', ... }, ]
           where annotation_id is the id of the Annotation object for this
           annotation

=cut
sub get_annotation_table
{
  my $config = shift;
  my $schema = shift;

  my @annotations = ();

  my $gene_rs = $schema->resultset('Gene');

  my %evidence_types = %{$config->{evidence_types}};
  my %annotation_types_config = %{$config->{annotation_types}};

  my $go_lookup = PomCur::Track::get_lookup($config, 'go');
  my $gene_lookup = PomCur::Track::get_lookup($config, 'gene');

  my $completed_count = 0;

  while (defined (my $gene = $gene_rs->next())) {
    my $an_rs = $gene->annotations();

    my $gene_lookup_results =
      $gene_lookup->lookup([$gene->primary_identifier()]);
    my @found_results = @{$gene_lookup_results->{found}};
    if (@found_results != 1) {
      die "expected 1 result looking up: ", $gene->primary_identifier(),
        " but got ", scalar(@found_results);
    }
    my $gene_synonyms_string = join '|', @{$found_results[0]->{synonyms}};

    my %gene_annotations = ();

    while (defined (my $annotation = $an_rs->next())) {
      my $data = $annotation->data();
      my $term_ontid = $data->{term_ontid};
      next unless defined $term_ontid and length $term_ontid > 0;

      my $annotation_type = $annotation->type();
      my $annotation_type_config = $annotation_types_config{$annotation_type};
      my $annotation_type_display_name =
        $annotation_type_config->{display_name};
      my $annotation_type_abbreviation =
        $annotation_type_config->{abbreviation};

      my $pubmedid = $annotation->pub()->pubmedid();
      my $result =
        $go_lookup->web_service_lookup(ontology_name => $annotation_type,
                                       search_string => $term_ontid);

      my $term_name = $result->[0]->{name};
      my $evidence_code = $data->{evidence_code};
      my $with_gene_identifier = $data->{with_gene};

      my $evidence_type_name = $evidence_types{$evidence_code}->{name};
      my $needs_with = $evidence_types{$evidence_code}->{with_gene};

      my $with_gene;
      my $with_gene_display_name;

      if ($with_gene_identifier) {
        $with_gene = $schema->find_with_type('Gene',
                                             { primary_identifier =>
                                                 $with_gene_identifier });
        $with_gene_display_name = $with_gene->display_name()
      }

      (my $short_date = $annotation->creation_date()) =~ s/-//g;

      my $completed = defined $evidence_code &&
          (!$needs_with || defined $with_gene_identifier);

      $completed_count++ if $completed;

      push @{$gene_annotations{$annotation_type}}, {
        gene_identifier => $gene->primary_identifier(),
        gene_name => $gene->primary_name() || '',
        gene_name_or_identifier =>
          $gene->primary_name() || $gene->primary_identifier(),
        gene_product => $gene->product(),
        gene_synonyms_string => $gene_synonyms_string,
        qualifier => '',
        annotation_type => $annotation_type,
        annotation_type_display_name => $annotation_type_display_name,
        annotation_type_abbreviation => $annotation_type_abbreviation,
        annotation_id => $annotation->annotation_id(),
        pubmedid => $pubmedid,
        term_ontid => $term_ontid,
        term_name => $term_name,
        evidence_code => $evidence_code,
        evidence_type_name => $evidence_type_name,
        creation_date => $annotation->creation_date(),
        creation_date_short => $short_date,
        term_suggestion => $annotation->data()->{term_suggestion},
        needs_with => $needs_with,
        with_or_from_identifier => $with_gene_identifier,
        with_or_from_display_name => $with_gene_display_name,
        taxonid => $gene->organism()->taxonid(),
        completed => $completed,
      };
    }

    for my $annotation_type_config (@{$config->{annotation_type_list}}) {
      my $annotation_type_name = $annotation_type_config->{name};

      for my $annotation_data (@{$gene_annotations{$annotation_type_name}}) {
        push @annotations, $annotation_data;
      }
    }
  }

  return ($completed_count, [@annotations]);;
}

1;
