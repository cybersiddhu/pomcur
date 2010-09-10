package PomCur::GOAnnotationLookup

=head1 NAME

PomCur::GOAnnotationSource - methods to retrieve information about the current
                             GO annotations

=head1 SYNOPSIS

=head1 AUTHOR

Kim Rutherford C<< <kmr44@cam.ac.uk> >>

=head1 BUGS

Please report any bugs or feature requests to C<kmr44@cam.ac.uk>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc PomCur::GOAnnotationLookup

=over 4

=back

=head1 COPYRIGHT & LICENSE

Copyright 2009 Kim Rutherford, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 FUNCTIONS

=cut

use Carp;
use Moose::Role;

with 'PomCur::Configurable';

=head2 annotation_of_genes

  Returns   : an array: [{ identifier => 'spc123', annotation => {}},
                         {

=cut
method annotation_of_genes(\@gene_identifiers, { options ... });

1;