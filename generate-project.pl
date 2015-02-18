#!/usr/bin/perl

use File::Basename;

use strict;

my $polymer_home = shift
  || die "Usage generate-project.pl path/to/polymer\n";

my $version = shift;

$version |= "0.5.4";

my $email = 'olivier.nouguier@gmail.com';

my $varProjectArtifactId = '${project.artifactId}';
my $varProjectVersion = '${project.version}';
my $varUpstreamVersion = '${upstream.version}';
my $varUpstreamUrl = '${upstream.url}';
my $varProjectBuildOutputDirectory = '${project.build.outputDirectory}';
my $varProjectBuildDirectory = '${project.build.directory}';
my $varDestDir = '${destDir}';



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
  <artifactId>webco</artifactId>
  <version>$version</version>
  <name>WebComponent Webjars</name>
  <description>WebJar for Polymer</description>
  <url>http://webjars.org</url>

  <properties>
    <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
    <upstream.version>$varProjectVersion</upstream.version>
    <upstream.url>https://github.com/Polymer/$varProjectArtifactId/archive/${varUpstreamVersion}.zip</upstream.url>
    <destDir>
      $varProjectBuildOutputDirectory/META-INF/resources/webjars/webco/$varUpstreamVersion/$varProjectVersion
    </destDir>
  </properties>


  <modules>
EOT


my @components = map { basename($_) } <$polymer_home."/components/*">;

#my @components = ("zozo");

foreach my $artifactId (@components) {
    print ROOT "    <module>$artifactId</module>\n";
    print "    <module>$artifactId</module>\n";
    unless(-d $artifactId){
        mkdir $artifactId;
        open POM, ">".$artifactId."/pom.xml";
        system "true > $artifactId/webjar";
        print POM <<"EOT";
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/maven-v4_0_0.xsd">
  <modelVersion>4.0.0</modelVersion>

  <parent>
    <groupId>org.webjars</groupId>
    <artifactId>webco</artifactId>
    <version>0.5.4</version>
  </parent>
  
  <packaging>jar</packaging>
  
  <groupId>org.webjars.webco</groupId>
  <artifactId>$artifactId</artifactId>
  <name>$artifactId</name>
  <description>WebJar for Polymer $artifactId</description>
      
  <dependencies>
    <dependency>
      <groupId>org.webjars.webco</groupId>
      <artifactId>polymer</artifactId>
      <version>0.5.4</version>
    </dependency>
  </dependencies>
      
</project>
EOT
       close(POM);
        
    }

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
                    <get src="${varUpstreamUrl}" dest="${varProjectBuildDirectory}/${varProjectArtifactId}.zip"/>
                    <echo message="unzip archive"/>
                    <unzip src="${varProjectBuildDirectory}/${varProjectArtifactId}.zip"
                           dest="${varProjectBuildDirectory}"/>
                    <echo message="moving resources"/>
                    <move todir="${varDestDir}">
                      <fileset dir="${varProjectBuildDirectory}/${varProjectArtifactId}-${varUpstreamVersion}"/>
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