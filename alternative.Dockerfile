FROM docker.repository.cloudera.com/cloudera/cdsw/ml-runtime-workbench-python3.9-standard:2023.05.2-b7

# install miniconda for python env
RUN curl -k  "https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh" --output miniconda.sh && \
    chmod +x miniconda.sh && \
    mkdir -p /opt && \
    /bin/bash miniconda.sh -b -p /opt/conda && \
    rm -f miniconda.sh && \
    export PATH=/opt/conda/bin:$PATH && \
    ln -s /opt/conda/etc/profile.d/conda.sh /etc/profile.d/conda.sh && \
    echo "conda activate base" >> ~/.bashrc && \
    /opt/conda/bin/conda clean -afy && \
    conda init
ENV PATH=/opt/conda/bin:$PATH

# Install mamba
RUN conda install mamba -n base -c conda-forge -y
RUN mamba install nginx=1.25.3 -c conda-forge -y

# su root to execute subsequent commands
USER root

# nginx user
RUN usermod -u 1000 www-data && groupmod -g 1000 www-data

# kong user
RUN addgroup -gid 1001 kong && adduser --disabled-password --gecos "" --uid 1001 --gid 1001 kong
RUN usermod -u 1001 kong && groupmod -g 1001 kong

# kong config dir
RUN mkdir -p /etc/kong-config
RUN chown -R kong:0 /etc/kong-config

# Kong build block
COPY kong_3.7.1_amd64.deb /tmp/kong.deb
   
RUN set -ex; \
    apt-get update \
    && apt-get install --yes /tmp/kong.deb libc6 \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /tmp/kong.deb \
    && chown kong:0 /usr/local/bin/kong \
    && chown -R kong:0 /usr/local/kong \
    && ln -s /usr/local/openresty/luajit/bin/luajit /usr/local/bin/luajit \
    && ln -s /usr/local/openresty/luajit/bin/luajit /usr/local/bin/lua \
    && ln -s /usr/local/openresty/nginx/sbin/nginx /usr/local/bin/nginx
    
# RUN kong version
   
COPY docker-entrypoint.sh /docker-entrypoint.sh
COPY just_start.sh /just_start.sh
RUN chmod a+x /docker-entrypoint.sh /just_start.sh
   
USER kong
RUN touch /etc/kong-config/kong.yml
   
ENTRYPOINT ["/just_start.sh"]
   
EXPOSE 8000 8443 8001 8444 8002 8445 8003 8446 8004 8447 8100
   
STOPSIGNAL SIGQUIT
   
HEALTHCHECK --interval=10s --timeout=10s --retries=10 CMD kong health