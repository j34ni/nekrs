FROM mambaorg/micromamba:1.5.10-noble

COPY start.sh /opt/

RUN . /opt/start.sh && \
     micromamba install -y -n base -c anaconda cmake=3.26.4 && \
     micromamba install -y -n base -c conda-forge gfortran_linux-aarch64=13.4.0 git make mvapich=4.1=shs_cuda_* && \
     micromamba clean -a -y

ENV  LD_LIBRARY_PATH=/opt/conda/lib/stubs:$LD_LIBRARY_PATH
RUN  ln -sf /opt/conda/lib/stubs/libcuda.so /opt/conda/lib/stubs/libcuda.so.1

RUN  ln -s /opt/conda/bin/aarch64-conda-linux-gnu-gcc-ar   /opt/conda/bin/ar
RUN  ln -s /opt/conda/bin/aarch64-conda-linux-gnu-gcc-ranlib /opt/conda/bin/ranlib

RUN  . /opt/start.sh && \
     git clone https://github.com/Nek5000/nekRS.git /var/tmp/nekRS && \
     cd /var/tmp/nekRS && \
     sed -i '14s/FORTRAN_UNPREFIXED(fchdir, FCHDIR)/FORTRAN_UNPREFIXED(nek_cchdir, NEK_CCHDIR)/' 3rd_party/nek5000/core/chelpers.c && \
     sed -i '1i #include <cstdint>' 3rd_party/occa/src/occa/internal/modes/dpcpp/polyfill.hpp && \
     sed -i 's/|no version information available//' config/utils.cmake && \
     CC=mpicc CXX=mpic++ FC=mpifort CFLAGS="-DUNDERSCORE -fPIC" CXXFLAGS="-fPIC" FFLAGS="-fPIC" LIBS="-lcudart -lcuda" cmake -S . -B build -DCMAKE_INSTALL_PREFIX=/opt/conda -DGNU=ON && \
     cmake --build build --target install --parallel $(nproc) && \
     sed -i 's/FORTRAN_UNPREFIXED(fchdir, FCHDIR)/FORTRAN_UNPREFIXED(nek_cchdir, NEK_CCHDIR)/g' /opt/conda/nek5000/core/chelpers.c && \
     sed -i 's/call fchdir/call nek_cchdir/g' /opt/conda/nek5000/core/comm_mpi.f && \
     rm -rf /var/tmp/nekRS && \
     rm /opt/conda/lib/stubs/libcuda.so.1
