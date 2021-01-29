#!/bin/bash

# set the job name to hello-mpi
#SBATCH --job-name=hello-mpi

# send output to hello-mpi.out
#SBATCH --output=hello-mpi.out

# this job requests 2 nodes
#SBATCH --nodes=1

# this job requests exclusive access to the nodes it is given
# this mean it will be the only job running on the node
#SBATCH --exclusive

# --constraint=ib must be give to guarantee a job is allocated 
# nodes with Infiniband

# load the openmpi module
# module load openmpi

# Run the process with mpirun. Notice -n is not required. mpirun will
# automatically figure out how many processes to run from the slurm options
/usr/lib64/mpich-3.2/bin/mpirun /root/slurm/mpi-demo
