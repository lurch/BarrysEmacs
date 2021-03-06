//
//
//    getdb.cpp
//
//
#include <emacs.h>

#undef THIS_FILE
static char THIS_FILE[] = __FILE__;
static EmacsInitialisation emacs_initialisation( __DATE__ " " __TIME__, THIS_FILE );




//
//
//    DatabaseEntryNameTable implementation
//
//


//
//
//    DatabaseEntryNameTable implementation
//
//
static int table_value;    // used as a value in the name table

DatabaseEntryNameTable *DatabaseEntryNameTable::activeTable = NULL;

DatabaseEntryNameTable::DatabaseEntryNameTable( DatabaseSearchList *_dbs )
    : EmacsStringTable( 1024, 1024 )
    , dbs( _dbs )
{ }

DatabaseEntryNameTable::~DatabaseEntryNameTable()
{ }

void DatabaseEntryNameTable::makeTable( EmacsString &prefix )
{
    // copy prefix as we need to add a * that is not to be returned
    EmacsString pattern( prefix );
    pattern.append( "*" );

    emacs_assert( activeTable == NULL );

#ifdef vms
    pattern.toUpper();
#endif

    emptyTable();

    activeTable = this;
    for( int i = 0; i < dbs->dbs_size; i++ )
        dbs->dbs_elements[i]->index_db( pattern, indexDatabaseEntryCallback );

    activeTable = NULL;
}

int DatabaseEntryNameTable::indexDatabaseEntryCallback( const EmacsString &key, unsigned char * * )
{
    EmacsString str( key );
    str.toLower();

    // prevent duplicate keys being inserted
    // duplicates are normal
    if( activeTable->find( str ) == NULL )
        activeTable->add( str, (void *)&table_value );

    return 1;
}
