def debug_log(f):
    def wrapper(*args, **kwargs):
        print 'enter into %s' %  f.__name__
        f(*args, **kwargs)
        print 'leaving %s' % f.__name__

    return wrapper


@debug_log
def test():
    print 'hello'


test()
