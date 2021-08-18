#!/usr/bin/perl -s

use v5.16;
use Test2::V0;
use List::Util qw(uniqnum uniq);
use Math::Prime::Util qw(fordivisors sqrtint lastfor is_power gcd);
use experimental qw(signatures postderef);

our ($tests, $examples);

run_tests() if $tests || $examples;	# does not return

die <<EOS unless @ARGV == 1;
usage: $0 [-examples] [-tests] [-verbose] [N]

-examples
    run the examples from the challenge
 
-tests
    run some tests

N
    Find all Pythagorean triples containing N

EOS


### Input and Output

map {say "(@$_)"} find_pythagorean_triples(pop @ARGV) or say -1;


### Implementation

# After I had submitted my solution, I looked through other
# contributions - especially Colin's blog - and realized that I had
# failed.  Euclid's formula generates all *primitive* Pythagorean
# triples and some more, but not all.  To get all triples, one has to
# consider multiples of primitive triples.

# According to Euclid's formula, all primitive Pythagorean triples
# x² + y² = z² having gcd(x, y, z) = 1 can be parametrized using
# u > v > 0:
# x = u² - v²
# y = 2uv
# z = u² + v².
# Such a triple is primitive if and only if u and v have no common
# divisor and not both are odd.
#
# There is a solution for every n > 2:
# (k + 1)² - k² = 2k + 1, therefore every odd number > 2 appears as x
# and on the other hand every even number > 2 appears as y.
#
# References:
# https://en.wikipedia.org/wiki/Pythagorean_triple
# https://de.wikipedia.org/wiki/Pythagoreisches_Tripel
# https://colincrain.com/2021/08/15/triple-tree-rings/


# Loop over three subs that find all valid parameters u and v
# reproducing a divisor of the given number as x, y or z and collect
# their results.
#
sub find_pythagorean_triples ($n) {
    my @pt;

    fordivisors {
        return if $_ == $n;
        my ($d, $k) = ($n / $_, $_);
        collect_triples($_, \@pt, $d, $k) for
            # $k-fold primitive triples with $x * $k = $n.
            sub ($x) {
                my @uv;
                # There is no v < u if u² - (u - 1)² > x or u² ≤ x.
                # Resolved to u:
                for my $u (sqrtint($x) + 1 .. ($x + 1) / 2) {
                    # The three-argument version of "is_power" checks if the
                    # given number is a perfect power and returns the
                    # integer root at the same time.  Incredibly handy.
                    next unless is_power($u**2 - $x, 2, \my $v);
                    push @uv, [$u, $v];
                }
                \@uv;
            },
            # $k-fold primitive triples with $y * $k = $n.
            sub ($y) {
                return [] if $y % 2;
                my @uv;
                fordivisors {
                    my ($u, $v) = ($y / (2 * $_), $_);
                    lastfor, return if $v >= $u;
                    push @uv, [$u, $v];
                } $y / 2;
                \@uv;
            },
            # $k-fold primitive triples with $z * $k = $n.
            sub ($z) {
                my @uv;
                # There is no u > v if (v + 1)² + v² > z.
                # Resolved to v:
                for my $v (1 .. (sqrtint(2 * $z - 1) - 1) / 2) {
                    next unless is_power($z - $v**2, 2, \my $u);
                    push @uv, [$u, $v];
                }
                \@uv;
            }
    } $n;

    @pt;
}

# Call a sub to find parametrizations of Pythagorean triples having d as
# x, y or z and restrict to primitive triples.  Primitive triples are
# generated by pairs (u, v) that have no common divisor and that are not
# both odd.  Collect the k-fold of these triples matching n in any
# position.
sub collect_triples ($code, $pt, $d, $k) {
    for my $uv ($code->($d)->@*) {
        my ($u, $v) = @$uv;
        next if $u % 2 + $v % 2 == 2 || gcd($u, $v) > 1;
        push @$pt,
            [$k * ($u**2 - $v**2), 2 * $k * $u * $v, $k * ($u**2 + $v**2)];
    }
}


### Examples and tests

sub run_tests {
    SKIP: {
        skip "examples" unless $examples;

        like [find_pythagorean_triples(5)],
            bag {item [5, 12, 13]; item [3, 4, 5]; end}, 'example 1';

        like [find_pythagorean_triples(13)],
            bag {item [13, 84, 85]; item [5, 12, 13]}, 'example 2';

        is [find_pythagorean_triples(1)], [], 'example 3'
    }

    SKIP: {
        skip "tests" unless $tests;

        like [find_pythagorean_triples(20)],
            bag {
                item [12, 16, 20];
                item [99, 20, 101];
                item [20, 48, 52];
                etc}, 'n in all positions';
        is [find_pythagorean_triples(2)], [],
            'the only other number without a solution';

        like [find_pythagorean_triples(7)],
            bag {item [7, 24, 25]; etc}, 'as x';
        like [find_pythagorean_triples(8)],
            bag {item [6, 8, 10]; item [15, 8, 17]; etc}, 'as y';
        like [find_pythagorean_triples(13)],
            bag {item [5, 12, 13]; etc}, 'as z'; 
        like scalar(find_pythagorean_triples(60)), 14,
            'Colin\'s example';
	}

    done_testing;
    exit;
}
