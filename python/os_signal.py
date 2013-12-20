import os
import signal
import sys
import time


def runcmd(cmd, timeout=5):
    argv = cmd.split()
    pid = os.fork()
    if pid == 0:
        os.execv(argv[0], argv)
        sys.exit(1)
    else:
        os.waitpid(pid, 0)


def handle_sigchld(signum, frame):
    try:
        print "wait sigchld terminate"
        pid, status = os.waitpid(-1, 0)
    except OSError:
        pass


def handle_sigterm(signum, frame):
    try:
        pid = os.getpid()
        print "pid %s received kill signal" % pid
        os.kill(pid, signal.SIGKILL)
        os.waitpid(-1, 0)
    except OSError:
        pass


def test(cmd):
    os.system("echo `date` test begin")
    pid = os.fork()
    if pid == 0:
        signal.signal(signal.SIGTERM, handle_sigterm)
        os.system("echo `date` test ------enter child")
        runcmd(cmd)
        os.system("echo `date` test ------leave child")
        sys.exit(1)
    else:
        signal.signal(signal.SIGCHLD, handle_sigchld)
        print "pid : %s" % pid
        timeout = 30
        runtime = 0
        overtime = True
        while runtime < timeout:
            time.sleep(0.1)
            runtime += 0.1
            pidfile = "/proc/%s" % pid
            if not os.path.exists(pidfile):
                print "pidfile %s  not exist, pid have exited" % pidfile
                overtime = False
                break
        if overtime:
            print "50s timeout and kill %s" % pid
#            os.kill(pid, signal.SIGKILL)
            os.kill(pid, signal.SIGTERM)

    os.system("echo `date` test end")


if __name__ == "__main__":
    print "In main"
    ret = test("/bin/sleep 60")
