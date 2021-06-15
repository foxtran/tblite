! This file is part of tblite.
! SPDX-Identifier: LGPL-3.0-or-later
!
! tblite is free software: you can redistribute it and/or modify it under
! the terms of the GNU Lesser General Public License as published by
! the Free Software Foundation, either version 3 of the License, or
! (at your option) any later version.
!
! tblite is distributed in the hope that it will be useful,
! but WITHOUT ANY WARRANTY; without even the implied warranty of
! MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
! GNU Lesser General Public License for more details.
!
! You should have received a copy of the GNU Lesser General Public License
! along with tblite.  If not, see <https://www.gnu.org/licenses/>.

!> API export for environment context setup
module tblite_api_context
   use, intrinsic :: iso_c_binding
   use mctc_env, only : error_type, fatal_error
   use tblite_context_type, only : context_type
   use tblite_api_error, only : vp_error
   use tblite_api_version, only : namespace
   use tblite_api_utils, only : f_c_character
   implicit none
   private

   public :: vp_context
   public :: new_context_api, check_context_api, get_context_error_api, delete_context_api


   !> Void pointer to manage calculation context
   type :: vp_context
      !> Actual payload
      type(context_type) :: ptr
   end type vp_context


   logical, parameter :: debug = .false.


contains


!> Create new calculation context object
function new_context_api() &
      & result(vctx) &
      & bind(C, name=namespace//"new_context")
   type(vp_context), pointer :: ctx
   type(c_ptr) :: vctx

   if (debug) print'("[Info]", 1x, a)', "new_context"

   allocate(ctx)
   vctx = c_loc(ctx)

end function new_context_api


!> Create new calculation context object
function check_context_api(vctx) result(status) &
      & bind(C, name=namespace//"check_context")
   type(vp_context), pointer :: ctx
   type(c_ptr), value :: vctx
   integer(c_int) :: status

   if (debug) print'("[Info]", 1x, a)', "check_context"

   if (c_associated(vctx)) then
      call c_f_pointer(vctx, ctx)

      status = merge(1, 0, ctx%ptr%failed())
   else
      status = 2
   end if

end function check_context_api


!> Get error message from calculation environment
subroutine get_context_error_api(vctx, charptr, buffersize) &
      & bind(C, name=namespace//"get_context_error")
   type(c_ptr), value :: vctx
   type(vp_context), pointer :: ctx
   character(kind=c_char), intent(inout) :: charptr(*)
   integer(c_int), intent(in), optional :: buffersize
   integer :: max_length
   type(error_type), allocatable :: error

   if (debug) print'("[Info]", 1x, a)', "get_context_error"

   if (c_associated(vctx)) then
      call c_f_pointer(vctx, ctx)

      if (present(buffersize)) then
         max_length = buffersize
      else
         max_length = huge(max_length) - 2
      end if

      call ctx%ptr%get_error(error)
      if (allocated(error)) then
         call f_c_character(error%message, charptr, max_length)
      end if
   end if

end subroutine get_context_error_api


!> Delete context object
subroutine delete_context_api(vctx) &
      & bind(C, name=namespace//"delete_context")
   type(c_ptr), intent(inout) :: vctx
   type(vp_context), pointer :: ctx

   if (debug) print'("[Info]", 1x, a)', "delete_context"

   if (c_associated(vctx)) then
      call c_f_pointer(vctx, ctx)

      deallocate(ctx)
      vctx = c_null_ptr
   end if

end subroutine delete_context_api


end module tblite_api_context
