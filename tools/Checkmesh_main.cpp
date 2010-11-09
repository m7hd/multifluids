/*  Copyright (C) 2006 Imperial College London and others.
    
    Please see the AUTHORS file in the main source directory for a full list
    of copyright holders.

    Prof. C Pain
    Applied Modelling and Computation Group
    Department of Earth Science and Engineering
    Imperial College London

    amcgsoftware@imperial.ac.uk
    
    This library is free software; you can redistribute it and/or
    modify it under the terms of the GNU Lesser General Public
    License as published by the Free Software Foundation,
    version 2.1 of the License.

    This library is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    Lesser General Public License for more details.

    You should have received a copy of the GNU Lesser General Public
    License along with this library; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307
    USA
*/

#include <cstring>
#include <iostream>
#include <sstream>
#include <stdlib.h>

#include "confdefs.h"

#include "c++debug.h"

#ifdef HAVE_MPI
#include <mpi.h>
#endif

using namespace std;

extern "C"{
#define checkmesh F77_FUNC(checkmesh, CHECKMESH)
  void checkmesh(const char* basename, const int* basename_len);
}

void Usage(){
  cout << "Usage: checkmesh TRIANGLE_BASENAME\n"
       << "\n"
       << "Checks the validity of the supplied triangle mesh" << endl;
}

int main(int argc, char** argv){
#ifdef HAVE_MPI
  MPI::Init(argc, argv);
  // Undo some MPI init shenanigans
  chdir(getenv("PWD"));
#endif
    
  if(argc < 2){
    Usage();
    return -1;
  }
  
  // Logging
  int nprocs = 1;
#ifdef HAVE_MPI
  if(MPI::Is_initialized()){
    nprocs = MPI::COMM_WORLD.Get_size();
  }
#endif
if(nprocs > 1){
  int rank = 0;
#ifdef HAVE_MPI
  if(MPI::Is_initialized()){
    rank = MPI::COMM_WORLD.Get_rank();
  }
#endif
  ostringstream buffer;
  buffer << "checkmesh.log-" << rank;
  if(freopen(buffer.str().c_str(), "w", stdout) == NULL){
    cerr << "Failed to redirect stdout" << endl;
    exit(-1);
  }
  buffer.str("");
  buffer << "checkmesh.err-" << rank;
  if(freopen(buffer.str().c_str(), "w", stderr) == NULL){
    cerr << "Failed to redirect stderr" << endl;
    exit(-1);
  }
  buffer.str("");
  }

  // Verbosity
  int verbosity = 2;
  set_global_debug_level_fc(&verbosity);

  int basename_len = strlen(argv[1]);
  checkmesh(argv[1], &basename_len);

#ifdef HAVE_MPI
  MPI::Finalize();
#endif
  return 0;
}
