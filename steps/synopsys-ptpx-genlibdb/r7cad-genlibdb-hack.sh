# ---------------------------------------------------------------------------------------
# Script: r7cad-genlibdb-hack.sh
# Purpose: This script is designed to run an older version of pt_shell (pts/M-2017.06).
# 
# Background: The latest version of pt_shell generates .lib and .db files containing
#             combinational loops within PE/MEM tiles. While the older version resolves 
#             this issue, it is only compatible with Red Hat 7 machines.
# 
# How It Works:
# 1. A shared mount point (/nsim) exists between r8cad and r7cad machines.
# 2. The script recreates the tool's runtime environment in a temporary folder under /nsim.
# 3. It then SSHs into the r7cad machine to execute the tool and copies the results back 
#    to the original build folder.
# 4. Since the adk/ directory is large, only the adk-setup scripts are copied, which 
#    recreate the necessary symlinks in the temporary folder.
#
# Note: We assume the user already put the ssh-key in both servers so no password is needed
# ---------------------------------------------------------------------------------------
pt_shell_tool=pts/M-2017.06
r7cad_machine=r7cad-intel16
user=$(whoami)

#---------------------------------------------------------------------------------------
# Working Directory
#---------------------------------------------------------------------------------------
source_dir=$(realpath ./)
temp_dir=$(mktemp -d "/nsim/${user}/r7cad-genlibdb-hack-temp-XXXXXX")
temp_adk_dir=${temp_dir}/adk-node
temp_inputs_dir=${temp_dir}/inputs
temp_logs_dir=${temp_dir}/logs
mkdir -p ${temp_adk_dir}
mkdir -p ${temp_inputs_dir}
mkdir -p ${temp_logs_dir}

#---------------------------------------------------------------------------------------
# Recreate the adk/
#---------------------------------------------------------------------------------------
# locate intel16-adk directory (e.g. 12-intel16-adk)
source_adk_dir=$(find ${source_dir}/.. -maxdepth 1 -name "*-intel16-adk" -type d -exec realpath {} \;)
cp ${source_adk_dir}/*.sh ${temp_adk_dir}
cp ${source_adk_dir}/*.py ${temp_adk_dir}
cp ${source_adk_dir}/mflowgen-run ${temp_adk_dir}
# recreate the adk in the temp folder
cd ${temp_adk_dir}
./mflowgen-run

#---------------------------------------------------------------------------------------
# Recreate the inputs/
#---------------------------------------------------------------------------------------
# copy the inputs over, except the adk and the hidden files
find ${source_dir}/inputs -maxdepth 1 ! -name ".*" ! -name "adk" -exec cp {} ${temp_inputs_dir} \;
# link the adk in the inputs folder
cd ${temp_inputs_dir}
ln -s ../adk-node/outputs/adk adk

#---------------------------------------------------------------------------------------
# Recreate the environments
#---------------------------------------------------------------------------------------
# copy the scripts over
cp -r ${source_dir}/scripts ${temp_dir}
cp ${source_dir}/*.tcl ${temp_dir}

#---------------------------------------------------------------------------------------
# Execute command
#---------------------------------------------------------------------------------------
# parameters needed by the tool, this should be provided by master program
# design_name=Tile_MemCore
# corner=bc
# order=read_design.tcl,genlibdb-constraints.tcl,extract_model.tcl

# execute the command in old server
ssh ${user}@${r7cad_machine} -t "\
    cd ${temp_dir}; \
    module load base ${pt_shell_tool}; \
    export design_name=${design_name}; \
    export corner=${corner}; \
    export order=${order}; \
    pt_shell -file START.tcl -output_log_file logs/pt.log \
    "

#---------------------------------------------------------------------------------------
# Copy results back
#---------------------------------------------------------------------------------------
cp -f  ${temp_dir}/*.pt  ${source_dir}/
cp -f  ${temp_dir}/*.db  ${source_dir}/
cp -f  ${temp_dir}/*.lib ${source_dir}/
cp -f  ${temp_dir}/*.log ${source_dir}/
cp -rf ${temp_dir}/logs  ${source_dir}/

#---------------------------------------------------------------------------------------
# Remove the temp directory
#---------------------------------------------------------------------------------------
trap "rm -rf ${temp_dir}" EXIT
