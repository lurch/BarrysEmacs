//
//    fio.c
//

#include    <emacs.h>


#undef THIS_FILE
static char THIS_FILE[] = __FILE__;
static EmacsInitialisation emacs_initialisation( __DATE__ " " __TIME__, THIS_FILE );

#include <em_stat.h>

#if defined( __WATCOMC__ ) || defined( __unix__ )
# include <unistd.h>
# define _S_IWRITE    S_IWRITE
#endif

#if defined( _MSDOS ) || defined( _NT ) || defined( _WINDOWS )
# include <io.h>
# include <share.h>
# if defined( __WATCOMC__ )
#  define SHARE_READ , SH_DENYWR
#  define SHARE_NONE , SH_DENYRW
# else
#  define SHARE_READ , _SH_DENYWR
#  define SHARE_NONE , _SH_DENYRW
# endif
# define fopen _fsopen
#endif

#ifndef SHARE_READ
# define SHARE_READ
# define SHARE_NONE
#endif


EmacsFile::EmacsFile( FIO_EOL_Attribute attr )
: m_full_file_name()
, m_file( NULL )
, m_attr( attr )
{ }

EmacsFile::~EmacsFile()
{
    if( m_file != NULL && m_file != stdin )
        fclose( m_file );
}

//
//    check that the file exists and has read or read and write
//    access allowed
//
int EmacsFile::fio_access( const EmacsString &filename )
{
    //  6 means read and write, 4 means read
    int r = access( filename.sdata(), 6 );
    if( r == 0 )
        return 1;

    r = access( filename.sdata(), 4 );
    if( r == 0 )
        return -1;

    return 0;
}

bool EmacsFile::fio_file_exists( const EmacsString &filename )
{
    int r = access( filename.sdata(), 0 );
    return r != -1;    // true if the file exists
}

int EmacsFile::fio_delete( const EmacsString &filename )
{
    EmacsString full_file_name;
    expand_and_default( filename, EmacsString::null, full_file_name );

    int r = unlink( full_file_name );

    return r;
}

bool EmacsFile::fio_create
    (
    const EmacsString &name,
    int PNOTUSED(size),
    FIO_CreateMode PNOTUSED(mode),
    const EmacsString &defnam,
    FIO_EOL_Attribute attr
    )
{
    expand_and_default( name, defnam, m_full_file_name );
    m_file = fopen( m_full_file_name, "w" BINARY_MODE SHARE_NONE );

    m_attr = attr;

    return m_file != NULL;
}

bool EmacsFile::fio_open
    (
    const EmacsString &name,
    int eof,
    const EmacsString &defnam,
    FIO_EOL_Attribute attr
    )
{
    expand_and_default( name, defnam, m_full_file_name );

    if( !file_is_regular( m_full_file_name ) )
        return false;

    if( eof )
    {
        // open for append
        m_file = fopen( m_full_file_name, "a" BINARY_MODE SHARE_NONE );
        m_attr = attr;
    }
    else
        // open for read
        m_file = fopen( m_full_file_name, "r" BINARY_MODE SHARE_READ );

    return m_file != NULL;
}

int EmacsFile::fio_get( unsigned char *buf, int len )
{
    int status = fread( buf, 1, len, m_file );
    if( ferror( m_file ) )
        return -1;
    if( status == 0 && feof( m_file ) )
        return 0;

    status = get_fixup_buffer( buf, status );

    return status;
}

int EmacsFile::fio_get_line( unsigned char *buf, int len )
{
    fgets( s_str(buf), len, m_file );
    if( ferror( m_file ) )
        return -1;
    if( feof( m_file ) )
        return 0;

    return get_fixup_buffer( buf, _str_len( buf ) );
}

int EmacsFile::fio_get_with_prompt( unsigned char *buf, int len, const unsigned char * /*prompt*/ )
{
    int status = fread( buf, 1, len, m_file );
    if( ferror( m_file ) )
        return -1;
    if( status == 0 && feof( m_file ) )
        return -1;
    return status;
}

