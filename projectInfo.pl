#!/usr/bin/perl

use File::Basename;

use strict;


my $dependencies_hacks = {
   'core-icon' => {"core-icons"=>1},
   'core-iconset' => {"core-icon" => 1},
   'polymer' => {"core-component-page" => 1},
   'paper-docs' => {"paper-doc-viewer" => 1}
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

&dependencies($dhacks);

system "git checkout master > /dev/null 2>&1";




sub last_tag {
  my @tags = reverse(`git tag --sort=version:refname`);
  foreach (@tags){
   chomp;
   return $_ if m!^\d+\.\d+(\.\d{1,4})?$!
  }
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
  my $dhacks = shift;
  binmode STDOUT, ":utf8";
  use utf8;

  use JSON;

  if(-e "bower.json"){
    local $/; #Enable 'slurp' mode
    open my $fh, "<", "bower.json";
    my $json = <$fh>;
    close $fh;
    my $data = decode_json($json);
    # Output to screen one of the values read

    foreach ( keys %{$data->{dependencies}}){
      print $_, "\n" unless $dhacks && $dhacks->{$_};
    }

  }else{
    my @htmls = <"*.html">;
    foreach my $html (@htmls){
          open my $fh, "<", $html;
            while(<$fh>){
              chomp;
              if(m!<link rel="import" href="\.\./([^/]+)/.*!){
                my $d = $1;
                print $d, "\n" unless $dhacks && $dhacks->{$d};
              }
            }
          close $fh;
       }
     }

  }
