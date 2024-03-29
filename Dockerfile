FROM hub.opensciencegrid.org/opensciencegrid/software-base:3.6-el8-release


## Build arguments for embedding a version string within the image.


ARG GITHUB_REF
ENV GITHUB_REF="${GITHUB_REF:-}"

ARG GITHUB_SHA
ENV GITHUB_SHA="${GITHUB_SHA:-}"


## Set the Python version.


ARG PY_PKG=python39
ARG PY_EXE=python3.9


## Locale and Python settings required by Flask.


ENV LANG="en_US.utf8"
ENV LC_ALL="en_US.utf8"
ENV PYTHONUNBUFFERED=1


## Install core dependencies and configuration.


RUN yum module enable -y mod_auth_openidc ${PY_PKG} \
    && yum update -y \
    && yum install -y httpd mod_auth_openidc mod_ssl ${PY_PKG}-pip ${PY_PKG}-mod_wsgi \
    && yum clean all \
    && rm -rf /etc/httpd/conf.d/* /var/cache/yum/ \
    #
    && ${PY_EXE} -m pip install --no-cache-dir -U pip setuptools wheel


## Install the Flask and WSGI applications.

COPY /registry/requirements.txt /srv/
RUN ${PY_EXE} -m pip install --no-cache-dir -r /srv/requirements.txt

## Copy over httpd.conf

COPY apache/httpd.conf /etc/httpd/conf.d/
COPY apache/supervisor-apache.conf /etc/supervisord.d/40-apache.conf

COPY registry /srv/registry
COPY wsgi.py /srv/

# Set up a instance run space
RUN mkdir -p /srv/instance\
    && rm -rf /srv/instance/* \
    && chown apache:apache /srv/instance/
