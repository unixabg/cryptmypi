#! /bin/bash
set -e


# VARIABLES ###################################################################
_IRC_NICK='<irc_nick>'
_IRC_PASSWORD='<irc_password>'
_CURRDIR=$(pwd)


# SETTING ARM64V8 TOR IRSSI DOCKER CONTAINER ##################################
echo "SETTING ARM64V8 TOR IRSSI DOCKER CONTAINER"
cd /opt
git clone https://github.com/splitstrikestream/arm-dockerfiles arm-dockerfiles
cd arm-dockerfiles/arm64v8-alpine-tor-irssi


# CREATING TOR-IRSSI EXECUTION SCRIPT #########################################
echo "CREATING TOR-IRSSI EXECUTION SCRIPT ( /usr/local/bin/tor-irssi )"
cat <<EOF > /usr/local/bin/tor-irssi
#!/bin/bash

/opt/arm-dockerfiles/arm64v8-alpine-tor-irssi/run.sh
EOF
chmod +x /usr/local/bin/tor-irssi
chmod +x /opt/arm-dockerfiles/arm64v8-alpine-tor-irssi/run.sh
chmod +x /opt/arm-dockerfiles/arm64v8-alpine-tor-irssi/build.sh
chmod +x /opt/arm-dockerfiles/arm64v8-alpine-tor/build.sh


# CREATING IRSSI BASIC CONFIG #################################################
echo "CREATING IRSSI BASIC CONFIG FILES"
cd ~
mkdir -p .irssi

# Place your .irssi config bellow (this is only an minimal example file)
cat <<EOF > ~/.irssi/config
servers = (
  {
    address = "zettel.freenode.net";
    chatnet = "FreenodeTor";
    port = "6697";
    use_tls = "yes";
    tls_cert = "~/.irssi/certs/FreenodeTor.pem";
    tls_verify = "no";
    autoconnect = "no";
  }
);

chatnets = {
  FreenodeTor = {
    type = "IRC";
    sasl_mechanism = "EXTERNAL";
    sasl_username = "$_IRC_NICK";
    sasl_password = "$_IRC_PASSWORD";
  };
};

channels = ( );

aliases = { };

statusbar = {

  items = {

    barstart = "{sbstart}";
    barend = "{sbend}";

    topicbarstart = "{topicsbstart}";
    topicbarend = "{topicsbend}";

    time = "{sb \$Z}";
    user = "{sb {sbnickmode \$cumode}\$N{sbmode \$usermode}{sbaway \$A}}";

    window = "{sb \$winref:\$tag/\$itemname{sbmode \$M}}";
    window_empty = "{sb \$winref{sbservertag \$tag}}";

    prompt = "{prompt \$[.15]itemname}";
    prompt_empty = "{prompt \$winname}";

    topic = " \$topic";
    topic_empty = " Irssi v\$J - https://irssi.org";

    lag = "{sb Lag: \$0-}";
    act = "{sb Act: \$0-}";
    more = "-- more --";
  };

  default = {

    window = {

      disabled = "no";
      type = "window";
      placement = "bottom";
      position = "1";
      visible = "active";

      items = {
        barstart = { priority = "100"; };
        time = { };
        user = { };
        window = { };
        window_empty = { };
        lag = { priority = "-1"; };
        act = { priority = "10"; };
        more = { priority = "-1"; alignment = "right"; };
        barend = { priority = "100"; alignment = "right"; };
      };
    };

    window_inact = {

      type = "window";
      placement = "bottom";
      position = "1";
      visible = "inactive";

      items = {
        barstart = { priority = "100"; };
        window = { };
        window_empty = { };
        more = { priority = "-1"; alignment = "right"; };
        barend = { priority = "100"; alignment = "right"; };
      };
    };

    prompt = {
      type = "root";
      placement = "bottom";
      position = "100";
      visible = "always";

      items = {
        prompt = { priority = "-1"; };
        prompt_empty = { priority = "-1"; };
        input = { priority = "10"; };
      };
    };

    topic = {

      type = "root";
      placement = "top";
      position = "1";
      visible = "always";

      items = {
        topicbarstart = { priority = "100"; };
        topic = { };
        topic_empty = { };
        topicbarend = { priority = "100"; alignment = "right"; };
      };
    };
  };
};

settings = {
  core = {
    real_name = "${_IRC_NICK}";
    user_name = "${_IRC_NICK}";
    nick = "${_IRC_NICK}";
    recode_transliterate = "no";
  };
  "fe-text" = { actlist_sort = "refnum"; };
};

ignores = ( { level = "CTCPS"; } );
EOF


mkdir -p .irssi/certs
# Place your certificate bellow (substitute the invalid example)
cat <<'EOF' > ~/.irssi/certs/FreenodeTor.pem

            !!!!!!IMPORTANT!!!!!!

THIS SHOULD BE REPLACED BY YOUR REAL PRIVATE KEY...
THIS IS JUST PLACEHOLDER TEXT. DO NOT USE IT AS IS.

For info on how to create the correct file contents
for your private key, how to register a certificate
can be found at:

https://github.com/splitstrikestream/arm-dockerfiles/tree/master/arm64v8-alpine-tor-irssi#connecting-to-freenode-using-tor

            !!!!!!IMPORTANT!!!!!!

This file's structure should have two parts:
-----BEGIN PRIVATE KEY-----

...

-----END PRIVATE KEY-----
-----BEGIN CERTIFICATE-----

...

-----END CERTIFICATE-----
EOF

chown -R 1001:1001 ~/.irssi

###############################################################################
cd "${_CURRDIR}"
