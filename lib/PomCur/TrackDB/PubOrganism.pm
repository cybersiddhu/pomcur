package PomCur::TrackDB::PubOrganism;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use namespace::autoclean;
extends 'DBIx::Class::Core';


=head1 NAME

PomCur::TrackDB::PubOrganism

=cut

__PACKAGE__->table("pub_organism");

=head1 ACCESSORS

=head2 pub_organism_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 pub

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 organism

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "pub_organism_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "pub",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "organism",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);
__PACKAGE__->set_primary_key("pub_organism_id");

=head1 RELATIONS

=head2 organism

Type: belongs_to

Related object: L<PomCur::TrackDB::Organism>

=cut

__PACKAGE__->belongs_to(
  "organism",
  "PomCur::TrackDB::Organism",
  { organism_id => "organism" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 pub

Type: belongs_to

Related object: L<PomCur::TrackDB::Pub>

=cut

__PACKAGE__->belongs_to(
  "pub",
  "PomCur::TrackDB::Pub",
  { pub_id => "pub" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2010-09-30 16:18:16
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:gpFpuGrWtPVPEEKC1gKkow


# You can replace this text with custom content, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
