
SSH for fun and profit
==================

`ssh` is a tool that many of us use in our daily work lives. Probably for
most of us, it is primarily a means to get a shell on a remote computer. This
post is all about exploring the power of `ssh` and making its daily use a
little more seamless. Also, I'll talk a bit about some of the more powerful
features hidden away in this ubiquitous utility.

History
--------

`ssh` originated in 1995 and was designed to replace remote login utilities
(like `telnet`) which transmitted everything, including passwords, in plain
text. In 1999 the [**OpenSSH**](http://www.openssh.com/) project created an
open source version of the original `ssh` project and continues to be actively
developed to this day. When you use `ssh` today, you are almost certainly
using OpenSSH (unless you are on windows ... I don't think that
[Putty](http://www.putty.org/) uses OpenSSH ... let me know in the comments if
you know).

One of the main advantages of `ssh` is that all data transmitted over an `ssh`
connection is encrypted. With `ssh`, it is possible to wrap unsecure protocols
in an '`ssh` tunnel' so all any middle-men see is encrypted traffic.


Remote Login
-----------------

This is what most people use ssh for. The typical usage is:

```bash
$ ssh user@host

user@host's password:
```

Although you can drop the `user` part if the local username is the same as the
username on the remote machine. The next step is to provide a password to
authenticate.

There are a few things that we can do to make this a bit more seamless.

#### RSA Keys for Authentication ####

First, we can simultaneously enhance security and ease of use by using key
authentication.   To do that, we'll use the `ssh-keygen` command like this:

```bash
$ ssh-keygen
Generating public/private rsa key pair.
Enter file in which to save the key (/path/to/your/home-dir/.ssh/id_rsa):
```

It will first ask you to specify a name for the private key. The default is
`'id_rsa'`. If you end up making several keys for different servers you will
want to have some sort of sane naming convention, but for now accepting the
default is just fine. (**Note**: by default `ssh-keygen` will generate RSA key-
pairs but you may specify other algorithms using the `-t` flag.)

Next it will ask you to enter a passphrase which you will use to unlock the key:

```bash
Enter passphrase (empty for no passphrase):
```

I always protect my keys with a password, but they work fine even if you don't.
Most operating systems offer some sort of a keychain for managing passwords,
including these RSA keys. I'm usually on OS X and the command to make the OS
handle the password management for the keys is:

```bash
$ ssh-add -K ~/.ssh/id_rsa
```

I'm not sure off the top what the linux equivalent would be for any given
distro. (If you know, feel free to leave a note in the comments.)

Once `ssh-keygen` is done running, you will find two new files in `~/.ssh/`. If
you accepted the default name for the key you will see `id_rsa` and
`id_rsa.pub`. These are [RSA](https://en.wikipedia.org/wiki/RSA_(cryptosystem))
public/private keypairs. Without going into a lengthy cryptography discussion,
suffice it to say that you distribute your public key the places you want to
authenticate to and you use your private key to do the authentication.

So, to use these shiny new keys to do `ssh` authentication you need to put your
public key in a special place on the remote computer. When you `ssh` into a
remote host, the host `ssh` daemon will check the contents of a file called
`~/.ssh/authorized_keys` for public keys to authenticate against.

This command will do the trick:

```bash
$ cat ~/.ssh/id_rsa.pub | ssh user@host \
    "mkdir .ssh 2>/dev/null; cat >> .ssh/authorized_keys"
```

There's a lot going on in that command. Lets break it down into digestible
chunks.

First, the `cat ~/.ssh/id_rsa.pub` portion will output the  contents of the
public key that we just generated. The output is then
'[piped](http://www.linfo.org/pipes.html)' into the `ssh` command.

The next part introduces a new `ssh` feature---remote command execution. The
general form is:

```bash
$ ssh user@host command
```

This ends up being roughly equivalent to logging into the remote host via `ssh`
and then issuing the `command` and exiting. The difference is that the input and
output associated with the command is bound to the local host rather than the
remote host. That is the key element here.

The output of the `cat` command on the local host is directed to the input of 

```bash
"mkdir .ssh 2>/dev/null; cat >> .ssh/authorized_keys"
```

First we are making sure that the `~/.ssh` directory exists. Then, the output of
`cat ~/.ssh/id_rsa.pub` is directed into `~/.ssh/authorized_keys` on the remote
host.

I do this often enough that I have a function defined in my `.bashrc` file so I
don't have to type that long command. Here it is:

```bash
key () {
	if [ -z $1 ]
	then
		printf "USAGE: key [user@]host\n"
	else
		cat ~/.ssh/id_rsa.pub | \
		    ssh $1 "mkdir .ssh 2>/dev/null; cat >> .ssh/authorized_keys"
		printf "put public key in .ssh/authorized_keys on $1\n"
	fi
}
```

With this function available the task of putting a key on the remote host is a
simple as

```bash
$ key user@host
```

Once that is done you can now do:

```bash
$ ssh user@host
```

and you don't have to type your password. Instead, the `ssh` program negotiates
the authentication process for you by using your private key.

`ssh` configuration file
-------------------------

This is a good time to talk about some of the awesome things you can do with the
`ssh` config file. Pretty much any of the settings you can specify in an `ssh`
command can be permanently cached in a config file for specific hosts (or for
all hosts if you like).

When you issue an `ssh` command, the program will look for a file called
`~/.ssh/config` and apply any specified options for the applicable host before
the command executes.

###Anatomy of an `ssh` config file:###

Let's start with an example:

```bash
Host host
     User username
     Hostname hostname.with.a.bunch.of.qualifiers.com
     IdentityFile ~/.ssh/hostname_key
     Port 2222
     AddressFamily inet
```

If that is in your `~/.ssh/config` file, you can now do:

```bash
$ ssh host
```

and it will be equivalent to doing:

```bash
$ ssh -4 -p 2222 -i ~/.ssh/hostname_key \
    username@hostname.with.a.bunch.of.qualifiers.com
```

The sky is the limit when it comes to setting up config options. Take a look at
the [documentation](http://linux.die.net/man/5/ssh_config) for a full listing of
the available options.

X11 Forwarding
-------------------

Some programs available on remote host have a graphical user interface. To use
those programs remotely it is usually a good idea to set up a remote desktop
environment ([VNC](https://en.wikipedia.org/wiki/Virtual_Network_Computing) and
[NX](https://www.nomachine.com/) are a couple examples). However, sometimes you
may wish to have quick and easy access to the graphical window of a particular
program.

Fortunately, `ssh` supports this with no ahead of time setup.

Lets say you wanted to launch `matlab` on some `host`. The command:

```bash
$ ssh -X host matlab
```

will launch `matlab` on the remote host and display in the local
[X11](https://en.wikipedia.org/wiki/X_Window_System) window.

There are security implications associated with allowing a remote program access
to a local X-window. For this reason, you may find that the `-X` flag will fail
to perform as expected. This is because X11 forwarding with the `-X` flag is
"subjected to X11 SECURITY extension restrictions by default" (according to the
man page).

You can get around these restrictions by using the `-Y` flag instead. Just
remember that you may be opening yourself to risk if you do so. Never use the
`-Y` flag unless you *really* trust the remote host and the remote program!


The good stuff (here there be dragons):
-----------------------------------------------

We've barely scratched the surface of the capabilities of the `ssh` utility, and
I don't intend to talk about every available feature. There are three more
features that I will discuss before calling it a day. They are 'local port
tunneling', 'remote port tunneling', and 'Dynamic port tunneling'.

**WARNING: The following sections could be used to circumvent network policy
implementation dictated by your local IT/IA/network policy. Just because you can
do a thing does not mean you should do that thing. Using the following
information in an irresponsible way may result in a violation of policy or could
potentially be a crime if used maliciously on government systems!**

#### Local port tunneling

So called 'local port tunneling' makes it so that connections to a specific port
on your local machine get forwarded to a port on a remote machine. This is the
syntax:

```bash
$ ssh -L[bind_address:]port:remote_host_b:hostport remote_host_a
```

Lets consider an example.

 * Suppose you have an account on 'server_a' and so you are able to `ssh` to it. 
 * Let's also suppose that there is a service running on 'server_b' on port 12345
   and you want to connect to it. Unfortunately the firewall rules on your network
   prevent connections to 'server_b' from your workstation. 
 * Suppose that 'server_a' can connect to 'server_b'.
 * Finally, suppose port `12345` is not available on your workstation, but `9999` is.

The following command will do the trick:

```bash
$ ssh -L9999:server_b:12345 server_a
```

Now you can connect to `localhost` on port `9999` and you will actually be
connecting to 'server_b' on port `12345`. As an added bonus, all of the traffic
is encrypted along the way.

Often times I will end up doing something more like:

```bash
$ ssh -L12345:localhost:12345 host
```

This will set up a local tunnel to `host` and make it so connections to _my_
`localhost:12345` get forwarded to `host`. Note the `localhost` argument where
`server_b` was in the last example. This makes the connection to port `12345`
over the loopback interface on the remote host. This is useful when a service
running on `host` does not accept incoming connections, but does serve local
traffic.

Before moving on, you may be asking about the optional `bind_address` mentioned
at the beginning of this section. Be careful with this one. If you specify an
address (i.e. an IP address of one of your interfaces) it will bind the tunnel
to that interface. The effect is that your machine will now accept incoming
connections to the local port and they will be forwarded through your tunnel to
the remote host. Unless you specifically want to enable this behavior, you
should probably shy away from this.

Unless you change the `GatewayPorts` option, the default behavior will be to
bind to `localhost` if `bind_address` is not set.

If you want to, you can also specify `bind_address` to be `*` if you really want
to bind to all interfaces, but you will probably need to either escape it (`\*`)
or quote it (`"*"`) due to
[globbing](http://tldp.org/LDP/abs/html/globbingref.html).

One final thought. When I set up tunnels, I always use the `-f` and `-N` flags.
`-f` puts `ssh` into the background just prior to remote command execution. `-N`
prevents remote command execution. In combination, these flags make it so the
tunnel is setup and you are returned to your shell.

I set up local tunnels so often that I have this convenience function defined in
my `.bashrc`:

```bash
tunnel () {
	if [[ -z $1 || -z $2 ]]
	then
		echo "USAGE: $0 <local-port> <host> [remote-port]"
		echo "       if remote-port is not supplied, the"
		echo "       remote-port will be set to local-port"
	else
		LOCALPORT=$1
		HOST=$2
		REMOTEPORT=$3
		[ -z $REMOTEPORT ] && REMOTEPORT=$LOCALPORT
		ssh -fNL${LOCALPORT}:localhost:${REMOTEPORT} ${HOST}
	fi
}
```

Forwarding privileged ports (i.e. less than 1024) requires root privileges.

#### Remote port tunneling ####

Remote port tunneling is pretty much the inverse operation of local port
tunneling. Instead of setting up a tunnel which will forward connections made to
the local host to the remote host, a remote tunnel take connections made to the
remote host and forward them to the local host.

The structure of the command is just like the local tunnel except that instead
of `-L` the flag is `-R`:

```bash
$ ssh -R[bind_address:]port:remote_host_b:hostport remote_host_a
```

This will make it so that connections made to `remote_host_a`  on `hostport`
will be forwarded to `remote_host_b` on `port` via the local machine.

If we wanted to grab all of the traffic on a remote `host:port` and handle it
locally, we could set up a remote tunnel and set `remote_host_b` to `localhost`.

Another common use case for remote tunnels is this: let's say you have a
computer that has `ssh`, but doesn't have an `ssh` server. If you want to
temporarily provide access to it you can make a 'reverse tunnel'. If you have a
VNC server running on `localhost:5900` you could provide remote GUI access by
doing:

```bash
$ ssh -fNR5900:localhost:5901 remotehost
```

Then a user on `remotehost` could connect a VNC server to `localhost:5901`. This
will result in a VNC connection to the computer that set up the remote tunnel.

**NOTE:** Forwarding privileged ports (i.e. less than 1024) requires the user
for `remote_host_a` to be `root`.

#### Dynamic port tunneling ####

In the previous sections we talked about forwarding connections to a specific
port to a remote host. In this section, we talk about setting up a way to
forward arbitrary ports at the application level to a remote host.

##### SOCKS Proxy #####

Many applications support something called a 'SOCKS Proxy'. This is a protocol
which acts as a proxy for applications accessing the internet. Instead of going
through the default gateway to resolve a route to an IP address, applications
configured to use a SOCKS Proxy will instead direct that traffic to the proxy.
The Proxy then does whatever translation is necessary and negotiates the
connection on behalf of the application.

The `ssh` utility supports the creation of a SOCKS Proxy with the `-D` flag. The
command is quite simple:

```bash
$ ssh -D[bind_address:]port host
```

This sets up a proxy which listens on the local machine (again you can
optionally bind to a specific device address or `*`) and dynamically forwards
the application data to the `host`.

There are *many* use cases for SOCKS Proxies. I won't go into all of them here,
but suffice it to say that it can be used as a "poor mans VPN".

##### One last example: #####

Suppose you are a developer on a project and you are using [`git`](https://git-
scm.com/) for version control. Let's also say that the git server uses IP
filtering. You have access to a large host which you want to do builds and
testing on but it isn't in the IP range that the git server accepts. Let's also
assume that wile you can `ssh` to the host, the host cannot `ssh` to your
computer.

In order to check out the project on the host we will do some ssh magic.

First we will make a tunnel so the host can connect back to your machine by
running this command on your computer:

```bash
$ ssh -fNR2222:localhost:22 host
```

Now, if you are logged into `host`, you can connect back to your computer by
(assume your username is `user`):

```bash
$ ssh -p 2222 user@localhost
```

Cool huh?

Ok, now that you can get back to your machine, exit that connection and let's
set up a proxy for git

```bash
$ ssh -p 2222 -fND1080 user@localhost
```

The proxy is set up, so it's time to let the `git` application know about it:

```bash
$ git config --global http.proxy "socks5://localhost:1080"
```

Now we can do a `git clone` on the repo despite the fact that the server isn't
on the IP whitelist!

Once the repo is pulled, it is a good idea to convert the global proxy
configuration to apply to just the repo by running the `git config` command in
the checked out repo--sans the `--global` flag. Then edit (or simply remove)
`~/.gitconfig`.

-----------------------------------------------------------------------------

**Please remember to carefully consider the implications of using the
techniques described above. As an authorized user on a government network it is
your responsibility to comply with all laws, regulations, and policies regarding
access to and exposure of government systems. Just because it may be trivial to
expose government networks to the outside internet does not in any way make it
acceptable to do so any more that it would be acceptable to provide physical
access to a government facility to unauthorized personnel.**
