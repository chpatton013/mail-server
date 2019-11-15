#!/usr/bin/env python3

import argparse
import getpass
import os
import pathlib
import subprocess
import sys

CONFIG = "/etc/mail-server"
DATA = "/var/lib/mail-server"
RUN = "/run/mail-server"
ROOT = os.path.abspath(os.path.dirname(__file__))
TOOLS = os.path.join(ROOT, "tools")


class Config:
    def __init__(self, domain, config, data, run, tools):
        self.domain = domain
        self.config = config
        self.data = data
        self.run = run
        self.tools = tools

        self.dovecot_config = os.path.join(self.config, "dovecot")
        self.opendkim_config = os.path.join(self.config, "opendkim")

        self.virtual_mail = os.path.join(self.data, "virtual-mail")
        self.mail_queues = os.path.join(self.data, "mail-queues")
        self.mail_servers = os.path.join(self.data, "mail-servers")
        self.mail_sockets = os.path.join(self.data, "mail-sockets")
        self.clamav_data = os.path.join(self.data, "clamav")
        self.postfix_data = os.path.join(self.data, "postfix")
        self.spamassassin_data = os.path.join(self.data, "spamassassin")

        self.clamav_run = os.path.join(self.run, "clamav")
        self.dovecot_run = os.path.join(self.run, "dovecot")
        self.opendkim_run = os.path.join(self.run, "opendkim")
        self.postfix_run = os.path.join(self.run, "postfix")
        self.spamassassin_run = os.path.join(self.run, "spamassassin")

    def address(self, name):
        return "{name}@{domain}".format(name=name, domain=self.domain)

    def directories(self):
        yield self.dovecot_config
        yield self.opendkim_config

        yield self.virtual_mail
        yield self.mail_queues
        yield os.path.join(self.mail_queues, "active")
        yield os.path.join(self.mail_queues, "corrupt")
        yield os.path.join(self.mail_queues, "deferred")
        yield os.path.join(self.mail_queues, "hold")
        yield os.path.join(self.mail_queues, "incoming")
        yield os.path.join(self.mail_queues, "maildrop")
        yield self.mail_servers
        yield os.path.join(self.mail_servers, "bounce")
        yield os.path.join(self.mail_servers, "defer")
        yield os.path.join(self.mail_servers, "flush")
        yield os.path.join(self.mail_servers, "saved")
        yield os.path.join(self.mail_servers, "trace")
        yield self.mail_sockets
        yield os.path.join(self.mail_sockets, "private")
        yield os.path.join(self.mail_sockets, "public")
        yield self.clamav_data
        yield self.postfix_data
        yield self.spamassassin_data
        yield os.path.join(self.spamassassin_data, "spamassassin")
        yield os.path.join(self.spamassassin_data, "razor")

        yield self.clamav_run
        yield self.dovecot_run
        yield self.opendkim_run
        yield self.postfix_run
        yield self.spamassassin_run

    def tool(self, name):
        return os.path.join(self.tools, name)


def capture(*args, **kwargs):
    return subprocess.check_output(args, **kwargs).decode("utf-8")


def run(*args, **kwargs):
    return subprocess.check_call(args, **kwargs)


def dovecot_passwd(config, users):
    dovecot_passwd_file = os.path.join(config.dovecot_config, "passwd")

    if os.path.exists(dovecot_passwd_file):
        print("Dovecot passwd file already exists.")
        return

    if not users:
        print("No Dovecot users specified.", file=sys.stderr)
        sys.exit(1)

    print("Populating Dovecot passwd file.")

    def prompt_password(address):
        while True:
            print("Choose a password for {address}".format(address=address))
            password1 = getpass.getpass("Enter new password: ")
            password2 = getpass.getpass("Retype new password: ")
            if password1 == password2:
                return password1
            else:
                print("Passwords do not match!")

    content = ""
    for user in users:
        address = config.address(user)
        plaintext_password = prompt_password(address)
        hashed_password = capture(
            config.tool("generate-dovecot-passwd.sh"),
            "-p",
            plaintext_password,
        )
        content += address
        content += ":"
        content += hashed_password.strip()
        content += "\n"

    with open(dovecot_passwd_file, "w") as f:
        f.write(content)


def dovecot_dh_params(config):
    dovecot_dh_params_file = os.path.join(config.dovecot_config, "dh.pem")

    if os.path.exists(dovecot_dh_params_file):
        print("Dovecot DH Params file already exists.")
        return
    print("Populating Dovecot DH Params file.")

    run(config.tool("generate-dh-params.sh"), config.dovecot_config)


def opendkim_keys(config):
    opendkim_key_files = [
        os.path.join(config.opendkim_config, "mail.private"),
        os.path.join(config.opendkim_config, "mail.txt"),
    ]

    if any([os.path.exists(f) for f in opendkim_key_files]):
        print("OpenDKIM key files already exist.")
        return
    print("Populating OpenDKIM key files.")

    env = os.environ.copy()
    env["MAIL_DOMAIN"] = config.domain

    run(
        config.tool("generate-opendkim-keys.sh"),
        config.opendkim_config,
        env=env,
    )


def spamassassin_ruleset(config):
    spamassassin_ruleset = os.path.join(config.spamassassin_data, "compiled")

    if os.path.exists(spamassassin_ruleset):
        print("SpamAssassin ruleset already populated.")
        return
    print("Populating SpamAssassin ruleset.")

    env = os.environ.copy()
    env["SPAM_DATA"] = config.spamassassin_data
    env["SPAM_RUN"] = config.spamassassin_run

    run(
        config.tool("generate-spamassassin-ruleset.sh"),
        env=env,
    )


def razor_identity(config):
    razor_home_directory = os.path.join(config.spamassassin_data, "razor")
    razor_identity_file = os.path.join(razor_home_directory, "identity")

    if os.path.exists(razor_identity_file):
        print("Razor identity already populated.")
        return
    print("Populating Razor identity.")

    run(config.tool("generate-razor-identity.sh"), razor_home_directory)


def clamav_databases(config):
    main_clamav_database = os.path.join(config.clamav_data, "main.cvd")

    if os.path.exists(main_clamav_database):
        print("ClamAV databases already downloaded.")
        return
    print("Downloading ClamAV databases.")

    env = os.environ.copy()
    env["CLAMAV_CONFIG"] = os.path.join(
        ROOT,
        "server/files/etc/clamav/freshclam.conf",
    )
    env["CLAMAV_DATA"] = config.clamav_data
    env["CLAMAV_RUN"] = config.clamav_run

    run(
        config.tool("generate-clamav-databases.sh"),
        env=env,
    )


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("domain")
    parser.add_argument("--config", default=CONFIG)
    parser.add_argument("--data", default=DATA)
    parser.add_argument("--run", default=RUN)
    parser.add_argument("--users", nargs="*")
    args = parser.parse_args()

    config = Config(
        args.domain,
        os.path.abspath(args.config),
        os.path.abspath(args.data),
        os.path.abspath(args.run),
        TOOLS,
    )

    for d in config.directories():
        pathlib.Path(d).mkdir(parents=True, exist_ok=True)

    dovecot_passwd(config, args.users)
    dovecot_dh_params(config)
    opendkim_keys(config)
    spamassassin_ruleset(config)
    razor_identity(config)
    clamav_databases(config)


if __name__ == "__main__":
    main()
