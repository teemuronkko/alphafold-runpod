from multiprocessing import Pool, current_process, Queue
import os
import subprocess

# Get the current working directory
cd = os.getcwd()

# Run nvidia-smi to get GPU information
result = subprocess.run(["nvidia-smi", "--list-gpus"], stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)

# Set number of available GPUs and number of processes per GPU
N_GPUS = len(result.stdout.strip().split('\n'))
PROCESS_PER_GPU = 1    

# Empty queue to store GPU ids
gpu_queue = Queue()

# Helper function to launch AF2 on a GPU
def launch_af2(filename):
    gpu_id = gpu_queue.get()
    try:
        # Get the process id of current process
        id = current_process().ident
        print('Launching AF2 job with ID {} and input file {} starting on GPU {}'.format(id, filename, gpu_id))
        
        # Launch AF2 job on the GPU
        AF2_command = f"bash {cd}/launch_af2_single.sh {filename} {gpu_id}"
        subprocess.run(AF2_command, shell=True)

        # Print the process id of the finished job
        print(f'Finished AF2 job with ID {id} for {filename} finished')

    finally:
        gpu_queue.put(gpu_id)

# Fill the queue with GPU ids
for gpu_ids in range(N_GPUS):
    for _ in range(PROCESS_PER_GPU):
        gpu_queue.put(gpu_ids)

# Path to the text file containing the paths to the fasta files
input_path = "/workspace/Complexes.txt"

# Open the text file and read the paths to the fasta files
with open(input_path, "r") as file:
    fasta_paths = [ line.strip() for line in file ]

# Create a pool of workers and launch the jobs on the pool
pool = Pool(processes=PROCESS_PER_GPU * N_GPUS)
for _ in pool.imap_unordered(launch_af2, fasta_paths):
    pass
pool.close()
pool.join()
