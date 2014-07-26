package Short::URL;
use strict;
use Mouse;
use List::Util qw//;
use Carp qw//;
#ABSTRACT: Encodes and Decodes short urls by using Bijection

has alphabet => (
    is => 'rw',
    isa => 'ArrayRef',
    default => sub {
        [qw/a b c d e f g h i j k l m n o p q r s t u v w x y z A B C D E F G H I J K L M N O P Q R S T U V W X Y Z 1 2 3 4 5 6 7 8 9/]
    },  
);

has shuffled_alphabet => (
    is => 'ro',
    isa => 'ArrayRef',
    default => sub {
        [qw/Q q F v j K L V g W S X P C I D B u z 6 i h w 4 H p 5 Z l b A r M E 1 a d c T R 9 7 x o t 3 J O 8 2 f U s N G Y n e m k y/]
    },  
);

has use_shuffled_alphabet => (
    is => 'rw',
    isa => 'Any',
    default => undef,
);

has offset => (
    is => 'rw',
    isa => 'Int',
    default => 0,
);

sub alphabet_in_use { 
    my ($self) = @_;
    return $self->use_shuffled_alphabet ? $self->shuffled_alphabet : $self->alphabet;
}

sub encode { 
    my ($self, $i) = @_; 

    $i += $self->offset;
    return $self->alphabet_in_use->[0] if $i == 0;

    my $s = ''; 
    my $base = @{$self->alphabet_in_use};

    while($i > 0) {
        $s .= $self->alphabet_in_use->[$i % $base];
        $i = int($i / $base);
    }   

    reverse $s; 
}

sub decode { 
	my ($self, $s) = @_;
	
	my $i = 0;
	my $base = @{$self->alphabet_in_use};
	my $last_index = $#{$self->alphabet_in_use};
	
	for my $char (split //, $s) { 
		my ($index) = grep { $self->alphabet_in_use->[$_] eq $char } 0..$last_index;
		Carp::croak "invalid character $char in $s" unless defined($index);
		
		$i = $i * $base + $index;
	}

	return $i - $self->offset;
}

1;

__END__ 

=head1 SYNOPSIS
 
    use Short::URL;
    
    #use default alphabet
    my $su = Short::URL->new;

    my $encoded = $su->encode(10000);
    my $short_url = "http://www.example.com/$encoded";

    print "Encoded: $encoded\n"; #prints cP6
    print "Short url: $short_url\n"; #prints http://www.example.com/cP6

    my $decoded = $su->decode('cP6');

    print "Decoded: $decoded\n"; #prints 10000

    #set new alphabet
    $su->alphabet([qw/1 2 3 a b c/]);

    #or when you create the Short::URL object
    my $su = Short::URL(alphabet => [qw/1 2 3 a b c/]);

    #have an 'offset'. Meaning if you pass in integer $i, you get unique string for $i + offset
    $su->offset(10000);

    #or
    my $su = Short::URL(offset => 10000);

    my $encoded_with_offset = $su->encode(0);

    print "Encoded with offset: $encoded_with_offset\n"; #prints unique string for 10000, 'cP6'

    my $decoded_with_offset = $su->decode('cP6');

    print "Decoded with offset: $decoded_with_offset\n"; #prints 0

    #use shuffled alphabet
    $su->use_shuffled_alphabet(1);

    #or
    my $su = Short::URL(use_shuffled_alphabet => 1);

    my $encoded_with_shuffled_alphabet = $su->encode(10000);

    print "Encoded with shuffled alphabet: $encoded_with_shuffled_alphabet"; #prints 'F7e'

    my $decoded_with_shuffled_alphabet = $su->decode(10000);

    print "Decoded with shuffled alphabet: $decoded_with_shuffled_alphabet"; #prints 10000
 
=head1 DESCRIPTION

Short::URL can be used to help generate short, unique character string urls. It uses L<Bijection/"http://en.wikipedia.org/wiki/Bijection"> to
create a one-to-one mapping from integers to strings in your alphabet, and from strings in your alphabet back to the original integer. An integer
primary key in your database would be a good example of an integer you could use to generate a unique character string that maps uniquely to that row.
 
=method alphabet
 
    $su->alphabet([qw/1 2 3 a b c/]);

The alphabet that will be used for creating strings when mapping an integer to a string. The default alphabet is:

   [qw/a b c d e f g h i j k l m n o p q r s t u v w x y z A B C D E F G H I J K L M N O P Q R S T U V W X Y Z 1 2 3 4 5 6 7 8 9/] 

All lower case letters, upper case letters, and digits 1-9.

=method encode

    my $encoded = $su->encode(1);

Takes an integer and encodes it into a unique string over your alphabet.

=method decode

    my $decoded = $su->decode('b');

Takes a string made from your alphabet and returns the corresponding integer that it maps to.

=method use_shuffled_alphabet

    $su->use_shuffled_alphabet(1);

    my $encoded_with_shuffled_alphabet = $su->encode(10000);

    print "Encoded with shuffled alphabet: $encoded_with_shuffled_alphabet"; #prints 'F7e'

Setting L</use_shuffled_alphabet> to 1 means that instead of using the more common alphabet stored in L</alphabet>, L<Short::URL> will use a shuffled alphabet.
Note, this shuffled alphabet will be the same every time, so encoding and decoding will work even in different sessions of using L<Short::URL>. This can be 
useful if for some reason you don't want people to know how many ids you have in your database. With the more standard alphabet it's clear when you are going
up by one between strings, and thus also how many ids you have. When used in combination with L</offset>, it is a lot harder to track what string would correspond
to what id in your databse, or how many ids you have in total. Below is the shuffled alphabet that is used:

    [qw/Q q F v j K L V g W S X P C I D B u z 6 i h w 4 H p 5 Z l b A r M E 1 a d c T R 9 7 x o t 3 J O 8 2 f U s N G Y n e m k y/]    

The default for L</use_shuffled_alphabet> is undef.

=head1 SEE ALSO

=over 4

=item

L<http://stackoverflow.com/a/742047/834140>

=item

L<https://gist.github.com/zumbojo/1073996>

=back
