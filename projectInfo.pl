#!/usr/bin/perl

use File::Basename;

use strict;


my $dependencies_hacks = {
   'core-icon' => {"core-icons"=>1},
   'core-iconset' => {"core-icon" => 1},
   'polymer' => {"core-component-page" => 1}
};

my $dir = shift
   || die "Usage projectInfo.pl path/to/project\n";
chdir $dir;

my $project = basename($dir);

my $dhacks;
if(exists $dependencies_hacks->{$project}){
  $dhacks= $dependencies_hacks->{$project};
}else{
  $dhacks = {};
}


my $lastTag = &last_tag();
print $lastTag, "\n";
print &github_account, "\n";

system "git branch -D $lastTag  > /dev/null 2>&1" unless $lastTag eq "master";
system "git checkout $lastTag -b $lastTag > /dev/null 2>&1";
my ($version, $deps) = &dependencies();
foreach ( keys %$deps){
   print $_, "\n" unless $dhacks && $dhacks->{$_};
}
system "git checkout master > /dev/null 2>&1";




sub last_tag {
  my @tags = reverse(`git tag --sort=version:refname`);
  foreach (@tags){
   chomp;
   return $_ if m!^v?\d+\.\d+(\.\d{1,4})?$!
  }
  return "master";
}

sub github_account {
   foreach (`git remote -v`){
       chomp;
       return $1 if m!\w+\s+ssh\://git\@github.com/([^/]+)/.*!;
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