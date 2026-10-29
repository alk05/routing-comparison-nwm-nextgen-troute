FROM python:3.11-slim

WORKDIR /app

RUN pip install --no-cache-dir \
    matplotlib \
    pandas \
    xarray \
    numpy \
    netCDF4 \
    pyarrow

ENTRYPOINT ["python"]
