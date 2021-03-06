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

module radiation
   
   !!< Radiation model initialisation, cleanup and solve procedures
   
   use futils
   use global_parameters, only : OPTION_PATH_LEN
   use spud
   use state_module   
   
   use radiation_particle
   use radiation_solve_module
   
   implicit none
   
   private 

   public :: radiation_initialise, &
             radiation_cleanup, &
             radiation_solve, &
             particle_type
         
contains

   ! --------------------------------------------------------------------------

   subroutine radiation_initialise(states_all, &
                                   particles) 
      
      !!< Initialise the radiation model via creating each particle
      
      type(state_type), dimension(:), intent(in) :: states_all
      type(particle_type), dimension(:), allocatable, intent(inout) :: particles
            
      ewrite(1,*) 'Initialise radiation model'
      
      ! create all particles                           
      call create(states_all, &
                  particles)
                  
      ewrite(1,*) 'Finished initialise radiation model'
      
   end subroutine radiation_initialise

   ! --------------------------------------------------------------------------

   subroutine radiation_cleanup(particles) 
   
      !!< Finalise the radiation model

      type(particle_type), dimension(:), allocatable, intent(inout) :: particles
      
      ewrite(1,*) 'Cleanup radiation model'
      
      ! destroy all particles
      call destroy(particles)

      ewrite(1,*) 'Finished cleanup radiation model'
                
   end subroutine radiation_cleanup

   ! --------------------------------------------------------------------------

   subroutine radiation_solve(particles, &
                              invoke_eigenvalue_solve) 
                              
      !!< Invoke the relevant radiation solver for each particle type
      
      type(particle_type), dimension(:), allocatable, intent(inout) :: particles
      logical, intent(in) :: invoke_eigenvalue_solve

      ! local variable
      integer :: p 
      character(len=OPTION_PATH_LEN) :: equation_type
      
      particle_type_loop: do p = 1,size(particles)
      
         call get_option(trim(particles(p)%option_path)//'/equation/name',equation_type)  
      
         which_solve: if (invoke_eigenvalue_solve) then
            
            solve_eig: if (trim(equation_type) == 'Eigenvalue') then
               
               ewrite(1,*) 'Solve radiation model eigenvalue for particle type ',trim(particles(p)%name)
               
               call radiation_solve_eigenvalue(particles(p))
            
            end if solve_eig
            
         else which_solve

            solve_time: if (trim(equation_type) == 'TimeDependent') then
               
               ewrite(1,*) 'Solve radiation model time for particle type ',trim(particles(p)%name)
               
               call radiation_solve_time(particles(p))

            end if solve_time
      
         end if which_solve

      end do particle_type_loop 
            
   end subroutine radiation_solve

   ! --------------------------------------------------------------------------

end module radiation
