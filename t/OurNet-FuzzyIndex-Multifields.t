use Test::More tests => 10;
#use Test::More qw(no_plan);
BEGIN { use_ok('OurNet::FuzzyIndex::Multifields') };
use Data::Dumper;


ok(
   my $inx = OurNet::FuzzyIndex::Multifields->new(
						  inxdir => './index',
						  fields => [qw(title fulltext)],
						  weight => [qw(3 1)],
						  subdbs => 3,
						  use_cache => 1,
						 ),
  'Initialization');
$inx->insert(
	     0,
	     title => 'This is the title',
	     fulltext => 'This is the full text',
	    );
ok(1, 'first insertion');

%words = $inx->parse_xs('This is another title', 5);
ok(1, 'parse_xs');
$inx->insert(
	     1,
	     title => \%words,
	     fulltext => 'This is another page',
	    );
ok(1, 'second insertion');

ok(
   %result = $inx->query(
			 'search for some text in title',
			 undef, # all fields
			 $MATCH_FUZZY,
			)
  );

is($result{0} => 4000, 'query');
ok(
   %result = $inx->query(
			 'search for some text',
			 '*',
			)
  );


ok(
   %result = $inx->query(
			 'search for some text',
			 '*',
			)
  );


is($result{0} => 1000, 'query');
