program bench_fortran
  implicit none
  integer, parameter :: SIEVE_SIZE = 1000000
  integer, parameter :: SQRT_LIMIT = 1000
  logical, allocatable :: sieve(:)
  integer :: i, j, count
  real :: t_start, t_end, timeout
  character(len=32) :: arg1, arg2, arg3, arg4

  ! Check for proper command-line arguments.
  if (command_argument_count() < 4) then
     print *, "Usage: bench-fortran --timeout <sec> --mp <n-cores>"
     stop 1
  end if

  ! Get timeout (the second argument). We ignore the core count for now.
  call get_command_argument(1, arg1)  ! should be "--timeout"
  call get_command_argument(2, arg2)  ! the timeout value
  call get_command_argument(3, arg3)  ! should be "--mp"
  call get_command_argument(4, arg4)  ! the core count (ignored in this implementation)

  read(arg2, *) timeout

  count = 0
  call cpu_time(t_start)
  do
     allocate(sieve(1:SIEVE_SIZE))
     sieve = .true.
     sieve(1) = .false.
     sieve(2) = .false.
     do i = 2, SQRT_LIMIT
        if (sieve(i)) then
           do j = i*i, SIEVE_SIZE, i
              sieve(j) = .false.
           end do
        end if
     end do
     deallocate(sieve)
     count = count + 1
     call cpu_time(t_end)
     if (t_end - t_start >= timeout) exit
  end do

  print *, "-- Operations performed: ", count
end program bench_fortran