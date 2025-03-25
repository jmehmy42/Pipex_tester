#!/bin/bash

green='\033[1;32m'  # Bold green
red='\033[1;31m'    # Bold red
reset='\033[0m'
log_file="pipex_tester.log"

# Automatically run make to build the project
(cd ..&& make re) &>> "$log_file"
if [ $? -ne 0 ]; then
    echo -e "${red}Make failed! Please check the makefile and dependencies.${reset}"
    exit 1
else
    echo -e "${green}Make successful!${reset}"
fi

# Create infile with random text
echo "Generating infile with random text..."
echo "This is a randomly generated text file for testing Pipex." > infile
echo "Line 2: Pipex is a program that simulates a simplified version of a shell pipeline," >> infile
echo "Line 3: where multiple commands are executed in sequence, with the output " >> infile 
echo "Line 4: with the output of one command passed as input to the next." >> infile
echo "Line 5: It uses pipes to connect commands and handles the process creation with fork & execve." >> infile
echo "Line 6: The program supports handling input and output redirection," >> infile
echo "Line 7: and ensures proper error handling and cleanup." >> infile

echo "Starting Pipex Tester..." > "$log_file"

original_path="$PATH"

test_cases=(
    "valgrind --leak-check=full --track-fds=yes --show-leak-kinds=all --trace-children=yes ./pipex"
    "valgrind --leak-check=full --track-fds=yes --show-leak-kinds=all --trace-children=yes ./pipex noexitinfile cat cat outfile"
    "valgrind --leak-check=full --track-fds=yes --show-leak-kinds=all --trace-children=yes ./pipex infile '' '' outfile && cat outfile"
    "valgrind --leak-check=full --track-fds=yes --show-leak-kinds=all --trace-children=yes ./pipex infile cat '' outfile && cat outfile"
    "valgrind --leak-check=full --track-fds=yes --show-leak-kinds=all --trace-children=yes ./pipex infile cat wrongcmd outfile"
    "valgrind --leak-check=full --track-fds=yes --show-leak-kinds=all --trace-children=yes ./pipex infile wrongcmd wrongcmd outfile"
    "valgrind --leak-check=full --track-fds=yes --show-leak-kinds=all --trace-children=yes ./pipex infile cat cat"
    "valgrind --leak-check=full --track-fds=yes --show-leak-kinds=all --trace-children=yes ./pipex Makefile 'grep .c' cat outfile && cat outfile"
    "valgrind --leak-check=full --track-fds=yes --show-leak-kinds=all --trace-children=yes ./pipex Makefile cat 'cut -d \" \" -f1' outfile && cat outfile"
    "valgrind --leak-check=full --track-fds=yes --show-leak-kinds=all --trace-children=yes ./pipex infile cat cat outfile && cat outfile"
    "valgrind --leak-check=full --track-fds=yes --show-leak-kinds=all --trace-children=yes ./pipex infile cat 'cut -d \" \" -f1' outfile && cat outfile"
    "valgrind --leak-check=full --track-fds=yes --show-leak-kinds=all --trace-children=yes ./pipex infile 'grep a1' cat outfile && cat outfile"
    "valgrind --leak-check=full --track-fds=yes --show-leak-kinds=all --trace-children=yes ./pipex infile cakt cat outfile && cat outfile"
    "valgrind --leak-check=full --track-fds=yes --show-leak-kinds=all --trace-children=yes ./pipex infile 'ls -l' cat outfile && cat outfile"
    "valgrind --leak-check=full --track-fds=yes --show-leak-kinds=all --trace-children=yes ./pipex infile 'cat' 'wc -l' outfile && cat outfile"
    "chmod 000 infile outfile && valgrind --leak-check=full --track-fds=yes --show-leak-kinds=all --trace-children=yes ./pipex infile cat cat outfile && cat outfile"
    "valgrind --leak-check=full --track-fds=yes --show-leak-kinds=all --trace-children=yes ./pipex infile cat cat outfile && cat outfile"
    "valgrind --leak-check=full --track-fds=yes --show-leak-kinds=all --trace-children=yes ./pipex infile cat wrongcmd outfile && cat outfile"
    "valgrind --leak-check=full --track-fds=yes --show-leak-kinds=all --trace-children=yes ./pipex infile wrongcmd cat outfile && cat outfile"
    "valgrind --leak-check=full --track-fds=yes --show-leak-kinds=all --trace-children=yes ./pipex infile wrongcmd wrongcmd outfile && cat outfile"

    "chmod 777 infile outfile && valgrind --leak-check=full --track-fds=yes --show-leak-kinds=all --trace-children=yes ./pipex infile cat cat outfile && cat outfile"
    "valgrind --leak-check=full --track-fds=yes --show-leak-kinds=all --trace-children=yes ./pipex infile cat 'sleep 5' outfile && cat outfile"
    "valgrind --leak-check=full --track-fds=yes --show-leak-kinds=all --trace-children=yes ./pipex infile 'sleep 5' cat outfile && cat outfile"
    "valgrind --leak-check=full --track-fds=yes --show-leak-kinds=all --trace-children=yes ./pipex infile 'sleep 4' 'sleep 5' outfile && cat outfile"
    "valgrind --leak-check=full --track-fds=yes --show-leak-kinds=all --trace-children=yes ./pipex Makefile "/bin/cat" "/bin/cat" outfile"
)
# this command should print error messages unset path && ./pipex infile cat cat outfile 
# this command should run because using absolute path unset path && ./pipex infile "/bin/cat" "/bin/cat" outfile
export PATH="$original_path"
run_test() {
    echo "Running test: $1" | tee -a "$log_file"
    eval "$1" &> output.txt
    cat output.txt >> "$log_file"
    
    if grep -q "ERROR SUMMARY: 0 errors" output.txt && grep -q "All heap blocks were freed -- no leaks are possible" output.txt; then
        echo -e "${green}OK${reset}" | tee -a "$log_file"
    elif grep -q "No such file or directory" output.txt; then
        echo -e "${green}Path not found!${reset}" | tee -a "$log_file"
    else
        errors=""
        if ! grep -q "ERROR SUMMARY: 0 errors" output.txt; then
            errors+="Leaks detected! "
        fi
        if grep -q "FILE DESCRIPTORS: [1-9]" output.txt; then
            errors+="Open file descriptors detected! "
        fi
        echo -e "${red}KO${reset} $errors" | tee -a "$log_file"
        cat output.txt
    fi
    rm -f output.txt
}

for test in "${test_cases[@]}"; do
    run_test "$test"
done

