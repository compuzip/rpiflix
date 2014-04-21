#!/usr/bin/perl
#
# Load up pearson correlations for Netflix Prize ratings
# Adapted from code provide by Larry Freeman
# http://algorithmsanalyzed.blogspot.com/2008/07/bellkor-algorithm-pearson-correlation.html
#
use 5.10.0;

use strict;
use warnings;

use DBI;

use Data::Dumper;

my $dbh = DBI->connect("dbi:Pg:database=rpiflix_dev;host=localhost", 'postgres');

my $sthPearson = $dbh->prepare(q/insert into pearson (movie1, movie2, num, pearson) values (?, ?, ?, ?)/);

#use constant NUM_RECORDS => 4849661;
#use constant NUM_USERS => 375858;
#use constant NUM_MOVIES => 1000;

#my $moviesTable = 'smallmovies';
#my $customersTable = 'smallcustomers';
#my $ratingsTable = 'smallratings';

use constant NUM_RECORDS => 99072112;
use constant NUM_USERS => 480189;
use constant NUM_MOVIES => 17770;

my $moviesTable = 'movies';
my $customersTable = 'customers';
my $ratingsTable = 'ratings';

my @ratingByUser;
my @movieByUser;
my @ratingByMovie;
my @userByMovie;

my @userIndex;
my @userNextPlace;
my @movieIndex;
my @movieNextPlace;

my %userMap;
my %movieMap;
my $nextRelId = 0;
my $nextRelMovieId = 0;

{
    say "Loading up user mapping and indicies";

    $userIndex[NUM_USERS] = NUM_RECORDS;

    my $i = 0;

    my $sth = $dbh->prepare(qq/select customer, rating_count from $customersTable/);

    $sth->execute;

    while (my $r = $sth->fetchrow_arrayref) {
        my $relUserId = getRelUserId($r->[0]);

        $userIndex[$relUserId] = $i;
        $userNextPlace[$relUserId] = $i;

        $i += $r->[1];
    }
}

{
    say "Loading up movie mapping and indicies";

    $movieIndex[NUM_MOVIES] = NUM_RECORDS;

    my $i = 0;

    my $sth = $dbh->prepare(qq/select id, rating_count from $moviesTable/);

    $sth->execute;

    while (my $r = $sth->fetchrow_arrayref) {
        my $movieId = $r->[0];
        my $relMovieId = $r->[0] - 1;

        $movieIndex[$relMovieId] = $i;
        $movieNextPlace[$relMovieId] = $i;

        $i += $r->[1];
    }
}

{
    say "Grouping ratings by user/movie";

    my $sth = $dbh->prepare(qq/select customer, movie, rating from $ratingsTable/);

    $sth->execute;

    while (my $r = $sth->fetchrow_arrayref) {
        my $userId = $r->[0];
        my $relUserId = getRelUserId($userId);
        my $movieId = $r->[1];
        my $relMovieId = $r->[1] - 1;
        my $rating = $r->[2];

        $movieByUser[$userNextPlace[$relUserId]] = $movieId;
        $ratingByUser[$userNextPlace[$relUserId]] = $rating;
        $userNextPlace[$relUserId]++;

        $userByMovie[$movieNextPlace[$relMovieId]] = $userId;
        $ratingByMovie[$movieNextPlace[$relMovieId]] = $rating;
        $movieNextPlace[$relMovieId]++;
    }
}

{
    say "Populating intermediate values";

    my @values;

    # For each movie $i
    for (my $i = 0; $i < NUM_MOVIES - 1; $i++) {

        # For each other movie $j
        for (my $j = $i + 1; $j < NUM_MOVIES; $j++) {
            # For each rating of movie $i 0-4
            for my $k (0 .. 4) {
                # For each rating of movie $i 0-4
                for my $l (0 .. 4) {
                    $values[$j][$k][$l] = 0;
                }
            }
        }

#        print "[1] Working on $movieIndex[$i] - " . $movieIndex[$i + 1] . "\n";

        # Itereate all customers who rated movie $i
        for (my $j = $movieIndex[$i]; $j < $movieIndex[$i + 1]; $j++) {
#print "So my j is now $j\n";
            my $relUserId = getRelUserId($userByMovie[$j]);

#print "and my relUserId = $relUserId\n";

            # Iterate through all movies rated by customer $j
            for (my $k = $userIndex[$relUserId]; $k < $userIndex[$relUserId + 1]; $k++) {
#print "[2] Working on $userIndex[$relUserId] - " . $userIndex[$relUserId + 1] . ": $k\n";

                if ($movieByUser[$k] - 1 > $i) {
#print "Incrementing values[" . ($movieByUser[$k] - 1) . "][" . ($ratingByUser[$k] - 1) . "][" . ($ratingByMovie[$j] - 1) . "]" . "\n"; 
                    $values[$movieByUser[$k] - 1][$ratingByUser[$k] - 1][$ratingByMovie[$j] - 1]++;
                }
            }
        }

        calculatePearson($i, \@values);
    }
}


sub calculatePearson {
    my $i = shift;
    my $values = shift;

    say "Calculating pearson coefficients for movie $i";

    for (my $j = $i + 1; $j< NUM_MOVIES; $j++) {
        my $sum1 = 0;
        my $sum2 = 0;
        my $sumsq1 = 0;
        my $sumsq2 = 0;
        my $sumpr = 0;
        my $num = 0;

        for my $k (1 .. 5) {
            for my $l (1 .. 5) {
                # Number of people who rated movie $i as $k
                # as also rated movie $j as $l
                my $val = $values->[$j]->[$k-1]->[$l-1];

                $sum1 += $l * $val;
                $sum2 += $k * $val;
                $sumsq1 += $l * $l * $val;
                $sumsq2 += $k * $k * $val;
                $sumpr += $k * $l * $val;
                $num += $val;
            }
        }

# I don't think this happens anymore, but meh
#print "$sum1, $sum2, $sumsq1, $sumsq2, $sumpr, $num\n";
next if (! $num);

        my $top = $sumpr - (($sum1 * $sum2) / $num);

        # This can't hapen anymore... right?
        if (($sumsq1 - ($sum1 * $sum1) / $num) * ($sumsq2 - ($sum2 * $sum2) / $num) < 0) {
            print "Whoa there, $sumsq1 - ($sum1 * $sum1) / $num) * ($sumsq2 - ($sum2 * $sum2) / $num) < 0!\n";
            next;
        }

        if (my $bottom = sqrt(($sumsq1 - ($sum1 * $sum1) / $num) * ($sumsq2 - ($sum2 * $sum2) / $num))) {
            my $pearson = ($top / $bottom) * ($num / ($num + 10));
            $sthPearson->execute($i + 1, $j + 1, $num, $pearson);
            $sthPearson->execute($j + 1, $i + 1, $num, $pearson);
            #printf("%s,%s,%s,%s\n", $i + 1, $j + 1, $num, $pearson);
            #reverse
        } else {
            #printf("%s,%s,%s,0\n", $i + 1, $j + 1, $num);
            $sthPearson->execute($i + 1, $j + 1, $num, 0);
        }
    }
}

sub getRelUserId {
    my $userId = shift;

    if (! exists($userMap{$userId})) {
        $userMap{$userId} = $nextRelId;
        $nextRelId++;
    }

    return $userMap{$userId};
}
