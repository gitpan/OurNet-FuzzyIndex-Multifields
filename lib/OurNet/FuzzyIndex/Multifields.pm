package OurNet::FuzzyIndex::Multifields;

use strict;
use warnings;

our $VERSION = '0.02';

#use Data::Dumper;

use DB_File;
use Storable;
use FreezeThaw qw(freeze thaw);
use Exporter::Lite;
use OurNet::FuzzyIndex;
our @EXPORT = qw($MATCH_FUZZY $MATCH_EXACT $MATCH_PART $MATCH_NOT);


=pod

=head1 NAME

OurNet::FuzzyIndex::Multifields - Multifield indexing extension to
OurNet::FuzzyIndex

=head1 DESCRIPTION

B<OurNet::FuzzyIndex::Multifields> adds extended features to
L<OurNet::FuzzyIndex> by indexing multifield documents. The basic
usage is much like that of L<OurNet::FuzzyIndex>. Please refer to it.

A simple linear combination of multifields' scores is used as the
scoring function of query result.


=head1 USAGE

 use OurNet::FuzzyIndex::Multifields;

=head2 Initiate indexer

 my $inx = OurNet::FuzzyIndex::Multifields->new(
					       inxdir => './index',
					       fields => [qw(title fulltext)],
					       weight => [qw(3 1)],

					       # refer to OurNet::FuzzyIndex
					       # for the following options.
					       pagesize => undef,
					       cache => undef,
					       subdbs => 3,
					      );

=cut

use fields qw(
	      inxdir fields weight mainfield inxdb cache use_cache
	      );
sub new {
    my $class = shift;
    my %arg = @_;
    mkdir $arg{inxdir};
    my %inxdb;
    foreach my $f (@{$arg{fields}}){
	$inxdb{$f} = OurNet::FuzzyIndex->new(
					     "$arg{inxdir}/$f.inx",
					     $arg{pagesize},
					     $arg{cache},
					     $arg{subdbs},
					     );
    }
    my %cache;
    if($arg{use_cache}){
	mkdir "$arg{inxdir}/cache";
	foreach my $f (@{$arg{fields}}){
	    $cache{$f} = {1,1};
	    tie
		%{$cache{$f}}, 'DB_File',
		"$arg{inxdir}/cache/$f", O_CREAT | O_RDWR, 0644, $DB_BTREE
		or die "Cannot create cache file <$f>: $!";
	}
    }


    bless {
	inxdir => $arg{inxdir},
	fields => $arg{fields},
	weight => { map{ $arg{fields}->[$_] => ($arg{weight}->[$_] || 1)} 0..$#{$arg{weight}} },
	mainfield => $arg{fields}->[0],
	inxdb => \%inxdb,
	cache => \%cache,
	use_cache => $arg{use_cache},
    }, $class;
}

sub parse { $_[0]->{inxdb}->{$_[0]->{mainfield}}->parse(@_) }
sub parse_xs { $_[0]->{inxdb}->{$_[0]->{mainfield}}->parse_xs(@_) }



=head2 Insert documents

 $inx->insert(
	     0, # document key
	     title => 'This is the title',
	     fulltext => 'This is the full text',
	    );

 # Parse the content with different weights
 %words = $inx->parse_xs('This is another title', 5);
 $inx->insert(
	     1,
	     title => \%words,
	     fulltext => 'This is another page',
	    );

=cut

sub insert {
    my $self = shift;
    my $docid = shift;
    my %fields = @_;
    foreach my $f (keys %fields){
	$self->{inxdb}->{$f}->insert($docid, $fields{$f});
    }
}


=head2  Perform a query

 %result = $inx->query(
    'search for some text in title',
    [qw(title)], # search title only
    $MATCH_FUZZY,
    );

 # Perform another query
 %result = $inx->query(
    'search for some text',
    '*',  # for all fields, or you can set it to undef
  );


If you need to cache query results, you can set the option
B<use_cache> to 1 with the constructor like

 my $inx = OurNet::FuzzyIndex::Multifields->new(
					       inxdir => './index',
					       fields => [qw(title fulltext)],
					       weight => [qw(3 1)],
					       subdbs => 3,
					       use_cache => 1,
					      );

=cut

sub query {
    my $self = shift;
    my $query = shift;
    my $fields = shift || '*';
    my $flag = shift;
    my $result = shift;
    my @subfields = $fields eq '*' ? @{$self->{fields}} : @$fields;

    my %pfr; # per-field result
    my %score;

    no warnings;
    foreach my $f (@subfields){
#	print "<$f>\n";
	my $r = {};
	if( exists($self->{cache}{$f}{join qq/\x0/, $query, $flag}) ){
#	    print "....... Thawing ......\n";
	    ($r) = thaw( # must be in a list context here........ :-[
			$self->{cache}{$f}{join qq/\x0/, $query, $flag}
			);
	}
	if(!%$r){
	    %$r = $self->{inxdb}->{$f}->query($query, $flag);
	    if(!exists($self->{cache}{$f}{join qq/\x0/, $query, $flag})) {
		$self->{cache}{$f}{join qq/\x0/, $query, $flag} = freeze($r);
	    }
	}
	$pfr{$f} = $r;
	# keep record of retrieved index keys
	while(my($k, undef) = each %$r){
	    $score{$k} = undef;
	}
    }
    # combine the scores of all fields here.
    while(my($k, undef) = each %score){
	my $key = $self->{inxdb}->{$self->{mainfield}}->getkey($k);
	foreach my $f (@subfields){
	    next unless $pfr{$f}->{$k};
	    $score{$key} += $self->{weight}->{$f} * $pfr{$f}->{$k};
	}
	delete $score{$k};
    }
#    print Dumper \%pfr;
#    print Dumper \%score;
    %score;
}


=head2 REMOVE CACHE

 $inx->remove_cache();

It deletes the temporary result in the cache file.

=cut


sub remove_cache {
    my $self = shift;
    if($self->{use_cache}){
      foreach my $f (@{$self->{fields}}){
	%{$self->{cache}{$f}} = ();
      }
    }
}

sub DESTROY {
    my $self = shift;
    foreach my $d (values %{$self->{inxdb}}){
        $d->DESTROY;
    }
    foreach my $f (@{$self->{fields}}){
	untie %{$self->{cache}{$f}};
    }
    undef $self;
}


1;
__END__
# Below is stub documentation for your module. You'd better edit it!


=head1 SEE ALSO

L<OurNet::FuzzyIndex>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Yung-chung Lin (a.k.a. xern) E<lt>xern@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself

=cut
