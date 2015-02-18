#!/usr/bin/perl

my $dir = shift
   || die "Usage projectInfo.pl path/to/project\n";
chdir $dir;

print &last_tag, "\n";
print &github_account, "\n";

my ($version, $deps) = &dependencies();
foreach ( keys %$deps){
   print $_, "\n";
}


sub last_tag {
  my @tags = reverse(`git tag --sort=version:refname`);
  foreach (@tags){
   chomp;
   return $_ if m!^v?\d+\.\d+(\.\d+)?$!
  }
}

sub github_account {
   foreach (`git remote -v`){
       chomp;
       return $1 if m!\w+\s+ssh\://git\@github.com/(\w+)/.*!;
   }
}

sub dependencies {
binmode STDOUT, ":utf8";
use utf8;

use JSON;

my $json;
{
  local $/; #Enable 'slurp' mode
  open my $fh, "<", "bower.json";
  $json = <$fh>;
  close $fh;
}
return (undef, {}) unless $json;
my $data = decode_json($json);
# Output to screen one of the values read

return ($data->{version}, $data->{dependencies} )
}