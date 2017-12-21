# FROM ubuntu:17.10
FROM datawire/ambassador-envoy:v1.5.0-47-g6b197c85c

MAINTAINER Datawire <flynn@datawire.io>
LABEL PROJECT_REPO_URL         = "git@github.com:datawire/ambassador.git" \
      PROJECT_REPO_BROWSER_URL = "https://github.com/datawire/ambassador" \
      DESCRIPTION              = "Ambassador REST Service" \
      VENDOR                   = "Datawire" \
      VENDOR_URL               = "https://datawire.io/"

RUN apt-get update && apt-get -q install -y \
    curl \
    python3-pip \
    git

WORKDIR /application

RUN curl -L https://s3.amazonaws.com/datawire-static-files/kubernaut/$(curl -s https://s3.amazonaws.com/datawire-static-files/kubernaut/stable.txt)/kubernaut -o /usr/local/bin/kubernaut && chmod +x /usr/local/bin/kubernaut

RUN pip3 install \
    semantic_version \
    gitpython \
    docopt \
    awscli \
    pytest \
    pytest-cov \
    dpath

COPY ./ ambassador

# RUN mkdir /etc/ambassador-config
# COPY ambassador/tests/certs/ /etc/ambassador-config/certs
# COPY ambassador/tests/ca_cert_chain/ /etc/ambassador-config/ca_cert_chain

RUN cd ambassador/ambassador && pip3 install -r requirements.txt
RUN cd ambassador && \
    sed -e "s/{{VERSION}}/$(python3 scripts/versioner.py --bump --magic-pre)/g" < VERSION-template.py > ambassador/ambassador/VERSION.py && \
    echo "VERSION: $(python3 ambassador/ambassador/VERSION.py)"
RUN cd ambassador/ambassador && python3 setup.py --quiet install
# RUN rm -rf ./ambassador

RUN cd ambassador && pytest --tb=short --cov=ambassador --cov-report term-missing
