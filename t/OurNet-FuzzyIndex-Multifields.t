use Test::More tests => 5;
#use Test::More qw(no_plan);
BEGIN { use_ok('OurNet::FuzzyIndex::Multifields') };
use Data::Dumper;


my $inx = OurNet::FuzzyIndex::Multifields->new(
					       inxdir => './index',
					       fields => [qw(title fulltext)],
					       weight => [qw(3 1)],
					       subdbs => 3,
					      );
$inx->insert(
	     0,
	     title => 'This is the title',
	     fulltext => 'This is the full text',
	    );

%words = $inx->parse_xs('This is another title', 5);
$inx->insert(
	     1,
	     title => \%words,
	     fulltext => 'This is another page',
	    );


ok(
   %result = $inx->query(
			 'search for some text in title',
			 undef, # all fields
			 $MATCH_FUZZY,
			)
  );

is($result{0} => 4000);
ok(
   %result = $inx->query(
			 'search for some text',
			 '*',
			)
  );

is($result{0} => 1000);

