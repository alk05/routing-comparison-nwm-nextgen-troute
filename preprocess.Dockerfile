FROM amazonlinux:2023 AS builder
ENV START_TIME=""
ENV FORECAST_TYPE=""

RUN dnf install -y git && dnf clean all
RUN git clone --depth 1 -b temp_routelinkdev https://github.com/alk05/troute-usgsdf.git /opt/troute-da


RUN dnf -y install \
        python3.11 tar gzip\
    && dnf clean all \
    && rm -rf /var/cache/dnf

RUN curl -LsSf https://astral.sh/uv/0.6.12/install.sh | sh
ENV PATH="/root/.local/bin:${PATH}"

RUN ln -sf /usr/bin/python3.11 /usr/bin/python3 \
    && ln -sf /usr/bin/python3.11 /usr/bin/python

COPY .. /routing-comparison-nwm-nextgen-troute

WORKDIR /routing-comparison-nwm-nextgen-troute
RUN uv pip install --system -e . \
    && rm -rf /root/.cache/uv /root/.cache/pip


WORKDIR /opt/troute-da
RUN uv pip install --system -e . \
    && rm -rf /root/.cache/uv /root/.cache/pip


FROM amazonlinux:2023 AS runtime


RUN dnf -y install \
        python3.11 wget gettext \
    && dnf clean all \
    && rm -rf /var/cache/dnf

RUN ln -sf /usr/bin/python3.11 /usr/bin/python3 \
    && ln -sf /usr/bin/python3.11 /usr/bin/python

COPY --from=builder /opt/troute-da /opt/troute-da

COPY --from=builder /usr/local/lib/python3.11/site-packages   \
    /usr/local/lib/python3.11/site-packages
COPY --from=builder /usr/local/lib64/python3.11/site-packages \
    /usr/local/lib64/python3.11/site-packages
COPY --from=builder /usr/local/bin                            /usr/local/bin
COPY --from=builder /routing-comparison-nwm-nextgen-troute/data    \
    /routing-comparison-nwm-nextgen-troute/data
COPY --from=builder /routing-comparison-nwm-nextgen-troute/scripts    \
    /routing-comparison-nwm-nextgen-troute/scripts

WORKDIR /routing-comparison-nwm-nextgen-troute
RUN wget \
    https://ciroh-community-ngen-datastream.s3.amazonaws.com/resources/v2.2_hydrofabric/troute_restart/RouteLink_CONUS.nc
RUN mv RouteLink_CONUS.nc /routing-comparison-nwm-nextgen-troute/data

ENTRYPOINT bash scripts/bash/preprocess_data.sh --START_TIME ${START_TIME} \
    --FORECAST_TYPE ${FORECAST_TYPE} --VPU ${VPU} --N_CPUS ${N_CPUS}