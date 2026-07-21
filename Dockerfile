FROM amazonlinux:2023 AS builder

# TODO: figure out what basic packages to install
# RUN dnf -y install \
#         git \
#         tar xz \
#         python3.11 python3.11-pip python3.11-devel \
#         gcc gcc-c++ make \
#         geos-devel proj-devel \
#     && dnf clean all \
#     && rm -rf /var/cache/dnf

RUN curl -LsSf https://astral.sh/uv/0.6.12/install.sh | sh
ENV PATH="/root/.local/bin:${PATH}"

RUN ln -sf /usr/bin/python3.11 /usr/bin/python3 \
    && ln -sf /usr/bin/python3.11 /usr/bin/python

# TODO: install t-route from the branch with the channel restart ID order fix
# TODO: install nwmurl

COPY . /routing-comparison-nwm-nextgen-troute

WORKDIR /routing-comparison-nwm-nextgen-troute
RUN uv pip install --system -e . \
    && rm -rf /root/.cache/uv /root/.cache/pip


FROM amazonlinux:2023 AS runtime

RUN ln -sf /usr/bin/python3.11 /usr/bin/python3 \
    && ln -sf /usr/bin/python3.11 /usr/bin/python

COPY --from=builder /usr/local/lib/python3.11/site-packages   /usr/local/lib/python3.11/site-packages
COPY --from=builder /usr/local/lib64/python3.11/site-packages /usr/local/lib64/python3.11/site-packages
COPY --from=builder /usr/local/bin                            /usr/local/bin
COPY --from=builder /routing-comparison-nwm-nextgen-troute    /routing-comparison-nwm-nextgen-troute

WORKDIR /routing-comparison-nwm-nextgen-troute

# TODO: download RouteLink_CONUS.nc and the troute.yaml template from datastream S3 bucket

# TODO: make directories


# TODO: set entrypoint to the run_nwm_route.sh script
# ENTRYPOINT ["bash", "Scripts/run_qkrig_hourly.sh"]
# CMD []