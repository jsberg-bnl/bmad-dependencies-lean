program test_blas
  implicit none
  real(kind(0d0)), dimension(8) :: x
  real(kind(0d0)) :: dnrm2
  external dnrm2

  x = 1d0
  write(*,'(f5.3)') dnrm2(size(x),x,1)
end program test_blas
