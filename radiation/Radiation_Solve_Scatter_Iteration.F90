!    Copyright (C) 2006 Imperial College London and others.
!    
!    Please see the AUTHORS file in the main source directory for a full list
!    of copyright holders.
!
!    Prof. C Pain
!    Applied Modelling and Computation Group
!    Department of Earth Science and Engineering
!    Imperial College London
!
!    amcgsoftware@imperial.ac.uk
!    
!    This library is free software; you can redistribute it and/or
!    modify it under the terms of the GNU Lesser General Public
!    License as published by the Free Software Foundation,
!    version 2.1 of the License.
!
!    This library is distributed in the hope that it will be useful,
!    but WITHOUT ANY WARRANTY; without even the implied arranty of
!    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
!    Lesser General Public License for more details.
!
!    You should have received a copy of the GNU Lesser General Public
!    License along with this library; if not, write to the Free Software
!    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307
!    USA

#include "fdebug.h"

module radiation_solve_scatter_iteration

   !!< This module contains procedures associated with scatter iteration solver for radiation problems

   ! keep in this order, please:
   use quadrature
   use elements
   use sparse_tools
   use fields
   
   use futils
   use global_parameters, only : OPTION_PATH_LEN
   use spud
   use state_module  

   use radiation_materials
   use radiation_materials_interpolation
   use radiation_assemble_solve_group

   implicit none
   
   private 

   public :: scatter_iteration
   
   type scatter_iteration_options_type
      integer :: max_scatter_iteration
      integer :: highest_upscatter_group
      real :: tol_scatter_iteration
      logical :: terminate_if_not_converged_scatter
      character(len=OPTION_PATH_LEN) :: whole_domain_rebalance_scatter   
   end type scatter_iteration_options_type
   
