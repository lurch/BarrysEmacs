import sys
import os
import time
import pysvn

template_file_prefix = 'brand.'

class Error(Exception):
    pass

def main( argv ):
    if len(argv) < 3:
        print 'Usage: %s <version-info-file> <wc-path>' % argv[0]
        return 1

    vi = VersionInfo()
    try:
        vi.setSvnVersion( argv[2] )
        vi.parseVersionInfo( argv[1] )

        finder = Finder( vi )
        finder.findAndBrandFiles( argv[2] )

    except Error, e:
        print 'Error: %s' % str(e)
        return 1

    return 0

class Finder:
    def __init__( self, vi ):
        self.__client = pysvn.Client()
        self.__vi = vi

    def findAndBrandFiles( self, path ):
        #print 'findAndBrandFiles:',path
        all_status = self.__client.status( path, recurse=False )
        for status in all_status:
            #print 'status:',status.text_status,'path:',status.path
            if status.text_status not in [pysvn.wc_status_kind.normal, pysvn.wc_status_kind.added, pysvn.wc_status_kind.modified]:
                continue

            if status.entry.kind == pysvn.node_kind.file:
                base = os.path.basename( status.path )
                #print base
                if base.startswith( template_file_prefix ):
                    self.__vi.brandOneFile( status.path )

        for status in all_status:
            #print 'status:',status.text_status,'path:',status.path
            if status.text_status not in [pysvn.wc_status_kind.normal, pysvn.wc_status_kind.added, pysvn.wc_status_kind.modified]:
                continue

            #print status.entry.kind
            if status.entry.kind == pysvn.node_kind.dir:
                base = os.path.basename( status.path )
                if base not in ['.'] and status.path != path:
                    self.findAndBrandFiles( status.path )
    

class VersionInfo:
    def __init__( self ):
        self.__info = {}
        now = time.localtime( time.time() )
        self.__info['year'] = time.strftime( '%Y', now )
        self.__info['date'] = time.strftime( '%Y-%m-%d', now )
        self.__info['time'] = time.strftime( '%H:%M:%S', now )

    def parseVersionInfo( self, filename ):
        f = file( filename )
        for line in f:
            line = line.strip()

            if line.startswith( '#' ):
                continue
            if line == '':
                continue

            key, value = line.split( ':', 1 )
            try:
                self.__info[ key.strip() ] = value.strip() % self.__info
            except (ValueError,TypeError,KeyError), e:
                raise Error( 'Cannot format key %s with value "%s" because %s' % (key.strip(), value.strip(), str(e)) )
        f.close()

    def setSvnVersion( self, wc_path ):
        cmd = 'svnversion -c "%s"' % (wc_path,)
        #print 'Info: Cmd %r' % (cmd,)
        pin, pout = os.popen2( cmd )

        output = pout.read()
        pout.close()
        pin.close()
        #print 'Info: Svn version %r' % (output,)

        version_string = output.strip().split(':')[-1]
        modifiers = ''
        while version_string[-1] not in '0123456789':
            modifiers += version_string[-1]
            version_string = version_string[:-1]

        if modifiers == '':
            self.__info[ 'build' ] = version_string
        else:
            self.__info[ 'build' ] = 0
        self.__info[ 'revision' ] = version_string
        self.__info[ 'wc_state' ] = modifiers

    def printInfo( self ):
        all_keys = self.__info.keys()
        all_keys.sort()
        for key in all_keys:
            print 'Info: %10s: %s' % (key, self.__info[ key ])

    def brandOneFile( self, filename ):
        f = file( filename )
        template_contents = f.readlines()
        f.close()

        try:
            branded_contents = []
            for line_no, line in enumerate( template_contents ):
                branded_contents.append( line % self.__info )
        except (ValueError,TypeError,KeyError), e:
            raise Error( 'Cannot format %s:%d because %s' % (filename, line_no+1, str(e)) )

        parent_dir = os.path.dirname( filename )
        base = os.path.basename( filename )
        new_filename = os.path.join( parent_dir, base[len(template_file_prefix):] )
        print 'Info: Creating',new_filename

        f = file( new_filename, 'w' )
        f.writelines( branded_contents )
        f.close()

if __name__ == '__main__':
    sys.exit( main( sys.argv ) )
