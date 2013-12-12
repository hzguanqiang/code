import os
import sys


def runcmd(cmd):
    print "Begin"
    ret = -2
    argv = cmd.split()
    pid = os.fork()
    try:
        if pid == 0:
            print "enter child"
            os.execv(argv[0], argv)
            print "leave child"
            sys.exit(1)
        else:
            print "before waitpid %s " % pid
            os.waitpid(pid, 0)
            print "after waitpid %s " % pid
            ret = 0
            return ret
    except OSError:
        print "exception OSError"
        ret = -1
        sys.exit(1)
    
    print "End"


def runcmd2(cmd, stdin=sys.stdin, stdout=sys.stdout):
    argv = cmd.split()
    old_stdin = sys.stdin
    old_stdout = sys.stdout
    sys.stdin = stdin
    sys.stdout = stdout
    try:
        pid = os.fork()
        if pid == 0:
            os.dup2(sys.stdin.fileno(), 0)
            os.dup2(sys.stdout.fileno(), 1)
            os.execv(argv[0], argv)
            sys.exit(1)
        else:
            os.waitpid(pid, 0)
            sys.stdin = old_stdin
            sys.stdout = old_stdout
    except OSError:
        sys.exit(1)


def test(cmd):
    print "test Begin"
    rp, wp = os.pipe()
    pid = os.fork()
    if pid == 0:
        os.close(rp)
        print "test ---   enter child"
        wp = os.fdopen(wp, 'w')
#        stdin = open("./data.in","r")
#        stdout = open("./data.out","w")
#        runcmd2(cmd, stdin, stdout)
        runcmd2(cmd, stdout=wp)
        wp.close()
        print "test ----leave child"
        sys.exit(1)
    else:
        os.close(wp)
        print "test before waitpid"
        os.waitpid(pid, 0)
        print "test after waitpid"
        rp = os.fdopen(rp)
        ret = rp.read()
        rp.close()
    print "=========================="
    print "bingo, ret : \n%s" % ret
    print "=========================="

    print "End"


if __name__ == "__main__":
    print "In main"
#    runcmd("/bin/df -l -h")
#    runcmd2("/bin/df -l -h")
#    test("/bin/df -l -h")

    ret = runcmd("/bin/df -l -h")
    print "bingo : %s" % ret
