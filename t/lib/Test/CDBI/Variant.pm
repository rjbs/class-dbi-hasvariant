
package Test::CDBI::Variant;
use base qw(Class::DBI);
__PACKAGE__->connection("dbi:SQLite:dbname=t/db/variants.db");

__PACKAGE__->add_relationship_type(
	has_variant => 'Class::DBI::Relationship::HasVariant'
);

use File::Copy qw(copy);
sub get_pristene_db {
	copy("./t/db/pristene.db", "./t/db/variants.db")
		or die "couldn't copy pristene db file: $!";
}
       
package Boolean::Stored;
use base qw(Test::CDBI::Variant);

__PACKAGE__->table("booleans");
__PACKAGE__->columns(All => qw(bid boolean));

__PACKAGE__->has_variant(
	boolean => undef,
	deflate => sub {
		return undef unless defined $_[0];
		return undef if ($_[0] and $_[0] == 0);
		return 1 if $_[0];
		return 0 unless $_[0];
	}
);

package Music::Album::Attribute;
use base qw(Test::CDBI::Variant);

Music::Album::Attribute->add_relationship_type(
	has_variant =>
	'Class::DBI::Relationship::HasVariant'
);

Music::Album::Attribute->table("albumattributes");

Music::Album::Attribute->columns(All => qw(albumattrid attribute attr_value));

Music::Album::Attribute->has_variant(
	attr_value => 'Music::Album::Attribute::Transformer',
	inflate => 'inflate',
	deflate => 'deflate'
);

package Music::Album::Attribute::Transformer;

sub inflate { shift;
	my ($value, $obj) = @_;

	if ($obj->attribute eq 'size') {
		return Music::Album::Edge->new({value => $value});
	} elsif ($obj->attribute eq 'area') {
		return Music::Album::Edge->new({value => ($value ** (1/2))});
	} elsif ($obj->attribute eq 'start_end') {
		my ($start,$end) = ($value =~ /^(\d+),(\d+)$/);
		return Music::Album::StartEnd->new({start => $start, end => $end});
	}
	return $value;
}

sub deflate { shift;
	my ($value, $obj) = @_;
	
	return $value unless ref $value;

	if ($obj->attribute eq 'size') {
		return $value->value;
	} elsif ($obj->attribute eq 'area') {
		return $value->value ** 2;
	} elsif ($obj->attribute eq 'start_end') {
		return join(',', ($value->start, $value->end));
	}
	return $value;
}

package Music::Album::Edge;
use base qw(Class::Accessor);
__PACKAGE__->mk_accessors(qw(value));

package Music::Album::StartEnd;
use base qw(Class::Accessor);
__PACKAGE__->mk_accessors(qw(start end));


1;
