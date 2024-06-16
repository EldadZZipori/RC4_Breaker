# RC4_Breaker
Digital design - Codebreaking Hardware Acceleration/Parallel processing

# SOF file location

# Lab status
    ### TasK 1 [V]
    Creating RAM, instantiating it, and writing to it.

    #### Pseudocode
    for i in 0 to 255 {
        s[i] = i;
    }  
    ### Task 2 [V]
    Building a single Decryption Core.
    Shuffling working memory (S), reading ROM (D) of encrypted data, decrypting data, write decrypted message to RAM (DE).

    ![Diagram of Task 2](https://github.com/EldadZZipori/RC4_Breaker/tree/main/doc/task_2_diagram.png)

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
        swap values of s[i] and s[j]
        f = s[ (s[i]+s[j]) ]
        decrypted_output[k] = f xor encrypted_input[k]
    }
    ### Task 3 [V]
    ### Task 4 [in progress]
# Important location

# Diagrams 

# Simulations

# SignalTap (signal analyzer)
