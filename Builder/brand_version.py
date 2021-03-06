#!/usr/bin/python3
import sys
import os
import time
import subprocess

template_file_prefix = 'brand.'

class Error(Exception):
    pass

def main( argv ):
    if len(argv) < 3:
        print( 'Usage: %s <version-info-file> <wc-path>' % argv[0] )
        return 1

    vi = VersionInfo( argv[2] )
    try:
        vi.parseVersionInfo( argv[1] )

        finder = FileFinder( vi )

        finder.findAndBrandFiles( argv[2] )

    except Error as e:
        print( 'Error: %s' % str(e) )
        return 1

    return 0

class FileFinder:
    def __init__( self, vi ):
        self.__vi = vi

    def findAndBrandFiles( self, path ):
        #print( 'findAndBrandFiles',path )
        all_files = os.listdir( path )

        for filename in all_files:
            #print( base )
            if( filename.startswith( template_file_prefix )
            and not filename.endswith( '~' )        # linux and mac edit file
            and not filename.split( '.' )[-1].startswith( '_' ) ):  # windows edit file
                self.__vi.brandOneFile( os.path.join( path, filename ) )

        for filename in all_files:
            full_path = os.path.join( path, filename )
            if( os.path.isdir( full_path )
            and not os.path.islink( full_path )
            and not full_path.endswith( '.git' )):
                self.findAndBrandFiles( full_path )

class VersionInfo:
    def __init__( self, wc_path ):
        self.__info = {}
        now = time.localtime( time.time() )
        self.__info['year'] = time.strftime( '%Y', now )
        self.__info['date'] = time.strftime( '%Y-%m-%d', now )
        self.__info['time'] = time.strftime( '%H:%M:%S', now )

        commit_id_file = os.path.join( wc_path, 'Builder/commit_id.txt' )
        if os.path.exists( commit_id_file ):
            with open( commit_id_file, 'r', encoding='utf-8' ) as f:
                result = f.read()
        else:
            result = subprocess.check_output( ['git', 'show-ref', '--head', '--hash', 'head'] )
            result = result.decode('utf-8')

        self.__info['commit'] = result.strip()

    def parseVersionInfo( self, filename ):
        f = open( filename, 'r', encoding='utf-8' )
        for line in f:
            line = line.strip()

            if line.startswith( '#' ):
                continue
            if line == '':
                continue

            key, value = line.split( ':', 1 )
            try:
                self.__info[ key.strip() ] = value.strip() % self.__info

            except (ValueError,TypeError,KeyError) as e:
                raise Error( 'Cannot format key %s with value "%s" because %s' % (key.strip(), value.strip(), str(e)) )

        f.close()

    def printInfo( self ):
        all_keys = self.__info.keys()
        all_keys.sort()
        for key in all_keys:
            print( 'Info: %10s: %s' % (key, self.__info[ key ]) )

    def brandOneFile( self, filename ):
        with open( filename, 'r', encoding='utf-8' ) as f:
            template_contents = f.readlines()

        try:
            branded_contents = []
            for line_no, line in enumerate( template_contents ):
                branded_contents.append( line % self.__info )

        except (ValueError, TypeError, KeyError) as e:
            raise Error( 'Cannot format %s:%d because %s' % (filename, line_no+1, str(e)) )

        parent_dir = os.path.dirname( filename )
        base = os.path.basename( filename )
        new_filename = os.path.join( parent_dir, base[len(template_file_prefix):] )
        print( 'Info: Creating', new_filename )

        with open( new_filename, 'w', encoding='utf-8' ) as f:
            f.writelines( branded_contents )

if __name__ == '__main__':
    sys.exit( main( sys.argv ) )
