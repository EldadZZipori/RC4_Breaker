repo - https://github.com/EldadZZipori/RC4_Breaker

# RC4_Breaker
Digital design - Codebreaking Hardware Acceleration/Parallel processing

# SOF file location
/rtl/output_files/rc4.sof
# Lab status
### Task 1 ✔️
    Creating RAM, instantiating it, and writing to it.

#### Pseudocode
    for i in 0 to 255 {
        s[i] = i;
    }  
### Task 2 ✔️
    Building a single Decryption Core.
    Shuffling working memory (S), reading ROM (D) of encrypted data, decrypting data, write decrypted message to RAM (DE).

![Diagram of Task 2](https://github.com/EldadZZipori/RC4_Breaker/blob/main/doc/task_2_diagram.png)

#### Pseudocode
    j = 0
    for i = 0 to 255 {
        j = (j + s[i] + secret_key[i mod keylength] ) 
        swap values of s[i] and s[j]
    }
    i = 0, j=0
    for k = 0 to message_length-1 {
        i = i+1
        j = j+s[i]
        swap valsues of s[i] and s[j]
        f = s[ (s[i]+s[j]) ]
        decrypted_output[k] = f xor encrypted_input[k]
    }
### Task 3 ✔️
    Craking an RC-4 decryption, writing the current key to a HEX, indicating success on an LED.

    Brute forcing the correct key for a message using a single core. The key is generated by a Linear Feedback Shift Register (LFSR).
### Task 4 ✔️
    Cracking an RC-4 decryption using four different cores. Cores operate in parallel to find the key faster.
    
# Important location
    - Signal Tap
    /rtl/SignalTap.stp
    - Assigning data to S memory by index
    /rtl/task1/populate_s_mem_by_index.sv
    - Reading data from D memory
    /rtl/task2/read_rom_mem.sv
    - Writing decrypted data to DE memory
    /rtl/task2/de_data_writer.sv
    - Shuffeling S memory data
    /rtl/task2/shuffle_fsm.sv
    - Preforming Decryption
    /rtl/task2/decryptor_fsm.sv
    - Managing Decryption seququantialism 
    /rtl/task2/time_machine.sv
    - Reading data from switches for secret key
    /rtl/task2/switches_fsm.sv
    - Decryption core - combines all operations needed for decryption
    /rtl/task3/decryption_core.sv
    - Evaluation of decrypted data
    /rtl/task3/determine_valid_message.sv
    - HEX Display
    /rtl/task3/HEX_Control.sv
    - LFSR for secret key generation
    /rtl/task3/LFSR_Controller.sv

# Linear Feedback Shift Registers (LFSR)
Linear feeback shift registers are used in this project as an exersice to replace counters. LFSRs require less logic while generating a sequance of 2^m -1. They are very usefull when a brute force sequance is needed for that reason as they require much less logic then an adder, while only creating one less state (the all zeros in our case).

Simulation for this and pyhthon code to confirm use of the LFSR for our purposes can be found under - 
1. Simulation code - /sim/LFSR_Python_simulation.ipynb
2. Simulation image - /doc/LFSR_Python_simulation.png
# Diagrams 
System level diagram is provided. For more detailed diagram of the FSM's see /doc/fsm_diag
![System level diagram](https://github.com/EldadZZipori/RC4_Breaker/blob/main/doc/ksa_system_level_diagram.png)

# Simulations

### Assign data to RAM (S) by index
![Assign By Index FSM](https://github.com/EldadZZipori/RC4_Breaker/blob/main/doc/task_1_annotated_simulation.png)


### Synchronizing switches for secret key
![Switches Sync](https://github.com/EldadZZipori/RC4_Breaker/blob/main/doc/switches_fsm_annotated_simulation.png)


### Shuffling RAM (S) data 
![Shuffle FSM](https://github.com/EldadZZipori/RC4_Breaker/blob/main/doc/shuffle_fsm_annotated_simulation.png)

### Reading ROM (D) data 
![ROM Reader](https://github.com/EldadZZipori/RC4_Breaker/blob/main/doc/rom_reader_annotated_simulation.png)

### Decrypting message
![Decrypt Message](https://github.com/EldadZZipori/RC4_Breaker/blob/main/doc/decryption_fsm_annotated_simulation.png)

### Determine Valid Message 
![Determine 1](https://github.com/EldadZZipori/RC4_Breaker/blob/main/doc/determine_valid_message_annotated_simulation_1.png)

![Determine 2](https://github.com/EldadZZipori/RC4_Breaker/blob/main/doc/determine_valid_message_annotated_simulation_2.png)
### Time machine FSM - need to make

### State Machine Y

### State Machine Z

### Linear Feedback Shift Register 
# SignalTap (signal analyzer)

### Decrypted data RAM writer
![DE Writer FSM](https://github.com/EldadZZipori/RC4_Breaker/blob/main/doc/de_writer_fsm.png)

### Decryption (third loop) FSM
![Decryption FSM](https://github.com/EldadZZipori/RC4_Breaker/blob/main/doc/decryption_fsm.png)

### ROM data reader
![ROM Reader FSM](https://github.com/EldadZZipori/RC4_Breaker/blob/main/doc/rom_reader_signal_tap.png)

### Timing manager of complete algorithem (all three loops)
![Time machine FSM](https://github.com/EldadZZipori/RC4_Breaker/blob/main/doc/time_machine_fsm.png)

### Full Decryption Core
![Decryption Core FSM](https://github.com/EldadZZipori/RC4_Breaker/blob/main/doc/four_cores_operation_signal_tap.png)
