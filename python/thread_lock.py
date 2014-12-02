import time
import datetime
import threading
from threading import Thread


LOCK = threading.Lock()
RLOCK = threading.RLock()


def myfunc(i):
    print "sleeping 5 sec from thread %d at %s" % (i,
                    datetime.datetime.now().strftime('%b-%d-%y %H:%M:%S'))
    time.sleep(5)
    print "finished sleeping from thread %d at %s" % (i,
                    datetime.datetime.now().strftime('%b-%d-%y %H:%M:%S'))


def myfunc_with_lock(i):
    global LOCK
    with LOCK:
        print "sleeping 5 sec from thread %d at %s" % (i,
                        datetime.datetime.now().strftime('%b-%d-%y %H:%M:%S'))
        time.sleep(5)
        print "finished sleeping from thread %d at %s" % (i,
                        datetime.datetime.now().strftime('%b-%d-%y %H:%M:%S'))


def myfunc_with_rlock(i):
    global RLOCK
    with RLOCK:
        print "sleeping 5 sec from thread %d at %s" % (i,
                        datetime.datetime.now().strftime('%b-%d-%y %H:%M:%S'))
        time.sleep(5)
        print "finished sleeping from thread %d at %s" % (i,
                        datetime.datetime.now().strftime('%b-%d-%y %H:%M:%S'))


def lock_test(i):
    global LOCK
    with LOCK:
        myfunc_with_lock(i)


def rlock_test(i):
    global RLOCK
    with RLOCK:
        myfunc_with_rlock(i)

for i in range(3):
#    t = Thread(target=myfunc, args=(i,))
#    t.start()

#    t1 = Thread(target=myfunc_with_lock, args=(i,))
#    t1.start()

#    t2 = Thread(target=myfunc_with_rlock, args=(i,))
#    t2.start()

#    t3 = Thread(target=lock_test, args=(i,))
#    t3.start()

    t4 = Thread(target=rlock_test, args=(i,))
    t4.start()
