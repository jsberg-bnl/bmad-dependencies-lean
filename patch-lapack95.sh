lapack95_prefix=LAPACK95/SRC/
ed -s "$lapack95_prefix"/f77_lapack_single_double_complex_dcomplex.f90 <<EOF
/INTERFACE LA_GGSVP/;/END INTERFACE/+1 d
.-1;/INTERFACE LA_TZRQF/;/END INTERFACE/+1 d
.-1;/INTERFACE LA_GEQPF/;/END INTERFACE/+1 d
.-1;/INTERFACE LA_GGSVD/;/END INTERFACE/+1 d
.-1;/INTERFACE LA_GEGV/;/END INTERFACE/+1 d
.-1;/INTERFACE LA_GEGS/;/END INTERFACE/+1 d
.-1;/INTERFACE LA_GELSX/;/END INTERFACE/+1 d
.-1;/SUBROUTINE SGELSX1/;/END SUBROUTINE SGELSX1/+1 d
.-1;/SUBROUTINE DGELSX1/;/END SUBROUTINE DGELSX1/+1 d
.-1;/SUBROUTINE CGELSX1/;/END SUBROUTINE CGELSX1/+1 d
.-1;/SUBROUTINE ZGELSX1/;/END SUBROUTINE ZGELSX1/+1 d
w
q
EOF
ed -s "$lapack95_prefix"/f95_lapack_single_double_complex_dcomplex.f90 <<EOF
/INTERFACE LA_GGSVD/;/END INTERFACE/+1 d
.-1;/INTERFACE LA_GEGV/;/END INTERFACE/+1 d
.-1;/INTERFACE LA_GEGS/;/END INTERFACE/+1 d
.-1;/INTERFACE LA_GELSX/;/END INTERFACE/+1 d
w
q
EOF
