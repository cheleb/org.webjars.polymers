#!/usr/bin/perl

use File::Basename;

use strict;

my $polymer_home = shift
  || die "Usage generate-project.pl path/to/polymer\n";

my $polymer_version = shift;

$polymer_version |= "0.5.4";

my $email = 'olivier.nouguier@gmail.com';

my $varProjectArtifactId = '${project.artifactId}';
my $varProjectVersion = '${project.version}';
my $varPolymerVersion = '${polymer.version}';
my $varUpstreamVersion = '${upstream.version}';
my $varUpstreamModule = '${upstream.module}';
my $varUpstreamVersionPrefix = '${upstream.version.prefix}';
my $varUpstreamGithub = '${upstream.github}';
my $varUpstreamUrl = '${upstream.url}';
my $varProjectBuildOutputDirectory = '${project.build.outputDirectory}';
my $varProjectBuildDirectory = '${project.build.directory}';
my $varDestDir = '${destDir}';
my $varBasedir = '${basedir}';



print "Importing projects from $polymer_home\n";

open ROOT, ">pom.xml";
print ROOT<<"EOT";
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/maven-v4_0_0.xsd">
  <modelVersion>4.0.0</modelVersion>

  <parent>
    <groupId>org.sonatype.oss</groupId>
    <artifactId>oss-parent</artifactId>
    <version>7</version>
  </parent>

  <packaging>pom</packaging>
  <groupId>org.webjars</groupId>
  <artifactId>polymers</artifactId>
  <version>$polymer_version</version>
  <name>WebComponent Webjars</name>
  <description>WebJar for Polymer</description>
  <url>http://webjars.org</url>

  <properties>
    <polymer.version>$polymer_version</polymer.version>
    <upstream.version>$varProjectVersion</upstream.version>
    <upstream.version.prefix />
    <upstream.module>${varProjectArtifactId}</upstream.module>
    <upstream.github>Polymer</upstream.github>
    <upstream.url>https://github.com/$varUpstreamGithub/$varUpstreamModule/archive/$varUpstreamVersionPrefix$varUpstreamVersion.zip</upstream.url>
    <destDir>
      $varProjectBuildOutputDirectory/META-INF/resources/webjars/polymers/$varPolymerVersion/$varProjectArtifactId
    </destDir>
    <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
  </properties>


  <modules>
EOT


my $upstream_modules = {
   firebase => 'firebase-bower'
};

my @components = <$polymer_home."/components/*">;

my $pinfos = {};

foreach my $project (@components) {
  my $artifactId = basename($project);
    open(INFO, "./projectInfo.pl $project|");

    my $lastTag = <INFO>;
    chomp($lastTag);
    $pinfos->{$artifactId}->{prefix} = "";
    if($lastTag eq "master"){
    }elsif($lastTag =~ m/^[a-zA-Z]+.*/){
       if($lastTag =~ m/^([a-zA-Z]+)(.*)$/){
        $pinfos->{$artifactId}->{prefix} = $1;
        $lastTag=$2;
       }
    }

    $pinfos->{$artifactId}->{version} = $lastTag;

    my $name = sprintf("%-40s [%s]", $artifactId, '${project.version}');
    $name =~ s/\s/./g;
    $pinfos->{$artifactId}->{name} = $name;

    my $github = <INFO>;
    chomp($github);

    $pinfos->{$artifactId}->{github} = $github;

    my @dependencies = <INFO>;

    $pinfos->{$artifactId}->{deps} = \@dependencies;

    close INFO;
}