contains

   ! --------------------------------------------------------------------------

   subroutine scatter_iteration(np_radmat, &
                                np_radmat_ii, &
                                state, &
                                np_radmat_name, &
                                number_of_energy_groups, &
                                keff) 
      
      !!< Perform iterations around the group loop to solve scatter
      
      type(np_radmat_type), intent(in) :: np_radmat
      type(np_radmat_ii_type), intent(in) :: np_radmat_ii
      type(state_type), intent(inout) :: state
      character(len=*), intent(in) :: np_radmat_name
      integer, intent(in) :: number_of_energy_groups
      real, intent(in), optional :: keff
      
      ! local variables
      integer :: iscatter
      integer :: start_group
      logical :: scatter_iteration_converged
      type(scatter_iteration_options_type) :: scatter_iteration_options
      character(len=OPTION_PATH_LEN) :: scatter_group_iteration_option_path
       
      ! set the scatter iteration option path
      scatter_path_if: if (present(keff)) then
      
         scatter_group_iteration_option_path = trim(np_radmat%option_path)//'/eigenvalue_run/power_iteration/scatter_group_iteration'
      
      else scatter_path_if
      
         scatter_group_iteration_option_path = trim(np_radmat%option_path)//'/time_run/energy_group_iteration/scatter_group_iteration'
      
      end if scatter_path_if
      
      call get_scatter_iteration_options(scatter_iteration_options, &
                                         trim(scatter_group_iteration_option_path))
           
      ! first iteration sweep down groups from 1
      start_group = 1
      
      scatter_iteration_loop: do iscatter = 1,scatter_iteration_options%max_scatter_iteration
         
         ewrite(1,*) 'Scatter iteration: ',iscatter
         
         call energy_group_loop(np_radmat, &
                                np_radmat_ii, &
                                state, &
                                trim(np_radmat_name), &
                                start_group, &
                                number_of_energy_groups, &
                                keff = keff)
         
         ! rebalance accelerate the scatter iteration if options chosen
         rebalance: if (trim(scatter_iteration_options%whole_domain_rebalance_scatter) /= 'none') then
         
            call scatter_iteration_whole_domain_rebalance()
         
         end if rebalance
         
         call check_scatter_iteration_convergence(scatter_iteration_converged)
         
         ! further iterations sweep down groups from highest_upscatter_group (which could be 1 again)
         start_group = scatter_iteration_options%highest_upscatter_group
         
      end do  scatter_iteration_loop

      need_to_terminate: if ((iscatter == scatter_iteration_options%max_scatter_iteration) .and. &
                              scatter_iteration_options%terminate_if_not_converged_scatter .and. &
                              (.not. scatter_iteration_converged)) then
         
         FLExit('Terminating as scatter iteration finished and solution NOT converged')
         
      end if need_to_terminate
            
   end subroutine scatter_iteration 

   ! --------------------------------------------------------------------------

   subroutine get_scatter_iteration_options(scatter_iteration_options, &
                                            scatter_group_iteration_option_path)
      
      !!< Get the scatter iteration options
      type(scatter_iteration_options_type), intent(out) :: scatter_iteration_options
      character(len=*), intent(in) :: scatter_group_iteration_option_path
       
      ! get the max scatter iteration and highest upscatter group and tolerance
      have_scatter_option: if (have_option(trim(scatter_group_iteration_option_path))) then
         
         call get_option(trim(scatter_group_iteration_option_path)//'/maximum',scatter_iteration_options%max_scatter_iteration)

         call get_option(trim(scatter_group_iteration_option_path)//'/flux_tolerance',scatter_iteration_options%tol_scatter_iteration)
         
         scatter_iteration_options%terminate_if_not_converged_scatter = have_option(trim(scatter_group_iteration_option_path)//'/terminate_if_not_converged')

         have_highest: if (have_option(trim(scatter_group_iteration_option_path)//'/highest_upscatter_group')) then
         
            call get_option(trim(scatter_group_iteration_option_path)//'/highest_upscatter_group',scatter_iteration_options%highest_upscatter_group)
         
         else have_highest
         
            scatter_iteration_options%highest_upscatter_group = 1
            
         end if have_highest

         have_rebalance: if (have_option(trim(scatter_group_iteration_option_path)//'/whole_domain_group_rebalance/all_group')) then
         
            scatter_iteration_options%whole_domain_rebalance_scatter = 'all_group'
         
         else if (have_option(trim(scatter_group_iteration_option_path)//'/whole_domain_group_rebalance/within_group')) then
         
            scatter_iteration_options%whole_domain_rebalance_scatter = 'within_group'
         
         else have_rebalance
         
            scatter_iteration_options%whole_domain_rebalance_scatter = 'none'
            
         end if have_rebalance
         
      else have_scatter_option
         
         scatter_iteration_options%max_scatter_iteration = 1 
         
         scatter_iteration_options%tol_scatter_iteration = 1.0

         scatter_iteration_options%terminate_if_not_converged_scatter = .false.
         
         scatter_iteration_options%highest_upscatter_group = 1
         
         scatter_iteration_options%whole_domain_rebalance_scatter = 'none'
               
      end if have_scatter_option   
       
   end subroutine get_scatter_iteration_options 

   ! --------------------------------------------------------------------------
   
   subroutine energy_group_loop(np_radmat, &
                                np_radmat_ii, &
                                state, &
                                np_radmat_name, &
                                start_group, &
                                number_of_energy_groups, &
                                keff)
      
      !!< Sweep the energy groups from the start_group down solving the within group neutral particle balance
      
      type(np_radmat_type), intent(in) :: np_radmat
      type(np_radmat_ii_type), intent(in) :: np_radmat_ii
      type(state_type), intent(inout) :: state
      character(len=*), intent(in) :: np_radmat_name
      integer, intent(in) :: start_group
      integer, intent(in) :: number_of_energy_groups
      real, intent(in), optional :: keff
      
      ! local variables
      integer :: g
      
      group_loop: do g = start_group,number_of_energy_groups
         
         ! Assemble and solve the group g neutral particle balance
         call np_assemble_solve_group(state, &
                                      trim(np_radmat_name), &
                                      np_radmat, &
                                      np_radmat_ii, &
                                      g, &
                                      number_of_energy_groups, &
                                      keff = keff)
         
      end do group_loop      
      
   end subroutine energy_group_loop

   ! --------------------------------------------------------------------------
   
   subroutine scatter_iteration_whole_domain_rebalance()  
      
      !!< 
      
      
   end subroutine scatter_iteration_whole_domain_rebalance

   ! --------------------------------------------------------------------------
   
   subroutine check_scatter_iteration_convergence(scatter_iteration_converged)  
      
      !!< Check the convergence of the scatter iterations
      
      logical, intent(out) :: scatter_iteration_converged
      
      scatter_iteration_converged = .true.
                  
   end subroutine check_scatter_iteration_convergence

   ! --------------------------------------------------------------------------

end module radiation_solve_scatter_iteration