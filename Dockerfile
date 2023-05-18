ARG SR_BASEIMG
ARG SR_LINUX_RELEASE

# FROM srl/custombase:$SR_LINUX_RELEASE AS target
FROM $SR_BASEIMG:$SR_LINUX_RELEASE AS target

# Create a Python virtual environment, note --upgrade is broken
RUN sudo python3 -m venv /opt/demo-agents/rpki-agent/.venv --system-site-packages --without-pip
ENV VIRTUAL_ENV=/opt/demo-agents/rpki-agent/.venv
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

# Use custom built rpki-rtr-client package
FROM quay.io/centos/centos:stream8 AS custom-build
RUN yum install -y python3 gcc git python3-devel && cd /tmp && \
    git clone https://github.com/jbemmel/rpki-rtr-client && \
    cd rpki-rtr-client && \
    pip3 install pytricia && \
    PYTHONDONTWRITEBYTECODE=1 python3 setup.py install

# Install pygnmi in separate image too, needs build tools and upgraded pip
# RUN yum install -y gcc-c++ && python3 -m pip install pip --upgrade && python3 -m pip install pygnmi

FROM target AS final
COPY --from=custom-build /tmp/rpki-rtr-client*  $VIRTUAL_ENV/lib/python3.6/site-packages/
COPY --from=custom-build /usr/local/lib64/python3.6/site-packages/pytricia* $VIRTUAL_ENV/lib/python3.6/site-packages/
# COPY --from=custom-build /usr/local/lib/python3.6/site-packages $VIRTUAL_ENV/lib/python3.6/

# NDB replaces ipdb
COPY requirements.txt /
RUN $VIRTUAL_ENV/bin/python3 -m pip install --upgrade -r /requirements.txt # pyroute2-ndb

ENV AGENT_PYTHONPATH="$VIRTUAL_ENV/lib/python3.6/site-packages:$AGENT_PYTHONPATH"

RUN sudo mkdir --mode=0755 -p /etc/opt/srlinux/appmgr/ /opt/demo-agents/rpki-agent
COPY --chown=srlinux:srlinux ./srl-rpki-agent.yml /etc/opt/srlinux/appmgr
COPY ./src /opt/demo-agents/

# Add in auto-config agent sources too
COPY --from=srl/auto-config-v2:latest /opt/demo-agents/auto-config-agent/ /opt/demo-agents/auto-config-agent/

# run pylint to catch any obvious errors
RUN PYTHONPATH=$AGENT_PYTHONPATH pylint --load-plugins=pylint_protobuf -E /opt/demo-agents/rpki-agent

# Using a build arg to set the release tag, set a default for running docker build manually
ARG SRL_RPKI_RELEASE="[custom build]"
ENV SRL_RPKI_RELEASE=$SRL_RPKI_RELEASE
