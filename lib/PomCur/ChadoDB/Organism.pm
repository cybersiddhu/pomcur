package PomCur::ChadoDB::Organism;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use namespace::autoclean;
extends 'DBIx::Class::Core';


=head1 NAME

PomCur::ChadoDB::Organism

=head1 DESCRIPTION

The organismal taxonomic
classification. Note that phylogenies are represented using the
phylogeny module, and taxonomies can be represented using the cvterm
module or the phylogeny module.

=cut

__PACKAGE__->table("organism");

=head1 ACCESSORS

=head2 organism_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'organism_organism_id_seq'

=head2 abbreviation

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 genus

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 species

  data_type: 'varchar'
  is_nullable: 0
  size: 255

A type of organism is always
uniquely identified by genus and species. When mapping from the NCBI
taxonomy names.dmp file, this column must be used where it
is present, as the common_name column is not always unique (e.g. environmental
samples). If a particular strain or subspecies is to be represented,
this is appended onto the species name. Follows standard NCBI taxonomy
pattern.

=head2 common_name

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 comment

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "organism_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "organism_organism_id_seq",
  },
  "abbreviation",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "genus",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "species",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "common_name",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "comment",
  { data_type => "text", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("organism_id");
__PACKAGE__->add_unique_constraint("organism_c1", ["genus", "species"]);

=head1 RELATIONS

=head2 biomaterials

Type: has_many

Related object: L<PomCur::ChadoDB::Biomaterial>

=cut

__PACKAGE__->has_many(
  "biomaterials",
  "PomCur::ChadoDB::Biomaterial",
  { "foreign.taxon_id" => "self.organism_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 cell_lines

Type: has_many

Related object: L<PomCur::ChadoDB::CellLine>

=cut

__PACKAGE__->has_many(
  "cell_lines",
  "PomCur::ChadoDB::CellLine",
  { "foreign.organism_id" => "self.organism_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 features

Type: has_many

Related object: L<PomCur::ChadoDB::Feature>

=cut

__PACKAGE__->has_many(
  "features",
  "PomCur::ChadoDB::Feature",
  { "foreign.organism_id" => "self.organism_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 libraries

Type: has_many

Related object: L<PomCur::ChadoDB::Library>

=cut

__PACKAGE__->has_many(
  "libraries",
  "PomCur::ChadoDB::Library",
  { "foreign.organism_id" => "self.organism_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 organism_dbxrefs

Type: has_many

Related object: L<PomCur::ChadoDB::OrganismDbxref>

=cut

__PACKAGE__->has_many(
  "organism_dbxrefs",
  "PomCur::ChadoDB::OrganismDbxref",
  { "foreign.organism_id" => "self.organism_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 organismprops

Type: has_many

Related object: L<PomCur::ChadoDB::Organismprop>

=cut

__PACKAGE__->has_many(
  "organismprops",
  "PomCur::ChadoDB::Organismprop",
  { "foreign.organism_id" => "self.organism_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 phenotype_comparisons

Type: has_many

Related object: L<PomCur::ChadoDB::PhenotypeComparison>

=cut

__PACKAGE__->has_many(
  "phenotype_comparisons",
  "PomCur::ChadoDB::PhenotypeComparison",
  { "foreign.organism_id" => "self.organism_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 phylonode_organisms

Type: has_many

Related object: L<PomCur::ChadoDB::PhylonodeOrganism>

=cut

__PACKAGE__->has_many(
  "phylonode_organisms",
  "PomCur::ChadoDB::PhylonodeOrganism",
  { "foreign.organism_id" => "self.organism_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 stocks

Type: has_many

Related object: L<PomCur::ChadoDB::Stock>

=cut

__PACKAGE__->has_many(
  "stocks",
  "PomCur::ChadoDB::Stock",
  { "foreign.organism_id" => "self.organism_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07006 @ 2011-02-04 16:45:42
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:4dzj+KLlryFaAINRGZBSQw


# the genus and species, used when displaying organisms
sub full_name {
  my $self = shift;

  return $self->genus() . ' ' . $self->species();
}

__PACKAGE__->meta->make_immutable;
1;
