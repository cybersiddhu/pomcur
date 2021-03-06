package PomCur::CursDB::Annotation;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use namespace::autoclean;
extends 'DBIx::Class::Core';


=head1 NAME

PomCur::CursDB::Annotation

=cut

__PACKAGE__->table("annotation");

=head1 ACCESSORS

=head2 annotation_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 status

  data_type: 'text'
  is_nullable: 0

=head2 pub

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 type

  data_type: 'text'
  is_nullable: 0

=head2 creation_date

  data_type: 'text'
  is_nullable: 0

=head2 data

  data_type: 'text'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "annotation_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "status",
  { data_type => "text", is_nullable => 0 },
  "pub",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "type",
  { data_type => "text", is_nullable => 0 },
  "creation_date",
  { data_type => "text", is_nullable => 0 },
  "data",
  { data_type => "text", is_nullable => 0 },
);
__PACKAGE__->set_primary_key("annotation_id");
__PACKAGE__->add_unique_constraint(
  "annotation_id_status_type_unique",
  ["annotation_id", "status", "type"],
);

=head1 RELATIONS

=head2 pub

Type: belongs_to

Related object: L<PomCur::CursDB::Pub>

=cut

__PACKAGE__->belongs_to(
  "pub",
  "PomCur::CursDB::Pub",
  { pub_id => "pub" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

=head2 gene_annotations

Type: has_many

Related object: L<PomCur::CursDB::GeneAnnotation>

=cut

__PACKAGE__->has_many(
  "gene_annotations",
  "PomCur::CursDB::GeneAnnotation",
  { "foreign.annotation" => "self.annotation_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2010-11-09 12:57:29
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:BszWB0et69SXmY8/9jfsWg

__PACKAGE__->many_to_many('genes' => 'gene_annotations', 'gene');

use YAML;

__PACKAGE__->inflate_column('data', {
  inflate => sub { my @res = Load(shift); $res[0] },
  deflate => sub { Dump(shift) },
});


# You can replace this text with custom content, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
