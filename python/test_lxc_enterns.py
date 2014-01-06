import os
import signal
import sys
import time
import libvirt
import libvirt_lxc


class __redirection__:

    def __init__(self):
        self.buff = ''
        self.__console__ = sys.stdout

    def write(self, output_stream):
        self.buff += output_stream

    def to_console(self):
        sys.stdout = self.__console__
        print self.buff

    def to_file(self, file_path):
        f = open(file_path, 'w')
        sys.stdout = f
        print self.buff
        f.close()

    def flush(self):
        self.buff = ''

    def reset(self):
        sys.stdout = self.__console__


def _connect_auth_cb(creds, opaque):
    if len(creds) == 0:
        return 0


AUTH = [[libvirt.VIR_CRED_AUTHNAME,
         libvirt.VIR_CRED_ECHOPROMPT,
         libvirt.VIR_CRED_REALM,
         libvirt.VIR_CRED_PASSPHRASE,
         libvirt.VIR_CRED_NOECHOPROMPT,
         libvirt.VIR_CRED_EXTERNAL],
        _connect_auth_cb,
        None]


def list_all_domains():
    uri = 'lxc:///'
    conn = libvirt.openAuth(uri, AUTH, 0)
    return conn.listAllDomains()


def runcmd(cmd, timeout=2):
    argv = cmd.split()
    try:
        pid = os.fork()
        if pid == 0:
            sys.stdout = r_obj
            os.execv(argv[0], argv)
            os._exit(255)
        else:
            last_time = int(time.time())
            cur_time = int(time.time())
            overtime = True
            while cur_time - last_time < timeout:
                os.waitpid(pid, os.WNOHANG)
                pidfile = "/proc/%s" % pid
                if not os.path.exists(pidfile):
                    overtime = False
                    break
                time.sleep(0.1)
                cur_time = int(time.time())

            if overtime:
                os.kill(pid, signal.SIGKILL)
                os.waitpid(pid, 0)

    except OSError:
        os._exit(255)


def exec_lxc_command(domain, cmd, timeout=2, flags=0):
    print "exec_lxc_command begin"
    ret = None
    try:
        fdlist = libvirt_lxc.lxcOpenNamespace(domain, flags)
        if fdlist is None:
            return ret
        pid = os.fork()
        if pid < 0:
            for fd in fdlist:
                os.close(fd)
                return ret
        elif pid == 0:
            if libvirt_lxc.lxcEnterNamespace(domain, fdlist, flags) < 0:
                os._exit(255)
            runcmd(cmd)
            os._exit(0)
        else:
            for fd in fdlist:
                os.close(fd)

            last_time = int(time.time())
            cur_time = int(time.time())
            overtime = True
            while cur_time - last_time < timeout:
                os.waitpid(pid, os.WNOHANG)
                pidfile = "/proc/%s" % pid
                if not os.path.exists(pidfile):
                    overtime = False
                    break
                time.sleep(0.1)
                cur_time = int(time.time())

            if overtime:
                os.kill(pid, signal.SIGKILL)
                os.waitpid(pid, 0)

            print "exec_lxc_command end"
            return ret
    except (libvirt.libvirtError, OSError) as e:
        return None


if __name__ == "__main__":

    print "begin"
    domains = list_all_domains()

    # redirection
#    r_obj = __redirection__()
#    sys.stdout = r_obj

    for domain in domains:
        exec_lxc_command(domain, "/bin/df -hl")

    # redirect to console
#    r_obj.to_console()

    # redirect to file
    r_obj.to_file('out.log')

    # flush buffer
#    r_obj.flush()

    # reset
    r_obj.reset()

    print "over"
