FROM continuumio/miniconda
MAINTAINER Hail Team <hail@broadinstitute.org>

RUN mkdir /home/hail-ci /batch /hail-ci && \
    groupadd hail-ci && \
    useradd -g hail-ci hail-ci && \
    chown -R hail-ci:hail-ci /home/hail-ci /batch /hail-ci /opt/conda

RUN apt-get update && apt-get install -y \
    make \
    && rm -rf /var/lib/apt/lists/*

USER hail-ci

WORKDIR /batch
COPY --chown=hail-ci:hail-ci batch/batch/batch batch
COPY --chown=hail-ci:hail-ci batch/batch/setup.py .

WORKDIR /hail-ci
COPY --chown=hail-ci:hail-ci environment.yml .
RUN conda env create -n hail-ci -f environment.yml && \
    rm -rf /opt/conda/pkgs/*

COPY --chown=hail-ci:hail-ci index.html pr-build-script pr-deploy-script deploy-index.html ./
COPY --chown=hail-ci:hail-ci ci ./ci

ENV PATH /home/hail-ci/google-cloud-sdk/bin:/opt/conda/envs/hail-ci/bin:$PATH

RUN /bin/sh -c 'curl https://sdk.cloud.google.com | bash' && \
    ls /home/hail-ci && ls /home/hail-ci/google-cloud-sdk/bin && \
    gcloud components install kubectl
RUN pip install --user /batch
EXPOSE 5000
VOLUME /hail-ci/oauth-token
VOLUME /hail-ci/gcloud-token
ENTRYPOINT ["python", "ci/ci.py"]