foreach my $project (@components) {
    my $artifactId = basename($project);
    print ROOT "    <module>$artifactId</module>\n";

    my $github = $pinfos->{$artifactId}->{github};
    my $version = $pinfos->{$artifactId}->{version};
    my $name = $pinfos->{$artifactId}->{name};

    unless(-d $artifactId){
        mkdir $artifactId;
    }
    open POM, ">".$artifactId."/pom.xml";
    system "true > $artifactId/webjar";
    print POM <<"EOT";
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/maven-v4_0_0.xsd">
  <modelVersion>4.0.0</modelVersion>

  <parent>
    <groupId>org.webjars</groupId>
    <artifactId>polymers</artifactId>
    <version>$polymer_version</version>
  </parent>
  
  <packaging>jar</packaging>
  
  <groupId>org.webjars.polymers</groupId>
  <artifactId>$artifactId</artifactId>
  <version>$version</version>
  <name>$name</name>
  <description>WebJar for Polymer $artifactId</description>

  <properties>
    <upstream.github>$github</upstream.github>
EOT

   print POM  "    <upstream.version.prefix>", $pinfos->{$artifactId}->{prefix}, "</upstream.version.prefix>\n" if $pinfos->{$artifactId}->{prefix};
   print POM  "    <upstream.module>", $upstream_modules->{$artifactId}, "</upstream.module>" if exists $upstream_modules->{$artifactId};
   print POM<<"EOT";
  </properties>

  <dependencies>
EOT


$pinfos->{marked} = {
     'group' => 'org.webjars',
     'version' => '0.3.2'
  };
$pinfos->{highlightjs} = {
     'group' => 'org.webjars',
     'version' => '8.4'
  };
$pinfos->{jquery2} = {
   'group' => 'org.webjars',
   'artifact' => 'jquery',
   'version' => '2.1.3'
  };
$pinfos->{jquery} = {
   'group' => 'org.webjars',
   'version' => '2.1.3'
  };
$pinfos->{'core-field'} = {
     'artifact' => 'core-label'
  };
$pinfos->{'polymer-ajax'} = {
       'artifact' => 'core-ajax'
  };
$pinfos->{'polymer-jsonp'} = {
    artifact => 'core-shared-lib'
   };
$pinfos->{polymer} = {
    version => $polymer_version
   };


foreach my $dep (@{$pinfos->{$artifactId}->{deps}}){
 chomp($dep);
 my ($group, $version) = ("org.webjars.polymers", "0.5.5");

   $dep = $pinfos->{$dep}->{'artifact'} if exists $pinfos->{$dep}->{'artifact'};
   $group = $pinfos->{$dep}->{'group'} if exists $pinfos->{$dep}->{'group'};
   $version = $pinfos->{$dep}->{'version'} if exists $pinfos->{$dep}->{'version'};

  print POM<<"EOT";
    <dependency>
      <groupId>$group</groupId>
      <artifactId>$dep</artifactId>
      <version>$version</version>
    </dependency>
EOT
}
print POM<<"EOT";
  </dependencies>
</project>
EOT
   close(POM);


}

    print ROOT<<"EOT";
  </modules>

  <developers>
    <developer>
      <id>cheleb</id>
      <name>Olivier NOUGUIER</name>
      <email>$email</email>
    </developer>
  </developers>

  <licenses>
    <license>
      <name>BSD</name>
      <url>https://github.com/polymer/polymer/blob/master/LICENSE</url>
      <distribution>repo</distribution>
    </license>
  </licenses>
  <scm>
    <url>http://github.com/cheleb/webco-polymer</url>
    <connection>scm:git:https://github.com/cheleb/webco-polymer.git</connection>
    <developerConnection>scm:git:https://github.com/cheleb/webco-polymer.git</developerConnection>
    <tag>HEAD</tag>
  </scm>


  <profiles>
    <profile>
      <id>webjar</id>
      <activation>
        <file>
          <exists>webjar</exists>
        </file>
      </activation>

      <build>
        <plugins>
          <plugin>
            <groupId>org.apache.maven.plugins</groupId>
            <artifactId>maven-antrun-plugin</artifactId>
            <version>1.7</version>
            <executions>
              <execution>
                <phase>process-resources</phase>
                <goals>
                  <goal>run</goal>
                </goals>
                <configuration>
                  <target>
                    <echo message="download archive"/>
                    <get src="${varUpstreamUrl}" dest="${varBasedir}/${varProjectArtifactId}-${varUpstreamVersion}.zip" skipexisting="true"/>
                    <echo message="unzip archive"/>
                    <unzip src="${varBasedir}/${varProjectArtifactId}-${varUpstreamVersion}.zip"
                           dest="${varProjectBuildDirectory}"/>
                    <echo message="moving resources"/>
                    <move todir="${varDestDir}">
                      <fileset dir="${varProjectBuildDirectory}/${varUpstreamModule}-${varUpstreamVersion}"/>
                    </move>
                  </target>
                </configuration>
              </execution>
            </executions>
          </plugin>

          <plugin>
            <groupId>org.apache.maven.plugins</groupId>
            <artifactId>maven-release-plugin</artifactId>
            <version>2.5.1</version>
          </plugin>

          <plugin>
            <groupId>org.sonatype.plugins</groupId>
            <artifactId>nexus-staging-maven-plugin</artifactId>
            <version>1.6.5</version>
            <extensions>true</extensions>
            <configuration>
              <serverId>sonatype-nexus-staging</serverId>
              <nexusUrl>https://oss.sonatype.org/</nexusUrl>
              <autoReleaseAfterClose>true</autoReleaseAfterClose>
            </configuration>
          </plugin>
        </plugins>
      </build>
    </profile>
  </profiles>
</project>
EOT
