use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'OurNet::FuzzyIndex::Multifields',
    VERSION_FROM      => 'lib/OurNet/FuzzyIndex/Multifields.pm',
    PREREQ_PM         => {
        'Exporter::Lite'     =>   '0.01',
	'OurNet::FuzzyIndex' =>   '1.60',
    },
    ($] >= 5.005 ?
      (ABSTRACT_FROM  => 'lib/OurNet/FuzzyIndex/Multifields.pm',
       AUTHOR         => 'Yung-chung Lin <xern@cpan.org>') : ()),
);
