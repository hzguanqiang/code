'''
Verify the unified log.
'''


import glob
import json
import sys
import logging
import os
import re


def usages():
    print 'python %s [directories of the unified logs (default: .)]' % \
        sys.argv[0]


if __name__ == '__main__':
    levels = ('error', 'warn', 'info', 'debug')
    modules = ('PF', 'DDB', 'RDS', 'NVS', 'NBS', 'NOS')
    
    if len(sys.argv) == 2 and \
            sys.argv[1] in ('-h', '--help', '-help'):
        usages()
        sys.exit(1)
    
    format_str = '%(asctime)-15s %(levelname)s %(message)s'
    result_file = 'log_verification.result'
    log_level = logging.INFO
    seq_re = re.compile(r'^\d+(?:\.\d+)*$')
    ip_re = re.compile(r'^\d+\.\d+\.\d+\.\d+$')
    
    logger = logging.getLogger('log_verification')
    logger.setLevel(log_level)
    formatter = logging.Formatter(format_str)
    handler1 = logging.StreamHandler(sys.stderr)
    handler1.setFormatter(formatter)
    handler2 = logging.FileHandler(result_file, 'w')
    handler2.setFormatter(formatter)
    logger.addHandler(handler1)
    logger.addHandler(handler2)
    
    current_dir = os.path.abspath(os.path.curdir)
    
    for d in (sys.argv[1:] or ['.']):
        logger.info('entering directory %s' % d)
        os.chdir(d)
        
        for f in glob.glob('unified-*.log'):
            logger.info('verifying file %s' % f)
            if os.path.isdir(f):
                logger.warn('%s is a directory, skipped' % f)
                continue
            
            if os.path.getsize(f) == 0:
                logger.warn('the size of file %s is 0' % f)
                continue
            
            log_ids = {}
            
            with open(f) as f_handle:
                for i, line in enumerate(f_handle):
                    line = line.strip()
                    if line.startswith('#') or not line:
                        continue
                    
                    logger.debug('verifying log: %s' % line)
                    
                    j = None
                    try:
                        j = json.loads(line.decode('GBK'), encoding='GBK')
                    except UnicodeDecodeError:
                        logger.error('log contains other wide-characters: %s (%s:%d)' %
                                     (line, f, i+1))
                        continue
                    except ValueError:
                        logger.error('could not parse the log to JSON: %s (%s:%d)' % 
                                     (line, f, i+1))
                        continue
                    
                    if 'id' in j and 'seq' in j:
                        if j['id'] in log_ids:
                            if j['seq'] in log_ids[j['id']]:
                                logger.error('log has the same id and same seq: %s %s (%s:%d)' %
                                              (j['id'], j['seq'], f, i+1))
                            else:
                                log_ids[j['id']].append(j['seq'])
                        else:
                            log_ids[j['id']] = [j['seq']]
                        
                        if not seq_re.search(j['seq']):
                            logger.error('the format of seq not correct: %s (%s:%d)' % 
                                         (j['seq'], f, i+1))
                    else:
                        logger.error('there is no item "id" or "seq": %s (%s:%d)' %
                                     (line, f, i+1))
                    
                    if 'timestamp' not in j:
                        logger.error('there is no item "timestamp": %s (%s:%d)' %
                                     (line, f, i+1))
                    elif len(str(j['timestamp'])) != 13 or \
                            not isinstance(j['timestamp'], (long, int)):
                        logger.error('the timestamp not correct (should be '
                                      'number and the length is 13): %s (%s:%d)' % 
                                      (j['timestamp'], f, i+1))
                    
                    if 'level' not in j:
                        logger.error('there is no item "level": %s (%s:%d)' %
                                     (line, f, i+1))
                    elif j['level'] not in levels:
                        logger.error('the level should be one of %s: %s (%s:%d)' % 
                                      (levels, j['level'], f, i+1))
                    
                    if 'module' not in j:
                        logger.error('there is no item "module": %s (%s:%d)' %
                                     (line, f, i+1))
                    elif j['module'] not in modules:
                        logger.error('the module should be one of %s: %s (%s:%d)' %
                                      (modules, j['module'], f, i+1))
                    
                    if 'object' not in j:
                        logger.error('there is no item "object": %s (%s:%d)' %
                                     (line, f, i+1))
                    elif not isinstance(j['object'], dict):
                        logger.error('object is not a dict: %s (%s:%d)' % 
                                     (j['object'], f, i+1))
                    else:
                        for key in j['object']:
                            if not isinstance(key, (str, unicode)):
                                logger.error('object key is not a string: %s (%s:%d)' %
                                             (key, f, i+1))
                            elif '.' in key or key.startswith('$'):
                                    logger.error('object key contains "." or starts with "$": %s (%s:%d)' %
                                                 (key, f, i+1))
                    
                    if 'ip' not in j:
                        logger.error('there is no item "ip": %s (%s:%d)' %
                                     (line, f, i+1))
                    elif not ip_re.search(j['ip']):
                        logger.error('the format of ip not correct: %s (%s:%d)' %
                                     (j['ip'], f, i+1))
                    
                    for item in ('identifier', 'op', 'description'):
                        if item not in j:
                            logger.error('there is no item "%s": %s (%s:%d)' %
                                         (item, line, f, i+1))
        
        logger.info('exiting from directory %s' % d)
        os.chdir(current_dir)
