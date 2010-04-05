'''
 ====================================================================
 Copyright (c) 2009-2010 Barry A Scott.  All rights reserved.

 This software is licensed as described in the file LICENSE.txt,
 which you should have received as part of this distribution.

 ====================================================================

    be_editor.py
    

'''
from __future__ import with_statement

import sys
import os
import time
import threading

import be_platform_specific

import _bemacs

import wx

_debug_editor = False
_debug_queue = False

class BEmacs(_bemacs.BemacsEditor):
    def __init__( self, app ):
        _bemacs.BemacsEditor.__init__( self,
                be_platform_specific.getUserDir(),
                be_platform_specific.getLibraryDir() )

        self.app = app
        self.log = app.log

        self.window = None

        self.__quit_editor = False
        self.__event_queue = Queue( self.log )

        self.__gui_result_event = threading.Event()

        self.__clipboard_data = None

        self.hook_ui_handlers = {
            "edit-copy":        self.uiHookEditCopy,
            "edit-paste":       self.uiHookEditPaste,
            "yes-no-dialog":    self.uiHookYesNoDialog,
            "set-window-title": self.uiHookSetWindowTitle,
            "test1":            self.uiHookTest1,
            "test2":            self.uiHookTest2,
            }

    def __debugEditor( self, msg ):
        if _debug_editor:
            self.log.debug( 'EDITOR %s' % (msg,) )

    def initEmacsProfile( self, window ):
        self.__debugEditor( 'BEmacs.initEmacsProfile()' )
        assert window is not None
        self.window = window

        # initEditor will start calling termXxx functions - must have windows setup first
        self.initEditor()
        self.setKeysMapping( self.window.getKeysMapping() )
        self.__debugEditor( 'BEmacs.initEmacsProfile() geometryChange %r %r' %
                            (self.window.term_width, self.window.term_length) )
        self.geometryChange( self.window.term_width, self.window.term_length )

        self.__debugEditor( 'TESTING' )
        #_bemacs.function.debug_emacs( 'flags=key,exec,tmp' )
        #_bemacs.variable.error_messages_buffer = "error-messages"

        self.__debugEditor( 'BEmacs.initEmacsProfile() emacs_profile.ml' )
        _bemacs.function.execute_mlisp_file( 'emacs_library:emacs_profile.ml' )

        self.executeEnterHooks()

        self.clientCommand( os.getcwd(), ['emacs'] + self.app.args[1:] )

    def guiCloseWindow( self ):
        self.__event_queue.put( (self.closeWindow, ()) )

    def closeWindow( self ):
        self.__quit_editor = True

    def openFile( self, filename ):
        self.log.info( 'openFile( %s ) start' % (filename,) )
        try:
            _bemacs.function.visit_file( filename )
            # force a redraw
            self.inputChar( -1, False )

            self.log.info( 'openFile done' )

        except Exception, e:
            self.log.error( 'openFile - %s' % (e,) )


    #--------------------------------------------------------------------------------
    def guiHasFocus( self ):
        self.__event_queue.put( (self.hasFocus, ()) )

    #--------------------------------------------------------------------------------
    def guiClientCommand( self, command_directory, command_args ):
        self.__event_queue.put( (self.clientCommand, (command_directory, command_args)) )

    def clientCommand( self, command_directory, command_args ):
        self.log.info( 'clientCommand dir  %r' % (command_directory,) )
        self.log.info( 'clientCommand args %r' % (command_args,) )

        assert len(command_args) > 0

        self.newCommandLine( command_directory, command_args )

    #--------------------------------------------------------------------------------
    def guiEventChar( self, ch, shift ):
        self.__event_queue.put( (self.inputChar, (ch, shift)) )

    def guiEventMouse( self, keys, shift, all_params ):
        self.__event_queue.put( (self.inputMouse, (keys, shift, all_params)) )

    def guiGeometryChange( self, width, length ):
        self.__event_queue.put( (self.geometryChange, (width, length)) )

    def guiOpenFile( self, filename ):
        self.log.info( 'guiOpenFile %s' % (filename,) )
        self.__event_queue.put( (self.openFile, (filename,)) )

    def guiScrollChangeHorz( self, window_id, change ):
        self.__event_queue.put( (self.scrollChangeHorz, (window_id, change) ) )

    def guiScrollSetHorz( self, window_id, position ):
        self.__event_queue.put( (self.scrollSetHorz, (window_id, position) ) )

    def guiScrollChangeVert( self, window_id, change ):
        self.__event_queue.put( (self.scrollChangeVert, (window_id, change) ) )

    def guiScrollSetVert( self, window_id, position ):
        self.__event_queue.put( (self.scrollSetVert, (window_id, position) ) )

    #--------------------------------------------------------------------------------
    def uiHookTest1( self, cmd ):
        self.setGuiResultSuccess( 99 )

    def uiHookTest2( self, cmd, text1, text2 ):
        dlg = wx.MessageDialog(
                    self.window,
                    unicode(text1),
                    unicode(text2),
                    wx.YES_NO | wx.NO_DEFAULT | wx.ICON_EXCLAMATION
                    )
        rc = dlg.ShowModal()
        dlg.Destroy()

        if rc == wx.ID_YES:
            self.setGuiResultSuccess( 'yes' )
        else:
            self.setGuiResultSuccess( 'no' )

    def uiHookSetWindowTitle( self, cmd, title ):
        self.app.setWindowTitle( title )
        self.setGuiResultSuccess( None )

    def uiHookEditCopy( self, cmd, text ):
        self.__clipboard_data = wx.TextDataObject()
        self.__clipboard_data.SetText( text )
        if wx.TheClipboard.Open():
            wx.TheClipboard.SetData( self.__clipboard_data )
            wx.TheClipboard.Close()
            self.setGuiResultSuccess( None )

        else:
            self.setGuiResultError( ValueError( 'failed to set data on clipboard' ) )

    def uiHookEditPaste( self, cmd, use_primary=False ):
        self.__debugEditor( 'uiHookEditPaste use_primary=%r' % (use_primary,) )
        success = False
        do = wx.TextDataObject()
        if wx.TheClipboard.Open():
            wx.TheClipboard.UsePrimarySelection( use_primary )
            self.__debugEditor( 'uiHookEditPaste clip open' )
            success = wx.TheClipboard.GetData( do )
            self.__debugEditor( 'uiHookEditPaste getdata %r' % (success,) )
            wx.TheClipboard.Close()

        if success:
            text = do.GetText().replace( '\r\n', '\n' ).replace( '\r', '\n' )
            self.__debugEditor( 'uiHookEditPaste text %r' % (text,) )
            self.setGuiResultSuccess( text )
            self.__debugEditor( 'uiHookEditPaste setGuiResultSuccess' )

        else:
            self.setGuiResultError( ValueError( 'clipboard is empty' ) )
            self.__debugEditor( 'uiHookEditPaste setGuiResultError' )

    def uiHookYesNoDialog( self, cmd, default, title, message ):
        result = self.app.guiYesNoDialog( default, title, message )
        self.setGuiResultSuccess( result )

    def hookUserInterface( self, *args ):
        self.__debugEditor( 'hookUserInterface( %r )' % (args,) )
        cmd = args[0]
        if cmd in self.hook_ui_handlers:
            self.initGuiResult()

            self.__debugEditor( 'hookUserInterface calling handler' )
            self.app.onGuiThread( self.hook_ui_handlers[ cmd ], args )

            self.__debugEditor( 'hookUserInterface waiting for result' )
            error, value = self.getGuiResult()

            self.__debugEditor( 'hookUserInterface error %r value %r' % (error, value) )

            if error is not None:
                self.__debugEditor( 'hookUserInterface handler error return' )
                raise error

            else:
                self.__debugEditor( 'hookUserInterface handler normal return' )
                return value

        else:
            raise ValueError( 'Unknown command %r' % (cmd,) )

    def initGuiResult( self ):
        self.__gui_result_event.clear()

    def getGuiResult( self ):
        self.__gui_result_event.wait()
        result = self.__gui_result
        self.__gui_result = None
        return result

    def setGuiResultSuccess( self, result ):
        self.__gui_result = (None, result)
        self.__gui_result_event.set()

    def setGuiResultError( self, error ):
        self.__gui_result = (error, None)
        self.__gui_result_event.set()

    #--------------------------------------------------------------------------------
    def termCheckForInput( self ):
        try:
            event_hander_and_args = self.__event_queue.getNoWait()

            while event_hander_and_args is not None:
                handler, args = event_hander_and_args
                self.__debugEditor( 'checkForInput: handler %r' % (handler,) )
                self.__debugEditor( 'checkForInput: args %r' % (args,) )
                handler( *args )

                event_hander_and_args = self.__event_queue.getNoWait()

            return 0

        except Exception, e:
            self.log.exception( 'Error: checkForInput: %s' % (str(e),) )
            self.app.debugShowCallers( 5 )
            return -1
 
    def termWaitForActivity( self, wait_until_time ):
        try:
            wait_timeout = wait_until_time - time.time()
            self.__debugEditor( 'termWaitForActivity %r' % (wait_timeout,) )
            if wait_timeout <= 0:
                event_hander_and_args = self.__event_queue.getNoWait()
            else:
                event_hander_and_args = self.__event_queue.get( wait_timeout )

            while event_hander_and_args is not None:
                handler, args = event_hander_and_args
                self.__debugEditor( 'waitForActivity: handler %r' % (handler,) )
                self.__debugEditor( 'waitForActivity: args %r' % (args,) )
                handler( *args )

                event_hander_and_args = self.__event_queue.getNoWait()

            if self.__quit_editor:
                self.__quit_editor = False
                self.__debugEditor( 'waitForActivity self.__quit_editor set' )
                return -1

            return 0

        except Exception, e:
            self.log.exception( 'Error: waitForActivity: %s' % (str(e),) )
            self.app.debugShowCallers( 5 )
            return -1

    def termTopos( self, y, x ):
        self.app.onGuiThread( self.window.termTopos, (y, x) )

    def termReset( self ):
        self.app.onGuiThread( self.window.termReset, () )

    def termInit( self ):
        self.__debugEditor( 'BEmacs.termInit() window %r' % (self.window,) )
        self.app.onGuiThread( self.window.termInit, () )

    def termBeep( self ):
        self.app.onGuiThread( self.window.termBeep, () )

    def termUpdateBegin( self ):
        self.__debugEditor( 'termUpdateBegin' )
        self.app.onGuiThread( self.window.termUpdateBegin, () )
        return True

    def termUpdateEnd( self, all_status_bar_values, all_horz_scroll_bars, all_vert_scroll_bars ):
        self.__debugEditor( 'termUpdateEnd' )
        self.app.onGuiThread( self.window.termUpdateEnd, (all_status_bar_values, all_horz_scroll_bars, all_vert_scroll_bars) )

    def termUpdateLine( self, old, new, line_num ):
        self.app.onGuiThread( self.window.termUpdateLine, (old, new, line_num) )

    def termMoveLine( self, from_line, to_line ):
        self.app.onGuiThread( self.window.termMoveLine, (from_line, to_line) )

    def termDisplayActivity( self, ch ):
        self.app.onGuiThread( self.window.termDisplayActivity, (ch,) )

class Queue:
    def __init__( self, log ):
        self.log = log

        self.__all_items = []
        self.__lock = threading.RLock()
        self.__condition = threading.Condition( self.__lock )

    def __debugQueue( self, msg ):
        if _debug_queue:
            self.log.debug( 'QUEUE %s' % (msg,) )

    def getNoWait( self ):
        with self.__lock:
            if len( self.__all_items ) > 0:
                item = self.get()
                return item

        return None

    def get( self, timeout=None ):
        self.__debugQueue( 'Queue.get( %r )' % (timeout,) )

        with self.__condition:
            if timeout is None:
                while len( self.__all_items ) == 0:
                    self.__condition.wait()

            else:
                if len( self.__all_items ) == 0:
                    self.__condition.wait( timeout )

            self.__debugQueue( 'Queue.get( %r )' % (timeout,) )
            if len( self.__all_items ) != 0:
                return self.__all_items.pop( 0 )

            else:
                return None

    def put( self, item ):
        with self.__condition:
            self.__all_items.append( item )
            self.__condition.notify()
