package pUtils;

use File::Find;

# replace string (case sensitive)
# args:
# $_[1] - string to be replaced
# $_[2] - string to be replaced by
# $_[3] - input string
#
# returns:
# $string - string after replacements
sub replace {
    my ($from, $to, $string) = @_;
    $string =~s/$from/$to/g;

    return $string;
}#replace

# generate a file
# args:
# $_[1] - file name (including its extension)
# $_[2] - data to be written
sub genFile {
    my ($name, $data) = @_;

    open(f, '>', $name) or die $!;
    print f $data;
    close(f);
}#genFile

# read file
# args:
# $_[1] - file name (including its path)
# 
# returns:
# $data - string containing read file data
sub readFile {
    my ($name) = @_;
    my $data = "";

    open(f, '<', $name) or die $!;
    while (<f>) {
        $data = "$data$_";
    }
    close(f);

    return $data;
}

# find file
# args:
# $_[1] - file name (including its extension)
# $_[2] - directory to search
#
# returns:
# @path - list of paths of found files (null if not found)
sub findFile {
    my ($file, $directory) = @_;
    my @path;

    find (
        sub {
            if (index($File::Find::name, $file) != -1) {
                push @path, $File::Find::name;
            }
        },
        $directory
    );
    
    return @path;
}

# split string into a list line by line (ignoring comments and whitespace lines)
# args:
# $_[1] - string to be converted into a list
# 
# returns:
# @list - list created from the input string
sub getList {
    my ($data) = @_;
    my @list;

    while ($data =~ /([^\n]+)\n?/g) {        
        if ($1 !~ /^\s*$/) {
            if ((index($1, "//") == -1) and (index($1, "#") == -1)) {
                push (@list, $1);
            }
        }
    }

    return @list;
}

1;