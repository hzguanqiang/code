import os
import signal
import sys
import time


def runcmd(cmd, timeout=5):
    argv = cmd.split()
    print "enter runcmd"
    pid = os.fork()
    if pid == 0:
        os.execv(argv[0], argv)
        os._exit(0)
    else:
        os.waitpid(pid, 0)

    print "leave runcmd"


def test(cmd):
    print "test begin"
    pid = os.fork()
    if pid == 0:
        print "enter child"
        runcmd(cmd)
        print "leave child"
        os._exit(0)
        print "child exit"
    else:
        print "pid : %s" % pid
        timeout = 30
        runtime = 0
        overtime = True
        while runtime < timeout:
            os.waitpid(pid, os.WNOHANG)
            pidfile = "/proc/%s" % pid
            if not os.path.exists(pidfile):
                print "pidfile %s  not exist, pid have exited" % pidfile
                overtime = False
                break
            time.sleep(0.1)
            runtime += 0.1
            print "runtime: %s" % runtime
        if overtime:
            print "30s timeout and kill %s" % pid
            os.kill(pid, signal.SIGKILL)
            os.waitpid(pid, 0)

    print "test end"


if __name__ == "__main__":
    print "In main"
    test("/bin/sleep 100")
#    test("/bin/sleep 10")