int EmacsFile::fio_put( const unsigned char *buf , int len )
{
    int written_length = 0;
    switch( m_attr )
    {
    case FIO_EOL__StreamCR:
    {
        // find each LF and output the text followed by a CR
        const unsigned char *from = buf;
        const unsigned char *end = &buf[len];

        while( from < end )
        {
            const unsigned char *to = (const unsigned char *)memchr( from, '\n', end - from );
            if( to == NULL )
            {
                int status = fwrite( from, 1, end-from, m_file );
                if( ferror( m_file ) )
                    return -1;
                written_length += status;
                break;
            }

            int status = fwrite( from, 1, to-from, m_file );
            if( ferror( m_file ) )
                return -1;
            written_length += status;

            status = fwrite( "\r", 1, 1, m_file );
            if( ferror( m_file ) )
                return -1;
            written_length += status;
            from = &to[1];
        }
    }
        break;

    case FIO_EOL__StreamCRLF:
    {
        // find each LF and output the text followed by a cR/LF
        const unsigned char *from = buf;
        const unsigned char *end = &buf[len];

        while( from < end )
        {
            const unsigned char *to = (const unsigned char *)memchr( from, '\n', end - from );
            if( to == NULL )
            {
                int status = fwrite( from, 1, end-from, m_file );
                if( ferror( m_file ) )
                    return -1;
                written_length += status;
                break;
            }

            int status = fwrite( from, 1, to-from, m_file );
            if( ferror( m_file ) )
                return -1;
            written_length += status;

            status = fwrite( "\r\n", 1, 2, m_file );
            if( ferror( m_file ) )
                return -1;
            written_length += status;
            from = &to[1];
        }
    }
        break;


    case FIO_EOL__Binary:
        // simply output as is
    case FIO_EOL__StreamLF:
    {
        // simply output as is
        int status = fwrite( buf, 1, len, m_file );
        if( ferror( m_file ) )
            return -1;
        written_length += status;
    }
        break;

    default:
        // cannot happen
        emacs_assert(false);
    }

    return written_length;
}

int EmacsFile::fio_split_put
    (
    const unsigned char *buf1, int len1,
    const unsigned char *buf2, int len2
    )
{
    int status1 = fio_put( buf1, len1 );
    if( status1 < 0 )
        return -1;

    int status2 = fio_put( buf2, len2 );
    if( status2 < 0 )
        return -1;

    return status1 + status2;
}

bool EmacsFile::fio_close()
{
    int status = fclose( m_file );
    m_file = NULL;

    return status == 0;
}

void EmacsFile::fio_setpos( long int pos )
{
    int status = fseek( m_file, pos, SEEK_SET );
    if( status != 0 )
    {
        status = errno;
    }
}

long int EmacsFile::fio_getpos()
{
    return ftell( m_file );
}

long int EmacsFile::fio_size()
{
    long int cur_pos, end_of_file_pos;

    // find the current position
    cur_pos = ftell( m_file );

    // seek to the end of the file
    if( fseek( m_file, 0l, SEEK_END ) == 0 )
    {
        // the current position is the size of the file
        end_of_file_pos = ftell( m_file );
    }
    else
    {
        _dbg_msg( "fseek failed!" );
        end_of_file_pos = 0l;
    }

    // seek back to the orginal position
    fseek( m_file, cur_pos, SEEK_SET );

    return end_of_file_pos;
}

const EmacsString &EmacsFile::fio_getname()
{
    return m_full_file_name;
}

time_t EmacsFile::fio_modify_date()
{
    EmacsFileStat s;

    if( !s.stat( m_file ) )
        return 0;

    return s.data().st_mtime;
}

time_t EmacsFile::fio_file_modify_date( const EmacsString &filename )
{
    EmacsFileStat s;

    if( !s.stat( filename.sdata() ) )
        return 0;

    return s.data().st_mtime;
}

// return true if the file mode is read only for this use
int EmacsFile::fio_access_mode()
{
    EmacsFileStat s;

    s.stat( m_file );

    return (s.data().st_mode&_S_IWRITE) == 0;
}

int EmacsFile::get_fixup_buffer( unsigned char *buf, int len )
{
    if( m_attr == FIO_EOL__None )
    {
        //
        //    this makes a snap judgement of the buffers record type
        //
        unsigned char *nl_pointer = (unsigned char *)memchr( buf, '\n', len );
        if( nl_pointer != NULL )
        {
            int nl_index = nl_pointer - buf;

            if( nl_index > 0 )
            {
                if( buf[nl_index-1] =='\r' )
                    m_attr = FIO_EOL__StreamCRLF;
                else
                    m_attr = FIO_EOL__StreamLF;
            }
            else
                // LF is first char in buffer cannot have a CR before it
                m_attr = FIO_EOL__StreamLF;
        }
        else
        {
            unsigned char *cr_pointer = (unsigned char *)memchr( buf, '\r', len );
            if( cr_pointer != NULL )
                m_attr = FIO_EOL__StreamCR;
        }
    }

    switch( m_attr )
    {
    default:
        // defualt never gets hit...
        emacs_assert( false );
    case FIO_EOL__None:
        // no CR or LF in the buf so return the orginal len
        return len;

    case FIO_EOL__StreamLF:
    case FIO_EOL__Binary:
        // no change required
        return len;

    case FIO_EOL__StreamCR:
    {
        // each CR becomes a LF
        for( int i=0; i<len; i++ )
            if( buf[i] == '\r' )
                buf[i] = '\n';
        return len;
    }

    case FIO_EOL__StreamCRLF:
    {
        // strip CR's from the buf
        unsigned char *end = &buf[ len ];
        unsigned char *put = (unsigned char *)memchr( buf, '\r', len );
        unsigned char *get = put;

        if( put == NULL )
            return len;
        get++;
        while( get < end )
        {
            unsigned char c = *get++;
            if( c != '\r' )
                *put++ = c;
        }

        // return the length
        return put - buf;
    }
    }
}
