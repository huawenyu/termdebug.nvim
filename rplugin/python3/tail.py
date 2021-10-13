import os
import pynvim
#import time
import datetime
import subprocess
import logging
import logging.config

LOGGING_CONFIG = {
    'version': 1,
    'disable_existing_loggers': True,
    'formatters': {
        'standard': {
            #'format': '%(asctime)s [%(levelname)-4.4s] %(name)-12s.%(funcName)s: %(message)s',
            #'format': '[%(asctime)s] [%(levelname)-4.4s] [%(funcName)-18s]',
            #'format':  '[%(asctime)s] [%(levelname)-4.4s] %(name)-12s.%(funcName)-18s(): %(message)s',
            'format':  '[%(asctime)s] [%(levelname)-4.4s] %(name)s.%(funcName)s(): %(message)s',
            #'datefmt': '%Y-%m-%d %H:%M:%S',
            'datefmt': '%M:%S',
        },
    },
    'handlers': {
        'null': {
            'class': 'logging.NullHandler',
        },

        'file': {
            'level':     'DEBUG',
            'formatter': 'standard',
            'class':     'logging.FileHandler',
            'filename':  '/tmp/vimgdb.log',
            'mode':      'a',
        },
    },

    'loggers': {
        # root logger: 'INFO', 'DEBUG'
        #   used when the <name> not exist here: logging.getLogger(<name>)
        '': {
            'level':     'DEBUG',
            'handlers':  ['file'],
            'propagate': False
        },
    }
}

@pynvim.plugin
class EntryTermdebug(object):
    def __init__(self, vim):
        self.vim = vim
        self.calls = 0
        logging.config.dictConfig(LOGGING_CONFIG)
        self.logger = logging.getLogger(type(self).__name__)

    #@neovim.command('AutoreadLoop', range='', nargs='*', sync=False)
    @pynvim.function('Termtail')
    def handle_tail(self, args):
        while(True):
            command = 'tail -F ' + ' '.join(args)
            #self.logger.info("tail cmd=" + command)
            #t = datetime.datetime.now() - datetime.timedelta(seconds=1)
            p = subprocess.Popen(command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, universal_newlines=True)
            for line in iter(p.stdout.readline, ""):
                #self.logger.info("command_handler line=[" + line + "]")
                #t = datetime.datetime.now() + datetime.timedelta(milliseconds=100)
                if line.startswith('//@end'):
                    #self.vim.command("checktime")
                    self.vim.command("e " + self.vim.vars['termdebugSelf'])
                    #self.vim.command("redraw")
                elif line.startswith('//@update'):
                    # The method can refresh the floaterm, but cause gdb-terminal lost the focus,
                    #   so comment it, and force refresh by manally click the floaterm.
                    command = 'nvr --servername="' + self.vim.vars['termdebugMain'] + '"' \
                            + ' -c "FloatermShow ' + self.vim.vars['termdebugSelf'] + '"' \
                            + ' -c "call win_gotoid(g:termdebugWinmain)"'
                    #self.logger.info("eject vim cmd=" + command)
                    os.system(command)
                elif line.startswith('//@tag '):
                    command = 'nvr --servername="' + self.vim.vars['termdebugMain'] + '"' \
                            + ' -c "call win_gotoid(g:termdebugWinmain)"' \
                            + ' -c "tag ' + line[line.find("[")+1:line.find("]")] + '"'
                    #self.logger.info("eject vim cmd=" + command)
                    os.system(command)

